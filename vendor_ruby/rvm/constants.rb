module RVM
  # Some constants
  VERSION         = '0.1'
  RVM_DIR         = File.join ENV['HOME'], '.rvm2'
  RVM_BIN_DIR     = proc { File.join RVM_DIR, 'bin' }
  RVM_SESSION_DIR = proc { File.join RVM_DIR, 'sessions' }
  RVM_RUBIES_DIR  = proc { File.join RVM_DIR, 'rubies' }
end
