# encoding: UTF-8

module MongoMapper

  class MultiParamAssign < Error; end

  module Plugins
    module MultiParameter
      module InstanceMethods
        def attributes=(attrs={})
          multi_parameter_attrs = get_multi_parameter_attrs attrs
          attrs = filter_multi_parameter_attrs attrs

          # assign regular attributes.
          super attrs

          # assign multi-parameter attributes.
          set_multi_parameter_attrs multi_parameter_attrs
        end

        protected

        def get_multi_parameter_attrs attrs
          multi_parameter_attrs = []
          attrs.each do |k, v|
            if k.include? "("
              multi_parameter_attrs << [ k, v ]
            end
          end
          multi_parameter_attrs
        end

        def filter_multi_parameter_attrs attrs
          attrs.reject do |k, v|
            k.include? "("
          end
        end

        def set_multi_parameter_attrs pairs
          callstack = extract_callstack_for_multiparameter_attributes pairs
          execute_callstack_for_multiparameter_attributes callstack
        end

        # Comes from the rails source code. Modified to work in MM context without any ActiveRecord dependencies.
        def execute_callstack_for_multiparameter_attributes(callstack)
          errors = []
          callstack.each do |name, values_with_empty_parameters|
            begin
              unless self.keys[name].nil?
                begin
                  # Not using String#classify because it doesn't exist in standard ruby.
                  klass = eval "#{self.keys[name].type}"
                rescue
                  "Key type of attribute named #{name} isn't a class name... can't assign as multiparameter attribute."
                end
              else
                raise "Trying to assign a multiparameter attribute named #{name}. No such key was defined."
              end
              # in order to allow a date to be set without a year, we must keep the empty values.
              # Otherwise, we wouldn't be able to distinguish it from a date with an empty day.
              values = values_with_empty_parameters.reject { |v| v.nil? }

              if values.empty?
                send(name + "=", nil)
              else
                value = if Time == klass
                          instantiate_time_object(name, values)
                        elsif Date == klass
                          begin
                            values = values_with_empty_parameters.collect do |v| v.nil? ? 1 : v end
                            Date.new(*values)
                          rescue ArgumentError => ex # if Date.new raises an exception on an invalid date
                            instantiate_time_object(name, values).to_date # we instantiate Time object and convert it back to a date thus using Time's logic in handling invalid dates
                          end
                        else
                          klass.new(*values)
                        end

                send(name + "=", value)
              end
            rescue => ex
              errors << ex
            end
          end
          unless errors.empty?
            raise MultiParamAssign.new "#{errors.size} error(s) on assignment of multiparameter attributes"
          end
        end

        # Comes from the rails source code.
        def extract_callstack_for_multiparameter_attributes(pairs)
          attributes = {}

          for pair in pairs
            multiparameter_name, value = pair
            attribute_name = multiparameter_name.split("(").first
            attributes[attribute_name] = [] unless attributes.include?(attribute_name)

            parameter_value = value.empty? ? nil : type_cast_attribute_value(multiparameter_name, value)
            attributes[attribute_name] << [ find_parameter_position(multiparameter_name), parameter_value ]
          end

          attributes.each { |name, values| attributes[name] = values.sort_by{ |v| v.first }.collect { |v| v.last } }
        end

        # Comes from the rails source code.
        def find_parameter_position multiparameter_name
          multiparameter_name.scan(/\(([0-9]*).*\)/).first.first
        end

        # Comes from the rails source code.
        def type_cast_attribute_value(multiparameter_name, value)
          multiparameter_name =~ /\([0-9]*([if])\)/ ? value.send("to_" + $1) : value
        end

        # Comes from the rails source code.
        def instantiate_time_object(name, values)
          #if self.class.send(:create_time_zone_conversion_attribute?, name, column_for_attribute(name))
          #Time.zone.local(*values)
          #else
          Time.time_with_datetime_fallback(@@default_timezone, *values)
          #end
        end
      end
    end
  end
end
