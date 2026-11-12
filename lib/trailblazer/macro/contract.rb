require "trailblazer/macro"

require "trailblazer/macro/contract/build"
require "trailblazer/macro/contract/validate"
require "trailblazer/macro/contract/persist"

module Trailblazer
  module Macro
    module Contract
      module Constants
        module Contract
          extend Macro::Contract::Build
          extend Macro::Contract::Validate
          extend Macro::Contract::Persist
        end
      end

      TOPOLOGY_BUILD_OPTIONS = {
        helpers: {
          Module.new => [:hash] # FIXME: we can't have constants, only, currently.
        },
        constants: [
          Macro::Contract::Constants,
        ],

        adds: [
        ]
      }
    end
  end

end
