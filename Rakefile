# -*- mode: ruby; coding: utf-8 -*-
require "rake"
require "rubygems/package_task"
require "rdoc/task"
load "ruby-tmx.gemspec"

RDoc::Task.new do |rt|
  rt.title = "Ruby-TMX RDocs"
  rt.main  = "README"
  rt.rdoc_files.include("README",
#                        "COPYING",
                        "lib/**/*.rb")
end

Gem::PackageTask.new(GEMSPEC).define
