# frozen_string_literal: true

# rubocop:disable  Metrics/BlockLength
::RSpec::Matchers.define :perform_constant_number_of_queries do
  supports_block_expectations

  chain :with_scale_factors do |*factors|
    @factors = factors
  end

  chain :matching do |pattern|
    @pattern = pattern
  end

  match do |actual, *_args|
    raise ArgumentError, "Block is required" unless actual.is_a? Proc

    raise "Missing tag :n_plus_one" unless
      @matcher_execution_context.respond_to?(:n_plus_one_populate)

    populate = @matcher_execution_context.n_plus_one_populate

    # by default we're looking for select queries
    pattern = @pattern || /^SELECT/i

    @queries = NPlusOneControl::Executor.call(
      population: populate,
      matching: pattern,
      scale_factors: @factors,
      &actual
    )

    counts = @queries.map(&:last).map(&:size)

    counts.max == counts.min
  end

  match_when_negated do |_actual|
    raise "This matcher doesn't support negation"
  end

  failure_message { |_actual| NPlusOneControl.failure_message(@queries) }
end
