# encoding: UTF-8
module MongoMapper
  module Translation
    include ActiveModel::Translation

    def i18n_scope
      :mongo_mapper
    end
  end
end