require 'spec_helper'
require "rails"
require 'mongo_mapper/railtie'

describe MongoMapper::Railtie do

  def expect_descendants(expectation)
    # Keep expectation a string so we don't accidentally load in a class
    Railtie::Parent.descendants.map(&:to_s).sort.should == expectation.sort
  end

  def run_initializer(mod, name)
    initializer = mod.initializers.detect do |i|
      i.name == name
    end
    initializer.block.arity == -1 ? initializer.run : initializer.run(FakeRails)
    # mongo_mapper.prepare_dispatcher takes a Rails app as its one arg,
    # set_clear_dependencies_hook takes no args
  end

  def load_autoloaded_class
    Railtie::Autoloaded.presence
  end

  class FakeRails
    def self.config
      return Class.new { def cache_classes ; false ; end }.new
    end
  end

  include Rails::Application::Bootstrap

  before do
    require 'fixtures/railtie'
    require 'fixtures/railtie/parent'
    require 'fixtures/railtie/not_autoloaded'

    ActiveSupport::Dependencies.autoload_paths << File.join(File.dirname(__FILE__), '..', 'fixtures')

    # These initializers don't actually run anything, they just register cleanup and prepare hooks
    run_initializer Rails::Application::Bootstrap, :set_clear_dependencies_hook
    run_initializer MongoMapper::Railtie, 'mongo_mapper.prepare_dispatcher'
  end

  it "should not clear ActiveSupport::DescendantsTracker" do
    expect_descendants %w( Railtie::NotAutoloaded )
    load_autoloaded_class
    expect_descendants %w( Railtie::NotAutoloaded Railtie::Autoloaded )

    ActionDispatch::Reloader.cleanup! # cleanup 'last request'

    expect_descendants %w( Railtie::NotAutoloaded )
    load_autoloaded_class
    expect_descendants %w( Railtie::NotAutoloaded Railtie::Autoloaded )

    ActionDispatch::Reloader.prepare! # prepare 'next request'
    expect_descendants %w( Railtie::NotAutoloaded Railtie::Autoloaded )
  end
end
