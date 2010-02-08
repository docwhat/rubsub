require 'rubsub/constants'
require 'rubsub/utils'
require 'rubsub/ruby_version'
require 'net/http'
require 'fileutils'

module RubSub

  class Session
    SESSION_CHARS = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    attr_reader :sid

    # initialize -- Pass in :new to allow a new session to be created.
    def initialize type = :old
      @sid = ENV[RubSub::SESSION_VARIABLE]
      @sid = nil unless not @sid.nil? and File.exists? bin_dir


      if @sid.nil?
        if :new == type
          # Generate a new session id.
          while @sid.nil?
            tmp = ''
            1.upto(rand(16)) { |i| tmp << SESSION_CHARS[rand(SESSION_CHARS.size-1)] }
            @sid = tmp unless File.exists? File.join(RubSub::SESSION_DIR, tmp)
          end

          # Create the session directory.
          Dir.mkdir dir
          Dir.mkdir bin_dir
        else
          raise "You must run rubsub-session first"
        end
      end
    end

    # dir -- The session directory.
    def dir
      File.join RubSub::SESSION_DIR, @sid
    end

    # bin_dir -- The session bin directory.
    def bin_dir
      File.join dir, 'bin'
    end

    # fetch_page -- Fetches a single page and returns the text.
    def fetch_page url
      uri = URI.parse(url)

      http = Net::HTTP.new(uri.host, uri.port)
      response = http.request(Net::HTTP::Get.new(uri.request_uri))

      response.body
    end

    # fetch_versions -- Fetch the versions of ruby.
    def fetch_versions
      require 'pp'

      response = fetch_page 'http://ftp.ruby-lang.org/pub/ruby/'
    end

    ###########################
    ######## Commands #########

    def info_cmd kind=nil
      # Set up the current link
      if File.symlink? File.join(dir, 'current')
        version = File.basename(File.readlink(File.join(dir, 'current')))
      else
        version = 'none'
      end
      puts "Current ruby version: #{version}"
    end

    def set_ruby_cmd version
      v = findVersion version
      ruby_dir = v.path
      reset_cmd v

      # Set up the current link
      path = File.join(dir, 'current')
      File.unlink path if File.exists? path or File.symlink? path
      File.symlink ruby_dir, path

      puts "Using #{v}"
    end

    def reset_cmd version=nil
      if version.nil?
        current = File.join(dir, 'current')
        return set_ruby_cmd 'default' unless File.exists? current
        version = makeVersion(File.basename(File.readlink(current)))
      else
        version = makeVersion version
      end
      ruby_dir = version.path

      raise NoSuchRubyError, version, caller unless File.directory? ruby_dir

      # Remove old symlinks
      Dir.entries(bin_dir).find_all {|i| not i.starts_with? '.'}.each do |f|
        path = File.join(bin_dir, f)
        File.unlink path if File.exists? path or File.symlink? path
      end

      Dir.entries(File.join(ruby_dir, 'bin')).find_all {|i| not i.starts_with? '.'}.each do |fname|
        if not version.is_a? MyRubyVersion
          # We need a special shell script to control variables.
          File.open(File.join(bin_dir, fname), 'w') do |fh|
            fh.write <<EOF
#!/bin/sh

#{File.join(ruby_dir, 'bin', fname)} "$@"
EOF

            fh.write "#{File.join(RubSub::BIN_DIR, 'rubsub')} reset\n" if ['gem'].include? fname
          end
          File.chmod 0755, File.join(bin_dir, fname)
        else
          binary = File.join(ruby_dir, 'bin', fname)
          File.symlink binary, File.join(bin_dir, fname)
        end
      end
    end

    def install_ruby_cmd version, force=false
      version = makeVersion version
      return if version.is_a? MyRubyVersion
      tarball = fetch_ruby_cmd version
      unpack_dir = File.join(RubSub::SRC_DIR,    version.to_s)
      final_dir  = File.join(RubSub::RUBIES_DIR, version.to_s)

      if File.directory? final_dir and not force
        raise "#{version} is already built."
      else
        FileUtils.rm_rf unpack_dir
        FileUtils.rm_rf final_dir

        RubSub.unpack tarball, RubSub::SRC_DIR

        RubSub.compile unpack_dir
      end
    end

    def remove_ruby_cmd version
      raise 'Not Implemented'
    end

    # fetch_ruby -- Fetch the requested version of ruby.
    def fetch_ruby_cmd version
      version = makeVersion version
      if not File.exists? version.tarball_path
        #url = "http://ftp.ruby-lang.org/pub/ruby/1.$rubsub_major_version/$rubsub_ruby_package_file.$rubsub_archive_extension"
        raise 'Not Implemented'
      end
      return tarball
    end

  end # End class Session
end