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
          puts :foo
        end

        define_method("#{name}=") do |value|
          puts value
        end

        define_method("touch_#{name}") do
          Norton.redis.with do |conn|
            conn.set("#{self.class.to_s.pluralize.downcase}:#{self.id}:#{name}", Time.now.to_i)
          end
        end
      end
    end
  end
end