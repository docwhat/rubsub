require 'yaml'

module RVM

  class ConfigStore
    # DEFAULTS -- A list of options and their default values.
    #
    # Override this in subclasses
    @@defaults = {}.freeze

    # filename -- Returns the path to the config file.
    #
    # Override this in subclasses.
    def filename
      raise "This must be overridden."
    end

    def initialize
      if File.exists? filename
        @config = YAML.load_file(filename)
      else
        @config = {}
      end
    end

    def save
      File.open(filename, "w+:utf-8") do |f|
        YAML.dump(@config, f)
      end
    end

    def delete name
      if @@defaults.has_key? name
        @config.delete name
      else
        raise ArgumentError("No such configuration value.")
      end
    end

    def method_missing(name, *args, &block)
      assignment = false
      if name.to_s[-1,1] == "="
        assignment = true
        name = name.to_s[0,name.to_s.length - 1].to_sym
      end
      if @@defaults.has_key? name
        if assignment
          @config[name] = args[0]
        end
        if @config.has_key? name
          @config[name]
        else
          @@defaults[name]
        end
      else
        super
      end
    end
  end
end
