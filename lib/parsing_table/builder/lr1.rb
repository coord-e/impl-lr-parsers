require 'set'

module ParsingTable::Builder
  class LR1 < Base
    def node_to_state(state_index)
      state = @states[state_index]
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
        reducing_item.lookahead_set.each do |lookahead|
          if actions[lookahead] && actions[lookahead] != action
            raise "conflict: at [#{state_index},#{lookahead}], want #{action.to_s} but already #{actions[lookahead]}"
          end
          if reducing_item.rule_index == 0
            actions[lookahead] = ::ParsingTable::State::AcceptAction.new
          else
            actions[lookahead] = ::ParsingTable::State::ReduceAction.new(reducing_item.rule_index)
          end
        end
      end
      ::ParsingTable::State.new(actions:, goto:)
    end

    def concurrent_item_at(rule_index:, item:)
      lookahead_set = Set.new.tap do |s|
        item.lookahead_set.each do |lookahead|
          s.merge(first_terminals(following_symbols(item.advanced) + [lookahead]))
        end
      end
      Item.new(rule_index:, position: 0, lookahead_set:)
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
  end
end
