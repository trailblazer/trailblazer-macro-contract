require "reform"

module Trailblazer
  module Macro
    module Contract
      module Build
        def Build(name: "default", constant: nil, builder: nil)
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
          task = Macro.task_adapter_for_decider(task_option_proc, variable_name: contract_path)

          {
            task: task,
            id: "contract.build",
            adapter: Circuit::Processor
          }
            .merge(injections)
            .merge(input)
            .merge(output)
        end

        module DSL
          # This is the class level DSL method.
          #   Op.contract #=> returns contract class
          #   Op.contract do .. end # defines contract
          #   Op.contract CommentForm # copies (and subclasses) external contract.
          #   Op.contract CommentForm do .. end # copies and extends contract.
          def contract(name = :default, constant = nil, base: Reform::Form, &block)
            heritage.record(:contract, name, constant, &block)

            path, form_class = Trailblazer::DSL::Build.new.(
              {prefix: :contract, class: base, container: self},
              name, constant, block
            )

            self[path] = form_class
          end
        end
      end
    end
  end
end
