# frozen_string_literal: true

module MebelFlow
  module AssetPrep
    module UI
      class ReadinessDialog
        def initialize
          @dialog = ::UI::HtmlDialog.new(
            dialog_title: 'MebelFlow — Готовность ассета',
            preferences_key: 'MebelFlowAssetReadiness',
            scrollable: true, resizable: true, width: 520, height: 700,
            style: ::UI::HtmlDialog::STYLE_DIALOG
          )
          @dialog.set_file(File.join(__dir__, 'readiness.html'))
          bind_callbacks
        end

        def show(report, tool)
          @report = report
          @tool = tool
          @dialog.show
        end

        private

        def bind_callbacks
          @dialog.add_action_callback('readiness_ready') do |_ctx|
            @dialog.execute_script("window.MebelFlowReadiness.render(#{JSON.generate(@report&.to_h || {})})")
          end
          @dialog.add_action_callback('highlight_readiness_entity') { |_ctx, id| @tool&.focus(id) }
          @dialog.add_action_callback('highlight_readiness_issue') do |_ctx, ids|
            first_id = Array(ids).first
            @tool&.focus(first_id) if first_id
          end
        end
      end
    end
  end
end
