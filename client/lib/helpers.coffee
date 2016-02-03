Template.registerHelper 'isLocalhost', ->
  localhost = window.location.hostname
  localhost is 'localhost'

Template.registerHelper 'isOdd', (val) -> if val % 2 then 'odd' else 'even'

Template.registerHelper '$eq', (what, to) ->
  what is to
  
