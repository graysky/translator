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
  # - shared keys within a controller (like flash messages or from protected methods)
  # - defaults (may have to pull them out for first attempt)
  #
  def self.translate_with_scope(controller, action, key, options={})
    # Keep the original options clean
    
    RAILS_DEFAULT_LOGGER.debug { "key: #{key}" }
    
    scoped_options = {}.merge(options)
    
    # Get the original scoping
    # From RDoc: 
    # Scope can be either a single key, a dot-separated key or an array of keys or dot-separated keys
    scope = []
    
    # Build up the scope
    scope.insert(0, controller.to_sym)
    scope.insert(1, action.to_sym)
    
    # Raise to know if the key was found
    scoped_options[:raise] = true
    
    # Merge the scope
    scoped_options[:scope] = scope
    
    begin
      # try with scope
      I18n.translate(key, scoped_options)
    rescue I18n::MissingTranslationData => exc
      # Fall back to trying original
      I18n.translate(key, options)
    end
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

    I18nExtensions.translate_with_scope(outer_scope, inner_scope, key, options)
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
      I18nExtensions.translate_with_scope(self.controller_name, self.action_name, key, options)
    end
    
    alias_method_chain :translate, :context
    alias :t :translate
  end
end

# TODO Add test helpers

# TODO Add to ActionMailer
#class ActionMailer::Base
#  include AsyncMailer
#end