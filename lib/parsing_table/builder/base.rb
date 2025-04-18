require 'set'

module ParsingTable::Builder
  class Base
    Item = Data.define(:rule_index, :position, :lookahead_set) do
      def advanced
        Item.new(rule_index:, position: position + 1, lookahead_set:)
      end

      def without_lookahead
        Item.new(rule_index:, position:, lookahead_set: nil)
      end
    end

    State = Data.define(:item_set, :transitions) do
      def item_set_without_lookahead
        item_set.map do |item|
          item.without_lookahead
        end
      end
    end

    def initialize(rules:)
      @rules = rules
      @states = []
    end

    def build
      build_states

      dump_states
      dump_transitions

      build_parising_table
    end

    private def build_states
      @states << State.new(item_set: closure_of([initial_item]), transitions: {})
      visit_state(0)
    end

    private def build_parising_table
      table = @states.each_with_index.map do |state, state_index|
        next unless state
        node_to_state(state_index)
      end
      ParsingTable.new(table)
    end

    def all_symbols
      @all_symbols ||= Set.new(['$']).tap do |s|
        @rules.each do |rule|
          rule.rhs.each do |sym|
            s << sym
          end
        end
      end.to_a
    end

    def all_terminals
      all_symbols.reject { |s| s.is_a?(NonTerminal) }
    end

    private def dump_states(io = STDOUT)
      io.puts
      io.puts "=== STATES"
      @states.each_with_index do |row, i|
        next unless row
        io.puts
        io.puts "==== State #{i}"
        row.item_set.each do |item|
          io.puts @rules[item.rule_index].to_s(item.position)
        end
      end
    end

    private def dump_transitions(io = STDOUT)
      io.puts
      io.puts "=== TRANSITIONS"
      io.puts "\t#{all_symbols.map(&:to_s).join("\t")}"
      @states.each_with_index do |row, i|
        next unless row
        io.print "#{i}\t"
        all_symbols.each do |s|
          io.print (row.transitions[s] || 'nil')
          io.print "\t"
        end
        io.print "\n"
        io.flush
      end
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
        concurrent_item = concurrent_item_at(rule_index:, item:)
        unless acc.include?(concurrent_item)
          acc << concurrent_item
          collect_concurrent_items(acc, concurrent_item)
        end
      end
    end

    private def concurrent_item_at(rule_index:, item:)
      raise NoMethodError
    end

    private def symbol_at(item)
      @rules[item.rule_index].rhs[item.position] || '$'
    end

    private def rules_for(non_terminal)
      @rules.each_with_index.select { |rule, _i| rule.lhs == non_terminal }
    end

    private def reducing_item?(item)
      @rules[item.rule_index].rhs.size == item.position
    end

    private def initial_item
      Item.new(rule_index: 0, position: 0, lookahead_set: Set.new(['$']))
    end
  end
end
