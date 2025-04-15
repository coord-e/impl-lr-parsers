# lhs: NonTerminal
# rhs: Array[NonTerminal | token]
Rule = Data.define(:lhs, :rhs) do
  def to_s(i = nil)
    right = rhs.map do |sym|
      case sym
      when NonTerminal
        sym.name
      else
        sym.inspect
      end
    end
    right.insert(i, '.') if i
    "#{lhs.name} -> #{right.join(' ')}"
  end
end
