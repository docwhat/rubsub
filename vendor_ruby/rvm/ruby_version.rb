module RVM
=begin
A class to manage and normalize the ruby package versions.
=end
  class RubyVersion
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
end
