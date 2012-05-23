# encoding: UTF-8
module MongoMapper
  module Plugins
    module Modifiers
      extend ActiveSupport::Concern

      module ClassMethods
        def increment(*args)
          modifier_update('$inc', args)
        end

        def decrement(*args)
          criteria, keys, options = criteria_and_keys_from_args(args)
          values, to_decrement = keys.values, {}
          keys.keys.each_with_index { |k, i| to_decrement[k] = -values[i].abs }
          collection.update(criteria, {'$inc' => to_decrement}, :multi => true)
        end

        def set(*args)
          criteria, updates, options = criteria_and_keys_from_args(args)
          updates.each do |key, value|
            updates[key] = keys[key.to_s].set(value) if key?(key)
          end
          modifier_update('$set', [criteria, updates, options])
        end

        def unset(*args)
          if args[0].is_a?(Hash)
            criteria, keys = args.shift, args
            options = keys.last.is_a?(Hash) ? keys.pop : {}
          else
            keys, ids = args.partition { |arg| arg.is_a?(Symbol) }
            options = ids.last.is_a?(Hash) ? ids.pop : {}
            criteria = {:id => ids}
          end

          criteria = criteria_hash(criteria).to_hash
          updates = keys.inject({}) { |hash, key| hash[key] = 1; hash }
          modifier_update('$unset', [criteria, updates, options])
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
            criteria, updates, options = criteria_and_keys_from_args(args)
            if options
              collection.update(criteria, {modifier => updates}, options.merge(:multi => true))
            else
              collection.update(criteria, {modifier => updates}, :multi => true)
            end    
          end

          def criteria_and_keys_from_args(args)
            if args[0].is_a?(Hash)
              criteria = args[0]
              updates = args[1]
              options = args[2]
            else
              split_args = args.partition{|a| a.is_a?(BSON::ObjectId)}
              criteria = {:id => split_args[0]}
              updates = split_args[1].first
              options = split_args[1].last
            end    
            [criteria_hash(criteria).to_hash, updates, options]
          end
      end

      def unset(*args)
        self.class.unset(id, *args)
      end

      def increment(hash, options=nil)
        self.class.increment(id, hash, options)
      end

      def decrement(hash, options=nil)
        self.class.decrement(id, hash, options)
      end

      def set(hash, options=nil)
        self.class.set(id, hash, options)
      end

      def push(hash, options=nil)
        self.class.push(id, hash, options)
      end

      def push_all(hash, options=nil)
        self.class.push_all(id, hash, options)
      end

      def pull(hash, options=nil)
        self.class.pull(id, hash, options)
      end

      def pull_all(hash, options=nil)
        self.class.pull_all(id, hash, options)
      end

      def add_to_set(hash, options=nil)
        self.class.push_uniq(id, hash, options)
      end
      alias push_uniq add_to_set

      def pop(hash, options=nil)
        self.class.pop(id, hash, options)
      end
    end
  end
end