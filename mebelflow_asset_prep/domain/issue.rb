# frozen_string_literal: true

module MebelFlow
  module AssetPrep
    module Domain
      class Issue
        SEVERITIES = %w[error warning info].freeze

        attr_reader :code, :severity, :message, :entity_ids, :details

        def initialize(code:, severity:, message:, entity_ids: [], details: {})
          raise ArgumentError, 'Unknown severity' unless SEVERITIES.include?(severity.to_s)

          @code = code.to_s
          @severity = severity.to_s
          @message = message.to_s
          @entity_ids = Array(entity_ids).compact.map(&:to_i).uniq.freeze
          @details = (details || {}).freeze
        end

        def blocking?
          severity == 'error'
        end

        def to_h
          { code: code, severity: severity, message: message, entity_ids: entity_ids, details: details }
        end
      end
    end
  end
end
