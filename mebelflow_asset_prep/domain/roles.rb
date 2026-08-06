# frozen_string_literal: true

module MebelFlow
  module AssetPrep
    module Domain
      module Roles
        ALL = %w[
          UNDEFINED BODY FACADE DRAWER HANDLE APPLIANCE GLASS DECOR
          INNER_SHADOW IGNORE DELETE_FROM_PREPARED_COPY
        ].freeze

        COLORS = {
          'UNDEFINED' => Sketchup::Color.new(255, 176, 0),
          'BODY' => Sketchup::Color.new(66, 184, 131),
          'FACADE' => Sketchup::Color.new(66, 184, 131),
          'DRAWER' => Sketchup::Color.new(66, 184, 131),
          'HANDLE' => Sketchup::Color.new(66, 184, 131),
          'APPLIANCE' => Sketchup::Color.new(66, 184, 131),
          'GLASS' => Sketchup::Color.new(66, 184, 131),
          'DECOR' => Sketchup::Color.new(66, 184, 131),
          'INNER_SHADOW' => Sketchup::Color.new(66, 184, 131),
          'IGNORE' => Sketchup::Color.new(69, 163, 255),
          'DELETE_FROM_PREPARED_COPY' => Sketchup::Color.new(156, 39, 176)
        }.freeze
      end
    end
  end
end
