# frozen_string_literal: true

require 'time'

module MebelFlow
  module AssetPrep
    module Domain
      class ReadinessReport
        SCHEMA_VERSION = '1.0'
        STATUSES = %w[ready ready_with_warnings not_ready].freeze

        attr_reader :status, :issues, :manifest, :checked_at

        def initialize(issues:, manifest:, checked_at: Time.now.utc)
          @issues = Array(issues).freeze
          @manifest = manifest
          @checked_at = checked_at
          @status = derive_status
        end

        def ready?
          status != 'not_ready'
        end

        def to_h
          {
            schema_version: SCHEMA_VERSION,
            report_type: 'asset_readiness',
            status: status,
            ready: ready?,
            checked_at: checked_at.iso8601,
            summary: {
              errors: issues.count(&:blocking?),
              warnings: issues.count { |issue| issue.severity == 'warning' },
              infos: issues.count { |issue| issue.severity == 'info' }
            },
            issues: issues.map(&:to_h),
            asset_manifest: manifest.to_h
          }
        end

        def to_json(*args)
          require 'json'
          JSON.generate(to_h, *args)
        end

        private

        def derive_status
          return 'not_ready' if issues.any?(&:blocking?)
          return 'ready_with_warnings' if issues.any? { |issue| issue.severity == 'warning' }

          'ready'
        end
      end
    end
  end
end
