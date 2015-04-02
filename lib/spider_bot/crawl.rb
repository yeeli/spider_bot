module SpiderBot
  class Crawl
    def initialize(url, options = {})
      parse_uri = URI.parse url
      @uri = parse_uri.scheme + "://" + parse_uri.host
      
      @origin_path = parse_uri.path || "/"
      @origin_type = options[:type] || :html
      @origin_headers = options[:headers] || {}
      @origin_query = options[:query]
      @origin_data = options[:data]
      @origin_since = options[:since]
      
      @page_path = @origin_path
      @page_type = @origin_type
      @page_headers = @origin_headers
      @page_query = nil
      @page_data = @origin_data
      @page_since = @origin_since

      @page_sleep = 0
      @page_start = 0
      @page_add = 1
      @page_expire = 30
      @page_num = @page_start + @page_add

      @pagiante_error = 0

      @connection = Http::Client.new do |http| 
        http.url= @uri
        http.user_agent= "Mac Safari"
        http.headers= @origin_headers
      end
    end

    def crawl_data(&block)
      request_body = crawl_request(@origin_path, @origin_query, @origin_type, @origin_data, @origin_since, &block)
      return request_body  if !block_given?
      yield request_body, @page_num
      @page_num += @page_add
      raise "Net Error" if request_body.nil?
      return if @page_query.blank? && @page_path == @origin_path
      crawl_paginate(&block) 
    end

    private
    
    def crawl_paginate(&block)
      @page_headers.merge({"X-Requested-With" => "XMLHttpRequest"}) if @page_type == :json 
      @connection.headers = @page_headers
      begin
        loop do
          break if @page_num > @page_expire 
          sleep(@page_sleep) if @page_sleep > 0
  
          path = @page_path.to_s % {page: @page_num}
          query_str = @page_query.to_s % { page: @page_num, since: @paginate_since }
          query = eval(query_str)
  
          request_body = crawl_request(path, query, @page_type, @page_data, @page_since, &block)
          break if request_body.nil?
          yield request_body, @page_num
          @page_num += @page_add
        end
        @pagiante_error = 0
      rescue Exception => e
        puts "error"
        
        @page_num += @page_add if @pagiante_error == 3
        raise "request error" if @pagiante_error == 6
        @pagiante_error += 1
        
        sleep(60)
        crawl_paginate(&block)
      end
    end

    def crawl_request(path, query, type, data, since, &block)
      response = @connection.get(path, query)
      
      return if !response
      return if response.status != 200
      body = response.parsed
      
      return if body.nil?

      if type.to_sym == :json
        body_data = body[data]
        @page_since = body[since].last
      else
        body_data = body.css(data)
        @page_since = value.text if value = body_data.last.attributes[since]
      end

      return body_data 
    end

    %i(path query since type add data headers expire sleep).each do |name|
      class_eval <<-RUBY
        def set_paginate_#{name}(arg)
          @page_#{name} = arg
        end
      RUBY
    end
  end
end
