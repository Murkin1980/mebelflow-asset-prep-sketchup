# frozen_string_literal: true

module MebelFlow
  module AssetPrep
    module Highlighting
      class ReviewTool
        ACTIVE_COLOR = Sketchup::Color.new(255, 230, 0)

        attr_reader :active_id

        def initialize(analysis)
          @analysis = analysis
          @active_id = nil
          @isolated_id = nil
        end

        def activate
          Sketchup.active_model.active_view.invalidate
        end

        def deactivate(view)
          view.invalidate
        end

        def select_by_id(id)
          entity = find_entity(id)
          return false unless entity

          @active_id = id.to_i
          model = Sketchup.active_model
          model.selection.clear
          model.selection.add(entity)
          model.active_view.invalidate
          true
        end

        def assign_role(id, role)
          entity = find_entity(id)
          return false unless entity

          Persistence::AttributeStore.set_role(entity, role)
          item = @analysis[:items].find { |candidate| candidate[:id] == id.to_i }
          item[:role] = role if item
          Sketchup.active_model.active_view.invalidate
          true
        end

        def focus(id)
          entity = find_entity(id)
          return false unless entity

          select_by_id(id)
          Sketchup.active_model.active_view.zoom(entity)
          true
        end

        def isolate(id)
          @isolated_id = id.to_i
          Sketchup.active_model.active_view.invalidate
          true
        end

        def show_context
          @isolated_id = nil
          Sketchup.active_model.active_view.invalidate
        end

        def onLButtonDown(_flags, x, y, view)
          helper = view.pick_helper
          helper.do_pick(x, y)
          entity = helper.best_picked
          entity = climb_to_tracked(entity)
          return unless entity

          @active_id = entity.persistent_id
          Sketchup.active_model.selection.clear
          Sketchup.active_model.selection.add(entity)
          UI::Dialog.notify_selection(@active_id)
          view.invalidate
        end

        def draw(view)
          @analysis[:items].each do |item|
            next if @isolated_id && item[:id] != @isolated_id

            entity = find_entity(item[:id])
            next unless entity&.valid?

            color = item[:id] == @active_id ? ACTIVE_COLOR : Domain::Roles::COLORS.fetch(item[:role], ACTIVE_COLOR)
            draw_bounds(view, entity.bounds, color, item[:id] == @active_id ? 5 : 2)
          end
        end

        def getExtents
          box = Geom::BoundingBox.new
          @analysis[:items].each do |item|
            entity = find_entity(item[:id])
            box.add(entity.bounds) if entity&.valid?
          end
          box
        end

        private

        def draw_bounds(view, bounds, color, width)
          points = 8.times.map { |index| bounds.corner(index) }
          edges = [[0,1],[1,3],[3,2],[2,0],[4,5],[5,7],[7,6],[6,4],[0,4],[1,5],[2,6],[3,7]]
          view.drawing_color = color
          view.line_width = width
          edges.each { |a, b| view.draw(GL_LINES, points[a], points[b]) }
        end

        def find_entity(id)
          Sketchup.active_model.find_entity_by_persistent_id(id.to_i)
        end

        def climb_to_tracked(entity)
          current = entity
          while current
            return current if @analysis[:items].any? { |item| item[:id] == current.persistent_id }
            current = current.respond_to?(:parent) ? current.parent : nil
          end
          nil
        end
      end
    end
  end
end
