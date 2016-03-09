# Show controls if 'click' event is triggered on the video element.
# Works also when user 'taps' on their smartphones/tablets

Template.videoFS.helpers
  urlAndVideoType: ->
    # Only for desktop, tablets and TV can we expect decent support for stream play
    # from a <video> tag. Otherwise, prefer download option and let the guest OS
    # decide what to do with the file..
    if Meteor.Device.isDesktop() or Meteor.Device.isTablet()
      command = 'play'
    else
      command = 'download'

    # Get supported extensions from browser..
    preferedUserVideoTypes = Config.findOne key: 'preferedVideoTypes'
    if preferedUserVideoTypes and Array.isArray preferedUserVideoTypes.value
      type = null
      for videoType in preferedUserVideoTypes.value
        supported = Modernizr.video[videoType]
        if !!supported
          type = videoType
          break

      if type isnt null
        {
          url: "/video/#{type}?#{command}"
          type: type.toUpperCase()
          mediaType: "video/#{type}"
        }
    else
      alert 'No configuration set: preferedUserVideoTypes'

Template.videoFS.events
  'click': (evt, tmpl) ->
    evt.preventDefault()
    evt.stopImmediatePropagation()
    App.set 'showNavs', true
    return

# Handle show/hide controls from here since it will only happen if video is in
# the web browser.
Meteor.setInterval ->
  playInBrowser = App.get 'playInBrowser'
  controlIsActive = App.get 'controlIsActive'
  if playInBrowser and not controlIsActive
    App.set 'showNavs', false
, 5000
