module Norton
  module Helper
    extend ActiveSupport::Concern

    included do
      instance_variable_set(:@norton_values, {})
    end

    module ClassMethods
      attr_reader :norton_values

      #
      # 当定义一个 Norton Value 的时候，将这个 Norton Value 记录在 Class Variable `@norton_values` 中
      #
      #
      # @return [void]
      #
      def register_norton_value(name, norton_type, options = {})
        if !Norton::SUPPORTED_TYPES.include?(norton_type.to_sym)
          raise Norton::InvalidType.new("Norton Type: #{norton_type} invalid!")
        end

        @norton_values[name.to_sym] = options.symbolize_keys.merge(:type => norton_type.to_sym)
      end

      #
      # 当前类是否定义了某个 Norton Value
      #
      # @param [String/Symbol] name
      #
      # @return [Boolean]
      #
      def norton_value_defined?(name)
        norton_values.has_key?(name.to_sym)
      end

      #
      # 返回当前类定义的某个 Norton Value 的类型
      #
      # @param [String] name
      #
      # @return [Symbol]
      #
      def norton_value_type(name)
        norton_values.dig(name.to_sym, :type)
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
      "#{klass}:#{id}"
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
      "#{norton_prefix}:#{name}"
    end

    def cast_value(type, value)
      case type.to_sym
      when :counter then value.to_i
      when :timestamp then value.to_i
      end
    end

    # 批量取出当前对象的多个 Norton 字段, 仅仅支持 counter / timestamp
    #
    # @param [Array] names 需要检索的字段, 例如: :field1, :field2
    #
    # @return [Model] 当前对象
    #
    def norton_mget(*names)
      values = Norton.redis.with do |conn|
        conn.mget(names.map { |name| norton_value_key(name) })
      end

      assign_values(names.zip(values).to_h)

      self
    end

    # :nodoc
    def assign_values(new_values)
      new_values.each do |field, val|
        type = self.class.norton_value_type(field)

        case type
        when :counter
          value = cast_value(type, val || try("#{field}_default_value"))
          instance_variable_set("@#{field}", value)
        when :timestamp
          if !val.nil?
            instance_variable_set("@#{field}", cast_value(type, val))
          elsif self.class.norton_values[field][:allow_nil]
            instance_variable_set("@#{field}", nil)
          else
            value = cast_value(type, try("#{field}_default_value"))
            instance_variable_set("@#{field}", value)
            Norton.redis.with { |conn| conn.set(norton_value_key(field), value) }
          end
        end
      end
    end
    send(:private, :assign_values)
  end
end
