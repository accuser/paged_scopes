require 'spec_helper'

describe "Context" do
  in_contexts do
    it "should know the object after an object in the collection" do
      articles = @articles.all
      until articles.empty? do
        articles.shift.next.should == articles.first
      end
    end

    it "should know the object before an object in the collection" do
      articles = @articles.all
      until articles.empty? do
        articles.pop.previous.should == articles.last
      end
    end
    
    it "should be know for an object obtained with #first" do
      @articles.all.should have_at_least(2).articles
      @articles.first.next.should_not be_nil
      @articles.first.previous.should be_nil
    end

    it "should be known for object for an object obtained with #last" do
      @articles.all.should have_at_least(2).articles
      @articles.last.previous.should_not be_nil
      @articles.last.next.should be_nil
    end
  end

  context "for an object found with #first" do
    before(:each) do
      @articles = User.first.articles
    end

    it "should know its next object" do
      @articles.all.should have_at_least(2).items
      @articles.first.next.should_not be_nil
    end
  end
end