module RubSub
  # Some constants
  SESSION_VARIABLE = 'RUBSUB_SESSION'

  if not ENV['RUBSUB_DIR'].nil? and File.exists? ENV['RUBSUB_DIR']
    DIR       = ENV['RUBSUB_DIR']
  else
    DIR       = File.join ENV['HOME'], '.rubsub'
  end
  BIN_DIR      = File.join DIR, 'bin'
  ARCHIVE_DIR  = File.join DIR, 'archive'
  SRC_DIR      = File.join DIR, 'src'
  LOG_DIR      = File.join DIR, 'log'
  DB_DIR       = File.join DIR, 'db'
  SESSION_DIR  = File.join DIR, 'sessions'
  RUBIES_DIR   = File.join DIR, 'rubies'

  # Load the version
  begin
    File.open File.join(DIR, 'VERSION') do |f|
      VERSION = f.readline.chomp.to_i
    end
  rescue
    VERSION = 0
  end
end
