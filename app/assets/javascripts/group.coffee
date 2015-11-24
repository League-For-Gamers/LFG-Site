$ ->
	Foundation.utils.S('.group-burger-button').click ->
		node = Foundation.utils.S(this)
		n = node.next(".group-control-panel")
		n.toggleClass("shown")
		n.removeClass("hidden")
	if window.location.pathname.match(/\/group/i)
		Foundation.utils.S('.post-icon').click ->
			Foundation.utils.S('.blackout').show()
			Foundation.utils.S('.blackout').data('usage', '#new-post')
			Foundation.utils.S('#new-post').show()
		return