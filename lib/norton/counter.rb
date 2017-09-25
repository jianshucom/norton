module Norton
  module Counter
    extend ::ActiveSupport::Concern

    included do
      include Norton::Helper
    end

    module ClassMethods
      #
      # [counter description]
      # @param name [type] [description]
      # @param options={} [type] [description]
      # @param block [description]
      #
      # @return [type] [description]
      def counter(name, options={}, &blk)
        register_norton_value(name, :counter, options)
        redis = norton_value_redis_pool(name)

        # Redis: GET
        define_method(name) do
          instance_variable_get("@#{name}") || begin
            value = redis.with do |conn|
              conn.get(norton_value_key(name))
            end || send("#{name}_default_value")
            instance_variable_set("@#{name}", value.to_i)
          end
        end

        # Redis: SET
        define_method("#{name}=") do |value|
          if redis.with { |conn| conn.set(norton_value_key(name), value) }
            instance_variable_set("@#{name}", value.to_i)
          end
        end

        define_method("#{name}_default_value") do
          0
        end

        # Redis: INCR
        define_method("incr_#{name}") do
          value = redis.with do |conn|
            conn.incr(norton_value_key(name))
          end
          instance_variable_set("@#{name}", value.to_i)
        end

        # Redis: DECR
        define_method("decr_#{name}") do
          value = redis.with do |conn|
            conn.decr(norton_value_key(name))
          end
          instance_variable_set("@#{name}", value.to_i)
        end

        # Redis: INCRBY
        define_method("incr_#{name}_by") do |increment|
          value = redis.with do |conn|
            conn.incrby(norton_value_key(name), increment)
          end
          instance_variable_set("@#{name}", value.to_i)
        end

        # Redis: DECRBY
        define_method("decr_#{name}_by") do |decrement|
          value = redis.with do |conn|
            conn.decrby(norton_value_key(name), decrement)
          end
          instance_variable_set("@#{name}", value.to_i)
        end

        # Redis: SET
        define_method("reset_#{name}") do
          value = instance_eval(&blk)

          redis.with do |conn|
            conn.set(norton_value_key(name), value)
          end
          instance_variable_set("@#{name}", value)
        end

        # Redis: DEL
        define_method("remove_#{name}") do
          redis.with do |conn|
            conn.del(norton_value_key(name))
          end
          remove_instance_variable("@#{name}") if instance_variable_defined?("@#{name}")
        end
        send(:after_destroy, "remove_#{name}".to_sym) if respond_to? :after_destroy

        # Add Increment callback
        unless options[:incr].nil?
          options[:incr].each do |callback|
            send callback, proc{ instance_eval("incr_#{name}") }
          end
        end

        # Add Decrement callback
        unless options[:decr].nil?
          options[:decr].each do |callback|
            send callback, proc{ instance_eval("decr_#{name}") }
          end
        end
      end
    end
  end
end
