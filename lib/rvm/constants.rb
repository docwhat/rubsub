module RVM
  # Some constants
  VERSION          = '0.1'
  SESSION_VARIABLE = 'RVM2_SESSION'
  RVM_DIR          = File.join ENV['HOME'], '.rvm2'
  RVM_BIN_DIR      = File.join RVM_DIR, 'bin'
  RVM_ARCHIVE_DIR  = File.join RVM_DIR, 'archive'
  RVM_SRC_DIR      = File.join RVM_DIR, 'src'
  RVM_LOG_DIR      = File.join RVM_DIR, 'log'
  RVM_SESSION_DIR  = File.join RVM_DIR, 'sessions'
  RVM_RUBIES_DIR   = File.join RVM_DIR, 'rubies'
end
