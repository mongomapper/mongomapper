require 'spec_helper'

describe "Strong parameters" do
  context 'A document with strong parameters protection' do
    if ::ActiveModel.const_defined?(:ForbiddenAttributesProtection)
      require "action_controller/metal/strong_parameters"

      before do
        @doc_class = Doc do
          plugin MongoMapper::Plugins::StrongParameters

          key :name, String
          key :admin, Boolean, :default => false
        end

        @doc = @doc_class.create(:name => 'Steve Sloan')
      end

      let(:params) {
        {name: "Permitted", admin: true}
      }

      let(:strong_params) {
        ActionController::Parameters.new params
      }

      it "allows assignment of attribute hashes" do
        @doc.attributes = params
        @doc.name.should =="Permitted"
      end

      it "doesn't allow mass assignment of ActionController::Parameters" do
        lambda {
          @doc.attributes = strong_params
        }.should raise_error(ActiveModel::ForbiddenAttributesError)
      end

      it "does not allow mass assignment of non-permitted attributes" do
        @doc.attributes = strong_params.permit(:name)
        @doc.admin.should == false
      end

      it "allows mass assignment of permitted attributes" do
        @doc.attributes = strong_params.permit(:name)
        @doc.name.should == "Permitted"
      end
    end
  end
end
