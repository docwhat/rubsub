require 'rubsub/constants'
require 'rubsub/ruby_version'
require 'net/http'
require 'yaml'
require 'nokogiri'
require 'open4'

module RubSub

  class LoggedError < StandardError
    #TODO
  end

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
    archflags = nil
    if RUBY_PLATFORM =~ /-darwin10/
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
      logrun "compile-#{rubyver}", "./configure --prefix=\"#{File.join(RubSub::RUBIES_DIR,rubyver)}\" #{flags[:configure]}"
      logrun "compile-#{rubyver}", "make"
      logrun "compile-#{rubyver}", "make install"
    ensure
      Dir.chdir old_cwd
    end
    puts "Finished compiling #{rubyver}!"
  end

  # log -- Send a log a message to a file.
  def log name, msg, reset=false
    flag = reset ? 'w' : 'a'
    File.open(File.join(RubSub::LOG_DIR,"#{name}.log"), flag) do |f|
      f.write(msg + "\n")
    end
  end

  # logrun -- Forks a process and sends the output to a logfile.
  def logrun name, cmd, reset=false
    flag = reset ? 'w' : 'a'

    log_fname = File.join(RubSub::LOG_DIR, "#{name}.log")
    File.open(log_fname, flag) do |f|
      f.write "+" * 60; f.write "\n"
      f.write "CMD: #{cmd}\n"
      status = Open4::popen4(cmd) do |pid, stdin, stdout, stderr|
        stdin.close
        f.write stdout.gets
        f.write stderr.gets
      end
      f.write "Exited with: #{status}\n"
      f.write "-" * 60; f.write "\n"
      raise "Error while running '#{cmd}'\nThe errors are in #{log_fname}" unless status.exitstatus == 0
    end
  end

  # get_ruby_versions -- Checks the website for current versions.
  def get_ruby_versions used_cached=true
    cache_path = File.join(DB_DIR, 'ruby_versions')
    if used_cached and File.exists? cache_path
      return File.open(cache_path) { |inf| YAML::load(inf) }
    else
      found = []
      Net::HTTP.start 'ftp.ruby-lang.org', 80 do |http|
        ['1.6', '1.8', '1.9'].each do |base|
          res = http.get("/pub/ruby/#{base}/")
          found = found + Nokogiri::HTML(res.body).xpath("//li/a/@href").
            map{|x| x.text}.
            find_all {|x| x =~ /^ruby-#{base}\.\d+(-p\d+)?\.tar\.gz$/}.
            map{|x| RubyVersion.new(x.sub(/\.tar\.gz$/,'')).freeze}
        end
      end
      found.sort!
      File.open(cache_path, 'w') { |out| YAML.dump(found, out) }
      return found
    end
  end

end
