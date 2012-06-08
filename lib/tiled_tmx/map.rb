# -*- coding: utf-8 -*-
module TiledTmx
	class Map
		attr_accessor :properties
		attr_accessor :tilesets
		attr_accessor :layers #[layers]
		
		attr_accessor :orientation
		
		attr_accessor :height,:width

		attr_accessor :tilewidth
		attr_accessor :tileheight

		def initialize
			@tilesets={}
			@layers = []
			@properties = {}
		end
		def draw(x,y,z,x_scale = 1, y_scale = 1,&block)
			@layers.each_with_index{|obj,z_off|
				obj.draw(self,x,y,z+z_off,x_scale,y_scale,&block)
			}
		end
		
		def self.load_xml(pathname)
			root = File.open(pathname) { |io| Nokogiri::XML(io).root }
			temp = new
			
			temp.height = root[:height].to_i
			temp.width = root[:width].to_i
			
			temp.tileheight = root[:tileheight].to_i
			temp.tilewidth = root[:tileheight].to_i
			
			temp.orientation = root[:orientation].to_sym
			
			root.xpath("tileset").each {|node|
				if(node[:source].nil?)
					tileset = Tileset.load_xml(node)
				else
					tileset = Tileset.load_xml(Path.new(node[:source],node))
				end
				temp.tilesets[node[:firstgid].to_i]=tileset
			}
			layertypes = {
				"layer" => TileLayer,
				"objectgroup" => ObjectGroup,
				"imagelayer" => ImageLayer
			}
			
			root.xpath(layertypes.keys.join("|")).each {|node|
				temp.layers << layertypes[node.name].load_xml(node)
			}
			
			root.xpath("properties/property").each {|obj|
				temp.properties[obj[:name]]=obj[:value]
			}
			return temp
		end

		#call-seq:
		#	 to_xml()     → a_string
		#	 to_xml(path)
		#
		#Writes out the TMX map as XML markup.
		#==Parameter
		#[path] (nil) If a string or Pathname object, open this file
		#       and dump the XML markup into that file. If nil, just
		#       return the XML as a string.
		#==Return value
		#In the first form without +path+, returns a UTF-8-encoded string
		#containing the XML markup for the TMX map. The second form
		#doesn’t return anything important as the XML is directly written
		#to a (UTF-8-encoded) file.
		def to_xml(path=nil)
			builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
				xml.map(
					:version => "1.0",
					:orientation=>@orientation,
					:width=>@width,
					:height=>@height,
					:tilewidth=>@tilewidth,
					:tileheight=>@tileheight) {
					
					xml.properties {
						@properties.each {|k,v|
							xml.property(:name =>k,:value =>v)
						}
					} unless @properties.nil?
					@tilesets.each {|k,v|
						s=Tileset.sets.key(v)
						if(!s.nil?)
							xml.tileset(:firstgid => k,:source=>s)
						else
							v.to_xml(xml,k)
						end
					}
					@layers.each{|obj| obj.to_xml(xml)}
				}
			end

			if path
				File.open(path, "w"){|f| f.write(builder.to_xml)}
			else
				builder.to_xml
			end
		end
	end
	
end
