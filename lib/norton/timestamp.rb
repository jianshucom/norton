module Norton
  module Timestamp
    extend ActiveSupport::Concern

    module ClassMethods
      #
      # [timestamp Define a timestamp]
      # @param name [type] [description]
      # @param touches={} [type] [description]
      #
      # @return [type] [description]
      def timestamp(name, options={})
        define_method(name) do
          ts = nil

          Norton.redis.with do |conn|
            ts = conn.get("#{self.class.to_s.pluralize.downcase}:#{self.id}:#{name}").try(:to_i)

            if ts.nil?
              ts = Time.now.to_i
              conn.set("#{self.class.to_s.pluralize.downcase}:#{self.id}:#{name}", ts)
            end

            ts
          end
        end

        define_method("touch_#{name}") do
          Norton.redis.with do |conn|
            if options[:digits].present? && options[:digits] == 13
              conn.set("#{self.class.to_s.pluralize.downcase}:#{self.id}:#{name}", (Time.now.to_f * 1000).to_i)
            else
              conn.set("#{self.class.to_s.pluralize.downcase}:#{self.id}:#{name}", Time.now.to_i)
            end
          end
        end

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