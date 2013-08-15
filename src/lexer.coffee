TokenTree = require './token-tree.coffee'

class Lexer
	constructor: (@grammar) ->

	tokenize: (root_token, string) ->
		token_tree = new TokenTree @grammar, string, root_token
		position = 0
		while not token_tree.root_token.match
			do token_tree.expand
			do token_tree.match
		match_tree = {}
		current_token = match_tree
		expand_queue = [token_tree.root_token]
		while expand_queue.length > 0
			token = expand_queue.shift
			current_token[token.name] = token.children.map (item) -> {
			current_token = current_token.next
			expand_queue = expand_queue.concat token.children


module.exports = Lexer
