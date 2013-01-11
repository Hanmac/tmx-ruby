# -*- coding: utf-8 -*-
require_relative "helpers"

class TilesetTest < Test::Unit::TestCase

	include TiledTmx

	def test_creation
		set = Tileset.new(:tileheight => 32, :tilewidth => 32,
			:width=>256, :height=>576)
		
		assert_equal([8,18], set.dimension) # 144 tiles
		assert_equal(144, set.num_tiles)
		
		
		assert_equal([0,0], set.tile_position(0))
		assert_equal([32,0], set.tile_position(1))
		assert_equal([64,0], set.tile_position(2))
		assert_equal([96,0], set.tile_position(3))
		
		assert_equal(nil, set.tile_position(144))
		
		assert_equal(false, set.external?)
	end
	
	def test_spacing_and_margin
		set = Tileset.new(:tileheight => 32, :tilewidth => 32,
			:width=>133, :height=>34,
			:spacing =>1,:margin => 1)
		
		assert_equal([4,1], set.dimension) # 4 tiles
		assert_equal(4, set.num_tiles)
		
		assert_equal([1,1], set.tile_position(0))
		assert_equal([34,1], set.tile_position(1))
		assert_equal([67,1], set.tile_position(2))
		assert_equal([100,1], set.tile_position(3))
		assert_equal(nil, set.tile_position(4))
		
	end
	
	def test_external
		dir = resources_dir + "gimp.tsx"
		set = Tileset.load_xml(dir)
		assert_equal(true, set.external?)
		dupped_set = set.dup
		assert_equal(false, dupped_set.external?)

		assert_equal(set.tileheight, dupped_set.tileheight)
		assert_equal(set.tilewidth, dupped_set.tilewidth)
		assert_equal(set.width, dupped_set.width)
		assert_equal(set.height, dupped_set.height)
		assert_equal(set.source.to_s, dupped_set.source.to_s)
		
		Dir.mktmpdir do |tmpdir|
			tmpdir = Pathname.new(tmpdir)
			dupped_set.external!(tmpdir + "gimp2.tsx")
			assert_equal(true, dupped_set.external?)
		
			set = Tileset.new(:tileheight => 32, :tilewidth => 32,
				:width=>256, :height=>576)
		
			dupped_set = set.external(tmpdir + "gimp3.tsx")
			assert_equal(false, set.external?)
			assert_equal(true, dupped_set.external?)
		end
	end
	
	def test_external_with_dtd
		dir = resources_dir + "gimp.tsx"
		set = Tileset.load_xml(dir)
		assert_equal(true, set.external?)
		assert_equal(false, set.dtd)
		
		Dir.mktmpdir do |tmpdir|
			tmpdir = Pathname.new(tmpdir)
			temppath = tmpdir + "gimp3.tsx"
			dupped_set = set.external(temppath)
			assert_equal(false, dupped_set.dtd)
			
			dupped_set = set.external(temppath,:dtd => true)
			assert_equal(true, dupped_set.dtd)
			
			assert_not_equal(File.read(dir), File.read(temppath))
		end
	end
	
	def test_to_and_from_xml
		set = Tileset.new(:tileheight => 32, :tilewidth => 32,
			:width=>256, :height=>576)
		
		xml = Nokogiri::XML::Builder.new do |xml|
			set.to_xml(xml)
		end.to_xml
		
		noko=Nokogiri::XML(xml)
		
		load_set = Tileset.load_xml(noko.root)
		
		assert_equal(set.tileheight, load_set.tileheight)
		assert_equal(set.tilewidth, load_set.tilewidth)
		assert_equal(set.width, load_set.width)
		assert_equal(set.height, load_set.height)
	end

end
