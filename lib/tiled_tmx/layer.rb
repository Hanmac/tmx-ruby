# -*- coding: utf-8 -*-
module TiledTmx
	class Layer
		include PropertySet
		
		attr_accessor :name
		
		attr_accessor :opacity
		attr_accessor :visible
		
		attr_accessor :map
		
		def initialize(map, node = {})
			self.map = map
			@name = node[:name]
			@opacity = node[:opacity].nil? ? 1.0 : node[:opacity].to_f
			
			@visible = case node[:visible]
			when String
				node[:visible] != "0"
			when Integer
				node[:visible] != 0
			when nil
				true
			else
				!!node[:visible]
			end
			
			super
		end
		
		def initialize_copy(old)
			super
			@map = nil
		end
		
		def index
			return @map ? @map.get_layer_index(self) : nil
		end
		
		def self.load_xml(map,node)
			obj = new(map,node)
			
			obj.load_xml_properties(node)
			
			return obj
		end
		
		def to_xml(xml)
			parent = xml.parent
			parent[:name]=@name
			parent[:width]=@map.width if @map
			parent[:height]=@map.height if @map
			parent[:visible]=0 unless @visible
			parent[:opacity]=@opacity unless @opacity == 1.0

			to_xml_properties(xml)
		end
	end
end
