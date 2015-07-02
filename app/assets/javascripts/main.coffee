$ ->
  $('.show_hidden').click ->
    node = $(this)
    id = node.data("id")
    console.log $("#hidden_#{id}")
    $("#hidden-#{id}").toggle()
    if node.text().match /show/i
      node.text node.text().replace(/show/i, "Hide")
    else
      node.text node.text().replace(/hide/i, "Show")