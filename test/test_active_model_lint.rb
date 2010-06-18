require 'test_helper'
# For testing against edge rails also.
# $:.unshift '/Users/jnunemaker/dev/ruby/rails/activemodel/lib'
require 'active_model'
require 'models'

class ActiveModelLintTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  def setup
    @model = Post.new
  end
end