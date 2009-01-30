require 'test/unit'
require 'test_helper'
require 'action_controller'
require 'action_controller/test_process'
require 'pp'

require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/../init'

#RAILS_ROOT = File.join( File.dirname(__FILE__), "rails_root" )
RAILS_ENV  = "test"

ActionController::Routing::Routes.reload rescue nil
ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
end

class I18nExtensionsTest < ActiveSupport::TestCase

  # Stub a blog Post controller
  class PostsController < ActionController::Base

    # Set up view template directories
    if respond_to? :view_paths=
      self.view_paths = [ "#{File.dirname(__FILE__)}/fixtures/" ]
    else
      self.template_root = [ "#{File.dirname(__FILE__)}/fixtures/" ]
    end

    def index
      # Pull out sample strings for index to the fake blog
      @page_title = t('title')
      @body = translate(:intro, :owner => "Robby Rails")
      render :nothing => true, :layout => false
    end
    
    def show
      # Sample blog post
      render :template => "show"
    end
    
  end

  def setup
    # Create test locale bundle
    I18n.backend = I18n::Backend::Simple.new
    
    # Store test text
    I18n.backend.store_translations 'en', :posts => {:index => {:title => "My Blog Posts" } }
    I18n.backend.store_translations 'en', :posts => {:index => {:intro => "Welcome to the blog of {{owner}}" } }
    
    # Sample post
    I18n.backend.store_translations 'en', :posts => {:show => {:title => "Catz Are Cute" } }
    I18n.backend.store_translations 'en', :posts => {:show => {:body => "My cat {{name}} is the most awesome" } }
    
    # Set up test env
    @controller = PostsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end
  
  
  # Test that translate gets typical controller scoping
  def test_controller_simple
    get :index
    assert_response :success
    assert_not_nil assigns
    # Test that controller could translate
    assert_equal I18n.t('posts.index.title'), assigns(:page_title)
    assert_equal I18n.translate('posts.index.intro', :owner => "Robby Rails"), assigns(:body)
  end
  
  # Test that translate works in Views
  def test_view_show
    get :show
    assert_response :success
    post_title = I18n.translate('posts.show.title')
    post_body = I18n.t('posts.show.body', :name => 'hobbes') # matches show.erb

    assert_match /#{post_title}/, @response.body
    assert_match /#{post_body}/, @response.body
  end
    
end