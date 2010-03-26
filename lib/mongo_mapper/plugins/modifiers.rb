module MongoMapper
  module Plugins
    module Modifiers
      module ClassMethods
        def increment(*args)
          modifier_update('$inc', args)
        end

        def decrement(*args)
          criteria, keys = criteria_and_keys_from_args(args)
          values, to_decrement = keys.values, {}
          keys.keys.each_with_index { |k, i| to_decrement[k] = -values[i].abs }
          collection.update(criteria, {'$inc' => to_decrement}, :multi => true)
        end

        def set(*args)
          modifier_update('$set', args)
        end

        def push(*args)
          modifier_update('$push', args)
        end

        def push_all(*args)
          modifier_update('$pushAll', args)
        end

        def push_uniq(*args)
          criteria, keys = criteria_and_keys_from_args(args)
          keys.each { |key, value | criteria[key] = {'$ne' => value} }
          collection.update(criteria, {'$push' => keys}, :multi => true)
        end

        def pull(*args)
          modifier_update('$pull', args)
        end

        def pull_all(*args)
          modifier_update('$pullAll', args)
        end

        def pop(*args)
          modifier_update('$pop', args)
        end

        private
          def modifier_update(modifier, args)
            criteria, keys = criteria_and_keys_from_args(args)
            modifiers = {modifier => keys}
            collection.update(criteria, modifiers, :multi => true)
          end

          def criteria_and_keys_from_args(args)
            keys     = args.pop
            criteria = args[0].is_a?(Hash) ? args[0] : {:id => args}
            [to_criteria(criteria), keys]
          end
      end

      module InstanceMethods
        def increment(hash)
          self.class.increment({:_id => id}, hash)
        end

        def decrement(hash)
          self.class.decrement({:_id => id}, hash)
        end

        def set(hash)
          self.class.set({:_id => id}, hash)
        end

        def push(hash)
          self.class.push({:_id => id}, hash)
        end

        def pull(hash)
          self.class.pull({:_id => id}, hash)
        end

        def push_uniq(hash)
          self.class.push_uniq({:_id => id}, hash)
        end

        def pop(hash)
          self.class.pop({:_id => id}, hash)
        end
      end
    end
  end
end