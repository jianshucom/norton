module Norton
  module Timestamp
    extend ActiveSupport::Concern

    included do
      include Norton::Helper
    end

    module ClassMethods
      #
      # [timestamp Define a timestamp]
      # @param name [type] [description]
      # @param touches={} [type] [description]
      #
      # @return [type] [description]
      def timestamp(name, options={})
        register_norton_value(name, :timestamp, options)
        redis = norton_value_redis_pool(name)

        # Redis: GET
        define_method(name) do
          return instance_variable_get("@#{name}") if instance_variable_defined?("@#{name}")

          value = redis.with do |conn|
            raw_value = conn.get(norton_value_key(name))
            break raw_value if raw_value.present?

            send("#{name}_default_value").tap do |default_value|
              conn.set(norton_value_key(name), default_value)
            end
          end
          if value.nil? && options[:allow_nil]
            instance_variable_set("@#{name}", nil)
          else
            instance_variable_set("@#{name}", value.to_i)
          end
        end

        define_method("#{name}_default_value") do
          return nil if options[:allow_nil]
          return (Time.current.to_f * 1000).to_i if options[:digits] == 13

          Time.current.to_i
        end

        # Redis: SET
        define_method("touch_#{name}") do
          value = options[:digits] == 13 ? (Time.current.to_f * 1000).to_i : Time.current.to_i

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

        # Add callback
        if options[:touch_on].present?
          options[:touch_on].each do |callback, condition|
            self.send callback, proc{ if instance_eval(&condition) then instance_eval("touch_#{name}") end }
          end
        end
      end
    end
  end
end
