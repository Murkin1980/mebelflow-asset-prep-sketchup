# frozen_string_literal: true

require 'fileutils'

module MebelFlow
  module AssetPrep
    module Packaging
      class AssetPackageService
        PACKAGE_FILENAME = 'package.json'

        def initialize(prepared_copy:, glb_path:)
          @prepared_copy = prepared_copy
          @glb_path = File.expand_path(glb_path.to_s)
        end

        def execute
          raise ArgumentError, 'Prepared Copy is required.' unless @prepared_copy

          package_directory = File.dirname(@prepared_copy.manifest_path)
          issues = validate_required_files
          target_glb_path = canonical_glb_path(package_directory)

          if issues.none?(&:blocking?)
            copy_glb(target_glb_path)
            issues.concat(Analysis::GlbValidationRules.evaluate(target_glb_path))
          end

          package = Domain::AssetPackage.new(
            asset_id: @prepared_copy.manifest.asset_id,
            package_directory: package_directory,
            manifest_path: @prepared_copy.manifest_path,
            report_path: @prepared_copy.report_path,
            glb_path: target_glb_path,
            issues: issues
          )

          write_package_json(package)
          package
        end

        private

        def validate_required_files
          issues = []
          issues.concat(missing_file_issue(@prepared_copy.manifest_path, 'manifest_missing', 'manifest.json'))
          issues.concat(missing_file_issue(@prepared_copy.report_path, 'report_missing', 'report.json'))
          issues.concat(Analysis::GlbValidationRules.evaluate(@glb_path))
          issues
        end

        def missing_file_issue(path, code, label)
          return [] if File.file?(path)

          [Domain::Issue.new(
            code: code, severity: 'error',
            message: "В Prepared Copy отсутствует #{label}.",
            details: { path: path.to_s }
          )]
        end

        def canonical_glb_path(package_directory)
          File.join(package_directory, "#{@prepared_copy.manifest.asset_id}.glb")
        end

        def copy_glb(target_path)
          return if File.expand_path(@glb_path) == File.expand_path(target_path)

          FileUtils.cp(@glb_path, target_path)
        end

        def write_package_json(package)
          path = File.join(package.package_directory, PACKAGE_FILENAME)
          File.open(path, 'w:utf-8') { |file| file.write(JSON.pretty_generate(package.to_h)) }
          path
        end
      end
    end
  end
end
