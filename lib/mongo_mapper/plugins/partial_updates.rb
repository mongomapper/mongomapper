module MongoMapper
  module Plugins
    module PartialUpdates
      extend ActiveSupport::Concern

      class PartialUpdatesDisabledError < StandardError; end

      included do
        class_attribute :partial_updates
        self.partial_updates = false

        self.after_find :_reset_partial_updates_callback
        self.after_save :_reset_partial_updates_callback
      end

      def initialize(*)
        _reset_partial_updates_callback
        super
      end

      def fields_for_partial_update
        raise PartialUpdatesDisabledError if !partial_updates

        Hash.new.tap do |hash|
          attrs = _dealiased_attributes

          hash[:set_fields] = Array.new.tap do |array|
            attrs.each do |key, value|
              if !@_last_saved_attributes.include?(key) ||
                  @_last_saved_attributes[key] != value
                array << key
              end
            end
          end

          hash[:unset_fields] = @_last_saved_attributes.keys - attrs.keys
        end
      end

    private

      def _reset_partial_updates_callback
        _reset_attributes_for_partial_update if partial_updates
        true
      end

      def update(options={})
        if partial_updates
          super(options.merge(:persistence_method => :update))
        else
          super
        end
      end

      def save_to_collection(options={})
        if partial_updates && options[:persistence_method] == :update
          updates = fields_for_partial_update

          set_fields = updates[:set_fields]
          unset_fields = updates[:unset_fields]

          if set_fields.any? || unset_fields.any?
            set_fields.push("_id") if !set_fields.include?("_id")
          end

          options = options.merge({
            :set_fields => set_fields,
            :unset_fields => unset_fields
          })

          super(options)
        else
          super
        end
      end

      def _dealiased_attributes
        self.class.dealias_keys(attributes)
      end

      def _reset_attributes_for_partial_update
        @_last_saved_attributes = _dealiased_attributes._mongo_mapper_deep_copy_
      end
    end
  end
end