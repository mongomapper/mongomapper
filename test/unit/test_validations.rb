require 'test_helper'

class ValidationsTest < Test::Unit::TestCase
  context "Validations" do
    context "on a Document" do
      setup do
        @document = Doc('John')
      end

      context "Validating acceptance of" do
        should "work with validates_acceptance_of macro" do
          @document.key :terms, String
          @document.validates_acceptance_of :terms
          doc = @document.new(:terms => '')
          doc.should have_error_on(:terms)
          doc.terms = '1'
          doc.should_not have_error_on(:terms)
        end
      end
    
      context "validating confirmation of" do
        should "work with validates_confirmation_of macro" do
          @document.key :password, String
          @document.validates_confirmation_of :password
          
          # NOTE: Api change as ActiveModel passes if password_confirmation is nil
          doc = @document.new
          doc.password = 'foobar'
          doc.password_confirmation = 'foobar1'
          doc.should have_error_on(:password)
          
          doc.password_confirmation = 'foobar'
          doc.should_not have_error_on(:password)
        end
      end
    
      context "validating format of" do
        should "work with validates_format_of macro" do
          @document.key :name, String
          @document.validates_format_of :name, :with => /.+/
          doc = @document.new
          doc.should have_error_on(:name)
          doc.name = 'John'
          doc.should_not have_error_on(:name)
        end
    
        should "work with :format shorcut key" do
          @document.key :name, String, :format => /.+/
          doc = @document.new
          doc.should have_error_on(:name)
          doc.name = 'John'
          doc.should_not have_error_on(:name)
        end
      end
    
      context "validating length of" do
        should "work with validates_length_of macro" do
          @document.key :name, String
          @document.validates_length_of :name, :minimum => 5
          doc = @document.new
          doc.should have_error_on(:name)
        end
    
        context "with :length => integer shortcut" do
          should "set maximum of integer provided" do
            @document.key :name, String, :length => 5
            doc = @document.new
            doc.name = '123456'
            doc.should have_error_on(:name)
            doc.name = '12345'
            doc.should_not have_error_on(:name)
          end
        end
    
        context "with :length => range shortcut" do
          setup do
            @document.key :name, String, :length => 5..7
          end
    
          should "set minimum of range min" do
            doc = @document.new
            doc.should have_error_on(:name)
            doc.name = '123456'
            doc.should_not have_error_on(:name)
          end
    
          should "set maximum of range max" do
            doc = @document.new
            doc.should have_error_on(:name)
            doc.name = '12345678'
            doc.should have_error_on(:name)
            doc.name = '123456'
            doc.should_not have_error_on(:name)
          end
        end
    
        context "with :length => hash shortcut" do
          should "pass options through" do
            @document.key :name, String, :length => {:minimum => 2}
            doc = @document.new
            doc.should have_error_on(:name)
            doc.name = '12'
            doc.should_not have_error_on(:name)
          end
        end
      end # validates_length_of
    
      context "Validating numericality of" do
        should "work with validates_numericality_of macro" do
          @document.key :age, Integer
          @document.validates_numericality_of :age
          doc = @document.new
          doc.age = 'String'
          doc.should have_error_on(:age)
          doc.age = 23
          doc.should_not have_error_on(:age)
        end
    
        context "with :numeric shortcut" do
          should "work with integer or float" do
            @document.key :weight, Float, :numeric => true
            doc = @document.new
            doc.weight = 'String'
            doc.should have_error_on(:weight)
            doc.weight = 23.0
            doc.should_not have_error_on(:weight)
            doc.weight = 23
            doc.should_not have_error_on(:weight)
          end
        end
    
        context "with :numeric shortcut on Integer key" do
          should "only work with integers" do
            @document.key :age, Integer, :numeric => true
            doc = @document.new
            doc.age = 'String'
            doc.should have_error_on(:age)
            doc.age = 23.1
            doc.should have_error_on(:age)
            doc.age = 23
            doc.should_not have_error_on(:age)
          end
        end
      end # numericality of
    
      context "validating presence of" do
           should "work with validates_presence_of macro" do
             @document.key :name, String
             @document.validates_presence_of :name
             doc = @document.new
             doc.should have_error_on(:name)
           end
       
           should "work with :required shortcut on key definition" do
             @document.key :name, String, :required => true
             doc = @document.new
             doc.should have_error_on(:name)
           end
         end

      context "validating exclusion of" do
        should "throw error if enumerator not provided" do
          @document.key :action, String
          lambda {
            @document.validates_exclusion_of :action
          }.should raise_error(ArgumentError)
        end
    
        should "work with validates_exclusion_of macro" do
          @document.key :action, String
          @document.validates_exclusion_of :action, :in => %w(kick run)
    
          doc = @document.new
          doc.should_not have_error_on(:action)
    
          doc.action = 'fart'
          doc.should_not have_error_on(:action)
    
          doc.action = 'kick'
          doc.should have_error_on(:action, 'is reserved')
        end

        should "work with :not_in shortcut on key definition" do
          @document.key :action, String, :not_in => %w(kick run)
    
          doc = @document.new
          doc.should_not have_error_on(:action)
    
          doc.action = 'fart'
          doc.should_not have_error_on(:action)
    
          doc.action = 'kick'
          doc.should have_error_on(:action, 'is reserved')
        end
    
        should "not have error if allow nil is true and value is nil" do
          @document.key :action, String
          @document.validates_exclusion_of :action, :in => %w(kick run), :allow_nil => true
    
          doc = @document.new
          doc.should_not have_error_on(:action)
        end
    
        should "not have error if allow blank is true and value is blank" do
          @document.key :action, String
          @document.validates_exclusion_of :action, :in => %w(kick run), :allow_nil => true
    
          doc = @document.new(:action => '')
          doc.should_not have_error_on(:action)
        end
      end
    
      context "validating inclusion of" do
        should "throw error if enumerator not provided" do
          @document.key :action, String
          lambda {
            @document.validates_inclusion_of :action
          }.should raise_error(ArgumentError)
        end
    
        should "work with validates_inclusion_of macro" do
          @document.key :action, String
          @document.validates_inclusion_of :action, :in => %w(kick run)
    
          doc = @document.new
          doc.should have_error_on(:action, 'is not included in the list')
    
          doc.action = 'fart'
          doc.should have_error_on(:action, 'is not included in the list')
    
          doc.action = 'kick'
          doc.should_not have_error_on(:action)
        end
    
        should "work with :in shortcut on key definition" do
          @document.key :action, String, :in => %w(kick run)
            
          doc = @document.new
          doc.should have_error_on(:action, 'is not included in the list')
            
          doc.action = 'fart'
          doc.should have_error_on(:action, 'is not included in the list')
            
          doc.action = 'kick'
          doc.should_not have_error_on(:action)
        end
            
        should "not have error if allow nil is true and value is nil" do
          @document.key :action, String
          @document.validates_inclusion_of :action, :in => %w(kick run), :allow_nil => true
            
          doc = @document.new
          doc.should_not have_error_on(:action)
        end
            
        should "not have error if allow blank is true and value is blank" do
          @document.key :action, String
          @document.validates_inclusion_of :action, :in => %w(kick run), :allow_blank => true
            
          doc = @document.new(:action => '')
          doc.should_not have_error_on(:action)
        end
      end
    
    end # End on a Document
    
    context "On an EmbeddedDocument" do
      setup do
        @embedded_doc = EDoc()
      end
    
      context "Validating acceptance of" do
        should "work with validates_acceptance_of macro" do
          @embedded_doc.key :terms, String
          @embedded_doc.validates_acceptance_of :terms
          doc = @embedded_doc.new(:terms => '')
          doc.should have_error_on(:terms)
          doc.terms = '1'
          doc.should_not have_error_on(:terms)
        end
      end
    
      context "validating confirmation of" do
        should "work with validates_confirmation_of macro" do
          @embedded_doc.key :password, String
          @embedded_doc.validates_confirmation_of :password
          doc = @embedded_doc.new
          doc.password = 'foobar'
          doc.password_confirmation = 'foobar1'
          doc.should have_error_on(:password)
          doc.password_confirmation = 'foobar'
          doc.should_not have_error_on(:password)
        end
      end
    
      context "validating format of" do
        should "work with validates_format_of macro" do
          @embedded_doc.key :name, String
          @embedded_doc.validates_format_of :name, :with => /.+/
          doc = @embedded_doc.new
          doc.should have_error_on(:name)
          doc.name = 'John'
          doc.should_not have_error_on(:name)
        end
    
        should "work with :format shorcut key" do
          @embedded_doc.key :name, String, :format => /.+/
          doc = @embedded_doc.new
          doc.should have_error_on(:name)
          doc.name = 'John'
          doc.should_not have_error_on(:name)
        end
      end
    
      context "validating length of" do
        should "work with validates_length_of macro" do
          @embedded_doc.key :name, String
          @embedded_doc.validates_length_of :name, :minimum => 5
          doc = @embedded_doc.new
          doc.should have_error_on(:name)
        end
    
        context "with :length => integer shortcut" do
          should "set maximum of integer provided" do
            @embedded_doc.key :name, String, :length => 5
            doc = @embedded_doc.new
            doc.name = '123456'
            doc.should have_error_on(:name)
            doc.name = '12345'
            doc.should_not have_error_on(:name)
          end
        end
    
        context "with :length => range shortcut" do
          setup do
            @embedded_doc.key :name, String, :length => 5..7
          end
    
          should "set minimum of range min" do
            doc = @embedded_doc.new
            doc.should have_error_on(:name)
            doc.name = '123456'
            doc.should_not have_error_on(:name)
          end
    
          should "set maximum of range max" do
            doc = @embedded_doc.new
            doc.should have_error_on(:name)
            doc.name = '12345678'
            doc.should have_error_on(:name)
            doc.name = '123456'
            doc.should_not have_error_on(:name)
          end
        end
    
        context "with :length => hash shortcut" do
          should "pass options through" do
            @embedded_doc.key :name, String, :length => {:minimum => 2}
            doc = @embedded_doc.new
            doc.should have_error_on(:name)
            doc.name = '12'
            doc.should_not have_error_on(:name)
          end
        end
      end # validates_length_of
    
      context "Validating numericality of" do
        should "work with validates_numericality_of macro" do
          @embedded_doc.key :age, Integer
          @embedded_doc.validates_numericality_of :age
          doc = @embedded_doc.new
          doc.age = 'String'
          doc.should have_error_on(:age)
          doc.age = 23
          doc.should_not have_error_on(:age)
        end
    
        context "with :numeric shortcut" do
          should "work with integer or float" do
            @embedded_doc.key :weight, Float, :numeric => true
            doc = @embedded_doc.new
            doc.weight = 'String'
            doc.should have_error_on(:weight)
            doc.weight = 23.0
            doc.should_not have_error_on(:weight)
            doc.weight = 23
            doc.should_not have_error_on(:weight)
          end
        end
    
        context "with :numeric shortcut on Integer key" do
          should "only work with integers" do
            @embedded_doc.key :age, Integer, :numeric => true
            doc = @embedded_doc.new
            doc.age = 'String'
            doc.should have_error_on(:age)
            doc.age = 23.1
            doc.should have_error_on(:age)
            doc.age = 23
            doc.should_not have_error_on(:age)
          end
        end
      end # numericality of
    
      context "validating presence of" do
         should "work with validates_presence_of macro" do
           @embedded_doc.key :name, String
           @embedded_doc.validates_presence_of :name
           doc = @embedded_doc.new
           doc.should have_error_on(:name)
         end
     
         should "work with :required shortcut on key definition" do
           @embedded_doc.key :name, String, :required => true
           doc = @embedded_doc.new
           doc.should have_error_on(:name)
         end
       end
     
      context "validating exclusion of" do
        should "throw error if enumerator not provided" do
          @embedded_doc.key :action, String
          lambda {
            @embedded_doc.validates_exclusion_of :action
          }.should raise_error(ArgumentError)
        end
    
        should "work with validates_exclusion_of macro" do
          @embedded_doc.key :action, String
          @embedded_doc.validates_exclusion_of :action, :in => %w(kick run)
    
          doc = @embedded_doc.new
          doc.should_not have_error_on(:action)
    
          doc.action = 'fart'
          doc.should_not have_error_on(:action)
    
          doc.action = 'kick'
          doc.should have_error_on(:action, 'is reserved')
        end
    
        should "work with :not_in shortcut on key definition" do
          @embedded_doc.key :action, String, :not_in => %w(kick run)
    
          doc = @embedded_doc.new
          doc.should_not have_error_on(:action)
    
          doc.action = 'fart'
          doc.should_not have_error_on(:action)
    
          doc.action = 'kick'
          doc.should have_error_on(:action, 'is reserved')
        end
    
        should "not have error if allow nil is true and value is nil" do
          @embedded_doc.key :action, String
          @embedded_doc.validates_exclusion_of :action, :in => %w(kick run), :allow_nil => true
    
          doc = @embedded_doc.new
          doc.should_not have_error_on(:action)
        end
    
        should "not have error if allow blank is true and value is blank" do
          @embedded_doc.key :action, String
          @embedded_doc.validates_exclusion_of :action, :in => %w(kick run), :allow_nil => true
    
          doc = @embedded_doc.new(:action => '')
          doc.should_not have_error_on(:action)
        end
      end
    
      context "validating inclusion of" do
        should "throw error if enumerator not provided" do
          @embedded_doc.key :action, String
          lambda {
            @embedded_doc.validates_inclusion_of :action
          }.should raise_error(ArgumentError)
        end
    
        should "work with validates_inclusion_of macro" do
          @embedded_doc.key :action, String
          @embedded_doc.validates_inclusion_of :action, :in => %w(kick run)
    
          doc = @embedded_doc.new
          doc.should have_error_on(:action, 'is not included in the list')
    
          doc.action = 'fart'
          doc.should have_error_on(:action, 'is not included in the list')
    
          doc.action = 'kick'
          doc.should_not have_error_on(:action)
        end
    
        should "work with :in shortcut on key definition" do
          @embedded_doc.key :action, String, :in => %w(kick run)
    
          doc = @embedded_doc.new
          doc.should have_error_on(:action, 'is not included in the list')
    
          doc.action = 'fart'
          doc.should have_error_on(:action, 'is not included in the list')
    
          doc.action = 'kick'
          doc.should_not have_error_on(:action)
        end
    
        should "not have error if allow nil is true and value is nil" do
          @embedded_doc.key :action, String
          @embedded_doc.validates_inclusion_of :action, :in => %w(kick run), :allow_nil => true
    
          doc = @embedded_doc.new
          doc.should_not have_error_on(:action)
        end
    
        should "not have error if allow blank is true and value is blank" do
          @embedded_doc.key :action, String
          @embedded_doc.validates_inclusion_of :action, :in => %w(kick run), :allow_blank => true
    
          doc = @embedded_doc.new(:action => '')
          doc.should_not have_error_on(:action)
        end
      end
    
    end # End on an EmbeddedDocument

  end # Validations

  context "Adding validation errors" do
      setup do
        @document = Doc do
          key :action, String
          def action_present
            errors.add(:action, 'is invalid') if action.blank?
          end
        end
      end
  
      should "work with validate callback" do
        @document.validate :action_present
  
        doc = @document.new
        doc.action = nil
        doc.should have_error_on(:action)
  
        doc.action = 'kick'
        doc.should_not have_error_on(:action)
      end
    end
end
