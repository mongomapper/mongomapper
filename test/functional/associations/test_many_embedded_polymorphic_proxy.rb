require 'test_helper'
require 'models'

class ManyEmbeddedPolymorphicProxyTest < Test::Unit::TestCase
  def setup
    Catalog.collection.remove
    TrModels::Fleet.collection.remove
  end
  
  should "default reader to empty array" do
    catalog = Catalog.new
    catalog.medias.should == []
  end

  should "allow adding to association like it was an array" do
    catalog = Catalog.new
    catalog.medias << Video.new
    catalog.medias.push Video.new
    catalog.medias.size.should == 2
  end

  should "be able to replace the association" do
    catalog = Catalog.new
    catalog.medias = [Video.new('file' => 'video.mpg', 'length' => 3600)]
    catalog.save.should be_true

    catalog = catalog.reload
    catalog.medias.size.should == 1
    catalog.medias[0].file.should == 'video.mpg'
    catalog.medias[0].new?.should == false
  end
  
  context "count" do
    should "default to 0" do
      Catalog.new.medias.count.should == 0
    end
    
    should 'return correct count if any are embedded' do
      catalog = Catalog.new
      catalog.medias = [
        Video.new('file' => 'video.mpg', 'length' => 3600),
        Music.new('file' => 'music.mp3', 'bitrate' => '128kbps'),
        Image.new('file' => 'image.png', 'width' => 800, 'height' => 600)
      ]
      catalog.medias.count.should == 3
      catalog.save.should be_true
      catalog.reload
      catalog.medias.count.should == 3
    end
  end
  
  should "store different associations" do      
    catalog = Catalog.new
    catalog.medias = [
      Video.new('file' => 'video.mpg', 'length' => 3600),
      Music.new('file' => 'music.mp3', 'bitrate' => '128kbps'),
      Image.new('file' => 'image.png', 'width' => 800, 'height' => 600)
    ]
    catalog.save.should be_true
    
    catalog = catalog.reload
    catalog.medias.size.should == 3
    catalog.medias[0].file.should == 'video.mpg'
    catalog.medias[0].length.should == 3600
    catalog.medias[1].file.should == 'music.mp3'
    catalog.medias[1].bitrate.should == "128kbps"
    catalog.medias[2].file.should == 'image.png'
    catalog.medias[2].width.should == 800
    catalog.medias[2].height.should == 600
  end
  
  context "With modularized models" do
    should "set associations correctly" do
      fleet_attributes = { 
        'name' => 'My Fleet', 
        'transports' => [
          {'_type' => 'TrModels::Ambulance', 'license_plate' => 'GGG123', 'icu' => true},
          {'_type' => 'TrModels::Car', 'license_plate' => 'ABC123', 'model' => 'VW Golf', 'year' => 2001}, 
          {'_type' => 'TrModels::Car', 'license_plate' => 'DEF123', 'model' => 'Honda Accord', 'year' => 2008},
        ] 
      }
      
      fleet = TrModels::Fleet.new(fleet_attributes)
      fleet.transports.size.should == 3
      fleet.transports[0].class.should == TrModels::Ambulance
      fleet.transports[0].license_plate.should == 'GGG123'
      fleet.transports[0].icu.should be_true
      fleet.transports[1].class.should == TrModels::Car
      fleet.transports[1].license_plate.should == 'ABC123'
      fleet.transports[1].model.should == 'VW Golf'
      fleet.transports[1].year.should == 2001
      fleet.transports[2].class.should == TrModels::Car
      fleet.transports[2].license_plate.should == 'DEF123'
      fleet.transports[2].model.should == 'Honda Accord'
      fleet.transports[2].year.should == 2008      
      fleet.save.should be_true
      
      fleet = fleet.reload
      fleet.transports.size.should == 3
      fleet.transports[0].license_plate.should == 'GGG123'
      fleet.transports[0].icu.should be_true
      fleet.transports[1].license_plate.should == 'ABC123'
      fleet.transports[1].model.should == 'VW Golf'
      fleet.transports[1].year.should == 2001
      fleet.transports[2].license_plate.should == 'DEF123'
      fleet.transports[2].model.should == 'Honda Accord'
      fleet.transports[2].year.should == 2008      
    end
    
    should "default reader to empty array" do
      fleet = TrModels::Fleet.new
      fleet.transports.should == []
    end
    
    should "allow adding to association like it was an array" do
      fleet = TrModels::Fleet.new
      fleet.transports << TrModels::Car.new
      fleet.transports.push TrModels::Bus.new
      fleet.transports.size.should == 2
    end
    
    should "be able to replace the association" do
      fleet = TrModels::Fleet.new
      fleet.transports = [TrModels::Car.new('license_plate' => 'DCU2013', 'model' => 'Honda Civic')]
      fleet.save.should be_true
    
      fleet = fleet.reload
      fleet.transports.size.should == 1
      fleet.transports[0].license_plate.should == 'DCU2013'
    end
    
    should "store different associations" do
      fleet = TrModels::Fleet.new
      fleet.transports = [
        TrModels::Car.new('license_plate' => 'ABC1223', 'model' => 'Honda Civic', 'year' => 2003),
        TrModels::Bus.new('license_plate' => 'XYZ9090', 'max_passengers' => 51),
        TrModels::Ambulance.new('license_plate' => 'HDD3030', 'icu' => true)
      ]
      fleet.save.should be_true
    
      fleet = fleet.reload
      fleet.transports.size.should == 3
      fleet.transports[0].license_plate.should == 'ABC1223'
      fleet.transports[0].model.should == 'Honda Civic'
      fleet.transports[0].year.should == 2003
      fleet.transports[1].license_plate.should == 'XYZ9090'
      fleet.transports[1].max_passengers.should == 51
      fleet.transports[2].license_plate.should == 'HDD3030'
      fleet.transports[2].icu.should == true
    end
  end

  context "extending the association" do
    should "work using a block passed to many" do
      catalog = Catalog.new
      medias = catalog.medias = [
        Video.new('file' => 'video.mpg', 'length' => 3600, :visible => true),
        Music.new('file' => 'music.mp3', 'bitrate' => '128kbps', :visible => true),
        Image.new('file' => 'image.png', 'width' => 800, 'height' => 600, :visible => false)
      ]
      catalog.save
      catalog.medias.visible.should == [medias[0], medias[1]]
    end
  
    should "work using many's :extend option" do
      fleet = TrModels::Fleet.new
      transports = fleet.transports = [
        TrModels::Car.new('license_plate' => 'ABC1223', 'model' => 'Honda Civic', 'year' => 2003, :purchased_on => 2.years.ago.to_date),
        TrModels::Bus.new('license_plate' => 'XYZ9090', 'max_passengers' => 51, :purchased_on => 3.years.ago.to_date),
        TrModels::Ambulance.new('license_plate' => 'HDD3030', 'icu' => true, :purchased_on => 1.year.ago.to_date)
      ]
      fleet.save
      fleet.transports.to_be_replaced.should == [transports[1]]
    end
  end
end
