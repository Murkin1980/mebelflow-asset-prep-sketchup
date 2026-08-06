# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../mebelflow_asset_prep/domain/issue'
require_relative '../mebelflow_asset_prep/domain/asset_manifest'
require_relative '../mebelflow_asset_prep/domain/readiness_report'
require_relative '../mebelflow_asset_prep/analysis/readiness_rules'

class ReadinessRulesTest < Minitest::Test
  ManifestDouble = Struct.new(:items, :root_id, :root_dimensions_mm, :units_valid,
                              :normalized_units, :unit_scale_to_mm, :source_units,
                              :triangle_count, keyword_init: true) do
    def exportable_items
      items.select { |item| item[:exportable] }
    end
  end

  def manifest(overrides = {})
    defaults = {
      items: [
        { id: 1, parent_id: nil, role: 'MAIN_BODY', exportable: true, empty: false,
          dimensions_mm: { width: 600.0, depth: 560.0, height: 720.0 } },
        { id: 2, parent_id: 1, role: 'FACADE', exportable: true, empty: false,
          dimensions_mm: { width: 596.0, depth: 18.0, height: 716.0 } }
      ],
      root_id: 1,
      root_dimensions_mm: { width: 600.0, depth: 560.0, height: 720.0 },
      units_valid: true,
      normalized_units: 'millimeters',
      unit_scale_to_mm: 1.0,
      source_units: 'millimeters',
      triangle_count: 1_200
    }
    ManifestDouble.new(**defaults.merge(overrides))
  end

  def evaluate(value = manifest)
    MebelFlow::AssetPrep::Analysis::ReadinessRules.evaluate(value)
  end

  def test_valid_asset_is_ready
    assert_equal 'ready', evaluate.status
  end

  def test_missing_main_body_blocks
    items = manifest.items.map { |item| item.merge(role: 'BODY') }
    assert_includes evaluate(manifest(items: items)).issues.map(&:code), 'missing_main_body'
  end

  def test_unassigned_exportable_entity_blocks
    items = manifest.items.map(&:dup)
    items.last[:role] = 'UNDEFINED'
    assert_includes evaluate(manifest(items: items)).issues.map(&:code), 'unassigned_exportable_entities'
  end

  def test_non_exportable_undefined_entity_does_not_block
    items = manifest.items + [{ id: 3, parent_id: 1, role: 'UNDEFINED', exportable: false,
                                empty: false, dimensions_mm: { width: 1, depth: 1, height: 1 } }]
    refute_includes evaluate(manifest(items: items)).issues.map(&:code), 'unassigned_exportable_entities'
  end

  def test_empty_container_blocks
    items = manifest.items.map(&:dup)
    items.last[:empty] = true
    assert_includes evaluate(manifest(items: items)).issues.map(&:code), 'empty_containers'
  end

  def test_invalid_dimensions_block
    items = manifest.items.map(&:dup)
    items.last[:dimensions_mm] = { width: 0, depth: 18, height: 716 }
    assert_includes evaluate(manifest(items: items)).issues.map(&:code), 'unmeasurable_bounding_dimensions'
  end

  def test_invalid_units_block
    assert_includes evaluate(manifest(units_valid: false, unit_scale_to_mm: 0)).issues.map(&:code), 'invalid_model_units'
  end

  def test_polygon_warning_does_not_block
    report = evaluate(manifest(triangle_count: 60_000))
    assert_equal 'ready_with_warnings', report.status
    assert report.ready?
  end

  def test_schema_version_1_serialization
    domain_manifest = MebelFlow::AssetPrep::Domain::AssetManifest.new(
      asset_id: 'cabinet', root_id: 1, root_name: 'Cabinet',
      root_dimensions_mm: { width: 600, depth: 560, height: 720 },
      source_units: 'millimeters', unit_scale_to_mm: 1, units_valid: true,
      triangle_count: 1200, items: manifest.items
    )
    hash = evaluate(domain_manifest).to_h
    assert_equal '1.0', hash[:schema_version]
    assert_equal '1.0', hash[:asset_manifest][:schema_version]
  end
end
