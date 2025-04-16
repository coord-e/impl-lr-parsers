class Parser
  def initialize(table:, rules:)
    @table = table
    @rules = rules
    @stack = [0]
  end

  def parse(tokens)
    puts "parse #{tokens}"
    tokens.each do |token|
      consume(token)
    end
  end

  def consume(token)
    puts "consume #{token}"
    case current_state.actions[token]
    in ParsingTable::State::ShiftAction(state_index:)
      puts "shift #{state_index}"
      push(state_index)
    in ParsingTable::State::ReduceAction(rule_index:)
      rule = @rules[rule_index]
      puts "reduce #{rule.lhs.name}"
      rule.rhs.each do
        pop
      end
      push(current_state.goto[rule.lhs])
      consume(token)
    in ParsingTable::State::AcceptAction
      puts "accept"
      return
    else
      raise "unexpected token '#{token}'"
    end
  end

  private def push(state_index)
    @stack.push(state_index)
  end

  private def pop
    @stack.pop
  end

  private def current_state_index
    @stack.last
  end

  private def current_state
    @table.states[current_state_index]
  end
end
