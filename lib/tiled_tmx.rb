gem "nokogiri"
require "nokogiri"

require "rbtree"
require "pathname"

class RBTree
	def ==(other)
		return to_hash == other
	end
end
# Main namespace for this library.
module TiledTmx
end

require_relative "tiled_tmx/path"
require_relative "tiled_tmx/version"

require_relative "tiled_tmx/propertyset"
require_relative "tiled_tmx/layer"
require_relative "tiled_tmx/tilelayer"
require_relative "tiled_tmx/tileset"
require_relative "tiled_tmx/objectgroup"
require_relative "tiled_tmx/imagelayer"
require_relative "tiled_tmx/map"

