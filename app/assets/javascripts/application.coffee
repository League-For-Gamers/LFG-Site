# This is a manifest file that'll be compiled into application.js, which will include all the files
# listed below.
#= require vendor/modernizr
#= require jquery
#= require jquery.turbolinks
#= require jquery_ujs
#= require jquery-placeholder
#= require jquery.timeago

#= require foundation/foundation
# require foundation/foundation.abide
#= require foundation/foundation.accordion
#= require foundation/foundation.alert
# require foundation/foundation.clearing
# require foundation/foundation.dropdown
#= require foundation/foundation.equalizer
# require foundation/foundation.interchange
# require foundation/foundation.joyride
# require foundation/foundation.magellan
# require foundation/foundation.offcanvas
# require foundation/foundation.orbit
#= require foundation/foundation.reveal
# require foundation/foundation.slider
# require foundation/foundation.tab
#= require foundation/foundation.tooltip
# require foundation/foundation.topbar

#= require turbolinks
#= require_tree .

@ie_browser = !!navigator.userAgent.match(/Trident\/\d+/)
@ff_browser = !!navigator.userAgent.match(/Firefox\/\d+/)

$ ->
  $(document).foundation()
  $('input, textarea').placeholder()
  Turbolinks.enableProgressBar()
  Turbolinks.enableTransitionCache()
  return