# rvm-session.rb -- This sets up your RVM session environment.

require 'rvm'
require 'optparse'
require 'fileutils'
require 'pp'

# This hash will hold all of the options
# parsed from the command-line by
# OptionParser.
options = {}

optparse = OptionParser.new do|opts|


  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end

  shell = File.basename ENV['SHELL']
  if shell.starts_with? 'csh'
    options[:shell] = :csh
  else
    options[:shell] = :sh
  end
  opts.on('-s', '--shell SHELL', [:csh, :sh],
          "The type of shell you're using. (default: #{options[:shell]}") do |s|
    options[:shell] = s
  end
end

# Parse the command-line. Remember there are two forms
# of the parse method. The 'parse' method simply parses
# ARGV, while the 'parse!' method parses ARGV and removes
# any options found there, as well as any parameters for
# the options. What's left is the list of files to resize.
optparse.parse!

# Make sure the session top-level directory exists.
Dir.mkdir RVM_SESSION_DIR unless File.exists? RVM_SESSION_DIR

# Clean up old sessions.
existing = (Dir.entries RVM_SESSION_DIR).find_all {|i| not i.starts_with? '.'}
existing.each do |dir|
  path = File.join RVM_SESSION_DIR, dir
  delete = false
  if File.exists? File.join(path, 'shell.pid')
    File.open File.join(path, 'shell.pid'), 'r' do |fd|
      pid = fd.gets.to_i
      begin
        Process.kill(0, pid)
      rescue Errno::EPERM
      rescue Errno::ESRCH
        delete = true
      rescue
      end
    end
  else
    delete = true
  end
  if delete
    FileUtils.remove_dir(path, force=true)
  end
end

session = RVM::Session.new :new

# Modify the path.
path_hash = {}
old_path = ENV['PATH'].split ':'
# Add in our paths.
old_path.unshift session.bin_dir
old_path.unshift RVM_BIN_DIR
path = []
old_path.each do |item|
  if not path_hash.has_key? item
    path << item
    path_hash[item] = true
  end
end

# Display the shell commands.
if options[:shell] == :csh
  puts <<EOF
setenv #{RVM::SESSION_VARIABLE} #{session.sid};
setenv PATH '#{path.join ':'}'
EOF
else
  puts <<EOF
#{RVM::SESSION_VARIABLE}=#{session.sid}; export #{RVM::SESSION_VARIABLE};
PATH='#{path.join ':'}'; export PATH;
EOF
  puts "echo $$ > #{File.join session.dir, 'shell.pid'};"
  puts "rvm2 default;"
end

# EOF
