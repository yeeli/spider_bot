module SpiderBot
  class Crawling

    # Initialize a new Spider Bot
    #
    # @param url [String] the spider target website curl
    # @param options [Hash] the spider crawl configurate options
    # @option options :type [Symbol] the request body format, `:html` or `:json`
    # @option options :headers [Hash] the custom request headers
    # @option options :path, [String] the custom request path
    # @option options :query [Hash] the request query
    # @option options :user_agent [String] the custom request user agent
    # @option options :source [Boolean]
    # @option options :data [Proc] get crawl data list in body
    # @option options :first [Proc] get crawl data list first item
    # @option options :last [Porc] get crawl data list last item
    # @option options :encode [String] custom request encode

    def initialize(url, options = {}, class_options = {})
      parse_uri = URI.parse url
      @uri = parse_uri.scheme + "://" + parse_uri.host

      # don't add 443 port append to url when access https website
      if !["80", "443"].include?(parse_uri.port.to_s)
        @uri = @uri + ":" + parse_uri.port.to_s
      end

      @origin_path = parse_uri.path || "/"

      @origin_type = options[:type] || :html
      @origin_headers = options[:headers] || {}
      @origin_query = options[:query] || URI.decode_www_form(parse_uri.query || "").to_h

      @origin_user_agent = options[:user_agent] || "Mac Safari"
      @origin_source = options[:source] || false
      @origin_retry = options[:retry] || 0

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
      @paginate_type = :html
      @paginate_path = ""
      @paginate_query = {}

      @crawling_errors = []
      @crawling_retry = 0

      @connection = Http::Client.new do |http|
        http.url= @uri
        http.user_agent= @origin_user_agent
        http.headers= @origin_headers
      end
      @class_options = class_options
    end

    # Process crawl data
    #
    # @param a [block]

    def crawl_data(&block)
      @paginate_num = @page_start

      catch :crawling_break_all do
        begin
          crawl_response = crawl_request(@origin_path, @origin_query, @origin_type, @origin_data, @origin_first, @origin_last, &block)
          return crawl_response if !block_given?
          process_response(crawl_response, &block)
        rescue Exception => e
          if @origin_retry > 0
            handle_error(e)
            crawl_data(&block)
          else
            @crawling_errors << e.to_s
            SpiderBot.logger.error "#{ get_page_url } crawling failed."
            SpiderBot.logger.warn e.to_s
            SpiderBot.logger.warn e.backtrace.join("\n")
          end
        end

        @crawling_retry = 0
        return if @page_query.blank? && @page_path == @origin_path

        crawl_paginate(&block)
      end
    end

    def errors
      @crawling_errors.uniq
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
          #  break crawl_paginate current page number more than @page_expire and @page_expre
          if real_page_num > @page_expire && @page_expire != -1
            SpiderBot.logger.info "Crawl finished..."
            SpiderBot.logger.info "Finish reson: The current page more than setting paginate expire"
            break
          end

          sleep(@page_sleep) if @page_sleep > 0

          path = @page_path.to_s % {page: @paginate_num}
          query_str = @page_query.to_s % { page: @paginate_num, last: @paginate_last, first: @paginate_first }
          query = eval(query_str)

          crawl_response = crawl_request(path, query, @page_type, @page_data, @page_first, @page_last, &block)
          process_response(crawl_response, &block)
        end
      rescue Exception => e
        @paginate_num += @page_add if @crawling_retry == 2
        if @origin_retry > 0
          handle_error(e)
          crawl_paginate(&block)
        else
          SpiderBot.logger.error "#{ get_page_url } crawling pagination failed."
          SpiderBot.logger.error e.to_s

            SpiderBot.logger.warn e.to_s
        end
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
        res_body = response.body(options)
        body = Nokogiri::HTML res_body
      elsif type.to_s == "json"
        @paginate_type = :json
        res_body = response.body(options)
        body = MultiJson.load res_body
      elsif type.to_s == "rss"
        @paginate_type = :rss
        MultiXml.parser = :ox        
        MultiXml.parser = MultiXml::Parsers::Ox
        res_body = response.body(options)
        rss = MultiXml.parse res_body
        body = rss["rss"]["channel"]
      else
        @paginate_type = response.parser
        body = response.parsed
      end

      return if body.nil?
      return [body] if data.nil?

      body_data = data.call(body) if data
      @paginate_first = first.call(body_data, body) if first
      @paginate_last = last.call(body_data, body) if last

      return [body_data, body, res_body]
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
      throw :crawling_break_all
    end

    def handle_error(error)
      @crawling_errors << error.to_s
      if @crawling_retry >= @origin_retry
        SpiderBot.logger.error "#{ get_page_url } crawling retry failed."
        SpiderBot.logger.warn error.to_s
        SpiderBot.logger.warn error.backtrace.join("\n")
        break_all 
      else
        SpiderBot.logger.error "#{ get_page_url } crawling failed."
        SpiderBot.logger.warn error.to_s
        SpiderBot.logger.warn error.backtrace.join("\n")
      end
      @crawling_retry += 1

      sleep( 10 * @crawling_retry)
    end

    # Print error infomation with http client response blank
    #
    # @param response [Object] The Faraday connection builder

    def process_response(response, &block)
      if response[0].blank?
        SpiderBot.logger.info "Crawl finished..."
        SpiderBot.logger.info "Finish reson: Crawl response body is blank..."
        break_all
      end
      SpiderBot.logger.info "crawling #{get_page_url}"
      yield response[0], { body: response[1], origin_body: response[2], page: @paginate_num, type: @paginate_type }, @class_options
      @paginate_num += @page_add
      @paginate_error = 0
    end
  end
end
