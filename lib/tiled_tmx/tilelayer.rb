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
			size = map ? map.width*map.height : 0
			@data = Array.new(size,0)
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
			return value if size == @data.size
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
    #   each_tile                                                → an_enumerator
    #   each_tile{|x, y, tile, tileset, relative_id, flips| ...}
    #
    # Map the layer onto +map+ and iterate over the result.
    # == Parameter
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
    def each_tile
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
          yield(x, y, nil, nil,nil, {:diagonal => false, :horizontal => false, :vertical => false})
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
        tile, relative_id, tileset = @map.get_tile(gid)
        # Tell our customer
        yield(x, y, tile, relative_id, tileset, flips)
      end
      return self
    end
		
		def draw(x_off,y_off,z_off,x_scale,y_scale,&block)
			each_tile {|x, y, tile, relative_id, tileset, flips|
				
				next if tileset.nil?
				x = x_off + tileset.tileoffset_x + map.tilewidth*x*x_scale 
				y = y_off + tileset.tileoffset_y + map.tileheight*y*y_scale - tileset.tileheight + map.tileheight
				
				z = z_off
				
				z_prop = @properties["z"]
				z = z_prop.to_i if(z_prop)
				
				if(tile)
					z_prop = tile.properties["z"]
					if(z_prop)
						if ["+","-"].include?(z_prop[0])
							z += z_prop.to_i
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
			
			data =node.xpath("data")[0]
			temp.compression = data[:compression]
			if (temp.encoding = data[:encoding])
				temp.data = node.xpath("data").text
			else#load as data as xml
				temp.data = node.xpath("data/tile").map {|t| t[:gid].to_i}
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
