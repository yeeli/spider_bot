module SpiderBot
  class Base
    class << self
      def origin(url, options = {})
        @origin_url = url
        @origin_options = options
      end

      def crawl(name = nil, &block)
        crawl_instance = Crawl.new(@origin_url, @origin_options)
        crawl_instance.crawl_data if !block_given?
        crawl_instance.instance_eval &block
      end
    end
  end
end
