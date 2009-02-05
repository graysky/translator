require 'active_support'
require 'action_view/helpers/translation_helper'

# Extentions to make internationalization (i18n) of a Rails application simpler. 
# Support the method +translate+ (or shorter +t+) in models/view/controllers/mailers.
#
module Translator
  VERSION = '0.3.0'

  # Performs lookup with a given scope. The scope should be an array of strings or symbols
  # ordered from highest to lowest scoping. For example, for a given PicturesController 
  # with an action "show" the scope should be ['pictures', 'show'] which happens automatically.
  #
  # The key and options parameters follow the same rules as the I18n library (they are passed through).
  # 
  # The search order is from most specific scope to most general (and then using a default value, if provided).
  # So continuing the previous example, if the key was "title" and options included :default => 'Some Picture'
  # then it would continue searching until it found a value for:
  # * pictures.show.title
  # * pictures.title
  # * title
  # * use the default value (if provided)
  #
  # The key itself can contain a scope. For example, if there were a set of shared error messages within the 
  # Pictures controller, that could be found using a key like "errors.deleted_picture". The inital search with
  # narrowest scope ('pictures.show.errors.deleted_picture') will not find a value, but the subsequent search with
  # broader scope ('pictures.errors.deleted_picture') will find the string.
  #
  def self.translate_with_scope(scope, key, options={})
    # Keep the original options clean
    scoped_options = {}.merge(options)
    
    # From RDoc: 
    # Scope can be either a single key, a dot-separated key or an array of keys or dot-separated keys
    
    scope ||= [] # guard against nil scope
    RAILS_DEFAULT_LOGGER.debug { "key: #{key} scope: #{scope.to_s} options: #{options.to_s}" }
    
    # Convert the scopes to list of symbols and ignore anything
    # that cannot be converted
    scope.map! do |e| 
      if e.respond_to?(:to_sym)
        e.to_sym
      else
        nil
      end
    end
    
    scope.compact! # clear any nil values
    
    # Raise to know if the key was found
    scoped_options[:raise] = true
    
    # Remove any default value when searching with scope
    scoped_options.delete(:default)
    
    str = nil # the string being looked for
    
    # Loop through each scope until a string is found.
    # Example: starts with scope of [:blog_posts :show] then tries scope [:blog_posts]
    #
    while !scope.empty? && str.nil?
    
      # Set scope to use for search
      scoped_options[:scope] = scope
    
      RAILS_DEFAULT_LOGGER.debug { "searching key: #{key} scope: #{scope.to_s}" }
    
      begin
        # try to find key within scope
        str = I18n.translate(key, scoped_options)
      rescue I18n::MissingTranslationData => exc
        # did not find the string, remove a layer of scoping (if possible)
        scope.pop
      end
    end
    
    if str.nil?
      # Didn't find a string yet, so fall back to trying original request
      str = I18n.translate(key, options)
    end
    
    str
  end
  
end

class ActionView::Base
  # Redefine the +translate+ method in ActionView (contributed by TranslationHelper) that is
  # context-aware of what view (or partial) is being rendered. 
  # Initial scoping will be scoped to [:controller_name :view_name]
  def translate_with_context(key, options={})

    # The outer scope will typically be the controller name ("blog_posts")
    # but can also be a dir of shared partials ("shared").
    outer_scope = self.template.base_path
    
    # The template will be the view being rendered ("show.erb" or "_ad.erb")
    inner_scope = self.template.name
    
    # Partials template names start with underscore, which should be removed
    inner_scope.sub!(/^_/, '')

    Translator.translate_with_scope([outer_scope, inner_scope], key, options)
  end
  
  alias_method_chain :translate, :context
  alias :t :translate
end

module ActionController
  class Base
    
    # Add a +translate+ (or +t+) method to ActionController that is context-aware of what controller and action
    # is being invoked. Initial scoping will be [:controller_name :action_name] when looking up keys. Example would be
    # +['posts' 'show']+ for the +PostsController+ and +show+ action.
    def translate_with_context(key, options={})
      Translator.translate_with_scope([self.controller_name, self.action_name], key, options)
    end
    
    alias_method_chain :translate, :context
    alias :t :translate
  end
end

# Add translate method to ActionMailer
class ActionMailer::Base

  # Add a +translate+ (or +t+) method to ActionMailer that is context-aware of what mailer and action
  # is being invoked. Initial scoping of [:mailer_name :action_name] where mailer_name is like 'comment_mailer' 
  # and action_name is 'comment_notification' (note: no "deliver_" or "create_")
  def translate(key, options={})
    Translator.translate_with_scope([self.mailer_name, self.action_name], key, options)
  end
  
  alias :t :translate
end