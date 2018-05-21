module SpiderBot
  class Rails < Rails::Engine
    config.autoload_paths << File.expand_path(Rails.root.join("app/bots"))
  end
end
