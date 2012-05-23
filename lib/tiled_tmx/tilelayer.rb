require_relative "layer"
module TiledTmx
	class TileLayer < Layer

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
