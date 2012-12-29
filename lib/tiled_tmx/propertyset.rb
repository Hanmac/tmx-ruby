# -*- coding: utf-8 -*-
module TiledTmx
	module PropertySet
		attr_accessor :properties
		
		def initialize(*)
			@properties = {}
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
