require 'test_helper'

class DescendantAppendsTest < Test::Unit::TestCase
  context "Document" do
    should 'allow extensions to Document to be appended' do
      module Extension; def test_this_extension; end end
      silence_stderr { MongoMapper::Document.append_extensions(Extension) }
      article = Doc()
      article.should respond_to(:test_this_extension)
    end

    should 'add appended extensions to classes that include Document before they are added' do
      module Extension; def test_this_extension; end end
      article = Doc()
      silence_stderr { MongoMapper::Document.append_extensions(Extension) }
      article.should respond_to(:test_this_extension)
    end

    should 'allow inclusions to Document to be appended' do
      module Inclusion; def test_this_inclusion; end end
      silence_stderr { MongoMapper::Document.append_inclusions(Inclusion) }
      article = Doc()
      article.new.should respond_to(:test_this_inclusion)
    end

    should 'add appended inclusions to classes that include Document before they are added' do
      module Inclusion; def test_this_inclusion; end end
      article = Doc()
      silence_stderr { MongoMapper::Document.append_inclusions(Inclusion) }
      article.new.should respond_to(:test_this_inclusion)
    end
  end

  context "EmbeddedDocument" do
    should 'allow extensions to Document to be appended' do
      module Extension; def test_this_extension; end end
      silence_stderr { MongoMapper::EmbeddedDocument.append_extensions(Extension) }
      article = EDoc()
      article.should respond_to(:test_this_extension)
    end

    should 'add appended extensions to classes that include Document before they are added' do
      module Extension; def test_this_extension; end end
      article = EDoc()
      silence_stderr { MongoMapper::EmbeddedDocument.append_extensions(Extension) }
      article.should respond_to(:test_this_extension)
    end

    should 'allow inclusions to Document to be appended' do
      module Inclusion; def test_this_inclusion; end end
      silence_stderr { MongoMapper::EmbeddedDocument.append_inclusions(Inclusion) }
      article = EDoc()
      article.new.should respond_to(:test_this_inclusion)
    end

    should 'add appended inclusions to classes that include Document before they are added' do
      module Inclusion; def test_this_inclusion; end end
      article = EDoc()
      silence_stderr { MongoMapper::EmbeddedDocument.append_inclusions(Inclusion) }
      article.new.should respond_to(:test_this_inclusion)
    end
  end
end