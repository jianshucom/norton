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
    attr_accessor :pools
    attr_accessor :redis

    def pools
      @pools ||= {}
    end

    #
    # Setup your redis connection.
    #
    # @param options={} [Hash] [Redis connection configuration]
    #   url - Redis connection url
    #   pool - Connection pool size
    #   timeout - Connection pool timeout
    #
    # @example
    #   {
    #     "default" => { "url" => "redis://localhost:6379/0", "pool" => 4, "timeout" => 2 },
    #     "norton2" => { "url" => "redis://localhost:6379/3", "pool" => 4, "timeout" => 2 }
    #   }
    #
    # @return [Void]
    #
    def setup(options = {})
      self.pools = {}
      options.deep_symbolize_keys!

      options.each do |name, conn_params|
        pool_size = (conn_params.delete(:pool) || 1).to_i
        timeout   = (conn_params.delete(:timeout) || 2).to_i
        Norton.pools[name] = ConnectionPool.new(size: pool_size, timeout: timeout) do
          Redis.new(conn_params)
        end
      end

      Norton.redis = Norton.pools[:default]
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
      pools_with_name = fields.each_with_object({}) do |name, hash|
        pool = objects[0].class.norton_value_redis_pool(name)
        hash[pool] ||= []
        hash[pool] << name
      end

      pools_with_name.each do |pool, names|
        keys = objects.flat_map do |object|
          names.map { |name| object.norton_value_key(name) }
        end
        nested_values = pool.with do |conn|
          conn.mget(keys)
        end.each_slice(names.size)
        objects.zip(nested_values).each do |object, values|
          object.send(:assign_values, names.zip(values).to_h)
        end
      end

      objects
    end
  end
end
