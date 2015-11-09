$ ->
  @original_title = Foundation.utils.S("title").text()
  Foundation.utils.S('.quick-submit').keydown (e) ->
    if e.ctrlKey and e.keyCode == 13
      Foundation.utils.S(this).closest("form").submit()
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
  Foundation.utils.S('.requires-confirmation').on 'submit', (e) ->
    r = window.confirm("Are you sure? This can't be undone.")
    if !r
      e.preventDefault()
  Foundation.utils.S('.requires-confirmation').find('#confirmation').on 'keyup', ->
    required = Foundation.utils.S(this).attr("placeholder").toLowerCase()
    button = Foundation.utils.S(this).parent().parent().find("input[type='submit']")
    if Foundation.utils.S(this).val().toLowerCase() == required
      button.removeAttr('disabled')
    else
      button.attr('disabled', 'disabled')