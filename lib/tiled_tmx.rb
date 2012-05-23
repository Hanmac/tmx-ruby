gem "nokogiri"
require "nokogiri"

# Main namespace for this library.
module TiledTmx

  # Version of TiledTmx.
  VERSION = "0.0.1-dev".freeze

end

require_relative "tiled_tmx/map"
require_relative "tiled_tmx/tileset"
require_relative "tiled_tmx/tilelayer"
require_relative "tiled_tmx/objectgroup"
require_relative "tiled_tmx/imagelayer"
