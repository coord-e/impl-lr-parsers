S = NonTerminal.new(name: 'S')
B = NonTerminal.new(name: 'B')

RULES = [
  Rule.new(lhs: S, rhs: [B]),
  Rule.new(lhs: B, rhs: ['1']),
  Rule.new(lhs: B, rhs: ['0']),
]
