begin
  require File.expand_path("./config/application")
rescue LoadError => e
  system_boot = File.expand_path("./config/boot.rb")
  require system_boot if File.exist?(system_boot)
end

if defined?(Padrino)
  puts "read padrino environment #{Padrino.env}" 
  BOTDIR = Dir.glob("#{Padrino.root}/app/bots/**/*_bot.rb")
  if Padrino.env != :development
    SpiderBot::Logging.initialize_logger("#{Padrino.root}/log/spider.log")
  end
end

if defined?(Rails)
  class Railtie < Rails::Railtie
    initializer "disable eager load" do |app|
      app.config.eager_load = false
    end
  end
  Rails.application.initialize!
  puts "read rails environment #{Rails.env}"
  BOTDIR = Dir.glob("#{Rails.root}/app/bots/**/*_bot.rb")
  Rails.logger.level = Logger::WARN
  if !Rails.env.development?
    SpiderBot::Logging.initialize_logger("#{Rails.root}/log/spider.log")
  end
end

