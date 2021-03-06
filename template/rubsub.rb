# rubsub.rb -- A tool to manage your RubSub environment.

require 'rubsub'
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

  options[:quiet] = false
  opts.on('-q', '--quiet', 'Be very quiet') do
    options[:quiet] = true
  end
end

# Parse the command-line. Remember there are two forms
# of the parse method. The 'parse' method simply parses
# ARGV, while the 'parse!' method parses ARGV and removes
# any options found there, as well as any parameters for
# the options. What's left is the list of files to resize.
optparse.parse!

session = RubSub::Session.new

$verbose = options[:verbose]
$quiet   = options[:quiet]

if $quiet and $verbose
  puts "Uhmm... quiet *and* verbose? How do I do that?"
  exit 1
end


def problem message
  puts "** Error **"
  puts message.chomp
  exit 1
end

begin
  if ARGV.length == 0
    session.info_cmd :short
  elsif ARGV[0] == 'set' and ARGV[1] == 'default' and ARGV.length == 3
    session.set_default_cmd ARGV[2]
  else
    case ARGV[0]
    when 'install'  then session.install_ruby_cmd ARGV[1]
    when 'remove'   then session.remove_ruby_cmd ARGV[1]
    when 'info'     then session.info_cmd
    when 'reset'    then session.reset_cmd
    when 'update'   then session.update_cmd
    when 'upgrade'  then session.upgrade_cmd
    when 'system'   then session.set_ruby_cmd 'system'
    else                 session.set_ruby_cmd ARGV[0]
    end
  end
rescue RubSub::InvalidRubyStringError => e
  problem "#{e}"
rescue RubSub::NoSuchRubyError => e
  problem <<EOF
#{e.version} isn't installed.
Try: #{File.basename $0} install #{e.version}
EOF
end

# EOF
