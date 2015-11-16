$ ->
	Foundation.utils.S(".group-burger-button").click ->
		node = Foundation.utils.S(this)
		n = node.next(".group-control-panel")
		n.toggleClass("shown")
		n.removeClass("hidden")
	if window.location.pathname.match(/\/group/i)
		return