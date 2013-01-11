# -*- mode: ruby; coding: utf-8 -*- 
$:.unshift(File.dirname(File.expand_path(__FILE__)))
require "lib/tiled_tmx/version"

GEMSPEC = Gem::Specification.new do |spec|

  # General things
  spec.name                  = "ruby-tmx"
  spec.summary               = "Ruby library for reading/writing TiledTMX files"
  spec.description           =<<EOF
This is a small Ruby library that allows you to
read and write the TMX files used by the
Tiled map editor (http://mapeditor.org).
EOF
  spec.version               = TiledTmx::VERSION.sub("-", ".")
  spec.author                = "Hanmac"
  spec.email                 = "hanmac@gmx.de"
  spec.homepage              = "https://github.com/Hanmac/tmx-ruby"
  spec.platform              = Gem::Platform::RUBY
  spec.required_ruby_version = ">= 1.9"

  # Dependencies
  spec.add_dependency("nokogiri")
  spec.add_dependency("rbtree")
  spec.add_development_dependency("turn")
  
  # Gem contents
  spec.files = ["README",
#                "COPYING",
                Dir["lib/**/*.rb"]].flatten

  # RDoc
  spec.extra_rdoc_files = ["README"]
  spec.rdoc_options << "-t" << "Ruby-TMX RDocs" << "-m" << "README"
end
