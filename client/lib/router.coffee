getRenderTemplate = (name) ->
  {hostname} = window.location
  if hostname is 'localhost'
    "#{name}TV"
  else
    "#{name}Remote"

Router.configure
  layoutTemplate: 'layout'
  notFoundTemplate: 'notFound'

Router.map ->
  @route 'about',
    path: '/about'
  @route 'home',
    path: '/'
    waitOn: ->
      [Meteor.subscribe 'config']
    data: ->
    action: ->
      @render getRenderTemplate 'home'
