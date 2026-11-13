require "reform"

module Trailblazer
  module Macro
    module Contract
      module Build
        class Atom < DSL::Atom
          def build_node(**options)
            Build.build_node(**options)
          end
        end

        def Build(name: "default", constant: nil, builder: nil)
          Atom.new({name: name, constant: constant, builder: builder})
        end

        def self.build_node(name:, constant:, builder:, exec_context:, **)
          contract_path = :"contract.#{name}"

          injections = {
            Activity::Railway.Inject(:"#{contract_path}.class") => ->(*) { constant }, # default to {constant} if not injected.
          }

          # DISCUSS: can we force-default this via Inject()?
          input = {
            Activity::Railway.In() => ->(ctx, **) do
              ctx.to_hash.merge(
                constant: constant,
                name:     contract_path
              ) # FIXME: WHAT THE FUCK IS THIS?
            end
          }

          output = {
            Activity::Railway.Out() => [contract_path]
          }

          default_contract_builder = ->(ctx, model: nil, **) { ctx[:"#{contract_path}.class"].new(model) }

          # proc is called via {Option()}.
          task_option_proc = builder || default_contract_builder

          # after the builder proc is run, assign its result to {:"contract.default"}.
          task = Macro.task_adapter_for_decider(task_option_proc, variable_name: contract_path, exec_context: exec_context)

          {
            task: task,
            id: "contract.build",
            adapter: Circuit::Processor
          }
            .merge(injections)
            .merge(input)
            .merge(output)
        end
      end
    end
  end
end
