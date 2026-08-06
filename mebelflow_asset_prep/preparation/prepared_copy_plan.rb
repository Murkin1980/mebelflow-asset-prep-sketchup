# frozen_string_literal: true

module MebelFlow
  module AssetPrep
    module Preparation
      module PreparedCopyPlan
        DELETE_ROLE = 'DELETE_FROM_PREPARED_COPY'
        IGNORE_ROLE = 'IGNORE'

        module_function

        def action_for(role)
          case role.to_s
          when DELETE_ROLE then :delete
          when IGNORE_ROLE then :preserve_excluded
          else :preserve_in_manifest
          end
        end

        def manifest_items(items)
          Array(items).reject do |item|
            action_for(item[:role] || item['role']) != :preserve_in_manifest
          end
        end

        def deleted_ids(items)
          ids_for(items, :delete)
        end

        def ignored_ids(items)
          ids_for(items, :preserve_excluded)
        end

        def included_ids(items)
          ids_for(items, :preserve_in_manifest)
        end

        def ids_for(items, action)
          Array(items).filter_map do |item|
            role = item[:role] || item['role']
            id = item[:id] || item['id']
            id if action_for(role) == action
          end
        end
        private_class_method :ids_for
      end
    end
  end
end
