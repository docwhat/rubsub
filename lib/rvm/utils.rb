require 'rvm/constants'
require 'rvm/ruby_version'
require 'net/http'

module RVM
  # unpack -- Unpacks a tarball.
  def unpack src, dst
    raise "No such tarball: #{src}" unless File.exists? src
    raise "No such directory: #{dst}" unless File.exists? dst

    src = File.expand_path src
    dst = File.expand_path dst

    old_cwd = Dir.pwd
    begin
      Dir.chdir dst
      if src.end_with? '.gz' or src.end_with? '.tgz'
        `gzip -dc "#{src}" | tar xf -`
      elsif src.end_with? '.bz' or src.end_with? '.tbz'
        `bzip2 -dc "#{src}" | tar xf -`
      elsif src.end_with? '.tar'
        `tar xf "#{src}"`
      else
        raise "Don't know how to unpack #{src}"
      end
    ensure
      Dir.chdir old_cwd
    end
  end

  # get_flags -- Calculate the flags needed to build
  def get_flags
    flags = {
      :configure => nil,
      :cflags    => nil,
      :ldflags   => nil,
    }
    uname = `uname`.chomp
    archflags = nil
    if uname == "Darwin"
      sysctl = {}
      `sysctl -a`.split(/\n/).each do |line|
        line.chomp!
        key, value = line.split(/[:=]/,2)
        sysctl[key.strip] = value.strip if key and value
      end

      if sysctl['hw.machine'] == 'i386'
        # Intel Processor
        if sysctl['hw.cpu64bit_capable'] == '1'
          # 64-bit compiling
          archflags = "-arch x86_64"
          flags[:configure] = "--build=x86_64-apple-darwin#{sysctl['kern.osrelease']} --host=x86_64-apple-darwin#{sysctl['kern.osrelease']}"
        else
          # 32-bit compiling
          archflags = "-arch i386"
          flags[:configure] = "--build=i386-apple-darwin#{sysctl['kern.osrelease']} --host=i386-apple-darwin#{sysctl['kern.osrelease']}"
        end

        # Detect SDK
        sdk = nil
        Dir.entries('/Developer/SDKs').find_all {|i| i.starts_with? 'MacOSX'}.sort.each do |f|
          sdk = f
        end
        if sdk
          dir = File.join('/Developer/SDKs', sdk)
        end
        if ENV['CFLAGS']
          flags[:cflags]  = ENV['CFLAGS']
        else
          flags[:cflags]  = "-isysroot #{dir} #{archflags}"
        end
        if ENV['LDFLAGS']
          flags[:ldflags]  = ENV['LDFLAGS']
        else
          flags[:ldflags] = "-Wl,-syslibroot #{dir} #{archflags}"
        end
      end # Intel
    end # Darwin

    return flags
  end

  # compile -- Compiles a ruby
  def compile dir
    rubyver = File.basename(dir)
    puts "Compiling #{rubyver}...."
    log "compile-#{rubyver}", "Starting compile...", true
    old_cwd = Dir.pwd
    begin
      Dir.chdir dir
      flags = get_flags
      ENV['CFLAGS']  = flags[:cflags]
      ENV['LDFLAGS'] = flags[:ldflags]
      cmd = "./configure --prefix=\"#{File.join(RVM::RVM_RUBIES_DIR,rubyver)}\" #{flags[:configure]}"
      log "compile-#{rubyver}", cmd
      log "compile-#{rubyver}", `#{cmd} 2>&1`
      log "compile-#{rubyver}", "********************make********************"
      log "compile-#{rubyver}", `make 2>&1`
      log "compile-#{rubyver}", "********************make install********************"
      log "compile-#{rubyver}", `make install 2>&1`
    ensure
      Dir.chdir old_cwd
    end
  end

  def log name, msg, reset=false
    flag = reset ? 'w' : 'a'
    File.open(File.join(RVM::RVM_LOG_DIR,"#{name}.log"), flag) do |f|
      f.write(msg + "\n")
    end
  end
end
