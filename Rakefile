# -*- encoding: utf-8 -*-

require "rubygems"
require "rake/gempackagetask"
require "rake/rdoctask"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end

namespace :test do
  desc "Run tests with all available Ruby interpreters"

  task :versions do |t|
    # Kind of re-entrant, but it shouldn't matter too much
    rubies = `rvm list strings`.split("\n")
    system "rvm #{rubies.join(",")} rake test"
  end
end

task :default => ["test"]

spec = Gem::Specification.load('geolib.gemspec')

Rake::GemPackageTask.new(spec) do
end


Rake::RDocTask.new do |rd|
  rd.rdoc_files.include("lib/**/*.rb")
  rd.rdoc_dir = "rdoc"
end

