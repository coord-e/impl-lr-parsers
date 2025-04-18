class Parser
  Node = Data.define(:name, :children) do
    def to_s
      "#{name}(#{children.map(&:to_s).join(" ")})"
    end
  end

  def initialize(table:, rules:)
    @table = table
    @rules = rules
    @stack = [0]
    @tree = []
  end

  def parse(tokens)
    puts "parse #{tokens}"
    tokens.each do |token|
      consume(token)
    end
    puts "tree #{@tree.first.to_s}"
    reset!
  end

  def reset!
    @stack = [0]
    @tree = []
  end

  def consume(token)
    puts "consume #{token}"
    case current_state.actions[token]
    in ParsingTable::State::ShiftAction(state_index:)
      puts "shift #{state_index}"
      push(state_index)

      @tree << token
    in ParsingTable::State::ReduceAction(rule_index:)
      rule = @rules[rule_index]
      puts "reduce #{rule.lhs.name}"
      rule.rhs.each do
        pop
      end
      push(current_state.goto[rule.lhs])

      children = @tree.pop(rule.rhs.size)
      @tree << Node.new(name: rule.lhs.name, children:)

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
