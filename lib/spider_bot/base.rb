module SpiderBot
  class Base
    class << self
      # 
      # execute method with command "spider start" and "spider crawl" 
      #
      
      def auto &block
        if defined?(BOTCONSOLE)
          klass = Class.new do
            def origin url, options = {}
              @origin_url = url
              @origin_options = options
            end
  
            def execute name = nil, &block
              crawl_instance = Crawl.new(@origin_url, @origin_options)
              crawl_instance.instance_eval &block
            end
          end
          klass.allocate.instance_eval &block
        end
      end

      # 
      # Application require method scope
      #

      def method &block
        extend Module.new &block
      end

      def crawl url, options = {}
        crawl_instance = Crawl.new(url, options)
        crawl_instance.crawl_data
      end
    end
  end
end
