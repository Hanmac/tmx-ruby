# -*- coding: utf-8 -*-
require_relative "helpers"

class MapTest < Test::Unit::TestCase

	include TiledTmx


	def test_creation
		map = Map.new

		assert_empty(map.properties)
		assert_empty(map.layers.to_a)
		assert_empty(map.tilesets.to_a)
	end
	def test_first_gid
		map = Map.new(:tileheight => 32,
					:tilewidth => 32)
		assert_equal(1,map.next_first_gid)
		
		map.add_tileset(:width=>256, :height=>576) #use tilesize from the map
		
		assert_equal(145, map.next_first_gid) # 144 tiles
		
	end
	def test_layers
		map = Map.new(:width=>256, :height=>576,:tileheight => 32,
					:tilewidth => 32)
		tilelayer = map.add_layer(:tile)
		tilelayer = map.add_layer(:tile)
		object_group = map.add_layer(:objectgroup)
		map.add_layer(:imagelayer)
		
		assert_equal(4, map.layers.count)
		
		assert_equal(2, map.layers(TileLayer).count)
		assert_equal(1, map.layers(ObjectGroup).count)
		assert_equal(1, map.layers(ImageLayer).count)
		
		assert_equal(2, map.layers(:tile).count)
		assert_equal(1, map.layers(:objectgroup).count)
		assert_equal(1, map.layers(:imagelayer).count)
		
		assert_equal(TileLayer, map.get_layer(0).class)
		assert_equal(TileLayer, map.get_layer(1).class)
		assert_equal(ObjectGroup, map.get_layer(2).class)
		assert_equal(ImageLayer, map.get_layer(3).class)
		
		4.times {|i|assert_equal(map, map.get_layer(i).map)}
		
		assert_equal(3, map.get_layer_index(map.get_layer(3)))
		assert_equal(3, map.get_layer_index{|l|l.class == ImageLayer})
		assert_equal(3, map.get_layer(3).index)
		
		
	end
	def test_tilelayer
		map = Map.new(:width=>8, :height=>18,:tileheight => 32,
					:tilewidth => 32)
		tilelayer = map.add_layer(:tile)
		
		assert_equal(144, tilelayer[0..-1].size)
		
	end
	
	def test_object_group
		map = Map.new(:width=>8, :height=>18,:tileheight => 32,
					:tilewidth => 32)
		object_group = map.add_layer(:objectgroup)
		
		assert_empty(object_group.each.to_a)
		
		obj1 = TiledTmx::Object.new(:name =>"name",:type=>"type")
		obj1.points_string = "1,2 3,4" #[TiledTmx::Object::Point.new(1,2),TiledTmx::Object::Point.new(3,4)]
		obj2 = TiledTmx::Object.new(:name =>"name",:type=>"type")
		obj2.points_string = "1,2 3,4" #[TiledTmx::Object::Point.new(1,2),TiledTmx::Object::Point.new(3,4)]
		object_group.objects << obj1 << obj2
		
		assert_not_empty(object_group.each.to_a)
		assert_equal(2,object_group.each.count)
		
		dupped = object_group.dup

		assert_not_empty(dupped.each.to_a)
		assert_equal(2,dupped.each.count)

		obj = object_group.objects[0]
		dupped_obj = dupped.objects[0]
		assert_not_equal(object_group.objects[0].object_id,dupped_obj.object_id)
		
		
		
		assert_equal(obj.points,dupped_obj.points)
		assert_equal(obj.points[0],dupped_obj.points[0])
		assert_not_equal(obj.points[0].object_id,dupped_obj.points[0].object_id)
		
		
		assert_equal(1,obj.points[0].x)
		assert_equal(2,obj.points[0].y)
		assert_equal(3,obj.points[1].x)
		assert_equal(4,obj.points[1].y)
	end
end
