# -*- coding: utf-8 -*-
module TiledTmx
	INDENT = 1
	
	LayerTypes = {
		"layer" => TileLayer,
		"tile" => TileLayer,
		"tilelayer" => TileLayer,
		"objectgroup" => ObjectGroup,
		"imagelayer" => ImageLayer
	}
	
	class Map
		include PropertySet
		#attr_accessor :tilesets
		#attr_accessor :layers #[layers]
		
		attr_accessor :orientation
		
		attr_accessor :height, :width

		attr_accessor :tileheight, :tilewidth

		attr_accessor :backgroundcolor

		attr_accessor :dtd

		def initialize(node = {})
			@height = (node[:height] || node["height"]).to_i
			@width = (node[:width] || node["width"]).to_i
			@tileheight = (node[:tileheight] || node["tileheight"]).to_i
			@tilewidth = (node[:tilewidth] || node["tilewidth"]).to_i
			
			@orientation = (node[:orientation] || node["orientation"] || :orthogonal).to_sym
			
			@backgroundcolor = (node[:backgroundcolor] || node["backgroundcolor"])
			
			@tilesets=RBTree.new
			@layers = []
			super
		end
		
		def initialize_copy(old)
			super
			@tilesets=RBTree.new
			@layers = []
			
			old.tilesets.each {|k,v|
				@tilesets[k] = v.external? ? v : v.dup
			}
			old.each_layer {|l|add_layer(l.dup)}
		end
		
		def draw(x,y,z,x_scale = 1, y_scale = 1,&block)
			@layers.each_with_index{|obj,z_off|
				obj.draw(x,y,z+z_off,x_scale,y_scale,&block) if obj.visible
			}
		end

		def add_layer(layer,opts = {})
			if(!layer.is_a?(Layer))
				layer = LayerTypes[layer.to_s].new(self,opts)
			end
			layer.map = self
			@layers << layer
			return layer
		end

		def each_layer(type = Layer)
			return to_enum(__method__,type) unless block_given?
			type = LayerTypes[type.to_s] unless type.is_a?(Class)
			@layers.each {|l|yield l if l.is_a?(type)}
			return self
		end
		
		alias_method :layers,:each_layer

		def get_layer(id)
			return @layers[id]
		end
		
		def get_layer_index(layer=nil)
			return (each_layer.with_index.find{|(l)| yield l } || [])[1] if block_given?
			return @layers.index(layer)
		end

		def each_tileset(&block)
			return to_enum(__method__) unless block_given?
			@tilesets.each(&block)
			return self
		end

		alias_method :tilesets,:each_tileset
		
		def each_tileset_key(&block)
			return to_enum(__method__) unless block_given?
			@tilesets.each_key(&block)
			return self
		end

		
		def get_tileset(first_gid)
			return @tilesets[first_gid]
		end
		
		def add_tileset(tileset={},first_gid=next_first_gid)
			if(tileset.is_a?(Hash))
				tileset={
					:tileheight => @tileheight,
					:tilewidth => @tilewidth
				}.merge!(tileset)
				tileset = Tileset.new(tileset)
			end
			@tilesets[first_gid] = tileset
			
		end
		
		def next_first_gid
			return 1 if @tilesets.empty?
			last = @tilesets.each_key.max
			return last + @tilesets[last].num_tiles
		end
		
		
		#returns tile object relative_id and tileset for a given gid
		def get_tile(gid)
			return [nil,nil,nil] if gid.zero?
			tileset_gid = each_tileset_key.reverse_each.find{|first_gid| first_gid <= gid}
			raise("Cannot resolve tileset GID: #{tileset_gid}!") unless tileset_gid
			tileset = get_tileset(tileset_gid)
			# The tile IDs inside the tileset are relative to 0, but the GID we
			# have for our tile is global for all tilesets. As we already determined
			# which tileset it specifies above, we can just convert the absolute GID
			# into a one relative to the determined tileset by removing the absolute
			# part from it.
			relative_id = gid - tileset_gid
			return [nil,nil,nil] if relative_id >= tileset.num_tiles
			tile = tileset.tiles[relative_id]
			return [tile,relative_id,tileset]
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
				temp.add_tileset(tileset,node[:firstgid].to_i)
			}
			
			root.xpath(LayerTypes.keys.join("|")).each {|node|
				temp.add_layer(LayerTypes[node.name].load_xml(temp,node))
			}
			
			temp.load_xml_properties(root)
			
			temp.dtd = !!root.internal_subset
			return temp
		end

		def self.load_json(pathname)
			hash = JSON(File.read(pathname))
			temp = new(hash)
			hash["tilesets"].each {|s|temp.add_tileset(Tileset.load_json(s,pathname),s["firstgid"])}
			hash["layers"].each{|l|temp.add_layer(l["type"],l)}
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
				
				hash = {
					:version => "1.0",
					:orientation=>@orientation,
					:width=>@width,
					:height=>@height,
					:tilewidth=>@tilewidth,
					:tileheight=>@tileheight
				}
				
				hash[:backgroundcolor] = @backgroundcolor if @backgroundcolor
				
				xml.map(hash) {
					
					to_xml_properties(xml)
					@tilesets.each {|k,v|
						
						if(v.external?)
							s=Tileset.sets.key(v)
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
