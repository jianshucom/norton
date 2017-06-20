module Norton
  module Counter
    extend ::ActiveSupport::Concern

    module ClassMethods
      #
      # [counter description]
      # @param name [type] [description]
      # @param options={} [type] [description]
      # @param block [description]
      #
      # @return [type] [description]
      def counter(name, options={}, &blk)
        define_method(name) do
          Norton.redis.with do |conn|
            conn.get(self.norton_redis_key(name)).try(:to_i) || 0
          end
        end

        define_method("incr_#{name}") do
          Norton.redis.with do |conn|
            conn.incr(self.norton_redis_key(name))
          end
        end

        define_method("decr_#{name}") do
          Norton.redis.with do |conn|
            conn.decr(self.norton_redis_key(name))
          end
        end

        define_method("incr_#{name}_by") do |increment|
          Norton.redis.with do |conn|
            conn.incrby(self.norton_redis_key(name), increment)
          end
        end

        define_method("decr_#{name}_by") do |decrement|
          Norton.redis.with do |conn|
            conn.decrby(self.norton_redis_key(name), decrement)
          end
        end

        define_method("#{name}=") do |v|
          Norton.redis.with do |conn|
            conn.set(self.norton_redis_key(name), v)
          end
        end

        define_method("reset_#{name}") do
          count = instance_eval(&blk)

          Norton.redis.with do |conn|
            conn.set(self.norton_redis_key(name), count)
          end
        end

        define_method("remove_#{name}") do
          Norton.redis.with do |conn|
            conn.del(self.norton_redis_key(name))
          end
        end
        send(:after_destroy, "remove_#{name}".to_sym) if respond_to? :after_destroy

        # Add Increment callback
        unless options[:incr].nil?
          options[:incr].each do |callback|
            self.send callback, proc{ instance_eval("incr_#{name}") }
          end
        end

        # Add Decrement callback
        unless options[:decr].nil?
          options[:decr].each do |callback|
            self.send callback, proc{ instance_eval("decr_#{name}") }
          end
        end
      end
    end
  end
end
