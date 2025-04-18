require_relative './lr1'

module ParsingTable::Builder
  class LALR1 < LR1
    def build_states
      super
      dump_states
      merge_states
    end

    private def merge_states
      puts
      puts "=== MERGE"

      subst = {}

      @states.each_with_index.to_a.combination(2) do |(s1, s1_index), (s2, s2_index)|
        next unless s1.item_set_without_lookahead == s2.item_set_without_lookahead
        puts "merge #{s2_index} into #{s1_index}"
        subst[s2_index] = s1_index
      end

      subst.each do |src_index, dst_index|
        src = @states[src_index]
        dst = @states[dst_index]

        dst.item_set.each do |dst_item|
          src_item = src.item_set.find { |src_item| src_item.without_lookahead == dst_item.without_lookahead }
          dst_item.lookahead_set.merge(src_item.lookahead_set)
        end

        dst.transitions.merge(src.transitions) do |key, t1, t2|
          raise "#{src_index} #{dst_index} #{key}" unless (subst[t1] || t1) == (subst[t2] || t2)
        end
      end

      @states.each do |state|
        state.transitions.transform_values! do |idx|
          subst[idx] || idx
        end
      end

      subst.keys.each do |deleted_index|
        @states[deleted_index] = nil
      end
    end
  end
end
