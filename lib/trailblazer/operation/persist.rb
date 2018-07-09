module Trailblazer
  class Operation
    module Contract
      def self.Persist(method: :save, name: "default")
        path = "contract.#{name}"
        persist = ->(options, **) { options[path].send(method) }

        activity = Module.new do
          extend Activity::Railway(name: "Contract::Persist")

          step persist, id: "persist.#{method}", Activity::DSL.Output(:failure) => Activity::DSL.End(:persist_failure)
        end

        options = {task: activity, id: "contract.#{name}.persist", outputs: activity.outputs}

        options = options.merge(Activity::DSL.Output(:persist_failure) => Activity::DSL.Track(:failure))

        options
      end
    end
  end
end
