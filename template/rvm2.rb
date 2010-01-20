# rvm2.rb -- A tool to manage your RVM environment.

require 'rvm'
require 'optparse'

# This hash will hold all of the options
# parsed from the command-line by
# OptionParser.
options = {}

optparse = OptionParser.new do|opts|

  options[:verbose] = false
  opts.on( '-v', '--verbose', 'Show steps taken' ) do
    options[:verbose] = true
  end


  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

# Parse the command-line. Remember there are two forms
# of the parse method. The 'parse' method simply parses
# ARGV, while the 'parse!' method parses ARGV and removes
# any options found there, as well as any parameters for
# the options. What's left is the list of files to resize.
optparse.parse!

session = RVM::Session.new

$VERBOSE = options[:verbose]

if ARGV.length == 0
  session.info_cmd :short
else
  case ARGV[0]
  when 'install' then session.install_ruby_cmd ARGV[1]
  when 'remove'  then session.remove_ruby_cmd ARGV[1]
  when 'info'    then session.info_cmd
  when 'default' then session.set_ruby_cmd 'default'
  when 'system'  then session.set_ruby_cmd 'system'
  else                session.set_ruby_cmd ARGV[1]
  end
end

# EOF
