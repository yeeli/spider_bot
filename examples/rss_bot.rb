$LOAD_PATH.unshift(File.expand_path('../lib'))
require 'spider_bot'

class RssBot < SpiderBot::Base
  origin type: 'rss', retry: 1, data: Proc.new{ |body| body['item'] }
  crawl_data do |data, response, options|
    data.each do |item|
      p item
    end
  end
end

rss = RssBot.new("https://36kr.com/feed")
rss.execute
p rss.errors

rss = RssBot.new("https://www.ruby-lang.org/en/feeds/news.rss")
rss.execute
p rss.errors
