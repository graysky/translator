require 'rake'
require 'rake/testtask'
  
# Use Hanna for pretty RDocs (if installed), otherwise normal rdocs
begin
  require 'hanna/rdoctask'
rescue Exception
  require 'rake/rdoctask'
end

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the translator plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the translator plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Translator - i18n tooling for Rails'
  rdoc.options << '--line-numbers' << '--inline-source' << '--webcvs=http://github.com/graysky/translator/tree/master/'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

# Requires the allison gem and uses a path that only works locally
# desc 'Generate prettified documentation for the translator plugin.'
# Rake::RDocTask.new(:rdoc_pretty) do |rdoc|
#   rdoc.rdoc_dir = 'rdoc'
#   rdoc.title    = 'Translator'
#   rdoc.options << '--line-numbers' << '--inline-source'
#   rdoc.template = '/Library/Ruby/Gems/1.8/gems/allison-2.0.3/lib/allison'
#   rdoc.rdoc_files.include('README.rdoc')
#   rdoc.rdoc_files.include('lib/**/*.rb')
# end
