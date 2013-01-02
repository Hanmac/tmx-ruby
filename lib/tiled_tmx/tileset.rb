# -*- coding: utf-8 -*-
require_relative "path"

module TiledTmx
	class Tileset
		include PropertySet
		class Terrain
			include PropertySet
			
			attr_accessor :name
			attr_accessor :tile
			
			def initialize(node = {})
				@name = node[:name]
				@tile = (o = node[:tile]).nil? ? nil : o.to_i
				super
			end
			
			def self.load_xml(node)
				temp = new(node)
				temp.load_xml_properties(node)
				
				return temp
			end
			
			def to_xml(xml)
				hash = {:name => @name}
				hash[:tile] = @tile if @tile
				xml.terrain(hash) {
					to_xml_properties(xml)
				}
			end
		end
		class Tile
			include PropertySet
			
			attr_accessor :id
			attr_accessor :terrain
			
			def initialize(node = {})
				@id = node[:id].to_i
				
				if(terrain = node[:terrain])
					@terrain = terrain.split(",",-1).map {|i| i.empty? ? nil : i.to_i}
				else
					@terrain = []
				end
				super
			end
			
			
			def self.load_xml(node)
				temp = new(node)
				temp.load_xml_properties(node)
				
				return temp
			end
			
			def to_xml(xml)
				hash = {:id => @id}
				hash[:terrain] = @terrain.join(",") unless @terrain.empty?
				
				xml.tile(hash) {
					to_xml_properties(xml)
				}
			end
		end

		
		attr_accessor :name
		
		attr_accessor :tilewidth
		attr_accessor :tileheight
		
		attr_accessor :width
		attr_accessor :height
		
		attr_accessor :spacing
		attr_accessor :margin
		
		attr_accessor :source
		
		attr_accessor :tiles
		attr_accessor :terrains
		
		def initialize(node = {})
			@name = node[:name]
			
			@tilewidth = node[:tilewidth].to_i
			@tileheight = node[:tileheight].to_i
			
			@spacing = node[:spacing].to_i
			@margin = node[:margin].to_i
			
			super
			@tiles = {}
			@terrains = []
		end
		
		def draw(id,x,y,z,opacity,rot,x_scale,y_scale,&block)
			raise NotImplementedError.new("need to add #draw function")
		end

		def initialize_copy(old)
			super
			@tiles = Marshal::load(Marshal::dump(old.tiles))
			@terrains = Marshal::load(Marshal::dump(old.terrains))
			@source = old.source.dup
		end

    # Returns the position of the tile specified by +id+
    # on the tileset graphic, in pixels. +id+ is starts at
    # 1 for the top-left tile and ends at width*height at
    # the bottom-right tile. Return value is a two-element
    # array of form [x, y].
    #
    # FIXME: This method should take @spacing and @margin
    # into account.
    def tile_position(id)
      width  = @width / @tilewidth
      height = @height / @tileheight

      x = id % width
      y = id / width

      [x * @tilewidth, y * @tileheight]
    end
		
		def to_xml(xml,k=nil)
			
			hash = {}
			hash[:firstgid]= k unless k.nil?
			
			hash.merge!(:name=>@name,
				:tilewidth=>@tilewidth,
				:tileheight=>@tileheight)
			
			hash[:spacing] = @spacing unless @spacing.zero?
			hash[:margin] = @margin unless @margin.zero?
			
			xml.tileset(hash) {
				to_xml_properties(xml)
				xml.image(:source=>@source.relpath,:width=>@width,:height=>@height)
				xml.terraintypes {
					@terrains.each  {|v|v.to_xml(xml)}
				} unless @terrains.empty?
				@tiles.each_value {|v|v.to_xml(xml)}
			}
		end
		
		def external?
			return Tileset.sets.has_value?(self)
		end
		
		@sets = {}
		class << self
			attr_accessor :sets
			def load_xml(node)
				if(!node.is_a?(Nokogiri::XML::Node))
					s = Pathname.new(node.to_s)
					if(!@sets.include?(s))
						@sets[s]=load_xml(
							File.open(s) { |io| Nokogiri::XML(io).root}
						)
					end
					return @sets[s]
				end
				temp = new(node)
				
				temp.width = node.xpath("image")[0][:width].to_i
				temp.height = node.xpath("image")[0][:height].to_i
				
				temp.terrains = node.xpath("terraintypes/terrain").map {|obj| Terrain.load_xml(obj)}
				
				temp.load_xml_properties(node)
			
				temp.source = Path.new(node.xpath("image")[0][:source],node)
			
				node.xpath("tile").each {|obj|
					temp.tiles[obj[:id].to_i]=Tile.load_xml(obj)
				}
				return temp
			end
		end
	end
end
