module Norton
  module Counter
    extend ActiveSupport::Concern

    module ClassMethods
      #
      # [counter description]
      # @param name [type] [description]
      # @param touches={} [type] [description]
      #
      # @return [type] [description]
      def counter(name, options={})
        define_method(name) do
          Norton.redis.with do |conn|
            conn.set("#{self.class.to_s.pluralize.downcase}:#{self.id}:#{name}", Time.now.to_i).try(:to_i) || 0
          end
        end

        define_method("incr_#{name}") do
          Norton.redis.with do |conn|
            conn.incr("#{self.class.to_s.pluralize.downcase}:#{self.id}:#{name}")
          end
        end

        define_method("decr_#{name}") do
          Norton.redis.with do |conn|
            conn.decr("#{self.class.to_s.pluralize.downcase}:#{self.id}:#{name}")
          end
        end

        define_method("#{name}=") do |v|
          Norton.redis.with do |conn|
            conn.set("#{self.class.to_s.pluralize.downcase}:#{self.id}:#{name}", v)
          end
        end

        # Add Increment callback
        unless options[:incr].empty?
          options[:incr].each do |callback|
            self.send callback, proc{ instance_eval("incr_#{name}".to_sym) }
          end
        end

        # Add Decrement callback
        unless options[:decr].empty?
          options[:decr].each do |callback|
            self.send callback, proc{ instance_eval("decr_#{name}".to_sym) }
          end
        end
      end
    end
  end
end