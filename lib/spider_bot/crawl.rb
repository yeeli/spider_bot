module SpiderBot
  class Crawl
    def initialize(url, options = {})
      parse_uri = URI.parse url
      @uri = parse_uri.scheme + "://" + parse_uri.host
      
      @origin_path = parse_uri.path || "/"
      @origin_type = options[:type] || 'html'
      @origin_headers = options[:headers] || {}
      @origin_query = options[:query] || {}

      @origin_data = options[:data]
      @origin_first = options[:first]
      @origin_last = options[:last]
      
      @page_path = @origin_path
      @page_type = @origin_type
      @page_headers = @origin_headers || {}
      @page_query = {}

      @page_data = @origin_data
      @page_first = @origin_first
      @page_last = @origin_last

      @page_start = 1
      @page_add = 1
      @page_expire = 30
      @page_sleep = 0
      
      @paginate_last = nil
      @paginate_error = 0

      @connection = Http::Client.new do |http| 
        http.url= @uri
        http.user_agent= "Mac Safari"
        http.headers= @origin_headers
      end
    end

    def crawl_data(&block)
      @paginate_num = @page_start
      request_body = crawl_request(@origin_path, @origin_query, @origin_type, @origin_data, @origin_first, @origin_last, &block)
      return request_body  if !block_given?
      yield request_body, @paginate_num, get_page_url(@origin_path, @origin_query)
      @paginate_num += @page_add
      raise "Net Error" if request_body.nil?
      return if @page_query.blank? && @page_path == @origin_path
      crawl_paginate(&block) 
    end

    private
    
    def crawl_paginate(&block)
      @page_headers.merge({"X-Requested-With" => "XMLHttpRequest"}) if @page_type.to_s == 'json'
      @connection.headers = @page_headers
      begin
        loop do
          break if @paginate_num > @page_expire 
          sleep(@page_sleep) if @page_sleep > 0
  
          path = @page_path.to_s % {page: @paginate_num}
          query_str = @page_query.to_s % { page: @paginate_num, last: @paginate_last, first: @paginate_first }
          query = eval(query_str)
  
          request_body = crawl_request(path, query, @page_type, @page_data, @page_first, @page_last, &block)
          break if request_body.nil?
          yield request_body, @paginate_num, get_page_url(path, query) 
          @paginate_num += @page_add
        end

        @paginate_error = 0

      rescue Exception => e
        puts "paginate error"
        puts e
        
        @paginate_num += @page_add if @paginate_error == 3
        raise "request error" if @paginate_error == 6
        @paginate_error += 1
        
        sleep(60)
        crawl_paginate(&block)
      end
    end

    def crawl_request(path, query, type, data, first, last, &block)
      response = @connection.get(path, query)
      return if !response
      return if response.status != 200
      body = response.parsed
      
      return if body.nil?
      return body if data.nil?

      body_data = data.call(body) if data
      @paginate_first = first.call(body_data, body) if first
      @paginate_last = last.call(body_data, body) if last

      return body_data 
    end

    def get_page_url(path, query)
      if !query.blank?
        @uri + path + "?" + query.map{ |k,v| "#{k}=#{v}" }.join("&")
      else
        @uri + path
      end
    end

    def set_paginate_headers(arg)
      @page_headers = arg || {}
    end

    def paginate(&block)
      block.call
    end

    def option(name, params)
      raise "paginamte error" if %i(path query first last type data start add expire sleep).include?(name.to_s)
      eval("@page_#{name} = params")
    end
  end
end
