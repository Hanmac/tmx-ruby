# -*- coding: utf-8 -*-
module TiledTmx
	module PropertySet
		attr_accessor :properties
		
		def initialize(*args)
			node = args.last
			@properties = RBTree.new
			if(node)
				prop = node[:properties] || node["properties"]
				prop.each {|k,v| @properties[k] = v } if prop.respond_to?(:each)
			end
		end
		
		def initialize_copy(old)
			super
			@properties = Marshal::load(Marshal::dump(old.properties))
		end
		
		def load_xml_properties(node)
			node.xpath("properties/property").each {|obj|
				@properties[obj[:name]]=obj[:value]
			}
		end
		
		def to_xml_properties(xml)
			xml.properties {
				@properties.each {|k,v|
					xml.property(:name =>k,:value =>v)
				}
			} unless @properties.empty?
		end
	end
end
