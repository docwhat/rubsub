# rubsub-session.rb -- This sets up your RubSub session environment.

require 'rubsub'
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
  elsif shell.starts_with? 'zsh'
    options[:shell] = :zsh
  else
    options[:shell] = :sh
  end
  opts.on('-s', '--shell SHELL', [:csh, :sh, :zsh],
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
Dir.mkdir RubSub::SESSION_DIR unless File.exists? RubSub::SESSION_DIR

# Clean up old sessions.
existing = (Dir.entries RubSub::SESSION_DIR).find_all {|i| not i.starts_with? '.'}
existing.each do |dir|
  path = File.join RubSub::SESSION_DIR, dir
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

session = RubSub::Session.new :new

# Modify the path.
path_hash = {}
old_path = ENV['PATH'].split ':'
# Add in our paths.
old_path.unshift session.bin_dir
old_path.unshift RubSub::BIN_DIR
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
setenv #{RubSub::SESSION_VARIABLE} #{session.sid};
setenv PATH '#{path.join ':'}'
EOF
else
  puts <<EOF
#{RubSub::SESSION_VARIABLE}=#{session.sid}; export #{RubSub::SESSION_VARIABLE};
PATH='#{path.join ':'}'; export PATH;
EOF
  puts "echo $$ > #{File.join session.dir, 'shell.pid'};"
  if options[:shell] == :zsh
    puts 'rubsub() { command rubsub "$@" && rehash; };'
    puts 'gem()    { command gem "$@" && rehash; };'
    puts 'rehash;'
  end
end

# EOF
