require_relative './base'

module ParsingTable::Builder
  class LR0 < Base
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
      if state.item_set.any? { |item| item.rule_index == 0 && item.position == @rules[0].rhs.size }
        actions['$'] = ::ParsingTable::State::AcceptAction.new
      end
      state.item_set.select { |item| reducing_item?(item) && item.rule_index > 0 }.each do |reducing_item|
        reducing_action = ::ParsingTable::State::ReduceAction.new(reducing_item.rule_index)
        unless actions.empty?
          conflicting_token, conflicting_action = actions.first
          raise "conflict: at [#{state_index},#{conflicting_token}], want #{reducing_action.to_s} but already #{conflicting_action.to_s}"
        end
        actions = all_terminals.map { |t| [t, reducing_action] }.to_h
      end
      ::ParsingTable::State.new(actions:, goto:)
    end

    def concurrent_item_at(rule_index:, item:)
      Item.new(rule_index:, position: 0, lookahead_set: nil)
    end
  end
end
