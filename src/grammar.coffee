class Grammar

	constructor: (@tokens) ->

	is_terminal: (token_name) ->
		expansion = @tokens[token_name]
		if Array.isArray expansion
			expansion.every (item) -> typeof item isnt 'string' and 'regex' of item
		else
			'regex' of expansion

	tokenize: (root, string) ->

module.exports = Grammar
