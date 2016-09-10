require 'redd'

module Lemtzas
  module Reddit
    # Safe execution helpers for Redd
    class ReddSafe
      TRY_LIMIT = 3
      attr_reader :redd

      def initialize(client_id, client_secret, username, password)
        @client_id = client_id
        @client_secret = client_secret
        @username = username
        @password = password
        reconnect
      end

      # Forward any othe rmethods on to @redd
      def method_missing(method_id, *args)
        redd_try do
          @redd.__send__(method_id, *args)
        end
      end

      # Reconnect to Redd with our credentials
      def reconnect
        @redd = ::Redd.it(:script,
                          @client_id, @client_secret,
                          @username, @password)
        @redd.authorize!
      end

      # Attempts an action with reconnect logic
      # rubocop:disable MethodLength
      # rubocop:disable AbcSize
      def redd_try(tries = 0)
        tries += 1
        yield
      rescue ::Redd::Error::InvalidOAuth2Credentials
        puts $ERROR_INFO.inspect, $ERROR_POSITION
        raise if tries > TRY_LIMIT
        reconnect
        sleep(30 * (tries**2))
        retry
      rescue ::Redd::Error::RateLimited => error
        puts "Rate Limited by Reddit #{error.time}"
        sleep(error.time)
        retry
      rescue ::Redd::Error => error
        # 5-something errors are usually errors on reddit's end.
        puts $ERROR_INFO.inspect
        raise error unless (500...600).cover?(error.code)
        retry
      rescue ::Faraday::SSLError
        puts $ERROR_INFO.inspect
        retry
      rescue ::Faraday::ConnectionFailed
        puts $ERROR_INFO.inspect, $ERROR_POSITION
        retry
      end
    end # class ReddSafe
  end # module Redd
end # module Lemtzas
