# frozen_string_literal: true

module MebelFlow
  module AssetPrep
    module Analysis
      module GlbValidationRules
        module_function

        def evaluate(glb_path)
          path = glb_path.to_s
          issues = []

          unless File.extname(path).downcase == '.glb'
            issues << Domain::Issue.new(
              code: 'invalid_glb_extension', severity: 'error',
              message: 'Выбранный файл должен иметь расширение .glb.'
            )
          end

          unless File.file?(path)
            issues << Domain::Issue.new(
              code: 'glb_missing', severity: 'error',
              message: 'GLB-файл не найден на локальном диске.',
              details: { path: path }
            )
            return issues
          end

          if File.size(path).zero?
            issues << Domain::Issue.new(
              code: 'glb_empty', severity: 'error',
              message: 'GLB-файл существует, но имеет нулевой размер.',
              details: { path: path }
            )
          end

          issues
        end
      end
    end
  end
end
