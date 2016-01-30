Page = new ReactiveDict
@Torrents = new Meteor.Collection null

Page.setDefault 'currentPage', 1
Page.setDefault 'query', {}
Page.setDefault 'sortBy', {seeds: -1}

isLocal = ->
  'localhost' is window.location.hostname

Logs.addListener 'message', (key, value) ->
  console.log 'got message', key, value
  Page.set key, value

Template.homeTV.onRendered ->
  if isLocal
    $('body').addClass 'tv'
  return

# Template.navbar.helpers

Template.homeRemote.onRendered ->
  Meteor.call 'replayLog', (err,res) ->
    if err
      console.error 'replayLog', err
    else
      # console.log 'replayLog', res
      for key, value of res
        Page.set key, value

Template.homeRemoteFooter.helpers
  currentTorrent: ->
    torrent = Page.get 'currentTorrent'
    console.log 'get torrent', torrent
    torrent

Template.homeRemote.helpers
  hasTorrents: ->
    doc = Torrents.findOne()
    console.log 'hastorrents', doc
    return false unless doc
    fields = _.keys doc
    fields.length isnt 0
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
    Torrents.remove {}
    Meteor.call 'search', input.value, (err,res) ->
      if err
        throw err
      else
        {torrents} = res
        torrents.forEach (torrent) ->
          Torrents.insert torrent
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

Template.showControls.events
  'change [name="controls"]': (evt, tmpl) ->
    {value} = evt.currentTarget
    Meteor.call value, @, (err,res) ->
      console.log res
      console.error err
    return

Template.showControls.helpers
  pause: ->
    'pause' is Page.get 'status'
