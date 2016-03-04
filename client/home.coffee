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

Template.homeRemoteFooter.helpers
  animation: ->
    showNavs = App.get 'showNavs'
    if showNavs
      'show'
    else 'hide'

Template.homeRemote.helpers
  # Set styles for peers animation
  styles: ->
    ratio = (@peers?.length|0) / (@seeds + @leechs)
    # We consider that 50% of connected peers is enough to consider it 'green'
    ratio *= 2
    if ratio > 1 then ratio = 1
    calc = Math.ceil 40 + ratio * 400
    if isNaN calc then calc = 40
    "width: #{calc}px; height: #{calc}px;"

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
  videoFullscreen: ->
    vfs = App.get 'localUrl'
    if vfs
      App.set 'showNavs', false
      VideoUrl: vfs
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
    Torrents.remove {}
    Files.remove {}
    Meteor.call 'search', input.value, (err,res) ->
      if err
        throw err
      else
        {torrents} = res
        {files} = res
        if torrents
          torrents.forEach (torrent) ->
            Torrents.insert torrent
        if files
          files.forEach (file) ->
            console.log 'file', file
            Files.insert file
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

# Handle video controls
Template.homeRemoteFooter.events
  'change [name="controls"]': (evt, tmpl) ->
    {value} = evt.currentTarget
    console.log 'change', @
    localUrl = App.get 'localUrl'

    # Reset checked/unchecked value (with animation and stuff) with 100ms delay.
    ct = Meteor.setTimeout ->
      evt.currentTarget.checked = false
      Meteor.clearTimeout ct
    , 100
    console.log 'has localUrl', localUrl
    # If we are playing on the web, handle HTML5 video tag from here
    if localUrl
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
            App.set 'localUrl', false
            App.set 'showNavs', true
          when 'next30' then video.currentTime += 30
          when 'next600' then video.currentTime += 600
          when 'prev30' then video.currentTime -= 30
          when 'prev600' then video.currentTime -= 600
          else console.error 'Unknown command', value
      else
        alert 'No video tag !'
    else if value is 'local'
      App.set 'localUrl', true
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
