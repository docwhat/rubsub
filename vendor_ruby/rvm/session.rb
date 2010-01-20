require 'rvm/constants'
require 'rvm/ruby_version'

module RVM
  class Session
    SESSION_CHARS = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    attr_reader :sid

    # initialize -- Pass in :new to allow a new session to be created.
    def initialize type = :old
      @sid = ENV[RVM::SESSION_VARIABLE]
      @sid = nil unless not @sid.nil? and File.exists? bin_dir


      if @sid.nil?
        if :new == type
          # Generate a new session id.
          while @sid.nil?
            tmp = ''
            1.upto(rand(16)) { |i| tmp << SESSION_CHARS[rand(SESSION_CHARS.size-1)] }
            @sid = tmp unless File.exists? File.join(RVM_SESSION_DIR, tmp)
          end

          # Create the session directory.
          Dir.mkdir dir
          Dir.mkdir bin_dir
        else
          raise "You must run rvm-session first"
        end
      end
    end

    # dir -- The session directory.
    def dir
      File.join RVM_SESSION_DIR, @sid
    end

    # bin_dir -- The session bin directory.
    def bin_dir
      File.join dir, 'bin'
    end

    ###########################
    ######## Commands #########

    def info_cmd kind=nil
      puts 'current ruby version:'
    end

    def set_ruby_cmd version
      v = RubyVersion.new version
      ruby_dir = File.join(RVM::RVM_RUBIES_DIR, v.to_s)
      if not File.exists? ruby_dir
        fetch_ruby_cmd version
      end

      # Remove old symlinks
      Dir.entries(bin_dir).find_all {|i| not i.starts_with? '.'}.each do |f|
        path = File.join(bin_dir, f)
        File.unlink path if File.symlink? path
      end

      Dir.entries(File.join(ruby_dir, 'bin')).find_all {|i| not i.starts_with? '.'}.each do |f|
        binary = File.join(ruby_dir, 'bin', f)
        File.symlink binary, File.join(bin_dir, f)
      end
    end

    def install_ruby_cmd version
      #TODO filename = fetch_ruby version
      raise 'Not Implemented'
    end

    def remove_ruby_cmd version
      raise 'Not Implemented'
    end

    def fetch_ruby_cmd version
      raise 'Not Implemented'
    end

    # fetch_ruby -- Fetch the requested version of ruby.
    def fetch_ruby_cmd version
      interp, v, maj, min = split_version version
      url = "http://ftp.ruby-lang.org/pub/ruby/1.$rvm_major_version/$rvm_ruby_package_file.$rvm_archive_extension"

    end

  end # End class Session
end
