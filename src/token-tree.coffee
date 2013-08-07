class TokenTree

	@create_node: (token_name) ->
		name: token_name
		children: []
		next: null
		match: null

	constructor: (@grammar, root_token_name)->
		@current_token = @root_token = TokenTree.create_node root_token_name

	expand: ->
		while not @grammar.is_terminal @current_token.name
			@current_token.children = @grammar.tokens[@current_token.name].map TokenTree.create_node
			@current_token = @current_token.next

module.exports = TokenTree
