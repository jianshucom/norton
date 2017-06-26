module Norton
  module TimedValue
    extend ActiveSupport::Concern

    module ClassMethods

      def timed_value(name, options={}, &blk)
        if options[:ttl].nil?
          raise 'Time to live not specified.'
        end

        if blk.nil?
          raise 'Value generation not provided'
        end

        # Define getter
        define_method(name) do
          Norton.redis.with do |conn|
            v = conn.get(self.norton_value_key(name))

            if v.nil?
              v = instance_eval(&blk)
              conn.setex(self.norton_value_key(name), options[:ttl], v)
            end

            v
          end
        end

        define_method("reset_#{name}") do
          Norton.redis.with do |conn|
            v = instance_eval(&blk)
            conn.setex(self.norton_value_key(name), options[:ttl], v)
            v
          end
        end
      end
    end
  end
end
