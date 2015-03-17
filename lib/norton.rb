require "redis"
require "connection_pool"
require "active_support/concern"
require "active_support/inflector"
require "norton/version"
require "norton/timestamp"
require "norton/counter"

module Norton
  class << self
    attr_accessor :redis

    #
    # Setup your redis connection.
    # @param options={} [Hash] [Redis connection configuration]
    #   url - Redis connection url
    #   pool - Connection pool size
    #   timeout - Connection pool timeout
    # @return [nil] [description]
    def setup(options={})
      pool_size = (options[:pool] || 1).to_i
      timeout = (options[:timeout] || 2).to_i

      Norton.redis = ConnectionPool.new(size: pool_size, timeout: timeout) do
        Redis.new(url: options[:url])
      end
    end
  end
end