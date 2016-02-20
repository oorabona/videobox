Template.homeTV.helpers
  'apps': ->
    console.log 'get apps'
    apps = Config.findOne key: 'apps'
    unless apps
      console.warn 'No apps config found'
    apps.value

Template.homeTV.events
  'click .box': (evt, tmpl) ->
    evt.preventDefault()
    evt.stopImmediatePropagation()
    console.log 'clicked on box id', @name
    return

Template.ytplayer.onRendered ->
