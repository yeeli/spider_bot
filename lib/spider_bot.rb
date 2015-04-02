require "faraday"
require 'uri'
require "nokogiri"
require "multi_json"
require "multi_xml"
require "yaml"
require "active_support/time"
require 'tzinfo'
require "spider_bot/version"

module SpiderBot
  class << self
    def crawl(url, options, &block)
      crawl_instance = Crawl.new(url, options)
      crawl_instance.crawl_data if !block_given?
      crawl_instance.instance_eval &block
    end
  end

  autoload :Crawl, 'spider_bot/crawl'
  module Http
    autoload :Client, 'spider_bot/http/client'
    autoload :Response, 'spider_bot/http/response'
  end
  autoload :Engine, 'spider_bot/engine'
end
