require 'rvm/constants'
require 'yaml'

module RVM

  class Config < ConfigStore
    @@defaults = {
      :default => nil,
      :version => VERSION
    }.freeze

    def filename
      File.join RVM_DIR, 'config.yml'
    end
  end
end
