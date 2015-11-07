$ ->
	Foundation.utils.S(".group-burger-button").click ->
		node = Foundation.utils.S(this)
		n = node.next(".group-control-panel")
		n.toggleClass("shown")
		n.removeClass("hidden")
	if window.location.pathname.match(/\/group/i)
		loading_cards = {"next": false, "prev": false}
		Foundation.utils.S(".menu-panel .navigator a").click ->
			node = this
			dir = Foundation.utils.S(this).data("dir")
			source = Foundation.utils.S(this).parent().data("source")
			collection = Foundation.utils.S(this).parent().parent().parent().next(".collection")
			page = collection.data("page")
			collection.height(collection.height())
			switch dir
				when "next"
					page = page + 1
				when "prev"
					page = page - 1
			if page < 0
				page = 0
			if !loading_cards[dir]
				loading_cards[dir] = true
				console.log "Loading page: #{page}"
				$.ajax
					url: "/group"
					type: 'POST'
					dataType: 'html'
					data: {'source': source, 'page': page}
					complete: (data) ->
						collection.html(data.responseText)
						collection.data("page", page)
						if page == 1
							$(node).parent().children("a[data-dir='prev']").removeClass("hidden")
						if page == 0
							$(node).parent().children("a[data-dir='prev']").addClass("hidden")
						if collection.children().length < 12 or (collection.children().length == 12 and $(node).parent().children("a[data-dir='next']").hasClass("hidden"))
							$(node).parent().children("a[data-dir='next']").toggleClass("hidden")
						loading_cards[dir] = false
