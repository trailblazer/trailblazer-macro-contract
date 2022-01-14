module Trailblazer
  module Macro
    module Contract
      # result.contract = {..}
      # result.contract.errors = {..}
      # Deviate to left track if optional key is not found in params.
      # Deviate to left if validation result falsey.
      def self.Validate(skip_extract: false, name: "default", representer: false, key: nil, constant: nil, invalid_data_terminus: false, errors: nil) # DISCUSS: should we introduce something like Validate::Deserializer?
        contract_path = :"contract.#{name}" # the contract instance
        params_path   = :"contract.#{name}.params" # extract_params! save extracted params here.
        key_path      = :"contract.#{name}.extract_key"

        extract  = Validate::Extract.new(key_path: key_path, params_path: params_path)
        validate = Validate.new(name: name, representer: representer, params_path: params_path, contract_path: contract_path)

        # These are defaulting dependency injection, more here
        # https://trailblazer.to/2.1/docs/activity.html#activity-dependency-injection-inject-defaulting
        extract_injections  = {key_path => ->(*) { key }} # default to {key} if not injected.
        validate_injections = {contract_path => ->(*) { constant }} # default the contract instance to {constant}, if not injected (or passed down from {Build()})

        # Build a simple Railway {Activity} for the internal flow.
        activity = Class.new(Activity::Railway(name: "Contract::Validate")) do
          step extract,  id: "#{params_path}_extract", Output(:failure) => End(:extract_failure), inject: [extract_injections] unless skip_extract# || representer
          step validate, id: "contract.#{name}.call", inject: [validate_injections]
        end

        options = activity.Subprocess(activity)
        options = options.merge(id: "contract.#{name}.validate")

        options = options.merge(output: Errors.Output(result_path: "result.contract.#{name}", path: "contract.#{name}"), output_with_outer_ctx: true) if errors # TODO: what if we have {:output} already set?

        # Deviate End.extract_failure to the standard failure track as a default. This can be changed from the user side.
        options = options.merge(activity.Output(:extract_failure) => activity.Track(:failure)) unless skip_extract

        # Halt failure track to End with {contract.name.invalid}.
        options = options.merge(activity.Output(:failure) => activity.End(:invalid_data)) if invalid_data_terminus

        options
      end

      require "trailblazer/errors"
      module Errors # FIXME: move somewhere else!
        def self.Output(result_path:, path:)
          ->(inner_ctx, outer_ctx, **) do
            errors = outer_ctx[:errors] || Trailblazer::Errors.new # FIXME: make this better, don't instantiate here or warn or whatever?!

            result = inner_ctx[result_path]

            errors = errors.merge!(result)

            {errors: errors}
          end #->
        end
      end

      class Validate
        # Extract the contract's input from {params} by reading the hash under {:key}.
        # Example:
        #   key #=> :song
        #   ctx[:params] #=> {song: {title: "Stranded"}}
        #
        #  The extracted hash will be `{title: "Stranded"}`.
        class Extract
          def initialize(key_path: nil, params_path: nil)
            @key_path, @params_path = key_path, params_path
          end

          def call(ctx, params: {}, **)
            key = ctx[@key_path] # e.g. {:song}.
            ctx[@params_path] = key ? params[key] : params
          end
        end

        def initialize(name: "default", representer: false, params_path: nil, contract_path: )
          @name, @representer, @params_path, @contract_path = name, representer, params_path, contract_path
        end

        # Task: Validates contract `:name`.
        def call(ctx, **)
          validate!(
            ctx,
            representer: ctx[:"representer.#{@name}.class"] ||= @representer, # FIXME: maybe @representer should use DI.
            params_path: @params_path
          )
        end

        def validate!(ctx, representer: false, from: :document, params_path: nil)
          contract = ctx[@contract_path] # grab contract instance from "contract.default" (usually set in {Contract::Build()})

          # this is for 1.1-style compatibility and should be removed once we have Deserializer in place:
          ctx[:"result.#{@contract_path}"] = result =
            if representer
              # use :document as the body and let the representer deserialize to the contract.
              # this will be simplified once we have Deserializer.
              # translates to contract.("{document: bla}") { MyRepresenter.new(contract).from_json .. }
              contract.(ctx[from]) { |document| representer.new(contract).parse(document) }
            else
              # let Reform handle the deserialization.
              contract.(ctx[params_path])
            end

          result.success?
        end
      end
    end
  end # Macro
end
