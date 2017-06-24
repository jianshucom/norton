require "redis"
require "connection_pool"
require "active_support/concern"
require "active_support/inflector"
require "norton/version"
require "norton/helper"
require "norton/timestamp"
require "norton/counter"
require "norton/timed_value"
require "norton/objects/hash"
require "norton/hash_map"

module Norton
  class NilObjectId < StandardError; end

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

      Norton.redis = ConnectionPool.new(:size => pool_size, :timeout => timeout) do
        Redis.new(options.slice(:url, :host, :port, :db, :path, :password, :namespace, :ssl_params, :driver))
      end
    end

    #
    # 为多个 Norton 对象一次性取出多个值
    #
    # 从一组相同的对象中，一次性取出多个 Norton 值。
    #
    # 例如:
    #
    # vals = Norton.norton_vals([user1, user2, user3], [followers_count, profile_updated_at])
    #
    # 将会返回:
    #
    # ```
    # {
    #   "users:1:followers_count": 2,
    #   "users:2:followers_count": 3,
    #   "users:3:followers_count": 4,
    #   "users:1:profile_updated_at": 1498315792,
    #   "users:2:profile_updated_at": 1499315792,
    #   "users:3:profile_updated_at": 1409315792,
    # }
    # ```
    #
    # * 返回的 Field 之间的顺序无法保证
    #
    # @param [Array] objects
    # @param [Array] names
    #
    # @return [Hash]
    #
    def norton_vals(objects, names)
      ret = {}
      redis_keys = []

      objects.each do |obj|
        next if obj.nil?

        names.each do |n|
          redis_keys << obj.norton_redis_key(n)
        end
      end

      values = Norton.redis.with do |conn|
        conn.mget(redis_keys)
      end

      redis_keys.each_with_index do |k, i|
        ret[k] = values[i]
      end

      ret
    end
  end
end
