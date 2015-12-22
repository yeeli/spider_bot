module SpiderBot
  module Http
    class Response
      attr_reader :response

      CONTENT_TYPE = {
        'application/json' => :json,
        'application/x-www-form-urlencoded' => :html,
        'text/html' => :html,
        'text/javascript' => :json,
        'text/xml' => :xml
      }

      PARSERS = {
        :json => lambda{ |body| MultiJson.respond_to?(:adapter) ? MultiJson.load(body) : MultiJson.decode(body) rescue body},
        :html => lambda{ |body| Nokogiri::HTML(body)},
        :xml => lambda{ |body| MultiXml.parse(body) }
      }

      def initialize(response)
        @response = response
      end

      def headers
        response.headers
      end

      def body(options = {})
        options = options || {}
        decode(response.body, options)
      end

      def decode(body, options = {})
        return '' if !body 
        return body if json?
        charset = body.match(/charset\s*=[\s|\W]*([\w-]+)/)
        return body if charset[1].downcase == "utf-8"
        charset_code = charset_covert(charset[1])
        begin
          if options[:encode]
            return body.encode! "utf-8", options[:encode], {:invalid => :replace} 
          end
          body.encode! "utf-8", charset_code, {:invalid => :replace} 
        rescue
          body
        end
      end

      def status
        response.status
      end

      # Attempts to determine the content type of the response.
      def content_type
        ((response.headers.values_at('content-type', 'Content-Type').compact.first || '').split(';').first || '').strip
      end

      def json?
        CONTENT_TYPE[content_type] == :json || !response.body.match(/\<html/)
      end

      def parser
        type = CONTENT_TYPE[content_type]
        type = :json if type == :html && !response.body.match(/\<.*html|/) 
        type = :html if type.nil?
        return type
      end

      def parsed
        @parsed ||= PARSERS[parser].call(body)
      end

      def charset_covert(charset)
        case charset
        when "gb2312", "GB2312", "GBK"
          "gbk"
        else
          charset
        end
      end
    end
  end
end
