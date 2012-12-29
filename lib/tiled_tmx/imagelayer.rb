require_relative "layer"
module TiledTmx
	class ImageLayer < Layer
		attr_accessor :image
		attr_accessor :trans
		
		
		def self.load_xml(node)
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
