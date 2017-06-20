module Norton
  module Helper
    extend ActiveSupport::Concern

    if !respond_to?(:norton_prefix)
      #
      #
      #
      #
      # @return [<type>] <description>
      #
      def norton_prefix
        klass = self.class.to_s.underscore
        "#{klass}:#{self.id}"
      end
    end

    if !respond_to?(:norton_redis_key)
      #
      #
      #
      #
      # @return [<type>] <description>
      #
      def norton_redis_key(name)
        "#{self.norton_prefix}:#{name}"
      end
    end

    if !respond_to?(:norton_vals)
      #
      # 批量取出当前对象的多个 Norton value
      #
      # @param [Array] *value_keys 直接传入需要的值的 key，例如: :key1, :key2, :key3
      #
      # @return [Hash]
      #
      def norton_vals(*keys)
        ret = {}

        redis_keys = keys.map { |k| "#{self.class.to_s.pluralize.underscore}:#{self.id}:#{k}" }

        redis_values = Norton.redis.with do |conn|
          conn.mget(redis_keys)
        end

        keys.each_with_index do |key, index|
          ret[key] = redis_values[index].try(:to_i)
        end

        ret
      end
    end
  end
end
