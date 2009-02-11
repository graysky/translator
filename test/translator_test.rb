require 'test_helper'

# Model of a blog post, defined in schema.rb
class BlogPost < ActiveRecord::Base
  # Has a title, author and body
  
  def written_by
    # Get sting like "Written by Ricky"
    t('byline', :author => self.author)
  end
  
end

# A mailer for new comments on the fake blog
class BlogCommentMailer < ActionMailer::Base
  
  # Send email about new comments
  def comment_notification
    @subject = t('subject')
  end
end

BlogCommentMailer.template_root = "#{File.dirname(__FILE__)}/fixtures/app/views"

# Include the helpers directory on the load path
$:.unshift "#{File.dirname(__FILE__)}/fixtures/app/helpers"

# Stub a Blog Posts controller
class BlogPostsController < ActionController::Base
  
  # Sets up view paths so tests will work
  before_filter :fix_view_paths

  # Simulate auth filter
  before_filter :authorize, :only => [:admin]

  layout "blog_layout", :only => :show_with_layout

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
  
  # Render the show action with a layout
  def show_with_layout
    render :template => "blog_posts/show"
  end
  
  # The archives action references a view helper
  def archives
    render :template => "blog_posts/archives"
  end
  
  # View that has a key that doesn't reference a valid string
  def missing_translation
    render :template => "blog_posts/missing_translation"
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
    self.append_view_path("#{File.dirname(__FILE__)}/fixtures/app/views")
  end
  
end

# Set up simple routing for testing
ActionController::Routing::Routes.reload rescue nil
ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
end

class TranslatorTest < ActiveSupport::TestCase

  ### Test methods

  def setup
    # Create test locale bundle
    I18n.backend = I18n::Backend::Simple.new
    
    ## Strings for Controllers/Views
    I18n.backend.store_translations 'en', :blog_posts => {:index => {:title => "My Blog Posts" } }
    I18n.backend.store_translations 'en', :blog_posts => {:index => {:intro => "Welcome to the blog of {{owner}}" } }
    
    # Sample post
    I18n.backend.store_translations 'en', :blog_posts => {:show => {:title => "Catz Are Cute" } }
    I18n.backend.store_translations 'en', :blog_posts => {:show => {:body => "My cat {{name}} is the most awesome" } }
    
    # To be pulled out in a view helper
    I18n.backend.store_translations 'en', :blog_posts => {:archives => {:title => "My Blog Archives" } }
    
    # Fully qualified key
    I18n.backend.store_translations 'en', :header => {:author => {:name => "Ricky Rails" } }
    
    # Flash messages not specific to 1 action, but within 1 controller
    I18n.backend.store_translations 'en', :blog_posts => {:flash => {:invalid_login => "Invalid session" } }
    
    # Footer partial strings
    I18n.backend.store_translations 'en', :blog_posts => {:footer => {:copyright => "Copyright 2009" } }
    # Header partial strings
    I18n.backend.store_translations 'en', :shared => {:header => {:blog_name => "Ricky Rocks Rails" } }
    
    # Strings for layout
    I18n.backend.store_translations 'en', :layouts => {:blog_layout => {:blog_title => "The Blog of Ricky" } }
    
    # Strings for ActiveRecord test - convention is :model_name :method_name?
    I18n.backend.store_translations 'en', :blog_post => {:byline => "Written by {{author}}" }
    
    # Strings for ActionMailer test
    I18n.backend.store_translations 'en', :blog_comment_mailer => {:comment_notification => {:subject => "New Comment Notification" } }
    I18n.backend.store_translations 'en', :blog_comment_mailer => {:comment_notification => {:signoff => "Your Faithful Emailing Bot" } }
    
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
  
  # Test that layouts can pull strings
  def test_show_with_layout
    get :show_with_layout
    assert_response :success
    
    blog_title = I18n.t('layouts.blog_layout.blog_title')
    assert_match /#{blog_title}/, @response.body
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
  
  # Test that view helpers inherit correct scoping
  def test_view_helpers
    get :archives
    assert_response :success
    
    archives_title = I18n.t('blog_posts.archives.title')
    assert_match /#{archives_title}/, @response.body
  end
  
  # Test that original behavior of TranslationHelper is not undone.
  # It adds a <span class="translation_missing"> that should still be there
  def test_missing_translation_show_in_span
    Translator.strict_mode(false)
    
    assert_nothing_raised do
      get :missing_translation
      assert_response :success

      # behavior added by TranslationHelper
      assert_match /span class="translation_missing"/, @response.body, "Should be a span tag translation_missing"
    end
  end
  
  ### ActionMailer Tests
  
  def test_mailer    
    mail = BlogCommentMailer.create_comment_notification
    # Subject is fetched from the mailer action
    subject = I18n.t('blog_comment_mailer.comment_notification.subject')
    
    # Signoff is fetched in the mail template (via addition to ActionView)
    signoff = I18n.t('blog_comment_mailer.comment_notification.signoff')
    
    assert_match /#{subject}/, mail.body
    assert_match /#{signoff}/, mail.body
  end
   
  ### ActiveRecord tests
  
  # Test that a model's method can call translate
  def test_model_calling_translate
    
    post = nil
    author = "Ricky"
    assert_nothing_raised do
      post = BlogPost.create(:title => "First Post!", :body => "Starting my new blog about RoR", :author => author)
    end
    assert_not_nil post
    
    assert_equal I18n.t('blog_post.byline', :author => author), post.written_by
  end
   
   
  ### TestUnit helpers
  
  def test_strict_mode
    Translator.strict_mode(true)
    
    # With strict mode on, exception should be thrown
    assert_raise I18n::MissingTranslationData do
      str = "Exception should be raised #{I18n.t('the_missing_key')}"
    end
    
    Translator.strict_mode(false)
    
    assert_nothing_raised do
      str = "Exception should not be raised #{I18n.t('the_missing_key')}"
    end
  end
  
  # Fetch a miss
  def test_assert_translated
    # Within the assert_translated block, any missing keys fail the test
    assert_raise Test::Unit::AssertionFailedError do
      assert_translated do
        str = "Exception should be raised #{I18n.t('the_missing_key')}"
      end
    end
    
    assert_nothing_raised do
      str = "Exception should not be raised #{I18n.t('the_missing_key')}"
    end
  end
      
end