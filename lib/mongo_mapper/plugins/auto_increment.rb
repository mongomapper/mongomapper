# encoding: UTF-8
# @pablocantero
module MongoMapper
  module Plugins
    # Based on http://ihswebdesign.com/blog/autoincrement-in-mongodb-with-ruby/
    module AutoIncrement
      module ClassMethods
        def auto_increment!
          # rewrite "model.key :_id, ObjectId" from plugins/keys.rb
          key :_id, Integer
          class_eval { before_create class_eval { :update_auto_increment }}
        end
      end
      module InstanceMethods
        private
        def update_auto_increment
          self._id = MongoMapper::Plugins::AutoIncrement::Incrementor[self.class.name].inc
        end
      end
      class Incrementor
        class Sequence
          def initialize(sequence)
            @sequence = sequence.to_s
            exists? || create
          end
          def exists?
            collection.find(query).count > 0
          end
          def db
            MongoMapper.database # replace this if you're not using MongoMapper
          end
          def query
            { "seq_name" => @sequence }
          end
          def collection
            db['sequences']
          end
          def current
            collection.find_one(query)["number"]
          end
          def inc
            update_number_with("$inc" => { "number" => 1 })
          end
          def create(number = 0)
            collection.insert(query.merge({ "number" => number }))
          end
          def set(number)
            update_number_with("$set" => { "number" => number })
          end
          def update_number_with(mongo_func)
            opts = {
              "query"  => query,
              "update" => mongo_func,
              "new"    => true # return the modified document
            }
            collection.find_and_modify(opts)["number"]
          end
        end
        class << self
          def [](sequence)
            Sequence.new(sequence)
          end
          def []=(sequence, number)
            Sequence.new(sequence).set(number)
          end
        end
      end
    end
  end
end