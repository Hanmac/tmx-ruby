# -*- coding: utf-8 -*-
module TiledTmx
	class Layer
		include PropertySet
		
		attr_accessor :name
		
		attr_accessor :opacity
		attr_accessor :visible
		
		def initialize(node = {})
			@name = node[:name]
			@opacity = node[:opacity].nil? ? 1.0 : node[:opacity].to_f
			
			#dont use it directly it is deplicated
			@width = node[:width].to_i
			@height = node[:height].to_i
			
			@visible = case node[:visible]
			when String
				node[:visible] != "0"
			when nil
				true
			else
				!!node[:visible]
			end
			
			super
		end
		def self.load_xml(node)
			obj = new(node)
			
			obj.load_xml_properties(node)
			
			return obj
		end
		
		def to_xml(xml)
			parent = xml.parent
			parent[:name]=@name
			parent[:width]=parent.parent[:width]
			parent[:height]=parent.parent[:height]
			parent[:visible]=0 unless @visible
			parent[:opacity]=@opacity unless @opacity == 1.0

			to_xml_properties(xml)
		end
	end
end
