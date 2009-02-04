require 'active_support'
require 'action_view/helpers/translation_helper'

# Extentions to make internationalization (i18n) of a Rails application simpler. Features include :
# 1. Support the method +translate+ (or +t+) in Rails models/view/controllers.
# 2. Promote keeping DRY through convention for key hierarchy (TODO: Describe convention)
#
module I18nExtensions
  VERSION = '0.1.0'

  # TODO: Handle:
  # - layout (layout_name:key)
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

# Redefine the +translate+ method in ActionView (contributed by TranslationHelper) that is
# context-aware of what view is being rendered. Will try scoping key requests to [:controller_name :view_name]
class ActionView::Base
  def translate_with_context(key, options={})

    # The outer scope will typically be the controller name ("blog_posts")
    # but can also be a dir of shared partials ("shared").
    outer_scope = self.template.base_path
    
    # The template will be the view being rendered ("show.erb" or "_ad.erb")
    inner_scope = self.template.name
    
    # Partials template names start with underscore, which should be removed
    inner_scope.sub!(/^_/, '')

    I18nExtensions.translate_with_scope([outer_scope, inner_scope], key, options)
  end
  
  alias_method_chain :translate, :context
  alias :t :translate
end

# Add a +translate+ (or +t+) method to ActionController that is context-aware of what controller and action
# is being invoked. Will automatically add scoping of [:controller_name :action_name] to calls to translate.
module ActionController
  class Base
    
    # Add scoping of controller_name and action_name to the call to +translate+
    def translate_with_context(key, options={})
      I18nExtensions.translate_with_scope([self.controller_name, self.action_name], key, options)
    end
    
    alias_method_chain :translate, :context
    alias :t :translate
  end
end

# TODO Add test helpers to make testing translations simple. Ideas:
# - iterate through available locales for each action and test that there is no missing translations
# - no missing translations for the current test suite

# TODO Add "psuedo-translate" mode that is:
# - more whiny when keys not found
# - prepends/appends strings to make it easier to see untranslated ones

# TODO Add to ActionMailer
#class ActionMailer::Base
#  include AsyncMailer
#end