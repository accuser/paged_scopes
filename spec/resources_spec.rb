require 'spec_helper'

describe "Resources" do
  before(:each) do
    ActionController::Routing::Routes.clear!
  end
  
  after(:each) do
    ActionController::Routing::Routes.clear!
  end

  it "should not affect normal resource mapping if :paged option is not specified" do
    drawing_routes { |map| map.resources :articles }.should change { number_of_routes }.by(7)
  end
  
  it "should add a paged index route if a :paged option is specified" do
    drawing_routes { |map| map.resources :articles, :paged => true }.should change { number_of_routes }.by(7+1)
  end
  
  context "with a :paged options" do    
    it "should map a paged index route for GET only" do
      draw_routes { |map| map.resources :articles, :paged => true }
      recognise_path(   :get, "/pages/1/articles").should == { :controller => "articles", :action => "index", :page_id => "1" }
      recognise_path(   :put, "/pages/1/articles").should be_nil
      recognise_path(  :post, "/pages/1/articles").should be_nil
      recognise_path(:delete, "/pages/1/articles").should be_nil
    end

    it "should add a named route for the paged index route" do
      draw_routes { |map| map.resources :articles, :paged => true }
      named_routes.names.should include(:page_articles)
    end
    
    it "should observe the :path_prefix option in the paged route" do
      draw_routes { |map| map.resources :articles, :paged => true, :path_prefix => "foo" }
      recognise_path(:get, "/foo/pages/1/articles").should == { :controller => "articles", :action => "index", :page_id => "1" }
    end
    
    it "should observe a :namespace option in the paged route" do
      draw_routes { |map| map.resources :articles, :paged => true, :namespace => "bar/" }
      recognise_path(:get, "/pages/1/articles").should == { :controller => "bar/articles", :action => "index", :page_id => "1" }
    end
    
    it "should accept an :as option in the :paged option" do
      draw_routes { |map| map.resources :articles, :paged => { :as => "page" } }
      recognise_path(:get, "/page/1/articles").should == { :controller => "articles", :action => "index", :page_id => "1" }
    end
    
    it "should accept a :name option in the :paged option" do
      draw_routes { |map| map.resources :articles, :paged => { :name => :groups } }
      recognise_path(:get, "/groups/1/articles").should == { :controller => "articles", :action => "index", :group_id => "1" }
    end
    
    it "should accept a :path_prefix hash as the :paged option" do
      draw_routes { |map| map.resources :articles, :paged => true, :name_prefix => "baz_" }
      named_routes.names.should include(:baz_page_articles)
    end
    
    context "and nested resources" do
      it "should not change the nested routes" do
        drawing_routes do |map|
          map.resources :articles, :paged => true do |article|
            article.resources :comments
          end
        end.should change { number_of_routes }.by(7+1+7)
        drawing_routes do |map|
          map.resources :articles, :paged => true, :has_many => :comments
        end.should change { number_of_routes }.by(7+1+7)
      end
    end
  end
end