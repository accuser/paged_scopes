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
  end  
end