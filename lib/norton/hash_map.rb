module Norton
  module HashMap
    extend ActiveSupport::Concern

    included do
      include Norton::Helper
    end

    module ClassMethods
      def hash_map(name)
        self.register_norton_value(name, :hash_map)

        define_method(name) do
          instance_variable_get("@#{name}") ||
            instance_variable_set("@#{name}",
              Norton::Objects::Hash.new(self.norton_value_key(name))
            )
        end

        after_destroy { send(name).clear } if respond_to?(:after_destroy)
      end
    end
  end
end
