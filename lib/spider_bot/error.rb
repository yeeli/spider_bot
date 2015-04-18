module SpiderBot
  class Error < StandardError; end
  class TimeoutError < Faraday::TimeoutError; end
  class ConnectionFaild < Faraday::ConnectionFailed; end
end
