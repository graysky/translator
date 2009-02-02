require 'test/unit'
require File.dirname(__FILE__) + '/../../../../test/test_helper'
require 'action_controller'
require 'action_controller/test_process'
require 'pp'

require File.dirname(__FILE__) + '/../init'
RAILS_ENV  = "test"

# Stub a blog Posts (weblog) controller
class PostsController < ActionController::Base

  before_filter :fix_view_paths

  def index
    # Pull out sample strings for index to the fake blog
    @page_title = t('title')
    @body = translate(:intro, :owner => "Ricky Rails")
    render :nothing => true, :layout => false
  end
  
  def show
    # Sample blog post
    render :template => "posts/show"
  end
  
  def different_formats
    # Get the same tagline using the different formats
    @taglines = []
    @taglines << t('header.author.name') # dot-sep keys
    @taglines << t('author.name', :scope => :header) # dot-sep keys with scope
    @taglines << t('name', :scope => 'header.author') # string key with dot-sep scope
    @taglines << t(:name, :scope => 'header.author') # symbol key with dot-sep score
    @taglines << t(:name, :scope => %w(header author))
    render :nothing => true
  end
  
  def footer_partial
    render :partial => "footer"
  end
  
  protected
  
  def fix_view_paths
    # Append the view path to get the correct views
    self.append_view_path("#{File.dirname(__FILE__)}/fixtures/")
  end
  
end

# Set up simple routing for testing
ActionController::Routing::Routes.reload rescue nil
ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
end

class I18nExtensionsTest < ActiveSupport::TestCase

  ### Test methods

  def setup
    # Create test locale bundle
    I18n.backend = I18n::Backend::Simple.new
    
    # Store test text
    I18n.backend.store_translations 'en', :posts => {:index => {:title => "My Blog Posts" } }
    I18n.backend.store_translations 'en', :posts => {:index => {:intro => "Welcome to the blog of {{owner}}" } }
    
    # Sample post
    I18n.backend.store_translations 'en', :posts => {:show => {:title => "Catz Are Cute" } }
    I18n.backend.store_translations 'en', :posts => {:show => {:body => "My cat {{name}} is the most awesome" } }
    
    # Fully qualified key
    I18n.backend.store_translations 'en', :header => {:author => {:name => "Ricky Rails" } }
    
    # Footer partial strings
    I18n.backend.store_translations 'en', :posts => {:footer => {:copyright => "Copyright 2009" } }
    
    # Set up test env
    @controller = PostsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end
  
  ### ActionController Tests ###
  
  # Test that translate gets typical controller scoping
  def test_controller_simple
    get :index
    assert_response :success
    assert_not_nil assigns
    # Test that controller could translate
    assert_equal I18n.t('posts.index.title'), assigns(:page_title)
    assert_equal I18n.translate('posts.index.intro', :owner => "Ricky Rails"), assigns(:body)
  end
  
  # Test that if something that breaks convention is still processed correctly
  # This case breaks with standard key hierarchy convention
  def test_controller_different_formats
    get :different_formats
    assert_response :success
    assert_not_nil assigns(:taglines)
    
    expected = "Ricky Rails"

    assigns(:taglines).each do |str|
      assert_equal expected, str
    end

  end
  
  # TODO: Test defaults
  def test_controller_with_defaults
    # flunk
  end
  
  # TODO: Test bulk lookup
  def test_bulk_lookup
    # flunk
  end
  
  ### ActionView Tests ###
  
  # Test that translate works in Views
  def test_view_show
    get :show
    assert_response :success
    post_title = I18n.translate('posts.show.title')
    post_body = I18n.t('posts.show.body', :name => 'hobbes') # matches show.erb

    assert_match /#{post_title}/, @response.body
    assert_match /#{post_body}/, @response.body
  end
  
  # Test that partials pull strings from their own key
  def test_view_partial
    get :footer_partial
    assert_response :success
    
    footer = I18n.t('posts.footer.copyright')
    assert_match /#{footer}/, @response.body
  end
    
end