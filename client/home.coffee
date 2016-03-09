# We do not need to sync this collection on server neither do we want to store anything.
@Torrents = new Meteor.Collection null
@Files = new Meteor.Collection null

# Set default values for this page and only this page
Page = new ReactiveDict
Page.setDefault 'currentPage', 1
Page.setDefault 'query', {}
Page.setDefault 'sortBy', {seeds: -1}

isLocal = ->
  'localhost' is window.location.hostname

Logs.addListener 'message', (key, value) ->
  console.log 'got message', key, value
  App.set key, value

# Gather search results and dispatch to local collections.
# NOTE: might be easier to just stick with App.get since it is already a reactive
# data source. But then we might lack search facilities of ReactiveTable package.
Tracker.autorun ->
  results = App.get 'results'
  return unless results
  {torrents, local} = results
  if torrents
    torrents.forEach (torrent) ->
      Torrents.insert torrent
  if local
    local.forEach (file) ->
      console.log 'file', file
      Files.insert file

Template.homeTV.onRendered ->
  if isLocal
    $('body').addClass 'tv'
  return

# When rendered, ask for what we may have missed and set App values accordingly.
Template.homeRemote.onRendered ->
  Meteor.call 'replayLog', (err,res) ->
    if err
      console.error 'replayLog', err
    else
      console.log 'replayLog', res
      for key, value of res
        App.set key, JSON.parse value

Template.homeRemote.helpers
  # Set styles for peers animation
  innerStyles: ->
    ratio = (@peers?.length|0) / (@seeds + @leechs)
    ratio *= 2
    if ratio > 1 then ratio = 1
    red = Math.ceil(255 - ratio*255)
    tmp = red.toString 16
    redStr = ("00" + tmp).substring(tmp.length, 2+tmp.length)
    green = Math.ceil(ratio*255)
    tmp = green.toString 16
    greenStr = ("00" + tmp).substring(tmp.length, 2+tmp.length)
    "background-color:##{redStr}#{greenStr}00;"

  # If we have a video url endpoint forward it to the inner template.
  playInBrowser: ->
    playInBrowser = App.get 'playInBrowser'
    if playInBrowser
      App.set 'showNavs', false
    playInBrowser
  hasTorrents: ->
    doc = Torrents.findOne()
    console.log 'hastorrents', doc
    return false unless doc
    fields = _.keys doc
    fields.length isnt 0
  file: ->
    Files.find()
  options: ->
    fields = _.keys _.omit Torrents.findOne(), ['_id']
    console.log 'option fields', fields
    opts =
      collection: Torrents
      fields: fields
      maxPages: 3
      config:
        pagination: true

    page = Page.get 'currentPage'
    if page < 1 then page = 1
    opts.page = page
    opts.limit = Page.get 'maxByPage'
    opts.query = Page.get 'query'
    opts.sort = Page.get 'sortBy'
    opts

Template.homeRemote.events
  'submit form': (evt, tmpl) ->
    evt.preventDefault()
    evt.stopImmediatePropagation()
    input = tmpl.find 'input'
    console.log 'form submit', input.value

    # A whole new search, clear history..
    Torrents.remove {}
    Files.remove {}
    App.set 'currentFile', undefined

    Meteor.call 'search', ['torrents','local'], input.value, 'all', (err,res) ->
      if err
        throw err
      else
        console.log res
      return

    return

  'click .play': (evt, tmpl) ->
    evt.preventDefault()
    evt.stopImmediatePropagation()
    torrent = Torrents.findOne _id: @_id
    console.log 'clicked play', @
    return unless torrent
    Meteor.call 'play', torrent, (err,res) ->
      console.log res
      console.error err
    return

Template.linkLocalFile.events
  'click': (evt, tmpl) ->
    evt.preventDefault()
    evt.stopImmediatePropagation()
    file = Files.findOne _id: @_id
    console.log 'clicked play local', @
    return unless file
    Meteor.call 'play', file, (err,res) ->
      console.log res
      console.error err
    return

Template.tableLayout_bootstrap_useractions.helpers
  sortState: ->
    sortBy = Page.get 'sortBy'
    sort = sortBy[@id]
    switch sort
      when 1 then 'asc'
      when -1 then 'desc'
      else 0

Template.tableLayout_bootstrap_useractions.events
  'click .fa-times': (evt, tmpl) ->
    fields = Page.get 'fields'
    unless fields instanceof Array
      console.error "Fields must be an array!", fields
      return
    Page.set 'fields', _.filter fields, (field) => field isnt @id
    return

  'click .fa-chevron-down': (evt, tmpl) ->
    sortBy = Page.get 'sortBy'
    sortBy[@id] = -1
    Page.set 'sortBy', sortBy
    return

  'click .fa-ban': (evt, tmpl) ->
    sortBy = Page.get 'sortBy'
    delete sortBy[@id]
    Page.set 'sortBy', sortBy
    return

  'click .fa-chevron-up': (evt, tmpl) ->
    sortBy = Page.get 'sortBy'
    sortBy[@id] = 1
    Page.set 'sortBy', sortBy
    return

Template.tableLayout_bootstrap_pagination.helpers
  disabledIfFirstPage: ->
    if @data.page is 1 then 'disabled' else ''
  disabledIfLastPage: ->
    if @data.endIndex >= @data.count then 'disabled' else ''

Template.pagination_page.events
  'click': (evt, tmpl) ->
    evt.preventDefault()
    evt.stopImmediatePropagation()
    Page.set 'currentPage', @page
    return

Template.tableLayout_bootstrap_pagination.events
  'click .previous': (evt, tmpl) ->
    evt.preventDefault()
    evt.stopImmediatePropagation()
    Page.set 'currentPage', @data.page - 1
    return
  'click .next': (evt, tmpl) ->
    evt.preventDefault()
    evt.stopImmediatePropagation()
    Page.set 'currentPage', @data.page + 1
    return
