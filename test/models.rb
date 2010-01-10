# custom type
class WindowSize
  attr_reader :width, :height
  
  def self.to_mongo(value)
    value.to_a
  end
  
  def self.from_mongo(value)
    value.is_a?(self) ? value : WindowSize.new(value)
  end
  
  def initialize(*args)
    @width, @height = args.flatten
  end
  
  def to_a
    [width, height]
  end
  
  def ==(other)
    other.is_a?(self.class) && other.width == width && other.height == height
  end
end

module AccountsExtensions
  def inactive
    all(:last_logged_in => nil)
  end
end

class Post
  include MongoMapper::Document

  key :title, String
  key :body, String

  many :comments, :as => :commentable, :class_name => 'PostComment'

  timestamps!
end

class PostComment
  include MongoMapper::Document

  key :username, String, :default => 'Anonymous'
  key :body, String

  key :commentable_id, ObjectId
  key :commentable_type, String
  belongs_to :commentable, :polymorphic => true

  timestamps!
end

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
  key :position, Integer
  key :_type, String
  key :room_id, ObjectId

  belongs_to :room
end

class Enter < Message; end
class Exit < Message;  end
class Chat < Message;  end

class Room
  include MongoMapper::Document

  key :name, String
  many :messages, :polymorphic => true, :order => 'position' do
    def older
      all(:position => {'$gt' => 5})
    end
  end
  many :latest_messages, :class_name => 'Message', :order => 'position desc', :limit => 2
  
  many :accounts, :polymorphic => true, :extend => AccountsExtensions
end

class Account
  include MongoMapper::Document
  
  key :_type, String
  key :room_id, ObjectId
  key :last_logged_in, Time
  
  belongs_to :room
end
class AccountUser < Account; end
class Bot < Account; end

class Answer
  include MongoMapper::Document

  key :body, String
end

module CollaboratorsExtensions
  def top
    first
  end
end

class Project
  include MongoMapper::Document

  key :name, String
  
  many :collaborators, :extend => CollaboratorsExtensions
  many :statuses, :order => 'position' do
    def open
      all(:name => %w(New Assigned))
    end
  end
  
  many :addresses do
    def find_all_by_state(state)
      # can't use select here for some reason
      find_all { |a| a.state == state }
    end
  end
end

class Collaborator
  include MongoMapper::Document
  key :project_id, ObjectId
  key :name, String
  belongs_to :project
end

class Status
  include MongoMapper::Document

  key :project_id, ObjectId
  key :target_id, ObjectId
  key :target_type, String
  key :name, String, :required => true
  key :position, Integer

  belongs_to :project
  belongs_to :target, :polymorphic => true
end

class Media
  include MongoMapper::EmbeddedDocument

  key :_type, String
  key :file, String
  
  key :visible, Boolean
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
  
  many :medias, :polymorphic => true do
    def visible
      # for some reason we can't use select here
      find_all { |m| m.visible? }
    end
  end
end

module TrModels
  class Transport
    include MongoMapper::EmbeddedDocument

    key :_type, String
    key :license_plate, String
    key :purchased_on, Date
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

    module TransportsExtension
      def to_be_replaced
        # for some reason we can't use select
        find_all { |t| t.purchased_on < 2.years.ago.to_date }
      end
    end
    
    many :transports, :polymorphic => true, :class_name => "TrModels::Transport", :extend => TransportsExtension
    key :name, String
  end
end
