# frozen_string_literal: true

module MebelFlow
  module AssetPrep
    module Domain
      class PreparedCopyResult
        SCHEMA_VERSION = '1.0'

        attr_reader :prepared_root_id, :prepared_root_name, :output_directory,
                    :manifest_path, :report_path, :deleted_entity_ids,
                    :ignored_entity_ids, :manifest

        def initialize(prepared_root_id:, prepared_root_name:, output_directory:,
                       manifest_path:, report_path:, deleted_entity_ids:,
                       ignored_entity_ids:, manifest:)
          @prepared_root_id = prepared_root_id.to_i
          @prepared_root_name = prepared_root_name.to_s
          @output_directory = output_directory.to_s
          @manifest_path = manifest_path.to_s
          @report_path = report_path.to_s
          @deleted_entity_ids = Array(deleted_entity_ids).map(&:to_i).freeze
          @ignored_entity_ids = Array(ignored_entity_ids).map(&:to_i).freeze
          @manifest = manifest
        end

        def to_h
          {
            schema_version: SCHEMA_VERSION,
            prepared_root: { id: prepared_root_id, name: prepared_root_name },
            output_directory: output_directory,
            files: { manifest: manifest_path, report: report_path },
            deleted_entity_ids: deleted_entity_ids,
            ignored_entity_ids: ignored_entity_ids,
            asset_manifest: manifest.to_h
          }
        end
      end
    end
  end
end
