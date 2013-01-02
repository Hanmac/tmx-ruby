# -*- coding: utf-8 -*-
module TiledTmx
	class TileLayer < Layer

    # This bit is set if a tile is supposed to be flipped
    # diagonally.
    FLIPPED_DIAGONALLY_FLAG   = 2 << 28;
    # This bit is set if a tile is supposed to be flipped
    # horizontally.
    FLIPPED_HORIZONTALLY_FLAG = 2 << 29;
    # This bit is set if a tile is supposed to be flipped
    # vertically.
    FLIPPED_VERTICALLY_FLAG   = 2 << 30;

		attr_accessor :encoding
		attr_accessor :compression
		
		def initialize(map,node = {})
			@data = Array.new(map.width*map.height,0)
			super
		end
		
		def initialize_copy(old)
			super
			@data = old[0..-1]
		end
		
		def [](i)
			return @data[i]
		end
		def []=(i,value)
			return @data[i]=value
		end

		#
		def map=(value)
			super
			return value unless map
			size = @map.width*@map.height
			@data = @data[0,size]
			@data[size - 1] ||= 0
			@data.map! {|id|id || 0}
			return value
		end

		def data
			case @encoding
			when "csv"
				width = @map ? @map.width : @data.size
				temp = @data.each_slice(width).map{|s|s.join(",")}.join(",\n")
			when nil
				temp = @data
			else
				temp = @data.pack("V*")
			end
			case @compression
			when "zlib"
				require "zlib"
				temp = Zlib::Deflate.deflate(temp)
			when "gzip"
				require "zlib"
				require "stringio"
				string = ""
				Zlib::GzipWriter.wrap(StringIO.new(string)){|gz|gz.write(temp) }
				temp = string
			end
			if @encoding == "base64"
				require "base64"
				temp = "\n" + (" " * INDENT * 3) + Base64.encode64(temp).gsub("\n","") + "\n" + (" " * INDENT * 2)
			else
				temp = "\n#{temp}\n"
			end
			return temp
		end
		def data=(temp)
			if @encoding == "base64"
				require "base64"
				temp = Base64.decode64(temp)
			end
			case @compression
			when "zlib"
				require "zlib"
				temp = Zlib::Inflate.inflate(temp)
			when "gzip"
				require "zlib"
				require "stringio"
				temp = Zlib::GzipReader.wrap(StringIO.new(temp),&:read)
			end
			case @encoding
			when "csv"
				@data = temp.split(",").map(&:to_i)
			when nil
				@data = temp
			else
				@data = temp.unpack("V*")
			end
			return temp
		end

    # call-seq:
    #   each_tile(map)                                                → an_enumerator
    #   each_tile(map){|x, y, tile, tileset, relative_id, flips| ...}
    #
    # Map the layer onto +map+ and iterate over the result.
    # == Parameter
    # [map]
    #   The TiledTmx::Map object you want to map this layer onto.
    #   Th		def initialize(map, node = {})is is required, because a Layer doesn’t know about its
    #   height and width, which must therefore be taken from a
    #   map. However, as a Layer also doesn’t know about any maps,
    #   we must request this object to use it for the height and
    #   width. values.
    # [x (block)]
    #   The current X coordinate (in map fields).
    # [y (block)]
    #   The current Y coordinate (in map fields).
    # [tile]
    #   The Tileset::Tile object for that coordinate on this layer.
    #   +nil+ is this is an empty field.
    # [relative_id]
    #   The index of +tile+ in the +tileset+, starting at 1.
    # [tileset]
    #   The Tileset object the +tile+ belongs to. +nil+ if this is
    #   an empty field.
    # [flips]
    #   A hash with three keys: :diagonal, :horizontal, :vertical.
    #   If the corresponding value is +true+, this means to flip the
    #   tile graphic around accordingly. If this is an emtpy field,
    #   all values are guaranteed to be +false+.
    # == Return value
    # Undefined, if a block is given. An Enumerator otherwise.
    def each_tile(map)
      return enum_for(__method__) unless block_given?

      @data.each_with_index do |gid, index|
        # Determine the coordinates. For X, we count in groups of the map width,
        # resetting the counter to 0 when we reach the map width. When we reach
        # the current position in the `data' array (the array of tiles), the value
        # of the counter is the X coordinate. This count-up-and-reset-to-zero simply
        # is a modulo operation.
        # The Y coordinate is a bit tricker. Each time we counted a full-width group,
        # we increment a second counter (which also starts at 0). When we reach the
        # current position in the `data' array, the value of that second counter is
        # our Y coordinate. And, guess it? This is a simple division.
        # We than need to take care to get correct numbers. Array indexing starts
        # at 0, but dividing/moduling by 0 is bad. ?
        x = index % map.width
        y = index / map.width

        # If the GID is zero, this means this tile is empty.
        # We therefore just skip all the style calculations
        # below.
        if gid.zero?
          yield(x, y, nil, nil, {:diagonal => false, :horizontal => false, :vertical => false})
          next
        end

        # Diagonal, horizontal, and vertical flipping
        flips = {}
        flips[:diagonal]   = !(gid & FLIPPED_DIAGONALLY_FLAG).zero?
        flips[:horizontal] = !(gid & FLIPPED_HORIZONTALLY_FLAG).zero?
        flips[:vertical]   = !(gid & FLIPPED_VERTICALLY_FLAG).zero?

        # Clear the flag bits out as stated by the TMX format docs
        gid &= ~(FLIPPED_DIAGONALLY_FLAG | FLIPPED_HORIZONTALLY_FLAG | FLIPPED_VERTICALLY_FLAG)

        # Now `gid' contains solely the tileset position information. Use it to
        # find the first tileset whose first global ID is smaller or equal to
        # the global ID of the tile `gid' represents.
        tileset_gid = map.each_tileset_key.sort.reverse.find{|first_gid| first_gid <= gid}
        raise("Cannot resolve tileset GID: #{tileset_gid}!") unless tileset_gid
        tileset = map.get_tileset(tileset_gid)
        # The tile IDs inside the tileset are relative to 0, but the GID we
        # have for our tile is global for all tilesets. As we already determined
        # which tileset it specifies above, we can just convert the absolute GID
        # into a one relative to the determined tileset by removing the absolute
        # part from it.
        relative_id = gid - tileset_gid
        tile = tileset.tiles[relative_id]

        # Tell our customer
        yield(x, y, tile, relative_id, tileset, flips)
      end
    end
		
		def draw(map,x_off,y_off,z_off,x_scale,y_scale,&block)
			each_tile(map){|x, y, tile, relative_id, tileset, flips|
				
				next if tileset.nil?
				x = x_off + map.tilewidth*x*x_scale 
				y = y_off + map.tileheight*y*y_scale - tileset.tileheight + map.tileheight
				
				z = z_off
				
				z_prop = @properties["z"]
				z = z_prop.to_i if(z_prop)
				
				if(tile)
					z_prop = tile.properties["z"]
					if(z_prop)
						if z_prop[0]=='+'
							z += z_prop.to_i
						elsif z_prop[0]=='-'
							z -= z_prop.to_i
						else
							z = z_prop.to_i
						end
					end
				end
				tileset.draw(relative_id,
					x,y, z, opacity, flips[:diagonal] ? 180 : 0,
					x_scale * (flips[:vertical] ? -1 : 1),
					y_scale * (flips[:horizontal] ? -1 : 1),&block)
			}
		end
		
		
		def self.load_xml(map,node)
			temp = super
			
			temp.encoding = node.xpath("data")[0][:encoding]
			temp.compression = node.xpath("data")[0][:compression]
			if (temp.encoding.nil?)
				temp.data = node.xpath("data/tile").map {|t| t[:gid].to_i}
			else
				temp.data = node.xpath("data").text
			end
			return temp
		end
		
		def to_xml(xml)

			xml.layer {
				super
				
				hash = {}
				hash[:encoding]=@encoding unless @encoding.nil?
				hash[:compression]=@compression unless @compression.nil?
				xml.data(hash,data)
			}
		end
	end
end
