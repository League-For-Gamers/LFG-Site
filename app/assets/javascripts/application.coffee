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
#= require foundation/foundation.orbit
#= require foundation/foundation.reveal
# require foundation/foundation.slider
# require foundation/foundation.tab
#= require foundation/foundation.tooltip
# require foundation/foundation.topbar

#= require openpgp

#= require turbolinks
#= require_tree .

openpgp.config.useWebCrypto = true
openpgp.config.aead_protect = true
# Init web worker if webcrypto has failed.
openpgp.initWorker({path:'/openpgp.worker.min.js'})

@ie_browser = !!navigator.userAgent.match(/Trident\/\d+/)
@ff_browser = !!navigator.userAgent.match(/Firefox\/\d+/)

$ ->
  $(document).foundation({
  	orbit: {
  		bullets: false,
  		timer: false,
  		slide_number: false,
  		navigation_arrows: false,
  		variable_height: true,
  		next_on_click: false
  	}
  })
  Foundation.utils.S('input, textarea').placeholder()
  Turbolinks.enableProgressBar()
  # Just a precaution. Seriously. Any measure. We need to find a way to prevent XSS attacks.
  if Foundation.utils.S("meta[name=loggedin]").attr("content") == "false"
    window.sessionStorage.removeItem('pass')
    window.localStorage.removeItem('pass')
  #Turbolinks.enableTransitionCache()
  return