# encoding: utf-8
require "faraday"
require 'uri'
require "nokogiri"
require "multi_json"
require "ox"
require "multi_xml"
require 'active_support/core_ext/string/conversions'
require 'spider_bot/logging'
require "spider_bot/version"
require 'spider_bot/error'

module SpiderBot
  class << self
    def crawl(url, options = {}, &block)
      crawl_instance = Crawling.new(url, options)
      return crawl_instance.crawl_data if !block_given?
      crawl_instance.instance_eval &block
    end

    def logger
      SpiderBot::Logging.logger
    end

    def logger=(log)
      SpiderBot::Logging.logger = log
    end
  end

  autoload :Crawling, 'spider_bot/crawling'
  autoload :Base, 'spider_bot/base'
  module Http
    autoload :Client, 'spider_bot/http/client'
    autoload :Response, 'spider_bot/http/response'
  end
end

require 'spider_bot/rails' if defined?(::Rails::Engine)
