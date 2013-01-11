# -*- coding: utf-8 -*-
require "test/unit"
require "tempfile"
require "turn/autorun"

require_relative "../lib/tiled_tmx"

  def resources_dir
    Pathname.new(__FILE__).dirname + "resources"
  end

