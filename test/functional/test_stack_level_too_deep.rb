require 'test_helper'
require 'models'

class StackLevelTooDeepTest < Test::Unit::TestCase
  def setup
    @klass = Doc('Person') do
      key :name, String
    end

    @pet_klass = EDoc('Pet') do
      key :name, String
    end

    @klass.many :pets, :class => @pet_klass

    @address_class = EDoc('Address') do
      key :city, String
      key :state, String
    end
    
    @pet_klass.many :addresses, :class => @address_class
    
  end


  should "be able to save many embedded documents" do
    setup
    person = @klass.create
    
    1000.times do
      pet = @pet_klass.new(:name => 'sparky')
      person.pets << pet
    end
    failed = false
    begin
      person.save
    rescue SystemStackError => e
      puts "SystemStackError........#{e.inspect}"
      failed = true
      #silently swallow up error...
    end
    person.reload
    person.should be_persisted
    person.pets.count.should == 1000
    person.pets.last.should_not be_new
  end

end