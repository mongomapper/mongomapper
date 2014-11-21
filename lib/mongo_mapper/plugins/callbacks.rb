# encoding: UTF-8
module MongoMapper
  module Plugins
    module Callbacks
      extend ActiveSupport::Concern

      def initialize(*)
        run_callbacks(:initialize) { super }
      end

      def initialize_from_database(*)
        run_callbacks(:initialize) do
          run_callbacks(:find) do
            super
          end
        end
      end

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
