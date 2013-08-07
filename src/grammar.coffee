class Grammar

	constructor: (@tokens) ->

	is_terminal: (token_name) ->
		@tokens[token_name].every (item) -> typeof item isnt 'string' and 'regex' of item

	tokenize: (root, string) ->
		tree =
			token: root
			string: string
			match: false
			parent: null
			chlidren: []

		pattern = [tree]

		while pattern.length > 0
			# process unmatched terminals
			terminals = pattern.filter (item) -> @is_terminal @tokens[item]
			terminals.forEach (terminal) ->
				terminal.regex

			# replace a nonterminal depth-first
			nonterminal = null
			for item in pattern
				if not Grammar.is_terminal item
					nonterminal = item
					break

module.exports = Grammar
