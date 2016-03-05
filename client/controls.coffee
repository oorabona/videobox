# Handle video controls
clicks = 0

Template.homeRemoteFooter.helpers
  animation: ->
    showNavs = App.get 'showNavs'
    if showNavs
      'show'
    else 'hide'

Template.homeRemoteFooter.events
  'change [name="controls"]': (evt, tmpl) ->
    {value} = evt.currentTarget
    console.log 'change', @
    clicks++

    # Set up timeout for show/hide controls
    controls = Meteor.setTimeout ->
      console.log 'hello cb', clicks
      # Because we land here when clicks is already 1 (first time).
      if clicks is 0
        console.log 'clicks', clicks, 'showNavs should be false'
        playInBrowser = App.get 'playInBrowser'
        if playInBrowser
          App.set 'showNavs', false
      else
        clicks--
      Meteor.clearTimeout controls
    , 2000

    playInBrowser = App.get 'playInBrowser'

    # Reset checked/unchecked value (with animation and stuff) with 100ms delay.
    ct = Meteor.setTimeout ->
      evt.currentTarget.checked = false
      Meteor.clearTimeout ct
    , 100

    console.log 'has playInBrowser', playInBrowser
    # If we are playing on the web, handle HTML5 video tag from here
    if playInBrowser
      video = document.getElementById 'backgroundvid'
      # video = new MediaElementPlayer '#backgroundvid'
      if video
        switch value
          when 'play'
            video.play()
            App.set 'status', 'play'
          when 'pause'
            video.pause()
            App.set 'status', 'pause'
          when 'stop', 'local'
            App.set 'playInBrowser', false
            App.set 'showNavs', true
          when 'next30' then video.currentTime += 30
          when 'next600' then video.currentTime += 600
          when 'prev30' then video.currentTime -= 30
          when 'prev600' then video.currentTime -= 600
          else console.error 'Unknown command', value
      else
        alert 'BUG?: No video tag !'
    else if value is 'local'
      App.set 'playInBrowser', true
    else
      # If we a remote controlling video on a distant device/display (like TV),
      # forward this server side.
      Meteor.call value, @, (err,res) ->
        console.log res
        console.error err
    return

Template.showControls.helpers
  pause: ->
    'pause' is App.get 'status'
