# frozen_string_literal: true

require 'sketchup.rb'
require 'json'
require_relative 'domain/roles'
require_relative 'analysis/tree_scanner'
require_relative 'persistence/attribute_store'
require_relative 'highlighting/review_tool'
require_relative 'ui/dialog'

module MebelFlow
  module AssetPrep
    PLUGIN_ID = 'mebelflow_asset_prep'

    class << self
      attr_reader :dialog, :review_tool, :analysis

      def open
        root = selected_root
        unless root
          UI.messagebox('Выберите одну группу или компонент мебельного модуля.')
          return
        end

        @analysis = Analysis::TreeScanner.new(root).scan
        @review_tool = Highlighting::ReviewTool.new(@analysis)
        @dialog ||= UI::Dialog.new
        @dialog.show(@analysis, @review_tool)
        Sketchup.active_model.select_tool(@review_tool)
      rescue StandardError => e
        UI.messagebox("MebelFlow Asset Prep: #{e.message}")
        warn e.full_message
      end

      def selected_root
        selected = Sketchup.active_model.selection.to_a
        return nil unless selected.length == 1

        entity = selected.first
        return entity if entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)

        nil
      end
    end

    unless file_loaded?(__FILE__)
      command = UI::Command.new('MebelFlow Asset Prep') { AssetPrep.open }
      command.tooltip = 'Подготовить мебельный модуль для MebelFlow AI'
      UI.menu('Extensions').add_item(command)
      toolbar = UI::Toolbar.new('MebelFlow Asset Prep')
      toolbar.add_item(command)
      toolbar.restore
      file_loaded(__FILE__)
    end
  end
end
