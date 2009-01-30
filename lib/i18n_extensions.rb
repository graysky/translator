# I18nExtensions
require 'active_support'
require 'action_view/helpers/translation_helper'

# TODO. Need to make available in:
# - Controllers
# - Models
# - Views
# - ActionMailer

module I18nExtensions

  # TODO: Do we want to override scope if passed in?
  
  # Tests:
  #
  
  # TODO: Handle:
  # - partials (controller:partial:key)
  # - shared partials (folder:partial:key)
  # - layout (layout_name:key)
  #
  # - defaults (may have to pull them out for first attempt)
  def self.translate_with_scope(controller, action, key, options={})
    #Rails.logger.info("controller: #{controller}/#{action} key: #{key}")
    
    # Get the original scoping
    #orig_scope = options[:scope].blank? ? options[:scope].clone || []
    scope = options[:scope] || []
    
    scope.insert(0, controller.to_sym)
    scope.insert(1, action.to_sym)
    
    # Merge the scope
    options[:scope] = scope
    
    # Try with scope
    #pp options
    x = I18n.translate(key, options)
    #puts "Found: #{x}"
    x
  end
end

module ActionController #:nodoc:
  class Base
    def translate_with_defaults(key, options={})
      I18nExtensions.translate_with_scope(self.controller_name, self.action_name, key, options)
    end
    
    alias_method_chain :translate, :defaults
    alias :t :translate
  end
end

# For view helpers
class ActionView::Base
  def translate_with_defaults(key, options={})
    # TODO Handle partials, etc.
    
    I18nExtensions.translate_with_scope(self.controller_name, self.template.name, key, options)
  end
  
  alias_method_chain :translate, :defaults
  alias :t :translate
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