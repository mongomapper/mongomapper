module MongoMapper
  module Associations
    module ClassMethods
      ##
      # This macro allows you define a "belongs-to" relationship between one 
      # document and some other document.
      #
      # == Requirements
      #
      # Usage of this macro requires that your document define a key that can 
      # be used to store the ID of the target document that is the parent of 
      # this document.
      #
      # == Conventions
      # 
      # The following is a list of the conventions used by MongoMapper in 
      # defining a belongs-to relationship. Each can likely be overridden via 
      # the +options+ parameter.
      #
      # * The name of your belongs-to association is the lowercase, singular 
      #   name of the target class
      # * A key with the name of your association exists with an "_id" suffix 
      #   to store the ID of the target of this relationship
      #
      # @param [Symbol] association_id The name of this association
      # @param [Hash] options Optional parameters that define the 
      #   characteristics of this relationship. These are often used to 
      #   override MongoMapper conventions.
      # @option options [Boolean] :polymorphic (false) Set this option to 
      #   <code>true</code> to define a relationship that can be between this 
      #   document and any other type of document. Note that you *must* also 
      #   have a key on your document to store the type of document in this 
      #   relationship.
      # @option options [String] :class_name If your relationship doesn't use 
      #   the name of some class, you *must* use this option to indicate the 
      #   target class for this relationship.
      # @option options [Symbol] :foreign_key Use this option to specify a 
      #   non-conventional key that stores the ID of the parent in this 
      #   relationship
      #
      # @example Conventional, and simple, usage of <code>belongs_to</code>
      #   class Novel
      #     include MongoMapper::Document
      #
      #     key :author_id, String # our "foreign key"
      #
      #     belongs_to :author
      #   end
      #
      # @example Using :foreign_key and :class_name
      #   class Pet
      #     include MongoMapper::Document
      #
      #     key :person_id, String
      #
      #     belongs_to :owner,
      #       :foreign_key => :person_id,
      #       :class_name  => "Person"
      #   end
      #
      # @example Defining a polymorphic belongs-to relationship
      #   class Vehicle
      #     include MongoMapper::Document
      #
      #     key :owner_id,   String
      #     key :owner_type, String
      #
      #     belongs_to :owner,
      #       :polymorphic => true
      #   end
      #
      # @example Non-standard polymorphic belongs-to relationship
      #   class Vehicle
      #     include MongoMapper::Document
      #
      #     key :person_id,   String
      #     key :person_type, String
      #
      #     belongs_to :owner,
      #       :polymorphic   => true,
      #       :foreign_key   => "person_id",
      #       :type_key_name => "person_type"
      #   end
      def belongs_to(association_id, options={}, &extension)
        create_association(:belongs_to, association_id, options, &extension)
        self
      end

      ##
      # This macro allows you to define a "has-many" relationship between a 
      # document, and numerous child documents.
      #
      # == Conventions
      #
      # The following is a list of the conventions used by MongoMapper in 
      # defining this relationship. Each can likely be overridden via the 
      # +options+ parameter.
      #
      # * The name of your association is the lowercase, *plural* name of the 
      #   target class
      # * Your target class must have a "foreign key" bearing the name of this 
      #   class suffixed by "_id"
      #
      # @param [Symbol] association_id The name of this association
      # @param [Hash] options Optional parameters that define the 
      #   characteristics of this relationship. These are often used to 
      #   override MongoMapper conventions.
      # @option options [String] :class_name If your relationship doesn't use 
      #   the name of some class, you *must* use this option to indicate the 
      #   target class for this relationship.
      # @option options [Symbol] :foreign_key Use this option to specify a 
      #   non-conventional key that stores the ID of the parent in this 
      #   relationship
      # @option options [#to_s] :as Used when the target relationship is 
      #   polymorphic (i.e. the +belongs_to+ has set <tt>:polymorphic</tt> to 
      #   +true+). See examples for usage.
      def many(association_id, options={}, &extension)
        create_association(:many, association_id, options, &extension)
        self
      end

      def associations
        @associations ||= self.superclass.respond_to?(:associations) ? 
                            self.superclass.associations : 
                            HashWithIndifferentAccess.new
      end

      private
        def create_association(type, name, options, &extension)
          association = Associations::Base.new(type, name, options, &extension)
          associations[association.name] = association
          define_association_methods(association)
          define_dependent_callback(association)
          association
        end

        def define_association_methods(association)
          define_method(association.name) do
            get_proxy(association)
          end

          define_method("#{association.name}=") do |value|
            get_proxy(association).replace(value)
            value
          end
        end

        def define_dependent_callback(association)
          if association.options[:dependent]
            if association.many?
              define_dependent_callback_for_many(association)
            end
          end
        end

        def define_dependent_callback_for_many(association)
          after_destroy do |doc|
            if !association.embeddable?
              case association.options[:dependent]
              when :destroy
                doc.get_proxy(association).destroy_all
              when :delete_all
                doc.get_proxy(association).delete_all
              when :nullify
                doc.get_proxy(association).nullify
              end
            end
          end
        end
    end

    module InstanceMethods
      def get_proxy(association)
        unless proxy = self.instance_variable_get(association.ivar)
          proxy = association.proxy_class.new(self, association)
          self.instance_variable_set(association.ivar, proxy) if !frozen?
        end

        proxy
      end
    end
  end
end
