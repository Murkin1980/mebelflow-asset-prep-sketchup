# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../mebelflow_asset_prep/preparation/prepared_copy_plan'

class PreparedCopyPlanTest < Minitest::Test
  def items
    [
      { id: 1, role: 'MAIN_BODY' },
      { id: 2, role: 'FACADE' },
      { id: 3, role: 'IGNORE' },
      { id: 4, role: 'DELETE_FROM_PREPARED_COPY' }
    ]
  end

  def test_delete_role_is_removed_from_prepared_copy
    assert_equal :delete,
                 MebelFlow::AssetPrep::Preparation::PreparedCopyPlan.action_for('DELETE_FROM_PREPARED_COPY')
  end

  def test_ignore_role_is_preserved_but_excluded
    assert_equal :preserve_excluded,
                 MebelFlow::AssetPrep::Preparation::PreparedCopyPlan.action_for('IGNORE')
  end

  def test_regular_roles_are_preserved_in_manifest
    assert_equal :preserve_in_manifest,
                 MebelFlow::AssetPrep::Preparation::PreparedCopyPlan.action_for('FACADE')
  end

  def test_manifest_excludes_ignore_and_delete_roles
    result = MebelFlow::AssetPrep::Preparation::PreparedCopyPlan.manifest_items(items)
    assert_equal [1, 2], result.map { |item| item[:id] }
  end

  def test_ids_are_partitioned_stably
    plan = MebelFlow::AssetPrep::Preparation::PreparedCopyPlan
    assert_equal [4], plan.deleted_ids(items)
    assert_equal [3], plan.ignored_ids(items)
    assert_equal [1, 2], plan.included_ids(items)
  end
end
