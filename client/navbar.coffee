Template.navbar.helpers
  animation: ->
    showNav = App.get 'showNav'
    showNavs = App.get 'showNavs'
    if showNav or showNavs
      'show'
    else 'hide'

Template.footer.helpers
  animation: ->
    showFooter = App.get 'showFooter'
    if showFooter
      'show'
    else 'hide'
