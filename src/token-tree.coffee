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
			@grammar.tokens[@current_token.name].forEach (token, index) =>
				node = TokenTree.create_node token
				@current_token.children.push node
				@current_token.children[index-1].next = node unless index is 0

			[first_child, _..., last_child] = @current_token.children
			last_child ?= first_child
			last_child.next = @current_token.next
			last_child.parent = @current_token
			@current_token = @current_token.next = first_child

	match: (string, start) ->
		while @current_token? and @grammar.is_terminal @current_token.name
			match = string.substr(start).match @grammar.tokens[@current_token.name].regex
			@current_token.match =
				position: match.index + start
				length: match[0].length
			parent = @current_token.parent
			while parent
				parent.match =
					position: parent.children[0].match.position
					length: parent.children.reduce ((sum, item) -> sum + item.match.length), 0
				parent = parent.parent
			@current_token = @current_token.next

module.exports = TokenTree
