# I18nExtensions
require 'active_support'
require 'action_view/helpers/translation_helper'

# TODO. Need to make available in:
# - Controllers
# - Models
# - Views
# - ActionMailer

module I18nExtensions
  VERSION = '0.1.0'

  # TODO: Handle:
  # - partials (controller:partial:key)
  # - shared partials (folder:partial:key)
  # - layout (layout_name:key)
  #
  # - defaults (may have to pull them out for first attempt)
  #
  #
  def self.translate_with_scope(controller, action, key, options={})
    # Keep the original options clean
    scoped_options = {}.merge(options)
    
    # Get the original scoping
    # From RDoc: 
    # Scope can be either a single key, a dot-separated key or an array of keys or dot-separated keys
    scope = []
    # if !options[:scope].blank?
    #       if options[:scope]
    #       
    #       scope += options[:scope] unless options[:scope].blank?
    #     end
    
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

# For View helpers
class ActionView::Base
  def translate_with_defaults(key, options={})
    # TODO Handle:
    # - partials associated with single controllers
    # - shared partials
    #
    scope = self.template.name

    I18nExtensions.translate_with_scope(self.controller_name, scope, key, options)
  end
  
  alias_method_chain :translate, :defaults
  alias :t :translate
end

# Include in controllers
module ActionController #:nodoc:
  class Base
    def translate_with_defaults(key, options={})
      I18nExtensions.translate_with_scope(self.controller_name, self.action_name, key, options)
    end
    
    alias_method_chain :translate, :defaults
    alias :t :translate
  end
end

# 
#class ActionMailer::Base
#  include AsyncMailer
#end


# View level TranslationHelper
# require 'action_view/helpers/tag_helper'
# 
# module ActionView
#   module Helpers
#     module TranslationHelper
#       def translate(key, options = {})
#         options[:raise] = true
#         I18n.translate(key, options)
#       rescue I18n::MissingTranslationData => e
#         keys = I18n.send(:normalize_translation_keys, e.locale, e.key, e.options[:scope])
#         content_tag('span', keys.join(', '), :class => 'translation_missing')
#       end
#       alias :t :translate
# 
#       def localize(*args)
#         I18n.localize *args
#       end
#       alias :l :localize
#     end
#   end
# end