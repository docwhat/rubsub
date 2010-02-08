require 'rubsub/constants'
require 'rubsub/config_store'

module RubSub
  class LatestVersions < ConfigStore
    @@defaults = {
      :"ruby-1.8" => nil,
      :"ruby-1.9" => nil
    }.freeze

    def filename
      File.join RubSub::DIR, 'config.yml'
    end
  end

  # makeVersion -- A Factory method to create RubyVersion.
  def makeVersion string
    rv = nil
    if string.is_a? RubyVersion
      rv = string
    elsif string.is_a? String
      if string == 'default'
        rv = RubyVersion.new 'ruby-1.8.7-p174'
      elsif ['internal','myruby'].include? string
        rv = MyRubyVersion.new
      else
        rv = RubyVersion.new string
      end
    end
    rv.guess! unless rv.nil?
    if rv.nil? or not rv.complete?
      raise "Invalid RubyVersion"
    end
    return rv
  end

  def findVersion string
    if string.is_a? RubyVersion
      return string
    elsif string.is_a? String
      if string == 'default'
        return RubyVersion.new 'ruby-1.8.7-p174'
      elsif ['internal','myruby'].include? string
        return MyRubyVersion.new
      else
        rv = RubyVersion.new string
        if not rv.complete?
          found = []
          Dir.entries(RubSub::RUBIES_DIR).find_all do |f|
            found << f unless f.starts_with?('.') or not File.directory?(File.join RubSub::RUBIES_DIR, f) or not f.starts_with?(rv.to_s)
          end
        end
        if found.length > 0
          found.sort!
          return RubyVersion.new found[-1]
        else
          raise NoSuchRubyError, string, caller
        end
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

    # complete? -- Returns true if it is complete
    def complete?
      not (@major.nil? or @minor.nil? or @patch.nil?)
    end

    def guess!
      # If anything is still nill, then start guessing.
      if not complete?
        l = LATESTS.clone.find_all {|x| x.to_s.starts_with? to_s}.sort
        if l.length > 0
          v = l[-1]
          @major = v.major
          @minor = v.minor
          @patch = v.patch
        end
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
      return File.join(RubSub::RUBIES_DIR,to_s)
    end

    def src_path
      return File.join(RubSub::SRC_DIR,to_s)
    end

    def tarball_path
      return File.join(RubSub::ARCHIVE_DIR, "#{to_s}.tar.gz")
    end
  end

  class MyRubyVersion < RubyVersion
    def initialize; end
    def guess!; end
    def <=>(other)
      if other.is_a? MyRubyVersion
        return 0
      else
        return 1
      end
    end
    def to_s; return 'myruby'; end
    def complete?; return true; end
    def path; return File.join(RubSub::DIR, 'myruby'); end
  end

  LATESTS = [ RubyVersion.new('ruby-1.8.6-p383'),
              RubyVersion.new('ruby-1.8.6-p388'),
              RubyVersion.new('ruby-1.8.7-p249'),
              RubyVersion.new('ruby-1.9.1-p378')
            ]
end
