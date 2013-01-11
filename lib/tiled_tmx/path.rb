module TiledTmx
	class Path
		attr_accessor :relpath
		
		def initialize(path,node)
			@relpath = path
			if node.respond_to?(:document)
				url = node.document.url
				@dirname = url ? File.dirname(File.absolute_path(url)) : "."
			else
				@dirname = node
			end
		end
		
		def to_s
			return File.absolute_path(@relpath,@dirname)
		end
		
		def ==(other)
			return to_s == other.to_s
		end
	end
end

