module Norton
  module HashMap
    extend ActiveSupport::Concern

    included do
      include Norton::Helper
    end

    module ClassMethods
      def hash_map(name, options = {})
        register_norton_value(name, :hash_map, options)

        define_method(name) do
          instance_variable_get("@#{name}") ||
            instance_variable_set("@#{name}",
              Norton::Objects::Hash.new(norton_value_key(name), :pool_name => options[:redis])
            )
        end

        after_destroy { send(name).clear } if respond_to?(:after_destroy)
      end
    end
  end
end
