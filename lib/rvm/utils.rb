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

  # compile -- Compiles a ruby
  def compile dir
    old_cwd = Dir.pwd
    begin
      Dir.chdir dir
    ensure
      Dir.chdir old_cwd
    end
  end
end
