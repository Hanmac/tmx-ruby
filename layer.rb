module TiledTmx
	class Layer
	
	
		attr_accessor :properties
		
		attr_accessor :name
		
		attr_accessor :opacity
		attr_accessor :visible
		
		def initialize
			@opacity = 1.0
			@visible = true
			@properties = {}
		end
		def self.load_xml(node,obj)
			
			obj.name = node[:name]
			obj.opacity = node[:opacity].to_f unless node[:opacity].nil?
			obj.visible = node[:visible] != "0"
			
			node.xpath("properties/property").each {|prop|
				obj.properties[prop[:name]]=prop[:value]
			}
			
			return obj
		end
		
		def to_xml(xml)
			parent = xml.parent
			parent[:name]=@name
			parent[:width]=parent.parent[:width]
			parent[:height]=parent.parent[:height]
			parent[:visible]=0 unless @visible
			parent[:opacity]=@opacity unless @opacity == 1.0

			xml.properties {
				@properties.each {|k,v|
					xml.property(:name =>k,:value =>v)
				}
			} unless @properties.nil?
		end
	end
end
