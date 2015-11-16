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
  Foundation.utils.S('.requires-confirmation').find('#confirmation').on 'keyup', ->
    required = Foundation.utils.S(this).attr("placeholder").toLowerCase()
    button = Foundation.utils.S(this).parent().parent().find("input[type='submit']")
    if Foundation.utils.S(this).val().toLowerCase() == required
      button.removeAttr('disabled')
    else
      button.attr('disabled', 'disabled')

  loading_navigator = {"next": false, "prev": false}
  Foundation.utils.S(".menu-panel .navigator a").click ->
    node = this
    dir = Foundation.utils.S(this).data("dir")
    source = Foundation.utils.S(this).parent().data("source")
    url = Foundation.utils.S(this).parent().data("url")
    collection = Foundation.utils.S(this).parent().parent().parent().next(".collection")
    page = collection.data("page")
    per_page = Foundation.utils.S(this).parent().data("per")
    collection.height(collection.height())
    switch dir
      when "next"
        page = page + 1
      when "prev"
        page = page - 1
    if page < 0
      page = 0
    if !loading_navigator[dir]
      loading_navigator[dir] = true
      $.ajax
        url: url
        type: 'POST'
        dataType: 'html'
        data: {'source': source, 'page': page, 'raw': true}
        complete: (data) ->
          collection.html(data.responseText)
          collection.data("page", page)
          if page == 1
            Foundation.utils.S(node).parent().children("a[data-dir='prev']").removeClass("hidden")
          if page == 0
            Foundation.utils.S(node).parent().children("a[data-dir='prev']").addClass("hidden")
          if collection.children().length < per_page or (collection.children().length == per_page and Foundation.utils.S(node).parent().children("a[data-dir='next']").hasClass("hidden"))
            Foundation.utils.S(node).parent().children("a[data-dir='next']").toggleClass("hidden")
          loading_navigator[dir] = false
