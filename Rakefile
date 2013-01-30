RAILS_ROOT = File.expand_path(File.dirname(__FILE__))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'


require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec



# # Gem configuration
# require 'rubygems'
# Gem::manage_gems
# require "rake/gempackagetask"
# 
# spec = Gem::Specification.new do |spec|
#   spec.name = "rinda_server"
#   spec.summary = "A library that simplifies creating and managing a Rinda tuplespace"
#   spec.version = "0.0.1"
#   spec.author = "8th Light"
#   spec.files = FileList["lib/**/*.rb", "Rakefile"]
#   spec.test_files = ["spec"]
# end
# 
# Rake::GemPackageTask.new(spec) do |pkg|
#   pkg.need_tar = false
# end
