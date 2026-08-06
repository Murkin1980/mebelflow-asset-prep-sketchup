# frozen_string_literal: true

module MebelFlow
  module AssetPrep
    module Domain
      class AssetManifest
        SCHEMA_VERSION = '1.0'

        attr_reader :asset_id, :root_id, :root_name, :root_dimensions_mm,
                    :source_units, :normalized_units, :unit_scale_to_mm,
                    :units_valid, :triangle_count, :items

        def initialize(asset_id:, root_id:, root_name:, root_dimensions_mm:,
                       source_units:, normalized_units: 'millimeters',
                       unit_scale_to_mm:, units_valid:, triangle_count:, items:)
          @asset_id = asset_id.to_s
          @root_id = root_id.to_i
          @root_name = root_name.to_s
          @root_dimensions_mm = dimensions(root_dimensions_mm)
          @source_units = source_units.to_s
          @normalized_units = normalized_units.to_s
          @unit_scale_to_mm = Float(unit_scale_to_mm)
          @units_valid = !!units_valid
          @triangle_count = Integer(triangle_count || 0)
          @items = Array(items).map { |item| normalize_item(item) }.freeze
        end

        def exportable_items
          items.select { |item| item[:exportable] }
        end

        def to_h
          {
            schema_version: SCHEMA_VERSION,
            asset_id: asset_id,
            root: { id: root_id, name: root_name, dimensions_mm: root_dimensions_mm },
            units: { source: source_units, normalized: normalized_units, scale_to_mm: unit_scale_to_mm, valid: units_valid },
            geometry: { triangle_count: triangle_count },
            items: items
          }
        end

        private

        def normalize_item(item)
          source = item.transform_keys(&:to_sym)
          {
            id: source[:id].to_i,
            parent_id: source[:parent_id]&.to_i,
            name: source[:name].to_s,
            type: source[:type].to_s,
            role: source[:role].to_s,
            exportable: source.key?(:exportable) ? !!source[:exportable] : true,
            empty: !!source[:empty],
            dimensions_mm: dimensions(source[:dimensions_mm] || {}),
            triangle_count: Integer(source[:triangle_count] || 0)
          }.freeze
        end

        def dimensions(value)
          hash = value.transform_keys(&:to_sym)
          { width: numeric(hash[:width]), depth: numeric(hash[:depth]), height: numeric(hash[:height]) }.freeze
        end

        def numeric(value)
          Float(value)
        rescue ArgumentError, TypeError
          0.0
        end
      end
    end
  end
end
