class ParsingTable
  class State
    ShiftAction = Data.define(:state_index) do
      def to_s
        "s#{state_index}"
      end
    end

    ReduceAction = Data.define(:rule_index) do
      def to_s
        "r#{rule_index}"
      end
    end

    AcceptAction = Data.define do
      def to_s
        "acc"
      end
    end

    attr_reader :actions
    attr_reader :goto

    def initialize(actions:, goto: {})
      # token -> action
      @actions = actions
      # nonterminal -> state index
      @goto = goto
    end
  end

  attr_reader :states

  def initialize(states)
    @states = states
  end
end
