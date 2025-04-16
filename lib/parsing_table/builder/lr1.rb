require 'set'

class ParsingTable::Builder::LR1
  Item = Data.define(:rule_index, :position, :lookahead) do
    def advanced
      Item.new(rule_index:, position: position + 1, lookahead:)
    end
  end

  State = Data.define(:item_set, :transitions)

  def initialize(rules:)
    @rules = rules
    @states = []
  end

  def build
    @states << State.new(item_set: closure_of([initial_item]), transitions: {})
    visit_state(0)
    puts
    puts "=== STATES"
    @states.each_with_index do |row, i|
      puts
      puts "==== State #{i}"
      row.item_set.each do |item|
        puts "[#{@rules[item.rule_index].to_s(item.position)}\t, #{item.lookahead.inspect}]"
      end
    end
    puts
    puts "=== TRANSITIONS"
    STDOUT.puts "\t*\t+\t0\t1\tE\tB"
    @states.each_with_index do |row, i|
      STDOUT.print "#{i}\t"
      ['*', '+', '0', '1', NonTerminal.new('E'), NonTerminal.new('B')].each do |s|
        STDOUT.print (row.transitions[s] || 'nil')
        STDOUT.print "\t"
      end
      STDOUT.print "\n"
      STDOUT.flush
    end

    table = @states.each_with_index.map do |state, state_index|
      actions = {}
      goto = {}
      state.transitions.each do |symbol, next_state_index|
        if symbol.is_a?(NonTerminal)
          goto[symbol] = next_state_index
        else
          actions[symbol] = ::ParsingTable::State::ShiftAction.new(next_state_index)
        end
      end
      state.item_set.select { |item| reducing_item?(item) }.each do |reducing_item|
        action = ::ParsingTable::State::ReduceAction.new(reducing_item.rule_index)
        if actions[reducing_item.lookahead]
          raise "conflict: at [#{state_index},#{reducing_item.lookahead}], want #{action.to_s} but already #{actions[reducing_item.lookahead]}"
        end
        if reducing_item.rule_index == 0
          actions[reducing_item.lookahead] = ::ParsingTable::State::AcceptAction.new
        else
          actions[reducing_item.lookahead] = ::ParsingTable::State::ReduceAction.new(reducing_item.rule_index)
        end
      end
      ::ParsingTable::State.new(actions:, goto:)
    end
    ParsingTable.new(table)
  end

  private def reducing_item?(item)
    @rules[item.rule_index].rhs.size == item.position
  end

  private def visit_state(state_index)
    state = @states[state_index]
    state.item_set.group_by { |item| symbol_at(item) }.each do |symbol, items|
      next if symbol == '$'

      advanced_items = closure_of(items.map(&:advanced))
      new_state_index =
        if (new_state_index = @states.find_index { |st| st.item_set == advanced_items })
          new_state_index
        else
          new_state_index = @states.size
          @states << State.new(item_set: advanced_items, transitions: {})
          visit_state(new_state_index)
          new_state_index
        end
      state.transitions[symbol] = new_state_index
    end
  end

  private def closure_of(item_set)
    Set.new.tap do |s|
      item_set.each do |item|
        s.merge(concurrent_items(item))
      end
    end
  end

  private def concurrent_items(item)
    Set.new.tap do |s|
      collect_concurrent_items(s, item)
    end
  end

  private def collect_concurrent_items(acc, item)
    symbol = symbol_at(item)
    acc << item
    return unless symbol.is_a?(NonTerminal)

    rules_for(symbol).flat_map do |_rule, rule_index|
      first_terminals(following_symbols(item.advanced) + [item.lookahead]).each do |lookahead|
        concurrent_item = Item.new(rule_index:, position: 0, lookahead:)
        unless acc.include?(concurrent_item)
          acc << concurrent_item
          collect_concurrent_items(acc, concurrent_item)
        end
      end
    end
  end

  private def following_symbols(item)
    @rules[item.rule_index].rhs[item.position..]
  end

  private def first_terminals(symbols)
    head = symbols.first
    return Set.new unless head

    case head
    when NonTerminal
      result = Set.new
      rules_for(head).each do |rule, _index|
        result.merge(first_terminals(rule.rhs))
      end
      if nullable?(head)
        result.merge(first_terminals(symbols[1..]))
      end
      result
    else
      Set.new([head])
    end
  end

  private def nullable?(nonterminal)
    rules_for(nonterminal).any? do |rule, _index|
      rule.rhs.all? { |s| s.is_a?(NonTerminal) } && rule.rhs.all? { |s| nullable?(s) }
    end
  end

  private def symbol_at(item)
    @rules[item.rule_index].rhs[item.position] || '$'
  end

  private def rules_for(non_terminal)
    @rules.each_with_index.select { |rule, _i| rule.lhs == non_terminal }
  end

  private def initial_item
    Item.new(rule_index: 0, position: 0, lookahead: '$')
  end
end

