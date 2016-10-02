module SpiderBot
  class Crawl
    
    # Initialize a new Spider Bot
    # 
    # @param url [String] the spider target website curl
    # @param options [Hash] the spider crawl configurate options  
    # @option options :type [Symbol] the request body format, `:html` or `:json`
    # @option options :headers [Hash] the custom request headers
    # @option options :query [Hash] the request query
    # @option options :user_agent [String] the custom request user agent
    # @option options :source [Boolean] 
    # @option options :data [Proc] get crawl data list in body
    # @option options :first [Proc] get crawl data list first item 
    # @option options :last [Porc] get crawl data list last item
    # @option options :encode [String] custom request encode
    
    def initialize(url, options = {})
      parse_uri = URI.parse url
      @uri = parse_uri.scheme + "://" + parse_uri.host
      
      # don't add 443 port append to url when access https website
      if !["80", "443"].include?(parse_uri.port.to_s)
        @uri = @uri + ":" + parse_uri.port.to_s 
      end
      
      @origin_path = parse_uri.path || "/"
      
      @origin_type = options[:type] || 'html'
      @origin_headers = options[:headers] || {}
      @origin_query = options[:query] || {}

      @origin_user_agent = options[:user_agent] || "Mac Safari"
      @origin_source = options[:source] || false

      @origin_data = options[:data]
      @origin_first = options[:first]
      @origin_last = options[:last]

      @origin_encode = options[:encode]
      
      @page_path = @origin_path
      @page_type = @origin_type
      @page_headers = @origin_headers || {}
      @page_query = {}

      @page_data = @origin_data
      @page_first = @origin_first
      @page_last = @origin_last

      @page_start = 1
      @page_add = 1
      @page_expire = 10
      @page_sleep = 0
      
      @paginate_last = nil
      @paginate_error = 0
      @paginate_type = :html
      @paginate_path = ""
      @paginate_query = {}
      
      @connection = Http::Client.new do |http| 
        http.url= @uri
        http.user_agent= @origin_user_agent
        http.headers= @origin_headers
      end
    end

    # Process crawl data
    #
    # @param a [block]

    def crawl_data(&block)
      @paginate_num = @page_start
      
      catch :all do
        begin
          crawl_response = crawl_request(@origin_path, @origin_query, @origin_type, @origin_data, @origin_first, @origin_last, &block)
          return crawl_response if !block_given?
          process_response(crawl_response, &block)
        rescue Exception => e
          handle_error(e)
          crawl_data(&block)
        end
        
        @paginate_error = 0
        return if @page_query.blank? && @page_path == @origin_path
        
        crawl_paginate(&block) 
      end
    end

    private
    
    def crawl_paginate(&block)
      @page_headers.merge({"X-Requested-With" => "XMLHttpRequest"}) if @page_type.to_s == 'json'
      @connection.headers = @page_headers
      begin
        loop do
          real_page_num  = (@page_start == 0 && @page_add > 1) ? (@paginate_num / @page_add) + 1 : @paginate_num
          if defined?($expire_num)
            if $expire_num > 1
              break if real_page_num > $expire_num.to_i
            else
              break if real_page_num > 1
            end
          end
          break if real_page_num > @page_expire 
          
          sleep(@page_sleep) if @page_sleep > 0
          
          path = @page_path.to_s % {page: @paginate_num}
          query_str = @page_query.to_s % { page: @paginate_num, last: @paginate_last, first: @paginate_first }
          query = eval(query_str)
          
          crawl_response = crawl_request(path, query, @page_type, @page_data, @page_first, @page_last, &block)
          process_response(crawl_response, &block)
        end
      rescue Exception => e
        @paginate_num += @page_add if @paginate_error == 2
        handle_error(e)
        crawl_paginate(&block)
      end
    end

    def crawl_request(path, query, type, data, first, last, &block)
      @paginate_path = path
      @paginate_query = query
      
      response = @connection.get(path, query)

      return if !response
      return if response.status != 200

      options = { encode: @origin_encode } if @origin_encode

      if @origin_source && !block_given?
        return response.body(options) 
      end

      if type.to_s == "html"
        @paginate_type = :html
        body = Nokogiri::HTML response.body(options)
      elsif type.to_s == "json"
        @paginate_type = :json
        body = MultiJson.load response.body(options)
      else
        @paginate_type = response.parser
        body = response.parsed
      end
      
      return if body.nil?
      return body if data.nil?

      body_data = data.call(body) if data
      @paginate_first = first.call(body_data, body) if first
      @paginate_last = last.call(body_data, body) if last

      return body_data 
    end

    def get_page_url
      if !@paginate_query.blank?
        @uri + @paginate_path + "?" + @paginate_query.map{ |k,v| "#{k}=#{v}" }.join("&")
      else
        @uri + @paginate_path
      end
    end

    def set_paginate_headers(arg)
      @page_headers = arg || {}
    end

    # set crawl paginate settings
    #
    # @example
    #   paginate do
    #     option :path, '/path'
    #     option :query, {page: "%{page}"}
    #     option :first, Proc.new{|data| data.css("#item")}
    #     option :last, Proc.new{|data| data.css("#item")}
    #     option :type, :html
    #     option :data, Proc.new{|body| body.css("#item")}
    #     option :start, 1
    #     option :add, 1
    #     option :expire, 100
    #     option :sleep, 100
    #   end

    def paginate(&block)
      block.call
    end

    def option(name, params)
      raise "set paginate options has error" if %i(path query first last type data start add expire sleep).include?(name.to_s)
      eval("@page_#{name} = params")
    end

    def break_all
      throw :all
    end

    def handle_error(error)
      SpiderBot.logger.error "crawling url #{ get_page_url } has error..."
      SpiderBot.logger.error error.to_s
      
      break_all if @paginate_error == 3
      @paginate_error += 1
      
      sleep( 60 * @paginate_error )
    end

    # Print error infomation with http client response blank
    #
    # @param response [Object] The Faraday connection builder

    def process_response(response, &block)
      raise "Crawl response body is blank..." if response.blank?
      SpiderBot.logger.info "crawling page for #{get_page_url}"
      yield response, @paginate_num, @paginate_type
      @paginate_num += @page_add
      @paginate_error = 0
    end
  end
end
