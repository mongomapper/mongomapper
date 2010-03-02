require 'test_helper'
require 'active_model'
require 'models'

class ActiveModelLintTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests
  
  def setup
    @model = Post.new
  end
end