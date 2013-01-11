# -*- coding: utf-8 -*-
require_relative "helpers"

class TilelayerTest < Test::Unit::TestCase

	include TiledTmx

	def test_creation
		#default value
		layer = TileLayer.new(nil)
		assert_equal(true, layer.visible)
		#string param
		layer = TileLayer.new(nil,:visible => "0")
		assert_equal(false, layer.visible)
		layer = TileLayer.new(nil,:visible => "1")
		assert_equal(true, layer.visible)
		#int param
		layer = TileLayer.new(nil,:visible => 0)
		assert_equal(false, layer.visible)
		layer = TileLayer.new(nil,:visible => 1)
		assert_equal(true, layer.visible)
		#bool param
		layer = TileLayer.new(nil,:visible => false)
		assert_equal(false, layer.visible)
		layer = TileLayer.new(nil,:visible => true)
		assert_equal(true, layer.visible)
	end
	
	def test_iteration
		dir = resources_dir + "map.tmx"
		map = Map.load_xml(dir)
		
		check_x = 0
		check_y = 0
		map.get_layer(0).each_tile {|x,y|
			assert_equal([check_x,check_y],[x,y])
			
			check_x += 1
			if check_x == map.width
				check_x = 0
				check_y += 1
			end
		}
		
		tiles = map.get_layer(0).each_tile.with_object({}) {|(x,y,tile,id,set,flips),h| h[[x,y]]=id}
	
		assert_equal(true,map.width.times.map{|x|tiles[[x,0]]}.none?)
		
		map.width.times {|i|
			assert_equal(i,tiles[[i,1]])
		}
		
		assert_equal(true,map.width.times.map{|x|tiles[[x,2]]}.none?)
	end
end
