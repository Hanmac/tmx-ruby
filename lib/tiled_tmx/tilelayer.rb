# -*- coding: utf-8 -*-
require_relative "layer"
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
		
		def initialize
			super
			@data = []
		end
		def [](i)
			return @data[i]
		end
		def []=(i,value)
			return @data[i]=value
		end
		def data
			temp = @data.pack("V*") if encoding
			case compression
			when "zlib"
				require "zlib"
				temp = Zlib::Deflate.deflate(temp)
			when "gzip"
				require "zlib"
				require "stringio"
				string = ""
				begin
					io = StringIO.new(string)
					gz = Zlib::GzipWriter.new(io)
					gz.write temp
				ensure
					gz.close
				end
				temp = string
			end
			if encoding == "base64"
				require "base64"
				temp = Base64.encode64(temp)
			end
			return temp
		end
		def data=(temp)
			if encoding == "base64"
				require "base64"
				temp = Base64.decode64(temp)
			end
			case compression
			when "zlib"
				require "zlib"
				temp = Zlib::Inflate.inflate(temp)
			when "gzip"
				require "zlib"
				require "stringio"
				begin
					io = StringIO.new(temp)
					gz = Zlib::GzipReader.new(io)
					temp = gz.read
				ensure
					gz.close
				end
			end
			if encoding
				@data = temp.unpack("V*")
			else
				@data = temp
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
    #   This is required, because a Layer doesn’t know about its
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
        tileset_gid = map.tilesets.keys.sort.reverse.find{|first_gid| first_gid <= gid}
        raise("Cannot resolve tileset GID: #{tileset_gid}!") unless tileset_gid
        tileset = map.tilesets[tileset_gid]
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
			return unless @visible
			@data.each_with_index do |id,i|
				next if id.zero?
				d_flag = !(id & (2 << 28)).zero?
				h_flag = !(id & (2 << 29)).zero?
				v_flag = !(id & (2 << 30)).zero?
				
				id &= ~(14 << 28)
				
				set = map.tilesets.inject(nil){|m,(k,v)| k > id ? m : v}
				next if set.nil?
				x = x_off + map.tilewidth*(i % map.width)*x_scale 
				y = y_off + map.tileheight*(i / map.width)*y_scale - set.tileheight + map.tileheight
				
				id -= map.tilesets.key(set)
				
				z = z_off
				
				z_prop = @properties["z"]
				z = z_prop.to_i if(z_prop)
				
				tile  = set.tiles[id]
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
				set.draw(id,
					x,y, z, opacity, d_flag ? 180 : 0,
					x_scale * (v_flag ? -1 : 1),
					y_scale * (h_flag ? -1 : 1),&block)
			
			end
		end
		def self.load_xml(node)
			temp = super(node,new)
			
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