module RubSub
  # Some constants
  SESSION_VARIABLE = 'RUBSUB_SESSION'
  DIR          = File.join ENV['HOME'], '.rubsub'
  BIN_DIR      = File.join DIR, 'bin'
  ARCHIVE_DIR  = File.join DIR, 'archive'
  SRC_DIR      = File.join DIR, 'src'
  LOG_DIR      = File.join DIR, 'log'
  DB_DIR       = File.join DIR, 'db'
  SESSION_DIR  = File.join DIR, 'sessions'
  RUBIES_DIR   = File.join DIR, 'rubies'

  File.open File.join(DIR, 'VERSION') do |f|
    VERSION = f.readline.chomp.to_i
  end
end
