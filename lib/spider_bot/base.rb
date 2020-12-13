module SpiderBot
  class Base
    attr_accessor :bot_options

    def initialize(url, _options = {})
      origin_url = url
      origin_options = set_origin_options
      @crawl_instance = Crawling.new(origin_url, origin_options, _options)
    end

    def crawl
      response_data.call(@crawl_instance.crawl_data)
    end

    def execute
      @crawl_instance.crawl_data &response_data
    end

    def result
      data = @crawl_instance.crawl_data[0]
    end

    def errors
      @crawl_instance.errors
    end

    class << self
      #
      # execute method with command "spider start" and "spider crawl"
      #
      def origin(options)
        define_method(:set_origin_options){return options}
      end

      def crawl_data &block
        define_method(:response_data){return block}
      end

      def auto &block
        if defined?(BOTCONSOLE)
          klass = Class.new do
            def origin url, options = {}
              @origin_url = url
              @origin_options = options
            end

            def execute options = {}, &block
              crawl_instance = Crawling.new(@origin_url, @origin_options)
              crawl_instance.instance_eval &block
            end
          end
          klass.allocate.instance_eval &block
        end
      end

      def crawl url, options = {}
        crawl_instance = Crawling.new(url, options)
        crawl_instance.crawl_data
      end
    end
  end
end
