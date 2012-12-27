gem "nokogiri"
require "nokogiri"

require "pathname"

# Main namespace for this library.
module TiledTmx
end

require_relative "tiled_tmx/version"
require_relative "tiled_tmx/map"
require_relative "tiled_tmx/tileset"
require_relative "tiled_tmx/tilelayer"
require_relative "tiled_tmx/objectgroup"
require_relative "tiled_tmx/imagelayer"
