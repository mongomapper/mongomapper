# encoding: UTF-8
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
          criteria, updates = criteria_and_keys_from_args(args)
          updates.each do |key, value|
            updates[key] = keys[key].set(value) if key?(key)
          end
          collection.update(criteria, {'$set' => updates}, :multi => true)
        end

        def unset(*args)
          if args[0].is_a?(Hash)
            criteria, keys = args.shift, args
          else
            keys, ids = args.partition { |arg| arg.is_a?(Symbol) }
            criteria = {:id => ids}
          end

          criteria  = criteria_hash(criteria).to_hash
          modifiers = keys.inject({}) { |hash, key| hash[key] = 1; hash }
          collection.update(criteria, {'$unset' => modifiers}, :multi => true)
        end

        def push(*args)
          modifier_update('$push', args)
        end

        def push_all(*args)
          modifier_update('$pushAll', args)
        end

        def add_to_set(*args)
          modifier_update('$addToSet', args)
        end
        alias push_uniq add_to_set

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
            criteria, updates = criteria_and_keys_from_args(args)
            collection.update(criteria, {modifier => updates}, :multi => true)
          end

          def criteria_and_keys_from_args(args)
            keys     = args.pop
            criteria = args[0].is_a?(Hash) ? args[0] : {:id => args}
            [criteria_hash(criteria).to_hash, keys]
          end
      end

      module InstanceMethods
        def unset(*keys)
          self.class.unset(id, *keys)
        end

        def increment(hash)
          self.class.increment(id, hash)
        end

        def decrement(hash)
          self.class.decrement(id, hash)
        end

        def set(hash)
          self.class.set(id, hash)
        end

        def push(hash)
          self.class.push(id, hash)
        end

        def pull(hash)
          self.class.pull(id, hash)
        end

        def add_to_set(hash)
          self.class.push_uniq(id, hash)
        end
        alias push_uniq add_to_set

        def pop(hash)
          self.class.pop(id, hash)
        end
      end
    end
  end
end