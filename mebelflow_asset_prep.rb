# frozen_string_literal: true

require 'sketchup.rb'
require 'extensions.rb'

module MebelFlow
  module AssetPrep
    EXTENSION_NAME = 'MebelFlow Asset Prep'
    EXTENSION_VERSION = '0.1.0'

    unless file_loaded?(__FILE__)
      extension = SketchupExtension.new(
        EXTENSION_NAME,
        File.join(__dir__, 'mebelflow_asset_prep', 'extension')
      )
      extension.description = 'Prepare SketchUp furniture modules for MebelFlow AI.'
      extension.version = EXTENSION_VERSION
      extension.creator = 'MebelFlow AI'
      Sketchup.register_extension(extension, true)
      file_loaded(__FILE__)
    end
  end
end
