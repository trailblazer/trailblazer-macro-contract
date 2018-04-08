module Trailblazer
  class Operation
    module Contract
      module DrySchema
        # Error class for Schema
        class Errors
          def initialize(messages)
            @messages = messages
          end

          attr_reader :messages
        end

        # class used to pass in result.contract.#{name} when calling Contract::Validate(schema: Schema)
        class Schema
          def initialize(success, errors)
            @success, @errors = success, errors
          end

          def success?
            @success
          end

          def failure?
            !@success
          end
          attr_reader :errors
        end
      end
    end
  end
end
