# frozen_string_literal: true

module MebelFlow
  module AssetPrep
    module Persistence
      module AttributeStore
        DICTIONARY = 'MebelFlowAssetPrep'
        module_function

        def role(entity)
          entity.get_attribute(DICTIONARY, 'role', 'UNDEFINED')
        end

        def set_role(entity, role)
          raise ArgumentError, 'Unknown role' unless Domain::Roles::ALL.include?(role)

          entity.set_attribute(DICTIONARY, 'role', role)
        end
      end
    end
  end
end
