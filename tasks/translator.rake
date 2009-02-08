# Internationalization tasks
namespace :i18n do
  
  # Task invoked like 'rake i18n:missing[:de]'
  desc "Finds missing translations compared to locale (or default)"
  task :missing, :locale, :needs => [:environment] do |t, args|

    # Get the locale to use as the base for comparison
    args.with_defaults(:locale => I18n.default_locale)
    locale = args.locale.to_sym
    
    Translator.find_missing_translations(locale)
  end  
end
