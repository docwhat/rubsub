module RVM
  class Version
    attr_reader :version, :major, :minor, :patch, :interpreter
    def initialize string
      @patch = nil
      # ruby-1.8.7-p123
      dashparts = string.split('-')
      if dashparts[0] =~ /^\d/
        vmm = dashparts[0]
        @interpreter = 'ruby'
        @patch = dashparts[1].sub(/^p/, '').to_i unless dashparts[1].nil?
      else
        vmm = dashparts[1]
        @interpreter = dashparts[0]
        case dashparts[0]
        when 'ruby' then nil
        when 'macruby' then raise "Not on this platform" unless RUBY_PLATFORM =~ /-darwin10/
        when 'ironruby' then nil
        else raise "Unknown ruby interpreter #{dashparts[0]}"
        end
      end
      @version, @major, @minor = vmm.split('.').map {|x| x.to_i}
      @patch = dashparts[2].sub(/^p/, '').to_i unless dashparts[2].nil?
    end

    def to_s
      if @patch.nil?
        "#{@interpreter}-#{@version}.#{major}.#{minor}"
      else
        "#{@interpreter}-#{@version}.#{major}.#{minor}-p#{patch}"
      end
    end
  end

  def info kind=nil
    puts 'current ruby version:'
  end

  def set_ruby version
    raise 'Not Implemented'
  end

  def install_ruby version
    filename = fetch_ruby version
    raise 'Not Implemented'
  end

  def remove_ruby version
    raise 'Not Implemented'
  end

=begin
Fetch the requested version of ruby.
=end
  def fetch_ruby version
    interp, v, maj, min = split_version version
    url = "http://ftp.ruby-lang.org/pub/ruby/1.$rvm_major_version/$rvm_ruby_package_file.$rvm_archive_extension"

  end
end
