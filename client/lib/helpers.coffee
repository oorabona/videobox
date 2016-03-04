Template.registerHelper 'isLocalhost', ->
  localhost = window.location.hostname
  localhost is 'localhost'

Template.registerHelper 'isOdd', (val) -> if val % 2 then 'odd' else 'even'

Template.registerHelper '$eq', (what, that) ->
  what is that

# Template.registerHelper 'animationState', ->
#   if App.get 'animationState'

Template.registerHelper 'animationName', -> App.get 'animationName'

Template.registerHelper 'currentFile', ->
  torrent = App.get 'currentFile'
  console.log 'get torrent', torrent
  torrent
