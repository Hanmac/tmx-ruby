# -*- coding: utf-8 -*-
module TiledTmx
	INDENT = 1
	class Map
		include PropertySet
		attr_accessor :properties
		attr_accessor :tilesets
		attr_accessor :layers #[layers]
		
		attr_accessor :orientation
		
		attr_accessor :height,:width

		attr_accessor :tilewidth
		attr_accessor :tileheight

		attr_accessor :dtd

		def initialize(node = {})
			@height = node[:height].to_i
			@width = node[:width].to_i
			@tileheight = node[:tileheight].to_i
			@tilewidth = node[:tilewidth].to_i
			
			@orientation = (node[:orientation] || :orthogonal).to_sym
			
			@tilesets={}
			@layers = []
			super
		end
		def draw(x,y,z,x_scale = 1, y_scale = 1,&block)
			@layers.each_with_index{|obj,z_off|
				obj.draw(self,x,y,z+z_off,x_scale,y_scale,&block) if obj.visible
			}
		end

		#Loads a TMX map from a file.
		#==Parameter
		#[pathname] The path to load from. Either a string or a
		#           Pathname object.
		#==Return value
		#An instance of this class.
		def self.load_xml(pathname)
			
			doc = File.open(pathname) { |io| Nokogiri::XML(io) }
			#p doc.validate
			root = doc.root
			
			temp = new(root)
			

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
			
			temp.load_xml_properties(root)
			
			temp.dtd = !!root.internal_subset
			return temp
		end

		#call-seq:
		#	 to_xml()     → a_string
		#	 to_xml(path)
		#
		#Writes out the TMX map as XML markup.
		#==Parameter
		#[path] (nil) Currently ignored.
		#==Return value
		#In the first form without +path+, returns a UTF-8-encoded string
		#containing the XML markup for the TMX map. The second form
		#doesn’t return anything important as the XML is directly written
		#to a (UTF-8-encoded) file.
		def to_xml(path=nil)
			builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
				xml.doc.create_internal_subset("map",nil,"http://mapeditor.org/dtd/1.0/map.dtd") if @dtd
				xml.map(
					:version => "1.0",
					:orientation=>@orientation,
					:width=>@width,
					:height=>@height,
					:tilewidth=>@tilewidth,
					:tileheight=>@tileheight) {
					
					to_xml_properties(xml)
					@tilesets.each {|k,v|
						s=Tileset.sets.key(v)
						if(!s.nil?)
							source = path.nil? ? s : s.relative_path_from(Pathname.new(path).dirname.expand_path)
							xml.tileset(:firstgid => k,:source=>source)
						else
							v.to_xml(xml,k)
						end
					}
					@layers.each{|obj| obj.to_xml(xml)}
				}
			end

			return builder.to_xml(:indent => INDENT)
		end
	end
	
end
