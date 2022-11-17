module Trailblazer
  module Macro
    module Contract
      def self.Persist(method: :save, name: "default")
        path = :"contract.#{name}"
        step = ->(options, **) { options[path].send(method) }

        task = Activity::Circuit::TaskAdapter.for_step(step)

        {task: task, id: "persist.save"}
      end
    end
  end
end
