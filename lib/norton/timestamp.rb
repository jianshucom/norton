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
        self.register_norton_value(name, :timestamp)

        define_method(name) do
          ts = nil

          Norton.redis.with do |conn|
            ts = conn.get(self.norton_value_key(name)).try(:to_i)

            if ts.nil?
              ts = send("#{name}_default_value".to_sym)
              conn.set(self.norton_value_key(name), ts) if !ts.nil?
            end

            ts
          end
        end

        define_method("#{name}_default_value") do
          if !options[:allow_nil]
            if options[:digits].present? && options[:digits] == 13
              ts = (Time.now.to_f * 1000).to_i
            else
              ts = Time.now.to_i
            end

            ts
          else
            nil
          end
        end
        send(:private, "#{name}_default_value".to_sym)

        define_method("touch_#{name}") do
          Norton.redis.with do |conn|
            if options[:digits].present? && options[:digits] == 13
              conn.set(self.norton_value_key(name), (Time.now.to_f * 1000).to_i)
            else
              conn.set(self.norton_value_key(name), Time.now.to_i)
            end
          end
        end

        define_method("remove_#{name}") do
          Norton.redis.with do |conn|
            conn.del("#{self.class.to_s.pluralize.underscore}:#{self.id}:#{name}")
          end
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
