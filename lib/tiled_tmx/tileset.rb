# -*- coding: utf-8 -*-
require_relative "path"

module TiledTmx
	class Tileset

		class Tile
			attr_accessor :properties
			
			def initialize
				@properties = {}
			end
		
			def self.load_xml(node)
				temp = new
				node.xpath("properties/property").each {|obj|
					temp.properties[obj[:name]]=obj[:value]
				}
				
				return temp
			end
			
			def to_xml(xml,id)
				xml.tile(:id=>id) {
					xml.properties {
						@properties.each {|k,v|
							xml.property(:name =>k,:value =>v)
						}
					}
				}
			end
		end


		attr_accessor :properties
		
		attr_accessor :name
		
		attr_accessor :tilewidth
		attr_accessor :tileheight
		
		attr_accessor :width
		attr_accessor :height
		
		attr_accessor :spacing
		attr_accessor :margin
		
		attr_accessor :source
		
		attr_accessor :tiles
		def initialize
			@properties = {}
			@tiles = {}
		end
		
		def draw(id,x,y,z,opacity,rot,x_scale,y_scale,&block)
			raise NotImplementedError.new("need to add #draw function")
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
				:tileheight=>@tileheight,
				:spacing=>@spacing, :margin=>@margin)
			
			xml.tileset(hash) {
				xml.properties {
					@properties.each {|k,v|
						xml.property(:name =>k,:value =>v)
					}
				}
				xml.image(:source=>@source.relpath,:width=>@width,:height=>@height)
				@tiles.each {|k,v|v.to_xml(xml,k)}
			}
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
				temp = new
				temp.name = node[:name]
				
				temp.tilewidth = node[:tilewidth].to_i
				temp.tileheight = node[:tileheight].to_i
				
				temp.width = node.xpath("image")[0][:width].to_i
				temp.height = node.xpath("image")[0][:height].to_i
				
				temp.spacing = node[:spacing].to_i
				temp.margin = node[:margin].to_i
				
				node.xpath("properties/property").each {|obj|
					temp.properties[obj[:name]]=obj[:value]
				}
			
				temp.source = Path.new(node.xpath("image")[0][:source],node)
			
				node.xpath("tile").each {|obj|
					temp.tiles[obj[:id].to_i]=Tile.load_xml(obj)
				}
				return temp
			end
		end
	end
end
