module Trailblazer
  module Macro
    module Contract
      module Persist
        def Persist(method: :save, name: "default")
          path = :"contract.#{name}"
          provider = ->(ctx, **) { ctx[path].send(method) }

          node = Activity::Step.build(provider, binary: true)

          {
            node_for_call_task: node,
            id:   :"persist.save"
          }
        end
      end
    end
  end
end
