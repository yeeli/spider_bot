#coding: utf-8

module SpiderBot
  module Http
    class Client

      # return url for HttpClient
      attr_reader :url

      # return http user_agent for HttpClient
      attr_reader :user_agent

      attr_reader :headers

      #
      attr_accessor :options

      # return connection for HttpClient
      attr_accessor :connection

      attr_accessor :conn_build

      # Supported User-Agent
      #
      # * Linux Firefox (3.6.1)
      # * Linux Konqueror (3)
      # * Linux Mozilla
      # * Linux Chrome
      # * Mac Firefox
      # * Mac Mozilla
      # * Mac Chrome
      # * Mac Safari
      # * Mechanize (default)
      # * Windows IE 6
      # * Windows IE 7
      # * Windows IE 8
      # * Windows IE 9
      # * Windows Mozilla
      # * iPhone (3.0)
      # * iPad
      # * Android
     
      USER_AGENT = {
        'bot' => "bot/#{SpiderBot::VERSION}",
        'Linux Firefox' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.2.1) Gecko/20100122 firefox/3.6.1',
        'Linux Mozilla' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624',
        'Linux Chrome' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624  Chrome/26.0.1410.43',
        'Mac Firefox' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:35.0) Gecko/20100101 Firefox/35.0',
        'Mac Safari' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/600.3.18 (KHTML, like Gecko) Version/8.0.3 Safari/600.3.18',
        'Mac Chrome' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.104 Safari/537.36',
        'Windows IE 6' => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
        'Windows IE 7' => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)',
        'Windows IE 8' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)',
        'Windows IE 9' => 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)',
        'Windows Mozilla' => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
        'iPhone' => 'Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1C28 Safari/419.3',
        'iPad' => 'Mozilla/5.0 (iPad; U; CPU OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Version/4.0.4 Mobile/7B334b Safari/531.21.10',
        'Android' => 'Mozilla/5.0 (Linux; U; Android 3.0; en-us) AppleWebKit/534.13 (KHTML, like Gecko) Version/4.0 Safari/534.13'
      }

      # Initialize a new HttpClient
      # 
      # @param opts [String] the options to create a http with
      # @option opts [String] :a the options
      #
      # @example
      #
      # http = HttpClient.new
      #
      # http = HttpClient.new do |http|
      #   http.user_agent= "Mac Safri"
      #   http.url= "http://example.com"
      # end
     
      def initialize(uri = nil, options = nil, &block)
        @url = uri
        @user_agent ||= USER_AGENT['bot']
        yield self if block_given?
      end

      def builder(&block)
        @conn_build = block
      end

      # Set the url for HttpClient
      #
      # @param [String] the HttpClient url
     
      def url=(uri)
        @conn = nil
        @url = uri
      end

      # Set the headers for HttpClient
      #
      # @param [String] the HttpClient url
      
      def headers=(headers)
        @headers = headers.merge({"User-Agent" => user_agent})
      end

      # Set the user agent for HttpClient
      #
      # @param [Symbol] the HttpClient user agent 
      
      def user_agent=(name)
        @user_agent = USER_AGENT[name] || USER_AGENT['bot']
      end

      # The Faraday connection object
      
      def connection
        @connection ||= begin
                          conn = Faraday.new(url: url)
                          conn.build do |b|
                            conn_build.call(b)
                          end if conn_build
                          conn
                        end
      end


      # Make request with HttpClient
      #
      # @param verb [Symbol] verb one of :get, :post, :put, :delete
      # @param uri [String] URL path for request
      # @param query [Hash] additional query parameters for the URL of the request
      
      def request(verb, uri, query={})
        verb == :get ? query_get = query : query_post = query
        uri = connection.build_url(uri, query_get)

        response = connection.run_request(verb, uri, query_post, headers) do |request|
          yield request if block_given?
        end
        response = Response.new(response)
        
        case response.status
        when 301, 302, 303, 307
          request(verb, response.headers['location'], query)
        when 200..299, 300..399
          response
        end
      end

      # Make get request with HttpClient 
      #
      # @param uri [String] URL path for request
      # @param query [Hash] additional query parameters for the URL of the request
     
      def get(uri, query = {}, &block) 
        request(:get, uri, query, &block)
      end

      def post(uri, query = {}, &block)
        request(:post, uri, query, &block)
      end
    end
  end
end
