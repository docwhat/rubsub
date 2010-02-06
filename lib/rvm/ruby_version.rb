require 'rvm/constants'
require 'rvm/config_store'

module RVM
  class LatestVersions < ConfigStore
    @@defaults = {
      :"ruby-1.8" => nil,
      :"ruby-1.9" => nil
    }.freeze

    def filename
      File.join RVM_DIR, 'config.yml'
    end
  end

  # makeVersion -- A Factory method to create RubyVersion.
  def makeVersion string
    if string.is_a? RubyVersion
      return string
    elsif string.is_a? String
      if string == 'default'
        return RubyVersion.new 'ruby-1.8.7-p174'
      elsif ['internal','myruby'].include? string
        return MyRubyVersion.new
      else
        return RubyVersion.new string
      end
    else
      raise "Invalid RubyVersion"
    end
  end

  # RubyVersion -- A class to manage and normalize the ruby package versions.
  class RubyVersion
    include Comparable

    attr_reader :version, :major, :minor, :patch, :interpreter

    latests = LatestVersions.new

    def initialize string
      if string.nil?
        raise "Nil ruby version"
      end

      string = string.to_s

      # Figure out the interpreter.
      if string.match /^[0-9]/
        @interpreter = 'ruby'
      else
        tmp = string.split('-',2)
        @interpreter = tmp[0]
        raise "Invalid string '#{string}'" if tmp[1].nil?
        string = tmp[1]
      end

      parts = string.split('-')
      if parts.length > 2
        raise "Invalid version #{string}"
      end

      @version = @major = @minor = @patch = nil

      # Version Major Minor
      ver_maj_min = parts[0].split('.').map {|x| x.to_i}
      case ver_maj_min.length
      when 1 then @version = ver_maj_min[0]
      when 2 then @version, @major = ver_maj_min
      when 3 then @version, @major, @minor = ver_maj_min
      else raise "Invalid version #{string}"
      end

      # Patch
      patch = parts[1]
      if not patch.nil?
        if patch.starts_with? 'p'
          @patch = patch.sub(/^p/, '').to_i
        else
          raise "Invalid patch #{string}"
        end
      end
    end # intialize

    def guess!
      # If anything is still nill, then start guessing.
      if @major.nil? or @minor.nil? or @patch.nil?
        LATESTS.sort!
      end
    end

    def to_s
      parts = []
      if not @interpreter.nil?
        parts << @interpreter
      end
      ver = []
      ver << @version unless @version.nil?
      ver << @major   unless @major.nil?
      ver << @minor   unless @minor.nil?
      parts << ver.join('.')
      if not @patch.nil?
        parts << "p#{@patch}"
      end
      parts.join('-')
    end

    def <=>(other)
      return 1 if other.nil?

      def nilcmp a,b
        return -1 if a.nil? and not b.nil?
        return  1 if not a.nil? and b.nil?
        return 0
      end

      c = nilcmp @interpreter, other.interpreter
      return c if c != 0
      c = @interpreter <=> other.interpreter
      return c if c != 0

      c = nilcmp @version, other.version
      return c if c != 0
      c = @version     <=> other.version
      return c if c != 0

      c = nilcmp @major, other.major
      return c if c != 0
      c = @major       <=> other.major
      return c if c != 0

      c = nilcmp @minor, other.minor
      return c if c != 0
      c = @minor       <=> other.minor
      return c if c != 0

      c = nilcmp @patch, other.patch
      c = @patch       <=> other.patch
      return c
    end

    def path
      return File.join(RVM::RVM_RUBIES_DIR,to_s)
    end

    def src_path
      return File.join(RVM::RVM_SRC_DIR,to_s)
    end

    def tarball_path
      return File.join(RVM::RVM_ARCHIVE_DIR, "#{to_s}.tar.gz")
    end
  end

  class MyRubyVersion < RubyVersion
    def initialize
    end
    def guess!
    end
    def <=>(other)
      if other.is_a? MyRubyVersion
        return 0
      else
        return 1
      end
    end
    def to_s
      return 'myruby'
    end
    def path
      return File.join(RVM::RVM_DIR, 'myruby')
    end
  end

  LATESTS = [ RubyVersion.new('ruby-1.8.6-p383'),
              RubyVersion.new('ruby-1.8.6-p388'),
              RubyVersion.new('ruby-1.8.7-p249'),
              RubyVersion.new('ruby-1.9.1-p378')
            ]
end
