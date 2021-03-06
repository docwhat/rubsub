#!/bin/bash

set -eu
# ftp://ftp.ruby-lang.org/pub/ruby/1.$rubsub_major_version/$rubsub_ruby_package_file.$rubsub_archive_extension
start_dir="$(pwd -P)"
if [[ -n "${RUBSUB_DIR:-}" && -d "$(dirname ${RUBSUB_DIR})" ]]; then
    rubsub_dir="${RUBSUB_DIR}"
else
    rubsub_dir="${HOME}/.rubsub"
fi
ruby_ext=".tar.gz"

ruby_url="http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.1-p378${ruby_ext}"
ruby_md5="9fc5941bda150ac0a33b299e1e53654c"
ruby_rebuild_version=10

ruby_base="$(basename ${ruby_url} ${ruby_ext})"
log_dir="${rubsub_dir}/log"
tarball="archive/${ruby_base}${ruby_ext}"

# Get the current version, needed for upgrading.
if [[ -r "${rubsub_dir}/VERSION" ]]; then
    VERSION=$(cat "${rubsub_dir}/VERSION")
else
    VERSION=0
fi

# Is this to be installed from a local copy?
if [[ "$(basename $0)" = 'rubsub-install.bash' ]]; then
    basedir="$(dirname $0)"
    if [[ -r "${basedir}/README" ]]; then
        if [[ "$(head -n1 ${basedir}/README)" = '=RUBSUB=' ]]; then
            LOCAL_INSTALL=yes
        fi
    fi
fi

function rubsub_fetch {
    echo "Fetching ${ruby_url}..."
    cd archive

    set +e
    curl -D/dev/null -O -L -C - "${ruby_url}" \
        > "${log_dir}/fetch.log" 2>&1
    # Extra checking could be done here with $?
    # See rubsub_verify for an example.
    set -e

    # Reset directory
    cd "${rubsub_dir}"
}

function rubsub_verify {
    echo "Checking the md5sum..."
    local md5

    if [[ -x "/usr/bin/openssl" ]]; then
        md5=$(/usr/bin/openssl md5 "${tarball}" | cut -d ' ' -f 2)
    else
        md5=$(md5sum "${tarball}" | cut -d ' ' -f 1)
    fi

    if [[ "${md5}" != "${ruby_md5}"  ]]; then
        echo "Failed download: md5 checksums don't match."
        exit 1
    fi
}

function rubsub_install_myruby {
    local ec=1
    if [[ -r "${rubsub_dir}/myruby/.version" ]]; then
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

        # Compile rubsub's ruby.
        cd "${ruby_base}"
        ./configure \
            --prefix="${rubsub_dir}/myruby" \
            > "${log_dir}/myruby-configure.log" 2>&1
        make all \
            > "${log_dir}/myruby-make.log" 2>&1

        # Install the ruby.
        make install \
            > "${log_dir}/myruby-make.log" 2>&1

        # Verify it has everything we need.
        local libs="zlib openssl readline iconv"
        echo "Verifying ruby has required libs: ${libs}"
        for lib in ${libs}; do
            if ! "${rubsub_dir}/myruby/bin/ruby" -e "require '${lib}'"; then
                echo "Ruby seems to have failed to compile correctly."
                echo "Please make sure you have the '${lib}' development files installed."
                exit 11
            fi
        done


        # Write a version
        echo "${ruby_md5}" > "${rubsub_dir}/myruby/.version"

    else
        echo "Reusing the previous version of internal ruby..."
    fi

    # Install some handy gems
    for gem in nokogiri open4 rspec ZenTest diff-lcs; do
        if [[ ! -r "${rubsub_dir}/myruby/.gem-${gem}" ]]; then
            echo "Installing gem ${gem}..."
            set +e
            ${rubsub_dir}/myruby/bin/gem install ${gem} >> "${log_dir}/myruby-gem-${gem}.log" 2>&1
            ec=$?
            if [[ "${ec}" != '0' ]]; then
                echo "Failed installing ${gem}...See ${log_dir}/myruby-gem-${gem}.log for more information."
                exit ${ec}
            fi
            set -e
            touch "${rubsub_dir}/myruby/.gem-${gem}"
        fi
    done

    # Reset directory
    cd "${rubsub_dir}"
}

function rubsub_fetch_rubsub {
    if [[ "${LOCAL_INSTALL:-no}" = "yes" ]]; then
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

    fi

    # Reset directory
    cd "${rubsub_dir}"
}

function rubsub_install_rubsub {
    echo "Installing rubsub library..."

    # Install the contents of bin.
    rm -rf bin
    mkdir bin
    for template in src/"${rubsub_src}"/template/*; do
        bin="bin/$(basename ${template} .rb)"

        echo '#!'"${rubsub_dir}/myruby/bin/ruby"      >> "${bin}"
        cat "${template}"                          >> "${bin}"

        chmod a+x "${bin}"
    done

    # Re-install our libs.
    rm -rf "${rubsub_dir}/myruby/lib/ruby/vendor_ruby"
    cp -r  "${rubsub_dir}/src/${rubsub_src}/lib" "${rubsub_dir}/myruby/lib/ruby/vendor_ruby"

    # Save the version for update checks.
    cp src/"${rubsub_src}"/VERSION VERSION

    # Reset directory
    cd "${rubsub_dir}"
}

# Setup the rubsub directory.
[[ -d "${rubsub_dir}" ]] || mkdir "${rubsub_dir}"
cd "${rubsub_dir}"

# These directories can be re-used.
for dir in archive src log config db sessions; do
    [[ -d ${dir} ]] || mkdir ${dir}
done

# Fetch it if we don't have it.
if [[ ! -r "${tarball}" ]]; then
    rubsub_fetch
fi

# Verify that the tarball downloaded correctly.
rubsub_verify

# Fetch the latest rubsub code.
rubsub_fetch_rubsub

# Compile and install mini-ruby
rubsub_install_myruby

# Install rubsub into myruby.
rubsub_install_rubsub

echo "...done!"

if [[ -z "${RUBSUB_SESSION:-}" || ! -d "${rubsub_dir}/sessions/${RUBSUB_SESSION}" ]]; then
cat <<EOF

To use RubSub, you need your session set up.

To do this, you should "eval" the rubsub-session command.

An example for bourne shells would be:

if [[ -s ${rubsub_dir}/bin/rubsub-session ]] ; then eval \`${rubsub_dir}/bin/rubsub-session\`; fi

Place this command in your shell's startup script.

EOF
else
    "${rubsub_dir}/bin/rubsub" reset
fi

# EOF
