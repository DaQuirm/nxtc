TokenTree = require './token-tree.coffee'

class Lexer
	constructor: (@grammar) ->

	tokenize: (root_token, string) ->
		token_tree = new TokenTree @grammar, string, root_token
		while not token_tree.root_token.match
			do token_tree.expand
			do token_tree.match

		simplify_token = (token) ->
			{position, length} = token.match
			token: token.name
			match: string.substring position, position+length
			children: []

		match_tree = simplify_token token_tree.root_token
		expand_queue = token_tree.root_token.children.map (child) -> token:child, parent:match_tree
		while expand_queue.length > 0
			{token, parent} = do expand_queue.shift
			new_token = simplify_token token
			parent.children.push new_token
			expand_queue = expand_queue.concat token.children.map (child) -> token:child, parent:new_token
		match_tree

module.exports = Lexer
