module Norton
  module Helper
    extend ActiveSupport::Concern

    included do
      instance_variable_set(:@norton_values, {})
    end

    module ClassMethods
      attr_reader :norton_values


      #
      # 当前类是否定义了某个 Norton Value
      #
      # @param [String/Symbol] name
      #
      # @return [Boolean]
      #
      def norton_value_defined?(name)
        self.norton_values.has_key?(name.to_sym)
      end

      #
      # 当定义一个 Norton Value 的时候，将这个 Norton Value 记录在 Class Variable `@norton_values` 中
      #
      #
      # @return [void]
      #
      def register_norton_value(name, norton_type)
        if !Norton::SUPPORTED_TYPES.include?(norton_type.to_sym)
          raise Norton::InvalidType.new("Norton Type: #{norton_type} invalid!")
        end

        @norton_values[name.to_sym] = norton_type.to_sym
      end
    end

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
    def norton_value_key(name)
      "#{self.norton_prefix}:#{name}"
    end

    #
    # 批量取出当前对象的多个 Norton value
    #
    # @param [Array] *value_keys 直接传入需要的值的 key，例如: :key1, :key2, :key3
    #
    # @return [Hash]
    #
    def norton_mget(*names)
      ret = {}

      redis_keys = names.map { |n| self.norton_value_key(n) }

      redis_values = Norton.redis.with do |conn|
        conn.mget(redis_keys)
      end

      names.each_with_index do |n, index|
        val = redis_values[index].try(:to_i)

        if val.nil? && self.class.norton_value_defined?(n)
          val = send("#{n}_default_value".to_sym)
        end

        ret[n] = val
      end

      ret
    end
  end
end
