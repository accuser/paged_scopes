require 'spec_helper'

describe "Controller" do
  context "class" do
    it "should add a protected get_page_for callback as a before filter when get_page_for is called" do
      in_controller_class do
        get_page_for :articles
        before_filters.map(&:to_s).should include("get_page_for_articles")
        protected_instance_methods.map(&:to_s).should include("get_page_for_articles")
      end
    end
  end
  
  describe "instance" do
    it "should raise an error if no collection is set" do
      in_controller_instance_with_paged(:articles) do
        lambda { get_page_for_articles }.should raise_error(RuntimeError)
      end      
    end
    
    context "when the collection is set" do
      before(:all) do
        @articles = User.first.articles
        @articles.per_page = 3
      end
    
      it "should get the page from a page id in the params" do 
        in_controller_instance_with_paged(:articles) do
          stub!(:params).and_return({ :page_id => @articles.pages.last.id })
          get_page_for_articles
          @page.articles.should include(@articles.last)
        end
      end
    
      it "should otherwise get the page from the current object if no page id is present in the params" do 
        @article = @articles.last
        in_controller_instance_with_paged(:articles) do
          get_page_for_articles
          @page.should == @articles.pages.find_by_article(@article)
          @page.articles.should include(@article)
        end
      end
          
      it "should get the first page if the current object is a new record" do
        @article = @articles.new
        in_controller_instance_with_paged(:articles) do
          get_page_for_articles
          @page.should == @articles.pages.first
        end
      end
          
      it "should otherwise get the first page" do
        in_controller_instance_with_paged(:articles) do
          get_page_for_articles
          @page.should == @articles.pages.first
        end
      end
    end
  end
end