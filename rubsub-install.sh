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
ruby_rebuild_version=6

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
    if [[ "${myruby_version:-}" != "${ruby_md5}" || ${VERSION} -lt ${ruby_rebuild_version} ]]; then
        echo "Compiling a new version of internal ruby..."
        # Purge the oldversion
        rm -rf myruby
        mkdir myruby

        # Clean the logs.
        rm -f "${log_dir}"/myruby-*.log

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

        # Write a version
        echo "${ruby_md5}" > "${rubsub_dir}/myruby/.version"

    else
        echo "Reusing the previous version of internal ruby..."
    fi

    # Install some handy gems
    for gem in nokogiri open4 rspec ZenTest diff-lcs; do
        if [ ! -r "${rubsub_dir}/myruby/.gem-${gem}" ]; then
            echo "Installing gem ${gem}..."
            ${rubsub_dir}/myruby/bin/gem install ${gem} >> "${log_dir}/myruby-gem-${gem}.log" 2>&1
            touch "${rubsub_dir}/myruby/.gem-${gem}"
        fi
    done

    # Re-install our libs.
    rm -rf "${rubsub_dir}/myruby/lib/ruby/vendor_ruby"
    cp -r  "${rubsub_dir}/src/${rubsub_src}/lib" "${rubsub_dir}/myruby/lib/ruby/vendor_ruby"

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

    # Save the version for update checks.
    cp src/"${rubsub_src}"/VERSION VERSION

    # We'll need this later.
    VERSION=$(cat VERSION)
}

# Setup the rubsub directory.
[[ -d "${rubsub_dir}" ]] || mkdir "${rubsub_dir}"
cd "${HOME}/.rubsub"

# These directories can be re-used.
for dir in archive src log config db; do
    [[ -d ${dir} ]] || mkdir ${dir}
done

# Fetch it if we don't have it.
if [[ ! -r "${tarball}" ]]; then
    rubsub_fetch
fi

# Verify that the tarball downloaded correctly.
rubsub_verify

# Fetch and install the latest rubsub code.
rubsub_install_rubsub

# Compile and install mini-ruby
rubsub_install_myruby

echo "...done!"

if [[ -z "${RUBSUB_SESSION:-}" || ! -d "${rubsub_dir}/sessions/${RUBSUB_SESSION}" ]]; then
cat <<EOF

To use RubSub, you need your session set up.

To do this, you should "eval" the rubsub-session command.

An example for bourne shells would be:

if [[ -s \$HOME/.rubsub/bin/rubsub-session ]] ; then eval \`\$HOME/.rubsub/bin/rubsub-session\`; fi

Place this command in your shell's startup script.

EOF
fi

# EOF
