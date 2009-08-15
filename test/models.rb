class Address
  include MongoMapper::EmbeddedDocument
  key :address, String
  key :city,    String
  key :state,   String
  key :zip,     Integer
end

class Message
  include MongoMapper::Document
  key :body, String
  key :item_order, Integer
  belongs_to :room
end

class Enter < Message; end
class Exit < Message;  end
class Chat < Message;  end

class Room
  include MongoMapper::Document
  key :name, String
  many :messages, :polymorphic => true
end

class Project
  include MongoMapper::Document
  key :name, String
  many :statuses
  many :addresses
end

class Status
  include MongoMapper::Document
  belongs_to :project
  belongs_to :target, :polymorphic => true
  key :name, String
  key :item_order, Integer
end

class RealPerson
  include MongoMapper::Document
  many :pets
  key :name, String

  def realname=(n)
    self.name = n
  end
end

class Person
  include MongoMapper::EmbeddedDocument
  key :name, String
  key :child, Person
  many :pets
end

class Pet
  include MongoMapper::EmbeddedDocument
  key :name, String
  key :species, String
end

class Media
  include MongoMapper::EmbeddedDocument
  key :file, String
end

class Video < Media
  key :length, Integer
end

class Image < Media
  key :width, Integer
  key :height, Integer
end

class Music < Media
  key :bitrate, String
end

class Catalog
  include MongoMapper::Document
  many :medias, :polymorphic => true
end

module TrModels
  class Transport
    include MongoMapper::EmbeddedDocument
    key :license_plate, String
  end

  class Car < TrModels::Transport
    include MongoMapper::EmbeddedDocument
    key :model, String
    key :year, Integer
  end

  class Bus < TrModels::Transport
    include MongoMapper::EmbeddedDocument
    key :max_passengers, Integer
  end

  class Ambulance < TrModels::Transport
    include MongoMapper::EmbeddedDocument
    key :icu, Boolean
  end

  class Fleet
    include MongoMapper::Document
    many :transports, :polymorphic => true, :class_name => "TrModels::Transport"
    key :name, String
  end
end
