begin
  system_application = File.expand_path("./config/application.rb")
  require system_application if File.exist?(system_application)
  system_boot = File.expand_path("./config/boot.rb")
  require system_boot if File.exist?(system_boot)
rescue LoadError => e
  system_boot = File.expand_path("./config/boot.rb")
  require system_boot if File.exist?(system_boot)
end

if defined?(Padrino)
  puts "read padrino environment #{Padrino.env}" 
  BOTDIR = Dir.glob("#{Padrino.root}/app/bots/*_bot.rb")
end

if defined?(Rails)
  puts "read rails environment #{Rails.env}"
  BOTDIR = Dir.glob("#{Rails.root}/app/bots/*_bot.rb")
end

