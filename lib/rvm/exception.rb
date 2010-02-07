
module RVM
  class NoSuchRubyError < StandardError
    attr_reader :version
    def initialize version
      @version = version
    end
  end
end
