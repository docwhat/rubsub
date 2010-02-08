require 'rubsub/constants'

module RubSub

  class Config < ConfigStore
    @@defaults = {
      :default => nil,
      :version => VERSION
    }.freeze

    def filename
      File.join RubSub::DIR, 'config.yml'
    end
  end
end
