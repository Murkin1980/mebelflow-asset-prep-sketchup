# frozen_string_literal: true

module MebelFlow
  module AssetPrep
    module Analysis
      class TreeScanner
        def initialize(root)
          @root = root
        end

        def scan
          items = []
          walk(container_entities(@root), nil, Geom::Transformation.new, items)
          {
            root_id: @root.persistent_id,
            root_name: display_name(@root),
            items: items
          }
        end

        private

        def walk(entities, parent_id, transform, items)
          entities.each do |entity|
            next unless supported?(entity)

            local_transform = entity.respond_to?(:transformation) ? entity.transformation : Geom::Transformation.new
            world_transform = transform * local_transform
            item = serialize(entity, parent_id, world_transform)
            items << item
            walk(container_entities(entity), entity.persistent_id, world_transform, items) if container?(entity)
          end
        end

        def serialize(entity, parent_id, transform)
          bounds = transformed_bounds(entity, transform)
          {
            id: entity.persistent_id,
            parent_id: parent_id,
            name: display_name(entity),
            type: entity.typename,
            role: Persistence::AttributeStore.role(entity),
            dimensions_mm: {
              width: bounds.width.to_mm.round(1),
              depth: bounds.depth.to_mm.round(1),
              height: bounds.height.to_mm.round(1)
            }
          }
        end

        def transformed_bounds(entity, transform)
          source = entity.bounds
          result = Geom::BoundingBox.new
          8.times { |index| result.add(source.corner(index).transform(transform)) }
          result
        end

        def supported?(entity)
          entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
        end

        def container?(entity)
          supported?(entity)
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
