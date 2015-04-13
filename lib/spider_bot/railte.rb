module SpiderBot 
  class Railtie < Rails::Railtie
    initializer "load bots" do |app|
      Dir.glob(app.root.join('app', 'bots', '*_bot.rb').to_s).each do |file|
        require file
      end
    end
  end
end
