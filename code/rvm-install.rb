# setup.rb -- Setup the rvm environment.

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


require 'pp'
pp "Options:", options
pp "ARGV:", ARGV

puts 'nothing here yet.'
