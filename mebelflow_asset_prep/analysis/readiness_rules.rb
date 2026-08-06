# frozen_string_literal: true

module MebelFlow
  module AssetPrep
    module Analysis
      module ReadinessRules
        DEFAULT_POLYGON_WARNING_THRESHOLD = 50_000
        MAIN_BODY_ROLES = %w[MAIN_BODY main_body].freeze
        UNASSIGNED_ROLES = %w[UNDEFINED undefined].freeze

        module_function

        def evaluate(manifest, polygon_warning_threshold: DEFAULT_POLYGON_WARNING_THRESHOLD)
          issues = []
          issues.concat(main_body_issues(manifest))
          issues.concat(unassigned_role_issues(manifest))
          issues.concat(empty_container_issues(manifest))
          issues.concat(dimension_issues(manifest))
          issues.concat(unit_issues(manifest))
          issues.concat(polygon_issues(manifest, polygon_warning_threshold))
          Domain::ReadinessReport.new(issues: issues, manifest: manifest)
        end

        def main_body_issues(manifest)
          roots = manifest.items.select { |item| item[:parent_id].nil? }
          return [] if roots.any? { |item| MAIN_BODY_ROLES.include?(item[:role]) }

          [Domain::Issue.new(
            code: 'missing_main_body', severity: 'error',
            message: 'Назначьте хотя бы одному корневому объекту роль main_body.',
            entity_ids: roots.map { |item| item[:id] }
          )]
        end

        def unassigned_role_issues(manifest)
          invalid = manifest.exportable_items.select { |item| UNASSIGNED_ROLES.include?(item[:role]) }
          return [] if invalid.empty?

          [Domain::Issue.new(
            code: 'unassigned_exportable_entities', severity: 'error',
            message: 'У всех экспортируемых сущностей должна быть назначена роль.',
            entity_ids: invalid.map { |item| item[:id] }, details: { count: invalid.length }
          )]
        end

        def empty_container_issues(manifest)
          empty = manifest.items.select { |item| item[:empty] }
          return [] if empty.empty?

          [Domain::Issue.new(
            code: 'empty_containers', severity: 'error',
            message: 'Удалите пустые groups/components.',
            entity_ids: empty.map { |item| item[:id] }, details: { count: empty.length }
          )]
        end

        def dimension_issues(manifest)
          invalid_ids = []
          invalid_ids << manifest.root_id unless measurable?(manifest.root_dimensions_mm)
          manifest.exportable_items.each { |item| invalid_ids << item[:id] unless measurable?(item[:dimensions_mm]) }
          return [] if invalid_ids.empty?

          [Domain::Issue.new(
            code: 'unmeasurable_bounding_dimensions', severity: 'error',
            message: 'Bounding dimensions должны быть измеримыми и больше нуля.',
            entity_ids: invalid_ids
          )]
        end

        def unit_issues(manifest)
          return [] if manifest.units_valid && manifest.normalized_units == 'millimeters' && manifest.unit_scale_to_mm.positive?

          [Domain::Issue.new(
            code: 'invalid_model_units', severity: 'error',
            message: 'Единицы модели не удалось корректно нормализовать в миллиметры.',
            details: {
              source_units: manifest.source_units,
              normalized_units: manifest.normalized_units,
              scale_to_mm: manifest.unit_scale_to_mm
            }
          )]
        end

        def polygon_issues(manifest, threshold)
          return [] unless manifest.triangle_count > threshold.to_i

          [Domain::Issue.new(
            code: 'high_polygon_count', severity: 'warning',
            message: 'Количество полигонов превышает рекомендуемый порог, но не блокирует готовность.',
            details: { triangle_count: manifest.triangle_count, threshold: threshold.to_i }
          )]
        end

        def measurable?(dimensions)
          %i[width depth height].all? do |axis|
            value = dimensions[axis]
            value.is_a?(Numeric) && value.finite? && value.positive?
          end
        end
      end
    end
  end
end
