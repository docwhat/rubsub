module RVM
  # Some constants
  VERSION         = '0.1'
  RVM_DIR         = File.join ENV['HOME'], '.rvm2'
  RVM_BIN_DIR     = File.join RVM_DIR, 'bin'
  RVM_SESSION_DIR = File.join RVM_DIR, 'sessions'
end
