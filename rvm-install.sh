#!/bin/bash

set -eu
# ftp://ftp.ruby-lang.org/pub/ruby/1.$rvm_major_version/$rvm_ruby_package_file.$rvm_archive_extension
start_dir="$(pwd -P)"
rvm_dir="${HOME}/.rvm2"
ruby_ext=".tar.gz"
ruby_url="http://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p248${ruby_ext}"
ruby_md5="60a65374689ac8b90be54ca9c61c48e3"
ruby_base="$(basename ${ruby_url} ${ruby_ext})"
log_dir="${rvm_dir}/log"
tarball="archive/${ruby_base}${ruby_ext}"

# Is this to be installed from a local copy?
if [ "$(basename $0)" = 'rvm-install.sh' ]; then
    basedir="$(dirname $0)"
    if [ -r "${basedir}/README" -a "$(head -n1 ${basedir}/README)" = '=RVM2=' ]; then
        LOCAL_INSTALL=yes
    fi
fi

rvm_fetch() {
    echo "Fetching ${ruby_url}..."
    cd archive

    set +e
    curl -D/dev/null -O -L -C - "${ruby_url}" \
        > "${log_dir}/fetch.log" 2>&1
    # Extra checking could be done here with $?
    # See rvm_verify() for an example.
    set -e

    # Reset directory
    cd "${rvm_dir}"
}

rvm_verify() {
    echo "Checking the md5sum..."

    set +e
    echo "${ruby_md5}  ${tarball}" | md5sum --check --quiet
    result=$?
    set -e

    if [[ ${result} -ne 0 ]]; then
        echo "Failed download: md5sum doesn't match."
        exit 1
    fi
}

rvm_install_miniruby() {
    if [ -r "${rvm_dir}/miniruby/.version" ]; then
        miniruby_version="$(cat ${rvm_dir}/miniruby/.version)"
    fi
    if [ "${miniruby_version:-}" != "${ruby_md5}" ]; then
        echo "Compiling a new version of miniruby..."
        # Purge the oldversion
        rm -rf miniruby
        mkdir miniruby

        cd src

        rm -rf "${ruby_base}"
        gzip -dc ../${tarball} | tar xf -

        # Compile rvm
        cd "${ruby_base}"
        ./configure --prefix="${rvm_dir}/miniruby" \
            > "${log_dir}/miniruby-configure.log" 2>&1
        make miniruby .rbconfig.time \
            > "${log_dir}/miniruby-make.log" 2>&1

        # Install
        cp -r miniruby lib bin/irb "${rvm_dir}/miniruby"
        cp rbconfig.rb "${rvm_dir}/miniruby/lib"
        ln -s . "${rvm_dir}/miniruby/lib/ruby"
        ln -s . "${rvm_dir}/miniruby/lib/site_ruby"

        # Cleanup
        make clean \
            > "${log_dir}/miniruby-clean.log" 2>&1

        # Write a version
        echo "${ruby_md5}" > "${rvm_dir}/miniruby/.version"

    else
        echo "Reusing the previous version of miniruby..."
    fi

    # Reset directory
    cd "${rvm_dir}"
}

rvm_install_rvm() {
    if [ "${LOCAL_INSTALL:-no}" = "yes" ]; then
        echo "Getting your local rvm2..."
        # This is an install for testing and debugging.
        rvm_src="rvm-local"
        rsync -ravC --delete --delete-excluded "${start_dir}/" "${rvm_dir}/src/${rvm_src}/" \
            > "${log_dir}/rsync.log" 2>&1
    else
        echo "Fetching latest rvm2..."
        # This is the real install proceedure.
        rm -f "${rvm_dir}/archive/rvm-latest.tgz"
        curl  -D/dev/null -L -o "${rvm_dir}/archive/rvm-latest.tgz" \
            http://github.com/docwhat/rvm2/tarball/stable
            > "${log_dir}/fetch.log" 2>&1

        cd src
        rvm_src="$(tar tf ${rvm_dir}/archive/rvm-latest.tgz | head -n1)"
        tar xf "${rvm_dir}/archive/rvm-latest.tgz"

        # Reset directory
        cd "${rvm_dir}"
    fi

    # Install the contents of bin.
    rm -rf bin
    mkdir bin
    for template in src/"${rvm_src}"/template/*; do
        bin="bin/$(basename ${template} .rb)"

        echo '#!'"${rvm_dir}/miniruby/miniruby"    >> "${bin}"
        cat "${template}"                          >> "${bin}"

        chmod a+x "${bin}"
    done

    # Install our libs.
    cp -r src/"${rvm_src}"/vendor_ruby miniruby/lib
}

# Setup the rvm2 directory.
[[ -d "${rvm_dir}" ]] || mkdir "${rvm_dir}"
cd "${HOME}/.rvm2"

# These directories can be re-used.
for dir in archive src log; do
    [[ -d ${dir} ]] || mkdir ${dir}
done

# Fetch it if we don't have it.
if [[ ! -r "${tarball}" ]]; then
    rvm_fetch
fi

# Verify that the tarball downloaded correctly.
rvm_verify

# Compile and install mini-ruby
rvm_install_miniruby

# Fetch and install the latest rvm2 code.
rvm_install_rvm

echo "...done!"

# EOF
