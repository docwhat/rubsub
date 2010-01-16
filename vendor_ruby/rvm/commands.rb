require 'rvm/constants'

module RVM
  def info kind=nil
    puts 'current ruby version:'
  end

  def set_ruby version
    raise 'Not Implemented'
  end

  def install_ruby version
    filename = fetch_ruby version
    raise 'Not Implemented'
  end

  def remove_ruby version
    raise 'Not Implemented'
  end

=begin
Fetch the requested version of ruby.
=end
  def fetch_ruby version
    interp, v, maj, min = split_version version
    url = "http://ftp.ruby-lang.org/pub/ruby/1.$rvm_major_version/$rvm_ruby_package_file.$rvm_archive_extension"

  end
end
