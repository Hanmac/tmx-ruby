# -*- mode: ruby; coding: utf-8 -*-
require "rake"
require "rubygems/package_task"
require "rdoc/task"

desc "Run the test suite."
task :test do
  cd "tests" do
    Dir["test_*.rb"].each do |file|
      load(file)
    end
  end
end

RDoc::Task.new do |rt|
  rt.title = "Ruby-TMX RDocs"
  rt.main  = "README"
  rt.rdoc_files.include("README",
#                        "COPYING",
                        "lib/**/*.rb")
end

load "ruby-tmx.gemspec"
Gem::PackageTask.new(GEMSPEC).define
