module Norton
  module Helper
    extend ActiveSupport::Concern

    if !respond_to?(:norton_prefix)
      #
      # Prefix of Redis Key of Norton value, consists with Class name string in plural form
      # and Instance id.
      #
      # Example:
      #
      # a User instance with id = 1 -> `users:1`
      # a HolyLight::Spammer instance with id = 5 -> `holy_light/spammers:5`
      #
      #
      # @return [String]
      #
      def norton_prefix
        id = self.id
        raise Norton::NilObjectId if id.nil?
        klass = self.class.to_s.pluralize.underscore
        "#{klass}:#{self.id}"
      end
    end

    if !respond_to?(:norton_redis_key)
      #
      # Returns the final Redis Key of a certain Norton value, teh value will be saved in redis with
      # this value.
      #
      # Example:
      #
      # a User instance with id = 1 defines a counter named `likes_count` -> users:1:likes_count
      #
      #
      # @param [String] name
      #
      # @return [String]
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
      def norton_vals(*names)
        ret = {}

        redis_keys = names.map { |n| self.norton_redis_key(n) }

        redis_values = Norton.redis.with do |conn|
          conn.mget(redis_keys)
        end

        names.each_with_index do |n, index|
          ret[n] = redis_values[index].try(:to_i)
        end

        ret
      end
    end
  end
end
