require 'test/unit'
require File.dirname(__FILE__) + '/../../../../test/test_helper'
require 'action_controller'
require 'action_controller/test_process'
require 'action_mailer'
require 'pp'

require File.dirname(__FILE__) + '/../init'
RAILS_ENV  = "test" unless defined? RAILS_ENV

class BlogCommentMailer < ActionMailer::Base
  
  def comment_notification
    @subject = t('subject')
  end
end

BlogCommentMailer.template_root = "#{File.dirname(__FILE__)}/fixtures/"

# Stub a blog Posts (weblog) controller
class BlogPostsController < ActionController::Base
  
  # Sets up view paths so tests will work
  before_filter :fix_view_paths

  # Simulate auth filter
  before_filter :authorize, :only => [:admin]

  def index
    # Pull out sample strings for index to the fake blog
    @page_title = t('title')
    @body = translate(:intro, :owner => "Ricky Rails")
    render :nothing => true, :layout => false
  end
  
  def show
    # Sample blog post
    render :template => "blog_posts/show"
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
  
  # Partial template, but stored within this controller
  def footer_partial
    render :partial => "footer"
  end
  
  # Partial that is shared across controllers
  def header_partial
    render :partial => "shared/header"
  end

  def admin
    # Simulate an admin page that has a protection scheme
  end
  
  def default_value
    # Get a default value if the string isn't there
    @title = t('not_there', :default => 'the default')
    render :nothing => true
  end
  
  protected
  
  # Simulate an auth system that prevents login
  def authorize
    # set a flash with a common message
    flash[:error] = t('flash.invalid_login')
    redirect_to :action => :index
  end
  
  def fix_view_paths
    # Append the view path to get the correct views/partials 
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
    I18n.backend.store_translations 'en', :blog_posts => {:index => {:title => "My Blog Posts" } }
    I18n.backend.store_translations 'en', :blog_posts => {:index => {:intro => "Welcome to the blog of {{owner}}" } }
    
    # Sample post
    I18n.backend.store_translations 'en', :blog_posts => {:show => {:title => "Catz Are Cute" } }
    I18n.backend.store_translations 'en', :blog_posts => {:show => {:body => "My cat {{name}} is the most awesome" } }
    
    # Fully qualified key
    I18n.backend.store_translations 'en', :header => {:author => {:name => "Ricky Rails" } }
    
    # Flash messages not specific to 1 action, but within 1 controller
    I18n.backend.store_translations 'en', :blog_posts => {:flash => {:invalid_login => "Invalid session" } }
    
    # Footer partial strings
    I18n.backend.store_translations 'en', :blog_posts => {:footer => {:copyright => "Copyright 2009" } }
    # Header partial strings
    I18n.backend.store_translations 'en', :shared => {:header => {:blog_name => "Ricky Rocks Rails" } }
    
    # Strings for ActionMailer test
    I18n.backend.store_translations 'en', :blog_comment_mailer => {:comment_notification => {:subject => "New Comment Notification" } }
    
    # Set up test env
    @controller = BlogPostsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end
  
  ### ActionController Tests
  
  # Test that translate gets typical controller scoping
  def test_controller_simple
    get :index
    assert_response :success
    assert_not_nil assigns
    # Test that controller could translate
    assert_equal I18n.t('blog_posts.index.title'), assigns(:page_title)
    assert_equal I18n.translate('blog_posts.index.intro', :owner => "Ricky Rails"), assigns(:body)
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
  
  # Test call to translate with default value
  def test_controller_with_defaults
    get :default_value
    assert_response :success
    assert_not_nil assigns(:title)
    
    # TODO: Need better way to check that the default was only returned as last resort.
    assert_equal 'the default', assigns(:title)
  end
  
  # TODO: Test bulk lookup
  def test_bulk_lookup
    # flunk
  end
  
  # Test that first the most specific scope will be tried (controller.action) then
  # back off to just the outer scope (controller)
  def test_controller_shared_messages
    get :admin
    assert_response :redirect
    
    # Test that t should have tried the outer scope
    assert_equal I18n.t('blog_posts.flash.invalid_login'), flash[:error]
  end
  
  ### ActionView Tests
  
  # Test that translate works in Views
  def test_view_show
    get :show
    assert_response :success
    post_title = I18n.translate('blog_posts.show.title')
    post_body = I18n.t('blog_posts.show.body', :name => 'hobbes') # matches show.erb

    assert_match /#{post_title}/, @response.body
    assert_match /#{post_body}/, @response.body
  end
  
  # Test that partials pull strings from their own key
  def test_view_partial
    get :footer_partial
    assert_response :success
    
    footer = I18n.t('blog_posts.footer.copyright')
    assert_match /#{footer}/, @response.body
  end
  
  def test_header_partial
    get :header_partial
    assert_response :success
    
    blog_name = I18n.t('shared.header.blog_name')
    assert_match /#{blog_name}/, @response.body
  end
  
  ### ActionMailer Tests
  
  def test_mailer    
    mail = BlogCommentMailer.create_comment_notification
    subject = I18n.t('blog_comment_mailer.comment_notification.subject')
    assert_match /#{subject}/, mail.body
  end
    
end