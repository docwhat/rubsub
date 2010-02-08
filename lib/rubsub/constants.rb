module RubSub
  # Some constants
  VERSION          = '0.1'
  SESSION_VARIABLE = 'RUBSUB_SESSION'
  RubSub::DIR          = File.join ENV['HOME'], '.rubsub'
  RubSub::BIN_DIR      = File.join RubSub::DIR, 'bin'
  RubSub::ARCHIVE_DIR  = File.join RubSub::DIR, 'archive'
  RubSub::SRC_DIR      = File.join RubSub::DIR, 'src'
  RubSub::LOG_DIR      = File.join RubSub::DIR, 'log'
  RubSub::SESSION_DIR  = File.join RubSub::DIR, 'sessions'
  RubSub::RUBIES_DIR   = File.join RubSub::DIR, 'rubies'
end
