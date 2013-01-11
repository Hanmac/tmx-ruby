# -*- coding: utf-8 -*-

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
		
		attr_accessor :tileoffset_x,:tileoffset_y
		
		attr_accessor :spacing
		attr_accessor :margin
		
		attr_accessor :source
		
		attr_accessor :tiles
		attr_accessor :terrains
		
		attr_accessor :dtd
		
		def initialize(node = {})
			@name = node[:name]
			
			@tilewidth = node[:tilewidth].to_i
			@tileheight = node[:tileheight].to_i
			
			@spacing = node[:spacing].to_i
			@margin = node[:margin].to_i
			
			@width = node[:width].to_i unless node[:width].nil?
			@height = node[:height].to_i unless node[:height].nil?
			
			@tileoffset_x = node[:tileoffset_x].to_i
			@tileoffset_y = node[:tileoffset_y].to_i
			
			super
			@tiles = RBTree.new
			@terrains = []
		end
		
		def draw(id,x,y,z,opacity,rot,x_scale,y_scale,&block)
			raise NotImplementedError.new("need to add #draw function")
		end

		def initialize_copy(old)
			super
			@tiles = Marshal::load(Marshal::dump(old.tiles))
			@terrains = Marshal::load(Marshal::dump(old.terrains))
			old_source = old.source
			@source = old_source ? old_source.dup : nil
		end

    # Returns the position of the tile specified by +id+
    # on the tileset graphic, in pixels. +id+ is starts at
    # 0 for the top-left tile and ends at +num_tiles+ at
    # the bottom-right tile. Return value is a two-element
    # array of form [x, y] or returns nil if +id+ is out of bounds.

		def tile_position(id)
			width , height  = dimension
			
			return nil if id >= width * height
			x = id % width
			y = id / width

			[x,y].zip([@tilewidth,@tileheight]).map {|c,l| c * (l + @spacing) + @margin }
		end
		
		def dimension
			[@width,@height].zip([@tilewidth,@tileheight]).map {|s,l| (s - @margin * 2 + @spacing) / (l + @spacing)}
		end
		
		def num_tiles
			dimension.inject(:*)
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
				xml.tileoffset(:x=>@tileoffset_x,:y=>@tileoffset_y) unless @tileoffset_x.zero? && @tileoffset_y.zero?
				xml.image(:source=>@source ? @source.relpath : "",:width=>@width,:height=>@height)
				xml.terraintypes {
					@terrains.each  {|v|v.to_xml(xml)}
				} unless @terrains.empty?
				@tiles.each_value {|v|v.to_xml(xml)}
			}
		end
		
		def external?
			return Tileset.sets.has_value?(self)
		end
		
		def external!(path, opts = {})
		
			@dtd = opts.has_key?(:dtd) ? opts[:dtd] : @dtd
			path = Pathname.new(path).expand_path
			builder = Nokogiri::XML::Builder.new(:encoding => opts[:encoding] || 'UTF-8') do |xml|
				xml.doc.create_internal_subset("tileset",nil,"http://mapeditor.org/dtd/1.0/map.dtd") if @dtd
				to_xml(xml)
			end
			File.write(path,builder.to_xml(:indent => INDENT))
			Tileset.sets[path] = self
			return self
		end
		
		def external(path, opts = {})
			return dup.external!(path,opts)
		end
		
		
		@sets = {}
		class << self
			attr_accessor :sets

      # Loads a tileset from either an XML node or an external TSX file.
      # == Parameter
      # [node]
      #   A Nokogiri::XML::Node describing the tileset’s toplevel node
      #   inside a map file *or* a String/Pathname pointing to a TSX
      #   file to load.
      # == Return value
      # A new Tileset instance.
      # == Remarks
      # This method honours the concept of "internal" and "external"
      # tilesets, where an "internal" tileset is part of a map
      # definition and an "external" one is only referenced inside
      # a map. If you pass +node+ as an XML node (which is done
      # internally when loading a map from a file containing an
      # inline tileset definition in Map::load_xml) the constructed
      # Tileset instance will be marked as an "internal" tileset,
      # i.e. if added to a Map instance, the full tileset definition
      # will be written out into the map XML. Otherwise, +node+
      # is assumed to be a path to an "external" tileset, which will
      # be loaded and the resulting instance will be marked as "external".
			def load_xml(node)
				if(!node.is_a?(Nokogiri::XML::Node))
					s = Pathname.new(node.to_s)
					if(!@sets.include?(s))
						root = Nokogiri::XML(File.read(s)).root
						temp = load_xml(root)
						temp.dtd = !!root.internal_subset
						@sets[s] = temp
					end
					return @sets[s]
				end
				temp = new(node)
				
				if offset = node.xpath("tileoffset")[0]
					temp.tileoffset_x = offset[:x].to_i
					temp.tileoffset_y = offset[:y].to_i
				end
				
				if image = node.xpath("image")[0]
					temp.width = image[:width].to_i
					temp.height = image[:height].to_i
					temp.source = Path.new(image[:source].to_s,node)
				end
				
				temp.terrains = node.xpath("terraintypes/terrain").map {|obj| Terrain.load_xml(obj)}
				
				temp.load_xml_properties(node)
				
				node.xpath("tile").each {|obj|
					temp.tiles[obj[:id].to_i]=Tile.load_xml(obj)
				}
				return temp
			end
		end
	end
end
