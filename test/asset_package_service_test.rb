# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'json'
require_relative '../mebelflow_asset_prep/domain/issue'
require_relative '../mebelflow_asset_prep/domain/asset_package'
require_relative '../mebelflow_asset_prep/analysis/glb_validation_rules'
require_relative '../mebelflow_asset_prep/packaging/asset_package_service'

class AssetPackageServiceTest < Minitest::Test
  ManifestDouble = Struct.new(:asset_id, keyword_init: true)
  PreparedCopyDouble = Struct.new(:manifest_path, :report_path, :manifest, keyword_init: true)

  def test_builds_valid_local_package
    Dir.mktmpdir do |dir|
      prepared_dir = File.join(dir, 'cabinet-prepared')
      Dir.mkdir(prepared_dir)
      manifest_path = File.join(prepared_dir, 'manifest.json')
      report_path = File.join(prepared_dir, 'report.json')
      source_glb = File.join(dir, 'manual-export.glb')
      File.write(manifest_path, '{}')
      File.write(report_path, '{}')
      File.binwrite(source_glb, 'glTF-data')

      prepared = PreparedCopyDouble.new(
        manifest_path: manifest_path,
        report_path: report_path,
        manifest: ManifestDouble.new(asset_id: 'cabinet')
      )

      package = MebelFlow::AssetPrep::Packaging::AssetPackageService.new(
        prepared_copy: prepared,
        glb_path: source_glb
      ).execute

      assert package.valid?
      assert File.file?(File.join(prepared_dir, 'cabinet.glb'))
      assert File.file?(File.join(prepared_dir, 'package.json'))
      json = JSON.parse(File.read(File.join(prepared_dir, 'package.json')))
      assert_equal '1.0', json['schema_version']
      assert_equal 'valid', json['status']
      assert_equal 'cabinet.glb', json.dig('files', 'glb', 'name')
    end
  end

  def test_missing_manifest_produces_invalid_package
    Dir.mktmpdir do |dir|
      prepared_dir = File.join(dir, 'cabinet-prepared')
      Dir.mkdir(prepared_dir)
      report_path = File.join(prepared_dir, 'report.json')
      source_glb = File.join(dir, 'manual-export.glb')
      File.write(report_path, '{}')
      File.binwrite(source_glb, 'glTF-data')

      prepared = PreparedCopyDouble.new(
        manifest_path: File.join(prepared_dir, 'manifest.json'),
        report_path: report_path,
        manifest: ManifestDouble.new(asset_id: 'cabinet')
      )

      package = MebelFlow::AssetPrep::Packaging::AssetPackageService.new(
        prepared_copy: prepared,
        glb_path: source_glb
      ).execute

      refute package.valid?
      assert_includes package.issues.map(&:code), 'manifest_missing'
      assert File.file?(File.join(prepared_dir, 'package.json'))
    end
  end
end
