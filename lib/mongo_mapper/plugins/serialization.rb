# encoding: UTF-8
require 'active_support/json'

module MongoMapper
  module Plugins
    module Serialization
      def self.configure(model)
        model.class_eval { cattr_accessor :include_root_in_json, :instance_writer => true }
      end

      module InstanceMethods
        def as_json options={}
          options ||= {}
          unless options[:only]
            methods = [options.delete(:methods)].flatten.compact
            methods << :id
            options[:methods] = methods.uniq
          end

          except = [options.delete(:except)].flatten.compact
          except << :_id
          options[:except] = except

          # Direct rip from Rails 3 ActiveModel Serialization (#serializable_hash)
          hash = begin
            options[:only]   = Array.wrap(options[:only]).map { |n| n.to_s }
            options[:except] = Array.wrap(options[:except]).map { |n| n.to_s }

            attribute_names = attributes.keys.sort
            if options[:only].any?
              attribute_names &= options[:only]
            elsif options[:except].any?
              attribute_names -= options[:except]
            end

            method_names = Array.wrap(options[:methods]).inject([]) do |methods, name|
              methods << name if respond_to?(name.to_s)
              methods
            end

            (attribute_names + method_names).inject({}) { |hash, name|
              hash[name] = send(name)
              hash
            }
          end
          # End rip

          options.delete(:only) if options[:only].nil? or options[:only].empty?

          hash.each do |key, value|
            if value.is_a?(Array)
              hash[key] = value.map do |item|
                item.respond_to?(:as_json) ? item.as_json(options) : item
              end
            elsif value.is_a? BSON::ObjectId
              hash[key] = value.to_s
            elsif value.respond_to?(:as_json)
              hash[key] = value.as_json(options)
            end
          end

          # Replicate Rails 3 naming - and also bin anytihng after : for use in our dynamic classes from unit tests
          hash = { ActiveSupport::Inflector.underscore(ActiveSupport::Inflector.demodulize(self.class.name)).gsub(/:.*/,'') => hash } if include_root_in_json
          hash
        end
      end

      module ClassMethods
        def from_json(json)
          self.new(ActiveSupport::JSON.decode(json))
        end
      end

    end
  end
end
