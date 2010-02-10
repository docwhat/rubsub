#!/bin/bash

set -eu
# ftp://ftp.ruby-lang.org/pub/ruby/1.$rubsub_major_version/$rubsub_ruby_package_file.$rubsub_archive_extension
start_dir="$(pwd -P)"
rubsub_dir="${HOME}/.rubsub"
ruby_ext=".tar.gz"

# Ruby 1.8.7
#ruby_url="http://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p248${ruby_ext}"
#ruby_md5="60a65374689ac8b90be54ca9c61c48e3"

ruby_url="http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.1-p378${ruby_ext}"
ruby_md5="9fc5941bda150ac0a33b299e1e53654c"

ruby_base="$(basename ${ruby_url} ${ruby_ext})"
log_dir="${rubsub_dir}/log"
tarball="archive/${ruby_base}${ruby_ext}"

# Is this to be installed from a local copy?
if [ "$(basename $0)" = 'rubsub-install.sh' ]; then
    basedir="$(dirname $0)"
    if [ -r "${basedir}/README" -a "$(head -n1 ${basedir}/README)" = '=RUBSUB=' ]; then
        LOCAL_INSTALL=yes
    fi
fi

rubsub_fetch() {
    echo "Fetching ${ruby_url}..."
    cd archive

    set +e
    curl -D/dev/null -O -L -C - "${ruby_url}" \
        > "${log_dir}/fetch.log" 2>&1
    # Extra checking could be done here with $?
    # See rubsub_verify() for an example.
    set -e

    # Reset directory
    cd "${rubsub_dir}"
}

rubsub_verify() {
    echo "Checking the md5sum..."

    set +e
    echo "${ruby_md5}  ${tarball}" | md5sum --check --status
    result=$?
    set -e

    if [[ ${result} -ne 0 ]]; then
        echo "Failed download: md5sum doesn't match."
        exit 1
    fi
}

rubsub_install_myruby() {
    if [ -r "${rubsub_dir}/myruby/.version" ]; then
        myruby_version="$(cat ${rubsub_dir}/myruby/.version)"
    fi
    if [ "${myruby_version:-}" != "${ruby_md5}" ]; then
        echo "Compiling a new version of internal ruby..."
        # Purge the oldversion
        rm -rf myruby
        mkdir myruby

        cd src

        rm -rf "${ruby_base}"
        gzip -dc ../${tarball} | tar xf -

        # Compile rubsub
        cd "${ruby_base}"
        ./configure \
            --prefix="${rubsub_dir}/myruby" \
            > "${log_dir}/myruby-configure.log" 2>&1
        make all \
            > "${log_dir}/myruby-make.log" 2>&1
        make install \
            > "${log_dir}/myruby-make.log" 2>&1

        # Install some handy gems
        ${rubsub_dir}/myruby/bin/gem install rspec ZenTest diff-lcs \
            > "${log_dir}/myruby-gem.log" 2>&1

        # Write a version
        echo "${ruby_md5}" > "${rubsub_dir}/myruby/.version"

    else
        echo "Reusing the previous version of internal ruby..."
    fi

    # Reset directory
    cd "${rubsub_dir}"
}

rubsub_install_rubsub() {
    if [ "${LOCAL_INSTALL:-no}" = "yes" ]; then
        echo "Getting your local rubsub..."
        # This is an install for testing and debugging.
        rubsub_src="rubsub-local"
        rsync -ravC --delete --delete-excluded "${start_dir}/" "${rubsub_dir}/src/${rubsub_src}/" \
            > "${log_dir}/rsync.log" 2>&1
    else
        echo "Fetching latest rubsub..."
        # This is the real install proceedure.
        rm -f "${rubsub_dir}/archive/rubsub-latest.tgz"
        curl  -D/dev/null -L -o "${rubsub_dir}/archive/rubsub-latest.tgz" \
            http://github.com/docwhat/rubsub/tarball/stable
            > "${log_dir}/fetch.log" 2>&1

        cd src
        rubsub_src="$(tar tf ${rubsub_dir}/archive/rubsub-latest.tgz | head -n1)"
        tar xf "${rubsub_dir}/archive/rubsub-latest.tgz"

        # Reset directory
        cd "${rubsub_dir}"
    fi

    # Install the contents of bin.
    rm -rf bin
    mkdir bin
    for template in src/"${rubsub_src}"/template/*; do
        bin="bin/$(basename ${template} .rb)"

        echo '#!'"${rubsub_dir}/myruby/bin/ruby"      >> "${bin}"
        cat "${template}"                          >> "${bin}"

        chmod a+x "${bin}"
    done

    # Install our libs.
    rm -rf myruby/lib/ruby/vendor_ruby
    cp -r src/"${rubsub_src}"/lib myruby/lib/ruby/vendor_ruby
}

# Setup the rubsub directory.
[[ -d "${rubsub_dir}" ]] || mkdir "${rubsub_dir}"
cd "${HOME}/.rubsub"

# These directories can be re-used.
for dir in archive src log config; do
    [[ -d ${dir} ]] || mkdir ${dir}
done

# Fetch it if we don't have it.
if [[ ! -r "${tarball}" ]]; then
    rubsub_fetch
fi

# Verify that the tarball downloaded correctly.
rubsub_verify

# Compile and install mini-ruby
rubsub_install_myruby

# Fetch and install the latest rubsub code.
rubsub_install_rubsub

echo "...done!"

# EOF
