# This doesn't use yml because yml doesn't work in miniruby.

module RubSub

  class ConfigStore
    # DEFAULTS -- A list of options and their default values.
    #
    # Override this in subclasses
    @defaults = nil

    # filename -- Returns the path to the config file.
    #
    # Override this in subclasses.
    @filename = nil

    class << self
      attr_accessor :filename, :defaults
    end

    def initialize
      defaults.freeze
      @config = {}
      if File.exists? filename
        File.open(filename, "r:utf-8") do |f|
          f.each_line do |line|
            if line.match /^[a-z][^#:]*:/
              # Pull out the key and value.
              k,v = line.strip.split /:\s*/, 2
              k = k.strip.to_sym
              v = v.strip

              # Make sure we can use the key.
              next unless defaults.nil? or defaults.has_key? k

              # Set the type.
              v = nil if v == ''
              v = v.to_f if v == v.to_f.to_s
              v = v.to_i if v == v.to_i.to_s

              # Store it.
              @config[k] = v
            end
          end
        end
      end
    end

    def save
      File.open(filename, "w+:utf-8") do |f|
        if defaults.nil?
          @config.each do |k,v|
            f.write("#{k}: #{method_missing(k)}\n")
          end
        else
          defaults.each do |k,v|
            f.write("#{k}: #{method_missing(k)}\n")
          end
        end
      end
    end

    def delete name
      if defaults.nil?
        store = default
      else
        store = @config
      end
      if store.has_key? name
        @config.delete name
      else
        raise ArgumentError("No such configuration value.")
      end
    end

    ######################################################
    private
    ######################################################

    def filename
      self.class.filename
    end

    def defaults
      self.class.defaults
    end

    def method_missing(name, *args, &block)
      assignment = false
      if name.to_s[-1,1] == "="
        assignment = true
        name = name.to_s[0,name.to_s.length - 1].to_sym
      end
      if defaults.nil? or defaults.has_key? name
        if assignment
          @config[name] = args[0]
        end
        if @config.has_key? name
          @config[name]
        else
          if defaults.nil?
            super
          else
            defaults[name]
          end
        end
      else
        super
      end
    end
  end
end
