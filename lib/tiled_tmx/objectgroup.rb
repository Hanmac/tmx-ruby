require_relative "layer"

module TiledTmx
	class Object
		class Point
			attr_accessor :x, :y
			def initialize(x,y)
				@x=x
				@y=y
			end
			def inspect
			 return "#<#{self.class}:{#{self}}>"
			end
			def to_s
				return "#{x},#{y}"
			end
		end
		
		include PropertySet
		
		attr_accessor :name
		attr_accessor :type
		attr_accessor :gid
		attr_accessor :x
		attr_accessor :y
		
		attr_accessor :width
		attr_accessor :height
		
		attr_accessor :polygon
		attr_accessor :polyline
		def initialize
			@polygon = []
			@polyline = []
		end
		
		def draw(map,x_off,y_off,z_off,color,opacity,x_scale,y_scale)
				z = z_off
				
				z_prop = @properties["z"]
				z = z_prop.to_i if(z_prop)

			if !gid.nil?
				set = map.tilesets.inject(nil){|m,(k,v)| k > @gid ? m : v}
				return if set.nil?
				id = @gid - map.tilesets.key(set)
				
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
					x_off + @x*x_scale, y_off + (@y - set.tileheight)*y_scale,
					z,opacity,0,x_scale,y_scale)
			elsif !@polygon.empty?
#				#TODO the triangle drawing is not perfect if the polygon is concav
#				#each_cons(3)
#				(@polygon + [@polygon[0]]).each_with_index.group_by{|obj,i|i / 3}.each_value{|k|
#				k.map {|(v,i)|v}.tap{|(a,b,c)|
#					draw_triangle(
#						x_off+(x+a.x)*x_scale,y_off+(y+a.y)*y_scale,
#						x_off+(x+b.x)*x_scale,y_off+(y+b.y)*y_scale,
#						x_off+(x+c.x)*x_scale,y_off+(y+c.y)*y_scale,
#						z_off,color,opacity
#					)
#				}
#				}
			elsif !@polyline.empty?
				@polyline.each_cons(2).each {|a,b|
					draw_line(
					(@x+a.x)*x_scale+x_off,(@y+a.y)*y_scale+y_off,
					(@x+b.x)*x_scale+x_off,(@y+b.y)*y_scale+y_off,
					z_off,color,opacity)
				}
			elsif !@width.nil? && !@height.nil?
				draw_rect(
					x_off+@x*x_scale,
					y_off+@y*y_scale,
					x_off+(@x+@width)*x_scale,
					y_off+(@y+@height)*y_scale,
					z_off,color,opacity
				)
			end
		end
		def draw_line(x1,y1,x2,y2,z,color,opacity)
			raise NotImplementedError.new("need to add #draw_line function")
		end
		def draw_triangle(x1, y1, x2, y2, x3, y3, z,color,opacity)
			raise NotImplementedError.new("need to add #draw_triangle function")
		end
		def draw_rect(x1,y1,x2,y2,z,color,opacity)
			raise NotImplementedError.new("need to add #draw_rect function")
		end

		def self.load_xml(node)
			temp = new
			temp.name = node[:name]
			temp.type = node[:type]
			
			temp.gid = node[:gid].nil? ? nil : node[:gid].to_i
			temp.width = node[:width].nil? ? nil : node[:width].to_i
			temp.height = node[:height].nil? ? nil : node[:height].to_i
			
			temp.x = node[:x].to_i
			temp.y = node[:y].to_i
			
			temp.load_xml_properties(node)
			
			node.xpath("polygon").each{|obj|
				obj["points"].split(" ").each {|cord|
					temp.polygon << Point.new(*cord.split(",").map(&:to_i))
				}
			}
			node.xpath("polyline").each{|obj|
				obj["points"].split(" ").each {|cord|
					temp.polyline << Point.new(*cord.split(",").map(&:to_i))
				}
			}
			return temp
		end
		def to_xml(xml)
			hash = {}
			hash[:name]=@name unless @name.nil?
			hash[:type]=@type unless @type.nil?
			hash[:gid]=@gid unless @gid.nil?
			hash[:width]=@width unless @width.nil?
			hash[:height]=@height unless @height.nil?
			
			xml.object(hash.merge({:x=>@x,:y=>@y})) {
				to_xml_properties(xml)
				if !@polygon.empty?
					xml.polygon(:points=>@polygon.map(&:to_s).join(" "))
				elsif !@polyline.empty?
					xml.polyline(:points=>@polyline.map(&:to_s).join(" "))
				end
			}
		end
	end

	class ObjectGroup < Layer
		include Enumerable
		
		attr_accessor :color
		attr_accessor :objects
		
		
		def initialize(node = {})
			super
			@objects = {}
			@color = node[:color] unless node[:color].nil?
		end
		
		def each(&block)
			return to_enum(__method__) unless block_given?
			@objects.each(&block)
			return self
		end
		
		def draw(map,x_off,y_off,z_off,x_scale,y_scale)
				z = z_off
				
				z_prop = @properties["z"]
				z = z_prop.to_i if(z_prop)

			@objects.each {|obj| obj.draw(map,x_off,y_off,z,color,opacity,x_scale,y_scale) }
		end

		def self.load_xml(node)
			temp = super
			
			temp.objects = node.xpath("object").map {|obj| Object.load_xml(obj)}
			return temp
		end
		
		def to_xml(xml)
			hash = {}
			hash[:color]=@color unless @color.nil?
			xml.objectgroup(hash) {
				super
				@objects.each{|o| o.to_xml(xml) }
			}
		end
	end
end
