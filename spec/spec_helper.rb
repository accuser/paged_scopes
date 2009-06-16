require 'spec'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'active_support'
require 'active_record'
require 'action_controller'
require 'action_controller/test_process'
require 'action_view/test_case'
require 'paged_scopes'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :dbfile => ':memory:')
ActiveRecord::Schema.define do
  create_table "users", :force => true do |t|
    t.column "name",  :text
  end
  create_table "articles", :force => true do |t|
    t.column "user_id",  :integer
    t.column "title", :text
  end
  create_table "comments", :force => true do |t|
    t.column "article_id", :integer
    t.column "user_id", :integer
  end
end

class ::User < ActiveRecord::Base
  has_many :articles
  has_many :comments
  has_many :commented_articles, :through => :comments, :source => :article
end
class ::Article < ActiveRecord::Base
  belongs_to :user
  has_many :comments
end
class ::Comment < ActiveRecord::Base
  belongs_to :article
  belongs_to :user
end

[ "first user", nil, "last user" ].each { |name| User.create(:name => name) }
7.times do
  User.all.each do |user|
    user.articles.create.comments << User.first.comments.new
    user.articles.create(:title => "%03d title" % Article.count).comments << User.first.comments.new << User.last.comments.new
  end
end

module ControllerHelpers
  def in_instance(instance, &block)
    instance.instance_eval do
      extend Spec::Matchers
      instance_eval(&block)
    end
  end
  
  def in_controller(controller, &block)
    in_instance controller do
      stub!(:params).and_return({})
      instance_eval(&block)
    end
  end
end

module RoutingHelpers
  def draw_routes(&block)
    ActionController::Routing::Routes.draw(&block)
  end

  def drawing_routes(&block)
    lambda { draw_routes(&block) }
  end

  def number_of_routes
    ActionController::Routing::Routes.routes.size
  end

  def named_routes
    ActionController::Routing::Routes.named_routes
  end

  def recognise_path(method, path)
    request = ActionController::TestRequest.new
    request.request_method = method
    ActionController::Routing::Routes.recognize_path(path, ActionController::Routing::Routes.extract_request_environment(request))
  rescue ActionController::RoutingError, ActionController::MethodNotAllowed
    nil
  end
end

module Contexts
  def in_contexts(&block)
    [ [ "a scoped ActiveRecord class",      "Article.scoped({})"            ],
      [ "a has_many association",           "User.last.articles"            ], # not tested for habtm!
      [ "a has_many, :through association", "User.first.commented_articles" ] ].each do |base_type, base|
      [ [ "",                                         ""                                          ],
        [ "scoped with :conditions",                  ".scoped(:conditions => { :title => nil })" ],
        [ "scoped with :include",                     ".scoped(:include => :comments)"            ],
        [ "scoped with :joins",                       ".scoped(:joins => 'INNER JOIN users ON users.id = articles.user_id')" ],
        [ "scoped with :joins & :conditions",         ".scoped(:joins => 'INNER JOIN users ON users.id = articles.user_id', :conditions => [ 'users.name IS NOT :nil', { :nil => nil } ])" ],
        [ "scoped with :joins, :conditions & :order", ".scoped(:joins => 'INNER JOIN users ON users.id = articles.user_id', :conditions => [ 'users.name IS NOT :nil', { :nil => nil } ], :order => 'users.name')" ],
        [ "scoped with :joins & :group",              ".scoped(:joins => 'INNER JOIN comments AS article_comments ON article_comments.article_id = articles.id', :group => 'articles.id')" ],
        [ "scoped with :joins, :group & :limit",      ".scoped(:joins => 'INNER JOIN comments AS article_comments ON article_comments.article_id = articles.id', :group => 'articles.id', :limit => 4)" ],
        [ "scoped with :includes, :joins & subquery", ".scoped(:include => :comments, :joins => 'INNER JOIN (SELECT count(id) AS count, article_id FROM comments GROUP BY article_id) article_comments ON article_comments.article_id = articles.id', :conditions => 'article_comments.count > 1')"],
        [ "scoped with :limit",                       ".scoped(:limit => 5)"                      ],
        [ "scoped with :limit & :offset",             ".scoped(:limit => 5, :offset => 7)"        ],
        [ "scoped with :order",                       ".scoped(:order => 'articles.id DESC')"     ] ].each do |scope_type, scope|
        context "for #{base_type} #{scope_type}" do
          before(:each) do
            @articles = eval("#{base}#{scope}")
            @articles.all.should_not be_empty
          end
          instance_eval(&block)
        end
      end
    end
  end
end

Spec::Runner.configure do |config|
  config.extend Contexts
  config.include RoutingHelpers
  config.include ControllerHelpers
end

