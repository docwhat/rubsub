#!/bin/bash

set -eu
# ftp://ftp.ruby-lang.org/pub/ruby/1.$rvm_major_version/$rvm_ruby_package_file.$rvm_archive_extension
rvm_dir="${HOME}/.rvm2"
ruby_ext=".tar.gz"
ruby_url="http://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p248${ruby_ext}"
ruby_md5="60a65374689ac8b90be54ca9c61c48e3"
ruby_base="$(basename ${ruby_url} ${ruby_ext})"
tarball="cache/${ruby_base}${ruby_ext}"

rvm_fetch() {
    echo "Fetching ${ruby_url}..."
    pushd cache

    set +e
    curl -O -L -C - "${ruby_url}"
    # Extra checking could be done here with $?
    # See rvm_verify() for an example.
    set -e

    popd
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

rvm_compile() {
    pushd tmp

    rm -rf "${ruby_base}"
    gzip -dc ../${tarball} | tar xf -

    cd "${ruby_base}"
    ./configure --prefix="${rvm_dir}/miniruby"
    make miniruby

    # Install
    cp -r miniruby lib bin/irb "${rvm_dir}/miniruby"
    ln -s . "${rvm_dir}/miniruby/lib/ruby"
    ln -s . "${rvm_dir}/miniruby/lib/site_ruby"

    # Cleanup
    cd ..
    rm -rf "${ruby_base}"

    popd
}

rvm_install() {
    echo "Fetching rvm..."
    echo NOT DONE YET
}

# Setup the rvm2 directory.
[[ -d "${rvm_dir}" ]] || mkdir "${rvm_dir}"
cd "${HOME}/.rvm2"

# These directories can be re-used.
[[ -d cache ]] || mkdir cache
[[ -d tmp ]] || mkdir tmp

# This directory must be removed every-time.
if [[ -d miniruby ]]; then
    rm -rf miniruby
fi
mkdir miniruby

# Fetch it if we don't have it.
if [[ ! -r "${tarball}" ]]; then
    rvm_fetch
fi

# Verify that the tarball downloaded correctly.
rvm_verify

# Compile mini-ruby
rvm_compile

# Fetch and install the latest rvm2 code.
rvm_install

echo "...done!"

# EOF
