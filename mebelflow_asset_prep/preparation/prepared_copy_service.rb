# frozen_string_literal: true

require 'fileutils'
require 'time'

module MebelFlow
  module AssetPrep
    module Preparation
      class PreparedCopyService
        METADATA_SCHEMA_VERSION = '1.0'

        def initialize(root:, readiness_report:, output_directory:, model: Sketchup.active_model)
          @root = root
          @readiness_report = readiness_report
          @output_directory = output_directory
          @model = model
          @operation_open = false
        end

        def execute
          raise ArgumentError, 'Asset readiness report is required.' unless @readiness_report
          raise ArgumentError, 'Asset is not ready.' unless @readiness_report.ready?
          raise ArgumentError, 'Output directory is required.' if @output_directory.to_s.strip.empty?

          FileUtils.mkdir_p(@output_directory)
          @model.start_operation('MebelFlow Prepared Copy', true)
          @operation_open = true

          prepared_root = duplicate_root
          deep_make_unique(prepared_root)
          deleted_ids = delete_marked_entities(prepared_root)
          ignored_ids = normalize_metadata(prepared_root)

          scan = Analysis::TreeScanner.new(prepared_root).scan
          full_manifest = Analysis::AssetManifestBuilder.new(root: prepared_root, scan: scan, model: @model).build
          manifest = filtered_manifest(full_manifest)
          paths = write_files(manifest)

          @model.commit_operation
          @operation_open = false
          select_prepared_root(prepared_root)

          Domain::PreparedCopyResult.new(
            prepared_root_id: prepared_root.persistent_id,
            prepared_root_name: display_name(prepared_root),
            output_directory: @output_directory,
            manifest_path: paths[:manifest],
            report_path: paths[:report],
            deleted_entity_ids: deleted_ids,
            ignored_entity_ids: ignored_ids,
            manifest: manifest
          )
        rescue StandardError
          @model.abort_operation if @operation_open
          @operation_open = false
          raise
        end

        private

        def duplicate_root
          copy = @root.copy
          copy.make_unique if copy.respond_to?(:make_unique)
          source_name = display_name(@root)
          copy.name = "#{source_name} [PREPARED]" if copy.respond_to?(:name=)
          copy
        end

        def deep_make_unique(container)
          child_containers(container).each do |child|
            child.make_unique if child.respond_to?(:make_unique)
            deep_make_unique(child)
          end
        end

        def delete_marked_entities(container, deleted_ids = [])
          child_containers(container).each do |child|
            if PreparedCopyPlan.action_for(Persistence::AttributeStore.role(child)) == :delete
              deleted_ids << child.persistent_id
              child.erase!
            else
              delete_marked_entities(child, deleted_ids)
            end
          end
          deleted_ids
        end

        def normalize_metadata(root)
          source_root_id = @root.persistent_id
          timestamp = Time.now.utc.iso8601
          ignored_ids = []

          each_container(root) do |entity|
            role = Persistence::AttributeStore.role(entity)
            entity.delete_attribute(Persistence::AttributeStore::DICTIONARY) if entity.respond_to?(:delete_attribute)
            Persistence::AttributeStore.set_role(entity, role)
            included = PreparedCopyPlan.action_for(role) == :preserve_in_manifest
            entity.set_attribute(Persistence::AttributeStore::DICTIONARY, 'prepared_copy', true)
            entity.set_attribute(Persistence::AttributeStore::DICTIONARY, 'metadata_schema_version', METADATA_SCHEMA_VERSION)
            entity.set_attribute(Persistence::AttributeStore::DICTIONARY, 'manifest_included', included)
            entity.set_attribute(Persistence::AttributeStore::DICTIONARY, 'prepared_at', timestamp)
            ignored_ids << entity.persistent_id unless included
          end

          root.set_attribute(Persistence::AttributeStore::DICTIONARY, 'source_root_id', source_root_id)
          root.set_attribute(Persistence::AttributeStore::DICTIONARY, 'readiness_status', @readiness_report.status)
          ignored_ids
        end

        def filtered_manifest(full_manifest)
          Domain::AssetManifest.new(
            asset_id: full_manifest.asset_id,
            root_id: full_manifest.root_id,
            root_name: full_manifest.root_name,
            root_dimensions_mm: full_manifest.root_dimensions_mm,
            source_units: full_manifest.source_units,
            normalized_units: full_manifest.normalized_units,
            unit_scale_to_mm: full_manifest.unit_scale_to_mm,
            units_valid: full_manifest.units_valid,
            triangle_count: full_manifest.triangle_count,
            items: PreparedCopyPlan.manifest_items(full_manifest.items)
          )
        end

        def write_files(manifest)
          asset_directory = File.join(@output_directory, "#{manifest.asset_id}-prepared")
          FileUtils.mkdir_p(asset_directory)
          manifest_path = File.join(asset_directory, 'manifest.json')
          report_path = File.join(asset_directory, 'report.json')
          File.write(manifest_path, JSON.pretty_generate(manifest.to_h))
          File.write(report_path, JSON.pretty_generate(@readiness_report.to_h))
          { manifest: manifest_path, report: report_path }
        end

        def select_prepared_root(root)
          @model.selection.clear
          @model.selection.add(root)
          @model.active_view.zoom(root)
        end

        def each_container(root, &block)
          yield root
          child_containers(root).each { |child| each_container(child, &block) }
        end

        def child_containers(entity)
          container_entities(entity).to_a.select do |child|
            child.is_a?(Sketchup::Group) || child.is_a?(Sketchup::ComponentInstance)
          end
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
