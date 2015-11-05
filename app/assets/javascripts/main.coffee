$ ->
  @original_title = Foundation.utils.S("title").text()
  Foundation.utils.S('.quick-submit').keydown (e) ->
    if e.ctrlKey and e.keyCode == 13
      $(this).closest("form").submit()
    return
  Foundation.utils.S('.show_hidden').click ->
    node = Foundation.utils.S(this)
    id = node.data("id")
    Foundation.utils.S("#hidden-#{id}").toggle()
    if node.text().match /show/i
      node.text node.text().replace(/show/i, "Hide")
    else
      node.text node.text().replace(/hide/i, "Show")
  Foundation.utils.S('#login-button').click (e) -> 
    e.preventDefault()
    Foundation.utils.S('#login-form').slideToggle(200);