# encoding: UTF-8
module MongoMapper
  module Plugins
    module Userstamps
      module ClassMethods
        def userstamps!
          key :creator_id, ObjectId
          key :updater_id, ObjectId
          belongs_to :creator, :class_name => 'User'
          belongs_to :updater, :class_name => 'User'
        end
      end
    end
  end
end