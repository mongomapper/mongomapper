# encoding: UTF-8
module MongoMapper
  module Plugins
    module Userstamps
      extend ActiveSupport::Concern

      module ClassMethods
        def userstamps!(class_name = 'User')
          key :creator_id, ObjectId
          key :updater_id, ObjectId
          belongs_to :creator, :class_name => class_name
          belongs_to :updater, :class_name => class_name
        end
        def userstamps_for!(class_name = 'User')
          userstamps!(class_name)
        end
      end
    end
  end
end