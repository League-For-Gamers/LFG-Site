$ ->
  $('.quick-submit').keydown (e) ->
    if e.ctrlKey and e.keyCode == 13
      $(this).closest("form").submit()
    return
  $('.show_hidden').click ->
    node = Foundation.utils.S(this)
    id = node.data("id")
    Foundation.utils.S("#hidden-#{id}").toggle()
    if node.text().match /show/i
      node.text node.text().replace(/show/i, "Hide")
    else
      node.text node.text().replace(/hide/i, "Show")
  $('#login-button').click (e) -> 
    e.preventDefault()
    $('#login-form').slideToggle(200);

  # wire up the remaining characters
  $('textarea[maxlength]').each (_, item) ->
    item = $(item)
    text_max = parseInt item.attr('maxlength')
    if $("##{item.attr('id')}_feedback").length == 1
      feedback = ->
        text_length = item.val().length
        text_remaining = text_max - text_length
        $("##{item.attr('id')}_feedback").html "#{text_remaining} chars left"
      item.keyup feedback
      feedback()

