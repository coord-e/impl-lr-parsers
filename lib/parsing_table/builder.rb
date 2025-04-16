require 'set'

class ParsingTable::Builder
  Item = Data.define(:rule_index, :position) do
    def advanced
      Item.new(rule_index:, position: position + 1)
    end
  end

  State = Data.define(:item_set, :transitions)

  def initialize(rules:)
    @rules = rules
    @states = []

    # TODO: ?
    @all_tokens = Set.new(['$'])
    @rules.each do |rule|
      rule.rhs.each do |sym|
        unless sym.is_a?(NonTerminal)
          @all_tokens << sym
        end
      end
    end
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
        puts @rules[item.rule_index].to_s(item.position)
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

    table = @states.each_with_index.map do |state, sti|
      actions = {}
      goto = {}
      state.transitions.each do |symbol, next_state_index|
        if symbol.is_a?(NonTerminal)
          goto[symbol] = next_state_index
        else
          actions[symbol] = ::ParsingTable::State::ShiftAction.new(next_state_index)
        end
      end
      if state.item_set.any? { |item| item.rule_index == 0 && item.position == @rules[0].rhs.size }
        actions['$'] = ::ParsingTable::State::AcceptAction.new
      end
      if (reducing_item = state.item_set.find { |item| reducing_item?(item) && item.rule_index > 0 })
        unless actions.empty?
          raise "shift-reduce conflict"
        end
        actions = @all_tokens.map { |t| [t, ::ParsingTable::State::ReduceAction.new(reducing_item.rule_index)] }.to_h
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
      next if symbol.nil?

      advanced_items = closure_of(items.map(&:advanced))
      new_state_index =
        if (new_state_index = @states.find_index { |st| st.item_set == advanced_items })
          new_state_index
        else
          new_state_index = @states.size
          @states << State.new(item_set: advanced_items, transitions: {})
          new_state_index
        end
      state.transitions[symbol] = new_state_index
      visit_state(new_state_index)
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
      concurrent_item = Item.new(rule_index:, position: 0)
      unless acc.include?(concurrent_item)
        acc << concurrent_item
        collect_concurrent_items(acc, concurrent_item)
      end
    end
  end

  private def symbol_at(item)
    @rules[item.rule_index].rhs[item.position]
  end

  private def rules_for(non_terminal)
    @rules.each_with_index.select { |rule, _i| rule.lhs == non_terminal }
  end

  private def initial_item
    Item.new(rule_index: 0, position: 0)
  end
end
