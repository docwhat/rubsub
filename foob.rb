
require 'open4'
require 'io/wait'

status = Open4::popen4('yes', 'fishy') do |pid, stdin, stdout, stderr|
  stdin.close
  p pid

  p stderr.methods.sort
  p stderr.closed?
  puts "fileno: #{stderr.fileno}"

  is_done = false
  while not is_done
    so = se = ''
    p 1
    so = stdout.gets if stdout.ready?
    p 2
    se = stderr.gets if stderr.ready?
    p 3
    puts "O: #{so.class}"
    p 4
    puts "E: #{se.class}"
    p 5
    is_done = se.nil? and so.nil?
    p "NARF '#{stdout.ready?}' '#{stderr.ready?}'"
  end
end
