# frozen_string_literal: true

module MebelFlow
  module AssetPrep
    module Analysis
      class AssetManifestBuilder
        UNIT_DEFINITIONS = {
          0 => ['inches', 25.4], 1 => ['feet', 304.8], 2 => ['millimeters', 1.0],
          3 => ['centimeters', 10.0], 4 => ['meters', 1000.0], 5 => ['yards', 914.4]
        }.freeze
        EXCLUDED_ROLES = %w[IGNORE DELETE_FROM_PREPARED_COPY].freeze

        def initialize(root:, scan:, model: Sketchup.active_model)
          @root = root
          @scan = scan
          @model = model
        end

        def build
          unit_name, scale, valid = unit_info
          Domain::AssetManifest.new(
            asset_id: asset_id,
            root_id: @root.persistent_id,
            root_name: @scan[:root_name],
            root_dimensions_mm: dimensions_mm(@root.bounds),
            source_units: unit_name,
            unit_scale_to_mm: scale,
            units_valid: valid,
            triangle_count: triangle_count(container_entities(@root)),
            items: manifest_items
          )
        end

        private

        def manifest_items
          root_item = serialize_entity(@root, nil)
          descendants = @scan[:items].map do |item|
            entity = @model.find_entity_by_persistent_id(item[:id])
            parent_id = item[:parent_id] || @root.persistent_id
            if entity&.valid?
              serialize_entity(entity, parent_id).merge(name: item[:name], type: item[:type])
            else
              item.merge(parent_id: parent_id, exportable: false, empty: true, triangle_count: 0)
            end
          end
          [root_item] + descendants
        end

        def serialize_entity(entity, parent_id)
          role = Persistence::AttributeStore.role(entity)
          {
            id: entity.persistent_id,
            parent_id: parent_id,
            name: display_name(entity),
            type: entity.typename,
            role: role,
            exportable: !EXCLUDED_ROLES.include?(role),
            empty: empty_container?(entity),
            dimensions_mm: dimensions_mm(entity.bounds),
            triangle_count: triangle_count(container_entities(entity))
          }
        end

        def empty_container?(entity)
          container_entities(entity).none? do |child|
            child.is_a?(Sketchup::Face) || child.is_a?(Sketchup::Edge) ||
              child.is_a?(Sketchup::Group) || child.is_a?(Sketchup::ComponentInstance)
          end
        end

        def triangle_count(entities, visited = {})
          entities.sum do |entity|
            if entity.is_a?(Sketchup::Face)
              entity.mesh.polygons.sum { |polygon| [polygon.length - 2, 0].max }
            elsif entity.is_a?(Sketchup::Group)
              triangle_count(entity.entities, visited)
            elsif entity.is_a?(Sketchup::ComponentInstance)
              key = [entity.definition.persistent_id, entity.persistent_id]
              next 0 if visited[key]

              visited[key] = true
              triangle_count(entity.definition.entities, visited)
            else
              0
            end
          end
        end

        def dimensions_mm(bounds)
          { width: bounds.width.to_mm.round(3), depth: bounds.depth.to_mm.round(3), height: bounds.height.to_mm.round(3) }
        end

        def unit_info
          unit_code = @model.options['UnitsOptions']['LengthUnit']
          definition = UNIT_DEFINITIONS[unit_code]
          return ['unknown', 0.0, false] unless definition

          [definition[0], definition[1], true]
        rescue StandardError
          ['unknown', 0.0, false]
        end

        def asset_id
          value = @scan[:root_name].downcase.gsub(/[^a-z0-9а-яё]+/i, '-').gsub(/^-|-$/, '')
          value.empty? ? "asset-#{@root.persistent_id}" : value
        end

        def container_entities(entity)
          entity.is_a?(Sketchup::Group) ? entity.entities : entity.definition.entities
        end

        def display_name(entity)
          name = entity.name.to_s.strip
          name = entity.definition.name.to_s.strip if name.empty? && entity.respond_to?(:definition)
          name.empty? ? "#{entity.typename} ##{entity.persistent_id}" : name
        end
      end
    end
  end
end
