S = NonTerminal.new(name: 'S')
E = NonTerminal.new(name: 'E')
N = NonTerminal.new(name: 'N')

RULES = [
  Rule.new(lhs: S, rhs: [E]),
  Rule.new(lhs: E, rhs: [N]),
  Rule.new(lhs: E, rhs: [N, '+', E]),
  Rule.new(lhs: E, rhs: [N, '*', E]),
  Rule.new(lhs: N, rhs: ['(', E, ')']),
  Rule.new(lhs: N, rhs: ['-', N]),
  Rule.new(lhs: N, rhs: ['0']),
  Rule.new(lhs: N, rhs: ['1']),
  Rule.new(lhs: N, rhs: ['2']),
]
