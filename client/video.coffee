# Show controls if 'click' event is triggered on the video element.
# Works also when user 'taps' on their smartphones/tablets
Template.videoFS.events
  'click': (evt, tmpl) ->
    evt.preventDefault()
    evt.stopImmediatePropagation()
    App.set 'showNavs', true
    Meteor.setTimeout ->
      localUrl = App.get 'localUrl'
      if localUrl
        App.set 'showNavs', false
    , 5000
