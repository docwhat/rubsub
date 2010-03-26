require 'rubsub/constants'
require 'rubsub/utils'
require 'rubsub/ruby_version'
require 'net/http'
require 'fileutils'
require 'tmpdir'

module RubSub

  class Session
    SESSION_CHARS = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    attr_reader :sid

    # initialize -- Pass in :new to allow a new session to be created.
    def initialize type = :old
      @sid = ENV[RubSub::SESSION_VARIABLE]

      if @sid.nil? and :new == type
        # Generate a new session id.
        while @sid.nil?
          tmp = ''
          1.upto(rand(16)) { |i| tmp << SESSION_CHARS[rand(SESSION_CHARS.size-1)] }
          @sid = tmp unless File.exists? File.join(RubSub::SESSION_DIR, tmp)
        end
      end

      raise "You must run rubsub-session first" if @sid.nil?

      unless File.directory? dir
        # Create the session directory.
        Dir.mkdir dir
        Dir.mkdir bin_dir
        # Reset it.
        reset_cmd
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
      puts "RubSub version: #{RubSub::VERSION}"
      puts "Current ruby version: #{version}"
    end

    # set_default_cmd -- Sets the default ruby. Not necessarily a session command.
    def set_default_cmd version
      v = findVersion version
      set_default v
      puts "The default is now #{v}."
    end

    def set_ruby_cmd version
      if version == "system"
        v = :system
      else
        v = findVersion version
      end

      reset_cmd v

      # Set up the current link
      path = File.join(dir, 'current')
      File.unlink path if File.exists? path or File.symlink? path
      File.symlink v.path, path unless v == :system

      puts "Using #{v}"
    end

    # reset_cmd -- Resets the symlinks based on version.
    def reset_cmd version=nil
      if version.nil?
        # Try to get the version from the symlink.
        current = File.join(dir, 'current')
        if File.exists? current
          version = makeVersion(File.basename(File.readlink(current)))
        else
          version = get_default
        end
      elsif version != :system
        version = makeVersion version
      end

      raise NoSuchRubyError, version, caller unless version == :system or File.directory? version.path

      # Remove old symlinks
      Dir.entries(bin_dir).find_all {|i| not i.starts_with? '.'}.each do |f|
        path = File.join(bin_dir, f)
        File.unlink path if File.exists? path or File.symlink? path
      end


      unless version == :system
        Dir.entries(File.join(version.path, 'bin')).find_all {|i| not i.starts_with? '.'}.each do |fname|
          if not version.is_a? MyRubyVersion
            # We need a special shell script to control variables.
            File.open(File.join(bin_dir, fname), 'w') do |fh|
              fh.write <<EOF
#!/bin/sh

#{File.join(version.path, 'bin', fname)} "$@"
EOF

              fh.write "#{File.join(RubSub::BIN_DIR, 'rubsub')} reset\n" if ['gem'].include? fname
            end
            File.chmod 0755, File.join(bin_dir, fname)
          else
            binary = File.join(version.path, 'bin', fname)
            File.symlink binary, File.join(bin_dir, fname)
          end
        end
      end # unless system
    end

    def install_ruby_cmd version, force=false
      version = makeVersion version
      return if version.is_a? MyRubyVersion
      if not File.exists? version.tarball_path
          puts "Downloading #{version}...."
          tarball = version.fetch
      else
        tarball = version.tarball_path
      end
      unpack_dir = File.join(RubSub::SRC_DIR,    version.to_s)
      final_dir  = File.join(RubSub::RUBIES_DIR, version.to_s)

      if File.directory? final_dir and not force
        raise "#{version} is already built."
      else
        FileUtils.rm_rf unpack_dir
        FileUtils.rm_rf final_dir

        puts "Unpacking #{version}...."
        RubSub.unpack tarball, RubSub::SRC_DIR

        puts "Compiling #{version}...."
        RubSub.compile unpack_dir
        puts "Finished compiling #{version}!"
      end
    end

    def remove_ruby_cmd version
      raise 'Not Implemented'
    end

    # update_cmd -- Updates various cached information.
    def update_cmd
      get_ruby_versions false
    end

    # upgrade_cmd -- Upgrades rubsub.
    def upgrade_cmd
      latest_version = fetch_page("http://github.com/docwhat/rubsub/raw/stable/VERSION").to_i
      if RubSub::VERSION > latest_version
        puts "Development versions of RubSub should be upgraded by running "
        puts " './rubsub-install.sh' from your source checkout."
      elsif RubSub::VERSION < latest_version
        puts "Upgrading RubSub..."
        tmpdir = Dir.mktmpdir 'rubsub'
        tmpfile = File.join(tmpdir, 'rubsub-install.sh')
        File.open(tmpfile, 'w') do |f|
          f.write fetch_page("http://github.com/docwhat/rubsub/raw/stable/rubsub-install.sh")
        end
        exec "bash", tmpfile
      else # RubSub::VERSION == latest_version
        puts "You are up-to-date."
      end
    end

  end # End class Session
end
