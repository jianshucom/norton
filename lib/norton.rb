require "redis"
require "connection_pool"
require "active_support/concern"
require "active_support/inflector"
require "norton/version"
require "norton/helper"
require "norton/timestamp"
require "norton/counter"
require "norton/objects/hash"
require "norton/hash_map"

module Norton
  SUPPORTED_TYPES = %i(counter timestamp hash_map)

  class NilObjectId < StandardError; end
  class InvalidType < StandardError; end

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
        Redis.new(
          options.slice(:url, :host, :port, :db, :path, :password, :namespace, :ssl_params, :driver)
        )
      end
    end

    # 批量获取多个对象的多个 Norton 字段, 仅仅支持 counter / timestamp
    #
    # @example
    #   Norton.mget([a_user, another_user], [:followers_count, :profile_updated_at])
    #
    # @param [Array] names 需要检索的字段
    #
    # @return [Array] 一组对象
    #
    def mget(objects, fields)
      keys = objects.flat_map do |object|
        fields.map { |f| object.norton_value_key(f) }
      end
      nested_values = Norton.redis.with do |conn|
        conn.mget(keys)
      end.each_slice(fields.size)

      objects.zip(nested_values).each do |object, values|
        object.send(:assign_values, fields.zip(values).to_h)
      end

      objects
    end
  end
end
