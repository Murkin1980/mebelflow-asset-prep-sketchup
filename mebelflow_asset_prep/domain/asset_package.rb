# frozen_string_literal: true

require 'time'

module MebelFlow
  module AssetPrep
    module Domain
      class AssetPackage
        SCHEMA_VERSION = '1.0'

        attr_reader :asset_id, :package_directory, :manifest_path, :report_path,
                    :glb_path, :issues, :created_at

        def initialize(asset_id:, package_directory:, manifest_path:, report_path:,
                       glb_path:, issues: [], created_at: Time.now.utc)
          @asset_id = asset_id.to_s
          @package_directory = File.expand_path(package_directory.to_s)
          @manifest_path = File.expand_path(manifest_path.to_s)
          @report_path = File.expand_path(report_path.to_s)
          @glb_path = File.expand_path(glb_path.to_s)
          @issues = Array(issues).freeze
          @created_at = created_at
        end

        def valid?
          issues.none?(&:blocking?)
        end

        def status
          valid? ? 'valid' : 'invalid'
        end

        def to_h
          {
            schema_version: SCHEMA_VERSION,
            package_type: 'mebelflow_asset',
            status: status,
            valid: valid?,
            created_at: created_at.utc.iso8601,
            asset_id: asset_id,
            files: {
              manifest: file_descriptor(manifest_path),
              report: file_descriptor(report_path),
              glb: file_descriptor(glb_path)
            },
            issues: issues.map(&:to_h)
          }
        end

        private

        def file_descriptor(path)
          {
            name: File.basename(path),
            relative_path: relative_path(path),
            exists: File.file?(path),
            size_bytes: File.file?(path) ? File.size(path) : 0
          }
        end

        def relative_path(path)
          expanded = File.expand_path(path)
          prefix = package_directory.end_with?(File::SEPARATOR) ? package_directory : "#{package_directory}#{File::SEPARATOR}"
          expanded.start_with?(prefix) ? expanded.delete_prefix(prefix) : File.basename(expanded)
        end
      end
    end
  end
end
