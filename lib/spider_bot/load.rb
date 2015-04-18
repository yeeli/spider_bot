
begin
  require File.expand_path("./config/environment")
rescue LoadError => e
  bot_file = File.expand_path("./config/boot.rb")
  require bot_file if File.exist?(bot_file)
end

if defined?(Padrino)
  puts "read padrino environment #{Padrino.env}" 
  BOTDIR = Dir.glob("#{Padrino.root}/app/bots/*_bot.rb")
end

if defined?(Rails)
  puts "read rails environment #{Rails.env}"
  BOTDIR = Dir.glob("#{Rails.root}/app/bots/*_bot.rb")
  Rails.logger.level = Logger::WARN
end

