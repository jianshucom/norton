module Norton
  module HashMap
    extend ActiveSupport::Concern

    module ClassMethods
      def hash_map(name)
        define_method(name) do
          instance_variable_get("@#{name}") ||
            instance_variable_set("@#{name}",
              Norton::Objects::Hash.new(norton_field_key(name))
            )
        end

        after_destroy { send(name).clear } if respond_to?(:after_destroy)
      end
    end

    def norton_field_key(name)
      if id.nil?
        raise NilObjectId,
          "Attempt to address norton field :#{name} on class #{self.class.name} with nil id"
      end

      "#{self.class.name.tableize}:#{id}:#{name}"
    end
  end
end
