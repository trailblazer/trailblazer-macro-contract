module Trailblazer
  class Operation
    module Contract
      def self.Build(name: "default", constant: nil, builder: nil)
        task = lambda do |(options, flow_options), **circuit_options|
          result = Build.(options, circuit_options, name: name, constant: constant, builder: builder)

          return Activity::TaskBuilder::Binary.binary_direction_for( result, Activity::Right, Activity::Left ),
              [options, flow_options]
        end

        { task: task, id: "contract.build" }
      end

      module Build
        # Build contract at runtime.
        def self.call(options, circuit_options, name: "default", constant: nil, builder: nil)
          # TODO: we could probably clean this up a bit at some point.
          contract_class = constant || options["contract.#{name}.class"] # DISCUSS: Injection possible here?
          model          = options[:model]
          name           = "contract.#{name}"

          options[name] =
            if builder
              call_builder( options, circuit_options, builder: builder, constant: contract_class, name: name )
            else
              contract_class.new(model)
            end
        end

        def self.call_builder(options, circuit_options, builder:raise, constant:raise, name:raise)
          tmp_options = options.to_hash.merge(
            constant: constant,
            name:     name
          )
          Trailblazer::Option(builder).( options, tmp_options, circuit_options )
        end
      end
    end
  end
end
