module TiledTmx
	class Path
		attr_accessor :relpath
		
		def initialize(path,node)
			@relpath = path
			@dirname = File.dirname(File.absolute_path(node.document.url))
		end
		
		def to_s
			return File.absolute_path(@relpath,@dirname)
		end
	end
end

