# frozen_string_literal: true

module MebelFlow
  module AssetPrep
    module UI
      class Dialog
        @instance = nil

        class << self
          attr_accessor :instance

          def notify_selection(id)
            instance&.send_event('scene_selection', { id: id })
          end
        end

        def initialize
          self.class.instance = self
          @dialog = ::UI::HtmlDialog.new(
            dialog_title: 'MebelFlow Asset Prep',
            preferences_key: 'MebelFlowAssetPrep',
            scrollable: true,
            resizable: true,
            width: 430,
            height: 720,
            style: ::UI::HtmlDialog::STYLE_DIALOG
          )
          @dialog.set_file(File.join(__dir__, 'index.html'))
          bind_callbacks
        end

        def show(analysis, tool)
          @analysis = analysis
          @tool = tool
          @dialog.show
          @dialog.add_action_callback('ready') { |_ctx| send_event('analysis', @analysis) }
        end

        def send_event(name, payload)
          script = "window.MebelFlow.receive(#{JSON.generate(name)}, #{JSON.generate(payload)})"
          @dialog.execute_script(script)
        end

        private

        def bind_callbacks
          @dialog.add_action_callback('select_entity') { |_ctx, id| @tool&.select_by_id(id) }
          @dialog.add_action_callback('focus_entity') { |_ctx, id| @tool&.focus(id) }
          @dialog.add_action_callback('isolate_entity') { |_ctx, id| @tool&.isolate(id) }
          @dialog.add_action_callback('show_context') { |_ctx| @tool&.show_context }
          @dialog.add_action_callback('assign_role') do |_ctx, id, role|
            ok = @tool&.assign_role(id, role)
            send_event('role_updated', { id: id.to_i, role: role }) if ok
          end
        end
      end
    end
  end
end
