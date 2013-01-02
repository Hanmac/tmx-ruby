# -*- coding: utf-8 -*-
module TiledTmx
	class ImageLayer < Layer
		attr_accessor :image
		attr_accessor :trans
		
		def initialize(map,node = {})
			super
		end
		
		def initialize_copy(old)
			super
			@image = old.image.dup
		end
		
		def self.load_xml(map,node)
			temp = super
			
			temp.image = Path.new(node.xpath("image")[0][:source],node)
			temp.trans = node.xpath("image")[0][:trans]
			return temp
		end

		def to_xml(xml)
			xml.imagelayer {
				if @image
					hash = {:source=>@image.relpath}
					hash[:trans] = @trans if @trans
					xml.image(hash)
				end
				super
			}
		end
	end
end
