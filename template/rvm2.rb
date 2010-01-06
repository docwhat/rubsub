# rvm2.rb -- A tool to manage your RVM environment.

require 'rvm'
require 'rvm_commands'
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

$VERBOSE = options[:verbose]

if ARGV.length == 0
  info :short
end

case ARGV[0]
when 'default' then set_ruby :default
when 'install' then install_ruby ARGV[1]
when 'remove' then remove_ruby ARGV[1]
when 'info' then info
else set_ruby ARGV[1]
end

# EOF
