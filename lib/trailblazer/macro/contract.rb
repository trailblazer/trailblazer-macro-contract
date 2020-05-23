require "trailblazer/activity"
require "trailblazer/activity/dsl/linear"

require "trailblazer/macro/contract/build"
require "trailblazer/macro/contract/validate"
require "trailblazer/macro/contract/persist"

module Trailblazer
  module Macro
    module Contract
    end
  end

  # All macros sit in the {Trailblazer::Macro::Contract} namespace, where we forward calls from
  # operations and activities to.
  module Activity::DSL::Linear::Helper
    Contract = Macro::Contract
  end
end
