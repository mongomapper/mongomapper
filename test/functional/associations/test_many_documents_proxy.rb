require 'test_helper.rb'
require 'models'

class ManyDocumentsProxyTest < Test::Unit::TestCase
  def setup
    Project.collection.remove
    Status.collection.remove

    @pet_class = Doc do
      key :name, String
      key :owner_id, ObjectId
    end

    @owner_class = Doc do
      key :name, String
    end
    @owner_class.many :pets, :class => @pet_class, :foreign_key => :owner_id, :order => 'name'
  end

  should "default reader to empty array" do
    project = Project.new
    project.statuses.should == []
  end

  should "allow overriding association methods" do
    @owner_class.class_eval do
      def pets
        super
      end
    end

    instance = @owner_class.new
    instance.pets.should == []
    instance.pets.build
    instance.pets.should_not be_empty
  end

  should "allow assignment of many associated documents using a hash" do
    person_attributes = {
      'name' => 'Mr. Pet Lover',
      'pets' => [
        {'name' => 'Jimmy', 'species' => 'Cocker Spainel'},
        {'name' => 'Sasha', 'species' => 'Siberian Husky'},
      ]
    }

    owner = @owner_class.new(person_attributes)
    owner.name.should == 'Mr. Pet Lover'
    owner.pets[0].name.should == 'Jimmy'
    owner.pets[0].species.should == 'Cocker Spainel'
    owner.pets[1].name.should == 'Sasha'
    owner.pets[1].species.should == 'Siberian Husky'

    owner.save.should be_true
    owner.reload

    owner.name.should == 'Mr. Pet Lover'
    owner.pets[0].name.should == 'Jimmy'
    owner.pets[0].species.should == 'Cocker Spainel'
    owner.pets[1].name.should == 'Sasha'
    owner.pets[1].species.should == 'Siberian Husky'
  end

  should "allow adding to association like it was an array" do
    project = Project.new
    project.statuses <<     Status.new(:name => 'Foo1!')
    project.statuses.push   Status.new(:name => 'Foo2!')
    project.statuses.concat Status.new(:name => 'Foo3!')
    project.statuses.size.should == 3
  end

  context "replacing the association" do
    context "with objects of the class" do
      should "work" do
        project = Project.new
        project.statuses = [Status.new(:name => "ready")]
        project.save.should be_true

        project.reload
        project.statuses.size.should == 1
        project.statuses[0].name.should == "ready"
      end
    end

    context "with Hashes" do
      should "convert to objects of the class and work" do
        project = Project.new
        project.statuses = [{ 'name' => 'ready' }]
        project.save.should be_true

        project.reload
        project.statuses.size.should == 1
        project.statuses[0].name.should == "ready"
      end
    end
    
    context "with :dependent" do
      setup do
        @broker_class = Doc('Broker')
        @property_class = Doc('Property') do
          key :broker_id, ObjectId
          belongs_to :broker
        end
      end
      
      context "=> destroy" do
        setup do
          @broker_class.many :properties, :class => @property_class, :dependent => :destroy
    
          @broker = @broker_class.create(:name => "Bob")
          @property1 = @property_class.create
          @property2 = @property_class.create
          @property3 = @property_class.create
          @broker.properties << @property1
          @broker.properties << @property2
          @broker.properties << @property3
        end
            
        should "call destroy the existing documents" do
          @broker.properties[0].expects(:destroy).once
          @broker.properties[1].expects(:destroy).once
          @broker.properties[2].expects(:destroy).once
          @broker.properties = [@property_class.new]
        end
        
        should "remove the existing document from the database" do
          @property_class.count.should == 3
          @broker.properties = []
          @property_class.count.should == 0
        end
        
        should "skip over documents that are the same" do
          @broker.properties[0].expects(:destroy).never
          @broker.properties[1].expects(:destroy).once
          @broker.properties[2].expects(:destroy).never
          @broker.properties = [@property3, @property1]
        end
      end
      
      context "=> delete_all" do
        setup do
          @broker_class.many :properties, :class => @property_class, :dependent => :delete_all
    
          @broker = @broker_class.create(:name => "Bob")
          @property1 = @property_class.create
          @property2 = @property_class.create
          @property3 = @property_class.create
          @broker.properties << @property1
          @broker.properties << @property2
          @broker.properties << @property3
        end
            
        should "call delete the existing documents" do
          @broker.properties[0].expects(:delete).once
          @broker.properties[1].expects(:delete).once
          @broker.properties[2].expects(:delete).once
          @broker.properties = [@property_class.new]
        end
        
        should "remove the existing document from the database" do
          @property_class.count.should == 3
          @broker.properties = []
          @property_class.count.should == 0
        end
        
        should "skip over documents that are the same" do
          @broker.properties[0].expects(:delete).never
          @broker.properties[1].expects(:delete).once
          @broker.properties[2].expects(:delete).never
          @broker.properties = [@property3, @property1]
        end
      end
      
      context "=> nullify" do
        setup do
          @broker_class.many :properties, :class => @property_class, :dependent => :nullify
    
          @broker = @broker_class.create(:name => "Bob")
          @property1 = @property_class.create
          @property2 = @property_class.create
          @property3 = @property_class.create
          @broker.properties << @property1
          @broker.properties << @property2
          @broker.properties << @property3
        end
            
        should "nullify the existing documents" do
          @property1.reload.broker_id.should == @broker.id
          @property2.reload.broker_id.should == @broker.id
          @property3.reload.broker_id.should == @broker.id

          @broker.properties = [@property_class.new]
          
          @property1.reload.broker_id.should be_nil
          @property2.reload.broker_id.should be_nil
          @property3.reload.broker_id.should be_nil
        end
        
        should "skip over documents that are the same" do
          @broker.properties = [@property3, @property1]

          @property1.reload.broker_id.should == @broker.id
          @property2.reload.broker_id.should be_nil
          @property3.reload.broker_id.should == @broker.id
        end
        
        should "work" do
          old_properties = @broker.properties
          @broker.properties = [@property1, @property2, @property3]
          old_properties.should == @broker.properties
        end
      end
      
      context "unspecified" do
        should "nullify the existing documents" do
          @broker_class.many :properties, :class => @property_class
    
          @broker = @broker_class.create(:name => "Bob")
          @property1 = @property_class.create
          @property2 = @property_class.create
          @property3 = @property_class.create
          @broker.properties << @property1
          @broker.properties << @property2
          @broker.properties << @property3

          @broker.properties = [@property_class.new]
          
          @property1.reload.broker_id.should be_nil
          @property2.reload.broker_id.should be_nil
          @property3.reload.broker_id.should be_nil
        end
      end
    end
  end

  context "using <<, push and concat" do
    context "with objects of the class" do
      should "correctly assign foreign key" do
        project = Project.new
        project.statuses <<     Status.new(:name => '<<')
        project.statuses.push   Status.new(:name => 'push')
        project.statuses.concat Status.new(:name => 'concat')

        project.reload
        project.statuses[0].project_id.should == project.id
        project.statuses[1].project_id.should == project.id
        project.statuses[2].project_id.should == project.id
      end
    end

    context "with Hashes" do
      should "correctly convert to objects and assign foreign key" do
        project = Project.new
        project.statuses <<     { 'name' => '<<' }
        project.statuses.push(  { 'name' => 'push' })
        project.statuses.concat({ 'name' => 'concat' })

        project.reload
        project.statuses[0].project_id.should == project.id
        project.statuses[1].project_id.should == project.id
        project.statuses[2].project_id.should == project.id
      end
    end
  end

  context "build" do
    should "assign foreign key" do
      project = Project.create
      status = project.statuses.build
      status.project_id.should == project.id
    end

    should "allow assigning attributes" do
      project = Project.create
      status = project.statuses.build(:name => 'Foo')
      status.name.should == 'Foo'
    end

    should "reset cache" do
      project = Project.create
      project.statuses.size.should == 0
      status = project.statuses.build(:name => 'Foo')
      status.save!
      project.statuses.size.should == 1
    end

    should "update collection without save" do
      project = Project.create
      project.statuses.build(:name => 'Foo')
      project.statuses.size.should == 1
    end

    should "save built document when saving parent" do
      project = Project.create
      status = project.statuses.build(:name => 'Foo')
      project.save!
      status.should_not be_new
    end

    should "not save the parent when building associations" do
      project = Project.new
      status = project.statuses.build(:name => 'Foo')
      project.should be_new
    end

    should "not save the built object" do
      project = Project.new
      status = project.statuses.build(:name => 'Foo')
      status.should be_new
    end
  end

  context "create" do
    should "assign foreign key" do
      project = Project.create
      status = project.statuses.create(:name => 'Foo!')
      status.project_id.should == project.id
    end

    should "save record" do
      project = Project.create
      lambda {
        project.statuses.create(:name => 'Foo!')
      }.should change { Status.count }
    end

    should "allow passing attributes" do
      project = Project.create
      status = project.statuses.create(:name => 'Foo!')
      status.name.should == 'Foo!'
    end

    should "reset cache" do
      project = Project.create
      project.statuses.size.should == 0
      project.statuses.create(:name => 'Foo!')
      project.statuses.size.should == 1
    end
  end

  context "create!" do
    should "assign foreign key" do
      project = Project.create
      status = project.statuses.create!(:name => 'Foo!')
      status.project_id.should == project.id
    end

    should "save record" do
      project = Project.create
      lambda {
        project.statuses.create!(:name => 'Foo!')
      }.should change { Status.count }
    end

    should "allow passing attributes" do
      project = Project.create
      status = project.statuses.create!(:name => 'Foo!')
      status.name.should == 'Foo!'
    end

    should "raise exception if not valid" do
      project = Project.create
      lambda {
        project.statuses.create!(:name => nil)
      }.should raise_error(MongoMapper::DocumentNotValid)
    end

    should "reset cache" do
      project = Project.create
      project.statuses.size.should == 0
      project.statuses.create!(:name => 'Foo!')
      project.statuses.size.should == 1
    end
  end

  context "count" do
    should "work scoped to association" do
      project = Project.create
      3.times { project.statuses.create(:name => 'Foo!') }

      other_project = Project.create
      2.times { other_project.statuses.create(:name => 'Foo!') }

      project.statuses.count.should == 3
      other_project.statuses.count.should == 2
    end

    should "work with conditions" do
      project = Project.create
      project.statuses.create(:name => 'Foo')
      project.statuses.create(:name => 'Other 1')
      project.statuses.create(:name => 'Other 2')

      project.statuses.count(:name => 'Foo').should == 1
    end

    should "ignore unpersisted documents" do
      project = Project.create
      project.statuses.build(:name => 'Foo')
      project.statuses.count.should == 0
    end
  end

  context "size" do
    should "reflect both persisted and new documents" do
      project = Project.create
      3.times { project.statuses.create(:name => 'Foo!') }
      2.times { project.statuses.build(:name => 'Foo!') }
      project.statuses.size.should == 5
    end
  end

  context "empty?" do
    should "be true with no associated docs" do
      project = Project.create
      project.statuses.empty?.should be_true
    end

    should "be false if a document is built" do
      project = Project.create
      project.statuses.build(:name => 'Foo!')
      project.statuses.empty?.should be_false
    end

    should "be false if a document is created" do
      project = Project.create
      project.statuses.create(:name => 'Foo!')
      project.statuses.empty?.should be_false
    end
  end

  context "to_a" do
    should "include persisted and new documents" do
      project = Project.create
      3.times { project.statuses.create(:name => 'Foo!') }
      2.times { project.statuses.build(:name => 'Foo!') }
      project.statuses.to_a.size.should == 5
    end
  end

  context "to_json" do
    should "work on association" do
      project = Project.create
      3.times { |i| project.statuses.create(:name => i.to_s) }

      JSON.parse(project.statuses.to_json).collect{|status| status["name"] }.sort.should == ["0","1","2"]
    end
  end

  context "as_json" do
    should "work on association" do
      project = Project.create
      3.times { |i| project.statuses.create(:name => i.to_s) }

      project.statuses.as_json.collect{|status| status["name"] }.sort.should == ["0","1","2"]
    end
  end

  context "Unassociating documents" do
    setup do
      @project = Project.create
      @project.statuses << Status.create(:name => '1')
      @project.statuses << Status.create(:name => '2')

      @project2 = Project.create
      @project2.statuses << Status.create(:name => '1')
      @project2.statuses << Status.create(:name => '2')
    end

    should "work with destroy all" do
      @project.statuses.count.should == 2
      @project.statuses.destroy_all
      @project.statuses.count.should == 0

      @project2.statuses.count.should == 2
      Status.count.should == 2
    end

    should "work with destroy all and conditions" do
      @project.statuses.count.should == 2
      @project.statuses.destroy_all(:name => '1')
      @project.statuses.count.should == 1

      @project2.statuses.count.should == 2
      Status.count.should == 3
    end

    should "work with delete all" do
      @project.statuses.count.should == 2
      @project.statuses.delete_all
      @project.statuses.count.should == 0

      @project2.statuses.count.should == 2
      Status.count.should == 2
    end

    should "work with delete all and conditions" do
      @project.statuses.count.should == 2
      @project.statuses.delete_all(:name => '1')
      @project.statuses.count.should == 1

      @project2.statuses.count.should == 2
      Status.count.should == 3
    end

    should "work with nullify" do
      @project.statuses.count.should == 2
      @project.statuses.nullify
      @project.statuses.count.should == 0

      @project2.statuses.count.should == 2
      Status.count.should == 4
      Status.count(:name => '1').should == 2
      Status.count(:name => '2').should == 2
    end
  end

  context "Finding scoped to association" do
    setup do
      @project1          = Project.new(:name => 'Project 1')
      @brand_new         = Status.create(:name => 'New', :position => 1 )
      @complete          = Status.create(:name => 'Complete', :position => 2)
      @project1.statuses = [@brand_new, @complete]
      @project1.save

      @project2          = Project.create(:name => 'Project 2')
      @in_progress       = Status.create(:name => 'In Progress')
      @archived          = Status.create(:name => 'Archived')
      @another_complete  = Status.create(:name => 'Complete')
      @project2.statuses = [@in_progress, @archived, @another_complete]
      @project2.save
    end

    context "include?" do
      should "return true if in association" do
        @project1.statuses.should include(@brand_new)
      end

      should "return false if not in association" do
        @project1.statuses.should_not include(@in_progress)
      end
    end

    context "dynamic finders" do
      should "work with single key" do
        @project1.statuses.find_by_name('New').should == @brand_new
        @project1.statuses.find_by_name!('New').should == @brand_new
        @project2.statuses.find_by_name('In Progress').should == @in_progress
        @project2.statuses.find_by_name!('In Progress').should == @in_progress
      end

      should "work with multiple keys" do
        @project1.statuses.find_by_name_and_position('New', 1).should == @brand_new
        @project1.statuses.find_by_name_and_position!('New', 1).should == @brand_new
        @project1.statuses.find_by_name_and_position('New', 2).should be_nil
      end

      should "raise error when using !" do
        lambda {
          @project1.statuses.find_by_name!('Fake')
        }.should raise_error(MongoMapper::DocumentNotFound)
      end

      context "find_or_create_by" do
        should "not create document if found" do
          lambda {
            status = @project1.statuses.find_or_create_by_name('New')
            status.project.should == @project1
            status.should == @brand_new
          }.should_not change { Status.count }
        end

        should "create document if not found" do
          lambda {
            status = @project1.statuses.find_or_create_by_name('Delivered')
            status.project.should == @project1
          }.should change { Status.count }
        end
      end
    end

    context "sexy querying" do
      should "work with where" do
        @project1.statuses.where(:name => 'New').all.should == [@brand_new]
      end

      should "work with sort" do
        @project1.statuses.sort(:name).all.should == [@complete, @brand_new]
      end

      should "work with limit" do
        @project1.statuses.sort(:name).limit(1).all.should == [@complete]
      end

      should "work with skip" do
        @project1.statuses.sort(:name).skip(1).all.should == [@brand_new]
      end

      should "work with fields" do
        @project1.statuses.fields(:position).all.each do |status|
          status.position.should_not be_nil
          status.name.should be_nil
        end
      end

      should "work with scopes" do
        @project1.statuses.complete.all.should == [@complete]
      end

      should "work with methods on class that return query" do
        @project1.statuses.by_position(1).first.should == @brand_new
      end

      should "not work with methods on class that do not return query" do
        Status.class_eval { def self.foo; 'foo' end }
        lambda { @project1.statuses.foo }.
          should raise_error(NoMethodError)
      end
    end

    context "all" do
      should "work" do
        @project1.statuses.all(:order => "position asc").should == [@brand_new, @complete]
      end

      should "work with conditions" do
        @project1.statuses.all(:name => 'Complete').should == [@complete]
      end
    end

    context "first" do
      should "work" do
        @project1.statuses.first(:order => 'name').should == @complete
      end

      should "work with conditions" do
        @project1.statuses.first(:name => 'Complete').should == @complete
      end
    end

    context "last" do
      should "work" do
        @project1.statuses.last(:order => "position asc").should == @complete
      end

      should "work with conditions" do
        @project1.statuses.last(:order => 'position', :name => 'New').should == @brand_new
      end
    end

    context "with one id" do
      should "work for id in association" do
        @project1.statuses.find(@complete.id).should == @complete
      end

      should "not work for id not in association" do
        lambda {
          @project1.statuses.find!(@archived.id)
        }.should raise_error(MongoMapper::DocumentNotFound)
      end
    end

    context "with multiple ids" do
      should "work for ids in association" do
        statuses = @project1.statuses.find(@brand_new.id, @complete.id)
        statuses.should == [@brand_new, @complete]
      end

      should "not work for ids not in association" do
        assert_raises(MongoMapper::DocumentNotFound) do
          @project1.statuses.find!(@brand_new.id, @complete.id, @archived.id)
        end
      end
    end

    context "with #paginate" do
      setup do
        @statuses = @project2.statuses.paginate(:per_page => 2, :page => 1, :order => 'name asc')
      end

      should "return total pages" do
        @statuses.total_pages.should == 2
      end

      should "return total entries" do
        @statuses.total_entries.should == 3
      end

      should "return the subject" do
        @statuses.collect(&:name).should == %w(Archived Complete)
      end
    end
  end

  context "extending the association" do
    should "work using a block passed to many" do
      project = Project.new(:name => "Some Project")
      status1 = Status.new(:name => "New")
      status2 = Status.new(:name => "Assigned")
      status3 = Status.new(:name => "Closed")
      project.statuses = [status1, status2, status3]
      project.save

      open_statuses = project.statuses.open
      open_statuses.should include(status1)
      open_statuses.should include(status2)
      open_statuses.should_not include(status3)
    end

    should "work using many's :extend option" do
      project = Project.new(:name => "Some Project")
      collaborator1 = Collaborator.new(:name => "zing")
      collaborator2 = Collaborator.new(:name => "zang")
      project.collaborators = [collaborator1, collaborator2]
      project.save
      project.collaborators.top.should == collaborator1
    end
  end

  context ":dependent" do
    setup do
      # FIXME: make use of already defined models
      class ::Property
        include MongoMapper::Document
      end
      Property.collection.remove

      class ::Thing
        include MongoMapper::Document
        key :name, String
      end
      Thing.collection.remove
    end

    teardown do
      Object.send :remove_const, 'Property' if defined?(::Property)
      Object.send :remove_const, 'Thing' if defined?(::Thing)
    end

    context "=> destroy" do
      setup do
        Property.key :thing_id, ObjectId
        Property.belongs_to :thing, :dependent => :destroy
        Thing.many :properties, :dependent => :destroy

        @thing = Thing.create(:name => "Tree")
        @property1 = Property.create
        @property2 = Property.create
        @property3 = Property.create
        @thing.properties << @property1
        @thing.properties << @property2
        @thing.properties << @property3
      end

      should "should destroy the associated documents" do
        @thing.properties.count.should == 3
        @thing.destroy
        @thing.properties.count.should == 0
        Property.count.should == 0
      end
    end

    context "=> delete_all" do
      setup do
        Property.key :thing_id, ObjectId
        Property.belongs_to :thing
        Thing.has_many :properties, :dependent => :delete_all

        @thing = Thing.create(:name => "Tree")
        @property1 = Property.create
        @property2 = Property.create
        @property3 = Property.create
        @thing.properties << @property1
        @thing.properties << @property2
        @thing.properties << @property3
      end

      should "should delete associated documents" do
        @thing.properties.count.should == 3
        @thing.destroy
        @thing.properties.count.should == 0
        Property.count.should == 0
      end
    end

    context "=> nullify" do
      setup do
        Property.key :thing_id, ObjectId
        Property.belongs_to :thing
        Thing.has_many :properties, :dependent => :nullify

        @thing = Thing.create(:name => "Tree")
        @property1 = Property.create
        @property2 = Property.create
        @property3 = Property.create
        @thing.properties << @property1
        @thing.properties << @property2
        @thing.properties << @property3
      end

      should "should nullify relationship but not destroy associated documents" do
        @thing.properties.count.should == 3
        @thing.destroy
        @thing.properties.count.should == 0
        Property.count.should == 3
      end
    end
    
    context "unspecified" do
      setup do
        Property.key :thing_id, ObjectId
        Property.belongs_to :thing
        Thing.has_many :properties, :dependent => :nullify

        @thing = Thing.create(:name => "Tree")
        @property1 = Property.create
        @property2 = Property.create
        @property3 = Property.create
        @thing.properties << @property1
        @thing.properties << @property2
        @thing.properties << @property3
      end

      should "should nullify relationship but not destroy associated documents" do
        @thing.properties.count.should == 3
        @thing.destroy
        @thing.properties.count.should == 0
        Property.count.should == 3
      end
    end
  end

  context "namespaced foreign keys" do
    setup do
      News::Paper.many :articles, :class_name => 'News::Article'
      News::Article.belongs_to :paper, :class_name => 'News::Paper'

      @paper = News::Paper.create
    end

    should "properly infer the foreign key" do
      article = @paper.articles.create
      article.should respond_to(:paper_id)
      article.paper_id.should == @paper.id
    end
  end

  context "criteria" do
    setup do
      News::Paper.many :articles, :class_name => 'News::Article'
      News::Article.belongs_to :paper, :class_name => 'News::Paper'

      @paper = News::Paper.create
    end

    should "should find associated instances by an object ID" do
      article = News::Article.create(:paper_id => @paper.id)
      @paper.articles.should include(article)
    end

    should "should find associated instances by a string" do
      article = News::Article.create(:paper_id => @paper.id.to_s)
      @paper.articles.should include(article)
    end
  end
end
