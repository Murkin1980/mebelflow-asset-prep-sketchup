# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require_relative '../mebelflow_asset_prep/domain/issue'
require_relative '../mebelflow_asset_prep/analysis/glb_validation_rules'

class GlbValidationRulesTest < Minitest::Test
  def test_missing_glb_is_invalid
    issues = MebelFlow::AssetPrep::Analysis::GlbValidationRules.evaluate('/missing/model.glb')
    assert_includes issues.map(&:code), 'glb_missing'
  end

  def test_wrong_extension_is_invalid
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'model.gltf')
      File.binwrite(path, 'data')
      issues = MebelFlow::AssetPrep::Analysis::GlbValidationRules.evaluate(path)
      assert_includes issues.map(&:code), 'invalid_glb_extension'
    end
  end

  def test_empty_glb_is_invalid
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'model.glb')
      File.binwrite(path, '')
      issues = MebelFlow::AssetPrep::Analysis::GlbValidationRules.evaluate(path)
      assert_includes issues.map(&:code), 'glb_empty'
    end
  end

  def test_existing_non_empty_glb_passes_simple_validation
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'model.glb')
      File.binwrite(path, 'glTF')
      assert_empty MebelFlow::AssetPrep::Analysis::GlbValidationRules.evaluate(path)
    end
  end
end
