# -*- coding: utf-8 -*-
module TiledTmx
	module PropertySet
		attr_accessor :properties
		
		def initialize(*)
			@properties = {}
		end
		def initialize_copy(old)
			super
			@properties = Marshal::load(Marshal::dump(old.properties))
		end
		
		def load_xml_properties(node)
			p self unless @properties
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
