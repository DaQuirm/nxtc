class Grammar
	@is_terminal: (token) ->
		token.every (item) -> 'regex' of item

	constructor: (@tokens) ->

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
