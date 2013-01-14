# encoding: UTF-8
module MongoMapper
  module Plugins
    module Callbacks
      extend ActiveSupport::Concern

      def destroy
        run_callbacks(:destroy) { super }
      end
      
      def touch(*)
        run_callbacks(:touch) { super }
      end

    private
      def create_or_update(*)
        run_callbacks(:save) { super }
      end

      def create(*)
        run_callbacks(:create) { super }
      end

      def update(*)
        run_callbacks(:update) { super }
      end
    end
  end
end
