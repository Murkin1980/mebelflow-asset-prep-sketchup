# frozen_string_literal: true

require 'sketchup.rb'
require 'json'
require_relative 'domain/roles'
require_relative 'domain/issue'
require_relative 'domain/asset_manifest'
require_relative 'domain/readiness_report'
require_relative 'domain/prepared_copy_result'
require_relative 'analysis/tree_scanner'
require_relative 'analysis/asset_manifest_builder'
require_relative 'analysis/readiness_rules'
require_relative 'preparation/prepared_copy_plan'
require_relative 'preparation/prepared_copy_service'
require_relative 'persistence/attribute_store'
require_relative 'highlighting/review_tool'
require_relative 'ui/dialog'
require_relative 'ui/readiness_dialog'

module MebelFlow
  module AssetPrep
    PLUGIN_ID = 'mebelflow_asset_prep'

    class << self
      attr_reader :dialog, :readiness_dialog, :review_tool, :analysis,
                  :last_report, :last_prepared_copy

      def open
        root = require_selected_root
        return unless root

        scan, manifest = scan_and_manifest(root)
        @analysis = review_analysis(scan, manifest)
        @review_tool = Highlighting::ReviewTool.new(@analysis)
        @dialog ||= UI::Dialog.new
        @dialog.show(@analysis, @review_tool)
        Sketchup.active_model.select_tool(@review_tool)
      rescue StandardError => e
        handle_error(e)
      end

      def check_readiness
        root = require_selected_root
        return unless root

        scan, manifest = scan_and_manifest(root)
        @analysis = review_analysis(scan, manifest)
        @review_tool = Highlighting::ReviewTool.new(@analysis)
        @last_report = Analysis::ReadinessRules.evaluate(manifest)
        @readiness_dialog ||= UI::ReadinessDialog.new
        @readiness_dialog.show(@last_report, @review_tool)
        Sketchup.active_model.select_tool(@review_tool)
      rescue StandardError => e
        handle_error(e)
      end

      def save_readiness_report
        unless @last_report
          ::UI.messagebox('Сначала выполните команду «Проверить готовность ассета».')
          return
        end

        default_name = "#{@last_report.manifest.asset_id}-readiness-report.json"
        path = ::UI.savepanel('Сохранить Asset Readiness Report', nil, default_name)
        return unless path

        File.open(path, 'w:utf-8') { |file| file.write(JSON.pretty_generate(@last_report.to_h)) }
        ::UI.messagebox("Отчёт сохранён:\n#{path}")
      rescue StandardError => e
        handle_error(e)
      end

      def create_prepared_copy
        root = require_selected_root
        return unless root

        unless report_matches_root?(root) && @last_report.ready?
          ::UI.messagebox('Сначала проверьте выбранный ассет. Prepared Copy создаётся только для статусов ready или ready_with_warnings.')
          return
        end

        output_directory = select_output_directory
        return unless output_directory

        @last_prepared_copy = Preparation::PreparedCopyService.new(
          root: root,
          readiness_report: @last_report,
          output_directory: output_directory
        ).execute

        ::UI.messagebox(
          "Prepared Copy создана.\n\n" \
          "Исходная модель не изменена.\n" \
          "Manifest: #{@last_prepared_copy.manifest_path}\n" \
          "Report: #{@last_prepared_copy.report_path}\n\n" \
          'Подготовленная копия выделена для ручного экспорта GLB.'
        )
      rescue StandardError => e
        handle_error(e)
      end

      def selected_root
        selected = Sketchup.active_model.selection.to_a
        return nil unless selected.length == 1

        entity = selected.first
        return entity if entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)

        nil
      end

      private

      def require_selected_root
        root = selected_root
        ::UI.messagebox('Выберите одну группу или компонент мебельного модуля.') unless root
        root
      end

      def report_matches_root?(root)
        @last_report && @last_report.manifest.root_id == root.persistent_id
      end

      def select_output_directory
        if ::UI.respond_to?(:select_directory)
          ::UI.select_directory(title: 'Папка для manifest.json и report.json')
        else
          placeholder = ::UI.savepanel('Выберите папку для Prepared Copy', nil, 'prepared-copy-output')
          placeholder && File.dirname(placeholder)
        end
      end

      def scan_and_manifest(root)
        scan = Analysis::TreeScanner.new(root).scan
        manifest = Analysis::AssetManifestBuilder.new(root: root, scan: scan).build
        [scan, manifest]
      end

      def review_analysis(scan, manifest)
        items = manifest.items.map do |item|
          {
            id: item[:id], parent_id: item[:parent_id], name: item[:name], type: item[:type],
            role: item[:role], dimensions_mm: item[:dimensions_mm]
          }
        end
        scan.merge(items: items)
      end

      def handle_error(error)
        ::UI.messagebox("MebelFlow Asset Prep: #{error.message}")
        warn error.full_message
      end
    end

    unless file_loaded?(__FILE__)
      menu = ::UI.menu('Extensions').add_submenu('MebelFlow')

      prepare_command = ::UI::Command.new('Подготовить ассет') { AssetPrep.open }
      prepare_command.tooltip = 'Разобрать и назначить роли элементам мебельного модуля'
      menu.add_item(prepare_command)

      readiness_command = ::UI::Command.new('Проверить готовность ассета') { AssetPrep.check_readiness }
      readiness_command.tooltip = 'Создать Asset Readiness Report'
      menu.add_item(readiness_command)

      save_command = ::UI::Command.new('Сохранить отчёт JSON') { AssetPrep.save_readiness_report }
      save_command.set_validation_proc { AssetPrep.last_report ? MF_ENABLED : MF_GRAYED }
      menu.add_item(save_command)

      prepared_copy_command = ::UI::Command.new('Создать Prepared Copy') { AssetPrep.create_prepared_copy }
      prepared_copy_command.tooltip = 'Создать безопасную подготовленную копию и записать manifest.json + report.json'
      prepared_copy_command.set_validation_proc do
        AssetPrep.last_report&.ready? ? MF_ENABLED : MF_GRAYED
      end
      menu.add_item(prepared_copy_command)

      toolbar = ::UI::Toolbar.new('MebelFlow Asset Prep')
      toolbar.add_item(prepare_command)
      toolbar.add_item(readiness_command)
      toolbar.add_item(prepared_copy_command)
      toolbar.restore
      file_loaded(__FILE__)
    end
  end
end
