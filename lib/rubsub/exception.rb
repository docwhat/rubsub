
module RubSub
  class RubSubError < StandardError; end

  class NoSuchRubyError < RubSubError
    attr_reader :version
    def initialize version
      @version = version
    end
  end

  class InvalidRubyStringError < RubSubError; end
end
