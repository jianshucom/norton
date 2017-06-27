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

    #
    # 为多个 Norton 对象一次性取出多个值
    #
    # 从一组相同的对象中，一次性取出多个 Norton 值。
    #
    # 例如:
    #
    # vals = Norton.mget([user1, user2, user3], [followers_count, profile_updated_at])
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
    def mget(objects, names)
      ret = {}

      mapping = {}
      redis_keys = []

      objects.each_with_index do |obj, index|
        next if obj.nil?

        names.each do |n|
          redis_key = obj.norton_value_key(n)

          redis_keys << redis_key
          mapping[redis_key] = [n, index]
        end
      end

      Norton.redis.with do |conn|
        values = conn.mget(redis_keys)

        redis_keys.each_with_index do |k, i|
          val = values[i].try(:to_i)

          # 如果返回值为 nil 并且定义了这个 norton value
          # 那么获取返回值
          if val.nil?
            # 从 mapping 中取出 value name 和对应的 object
            value_name, obj_index = mapping[k]
            obj = objects[obj_index]

            # 如果 object 定义了这个 value
            if obj.class.norton_value_defined?(value_name)
              # 获取默认值
              val = obj.send("#{value_name}_default_value".to_sym)

              # 如果返回值不为空，并且当前 value 的类型是 `timestamp` 将默认值存入 Redis
              if !val.nil? && obj.class.norton_value_type(value_name) == :timestamp
                conn.set(k, val)
              end
            end
          end

          ret[k] = val
        end
      end

      ret
    end
  end
end
