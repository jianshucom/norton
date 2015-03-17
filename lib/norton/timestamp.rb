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
      def timestamp(name, touches={})
        define_method(name) do
          Norton.redis.with do |conn|
            conn.get("#{self.class.to_s.pluralize.downcase}:#{self.id}:#{name}").try(:to_i) || Time.now.to_i
          end
        end

        define_method("touch_#{name}") do
          Norton.redis.with do |conn|
            conn.set("#{self.class.to_s.pluralize.downcase}:#{self.id}:#{name}", Time.now.to_i)
          end
        end

        # Add callback
        unless touches.empty?
          touches.each do |callback, condition|
            self.send callback, proc{ if instance_eval(&condition) then instance_eval("touch_#{name}".to_sym) end }
          end
        end
      end
    end
  end
end