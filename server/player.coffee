{fork, spawn} = Meteor.npmRequire 'child_process'
path = Meteor.npmRequire 'path'
Future = Meteor.npmRequire 'fibers/future'

pPlayer = null

# FIXME: this should be part of Config ...
mapping =
  play: ' '
  pause: 'p'
  stop: 'q'
  rewind: '<'
  fforward: '>'
  next30: '\x1b\x5b\x43'
  prev30: '\x1b\x5b\x44'
  next600: '\x1b\x5b\x41'
  prev600: '\x1b\x5b\x42'
  toggleSubs: 's'

# This wraps the functunality, little at the moment, of handling remote control
# of child programs. This eventually will be more complex..
handleAction = (action) ->
  console.log 'new action', action, !!pPlayer
  if action and mapping[action] and pPlayer isnt null
    pPlayer.stdin.write mapping[action], -> console.log 'sent "', mapping[action],'"'

# Spawn video player and handle its I/O
# Input:
#   Player: program configuration
#   file: a file Object (file: String, size: Integer)
filesList = []
spawnPlayer = (Player, file) ->
  if pPlayer isnt null
    console.error "Assertion failed! pPlayer isnt null"
    return

  # Spawning !
  {cmd, args} = Player
  args = args.concat file.file

  console.log 'spawning', cmd, args
  App.set 'playing', file
  pPlayer = spawn cmd, args, {env: process.env, cwd: process.cwd, stdio: ['pipe', 'pipe', 'pipe', 'ipc']}
  pPlayer.stdout.on 'data', (data) -> # console.log 'stdout', data.toString()
  pPlayer.on 'exit', Meteor.bindEnvironment (code) ->
    Logs.emit 'message', 'log', "Player exited with code #{code}"
    pPlayer = null
    if filesList.length > 0
      nextFile = filesList.shift()
      spawnPlayer Player, nextFile
  pPlayer.on 'error', Meteor.bindEnvironment (e) ->
    Logs.emit 'message', 'error', "Player caught exception: #{e}"
  pPlayer.on 'message', Meteor.bindEnvironment (m) ->
    console.log 'pPlayer PARENT got message', m

downloader = spawn 'coffee', ["#{path.resolve '.'}/assets/app/player.coffee"], {env: process.env, cwd: process.cwd, stdio: [0,1,2,'ipc']}

Peers = []

downloader.on 'exit', Meteor.bindEnvironment (code) ->
  Logs.emit 'message', 'debug', "Client script exited with code #{code}"
downloader.on 'error', Meteor.bindEnvironment (e) ->
  Logs.emit 'message', 'error', "Caught exception #{e}"
downloader.on 'message', Meteor.bindEnvironment (m) ->
  console.log 'DOWNLOADER got message', m
  {error, peer, log, hasData, file, size, index, maxFiles} = m
  if error
    console.error error
  if log
    Logs.emit 'message', 'log', log
  if peer
    if -1 is Peers.indexOf peer
      Peers.push peer
      Logs.emit 'peers', Peers
  if hasData and file
    Player = Config.findOne({key: 'player'})?.value
    unless Player
      Logs.emit 'message', 'error', "Cannot find player settings! Abort."
      return

    console.log 'pPlayer', !!pPlayer
    # If pPlayer is not null, we need to see if we should kill the current playing
    # file (that would be the case if we are seeing a sample and now the main file is viewable).
    # Or maybe we are downloading a group of files (a whole season e.g) and
    # we should not stop but push somewhere the information on the next file to
    # be played.
    if pPlayer is null
      spawnPlayer.call @, Player, {file: file, size: size}
    else
      filesList.push file: file, size: size
      unless maxFiles > 2
        pPlayer.kill()

Meteor.methods
  'play': (what) ->
    @unblock()
    console.log 'play', what
    return unless what
    if pPlayer isnt null
      Logs.emit 'message', 'status', 'play'
      handleAction 'play'
    else
      console.log 'in play method', what
      Logs.emit 'message', 'currentTorrent', what
      ext = Config.findOne key: 'videoExt'
      ext ?= key: 'videoExt', value: '.[mp4|avi|mkv|mpeg|mpg]$'
      url = "magnet:?xt=urn:btih:#{what.hash}&"

      downloader.send {url: url, ext: ext.value}
    return

  'pause': ->
    @unblock()
    Logs.emit 'message', 'status', 'pause'
    handleAction 'pause'
    return

  'stop': ->
    @unblock()
    handleAction 'stop'
    return

  'prev30': ->
    @unblock()
    handleAction 'prev30'
    return

  'prev600': ->
    @unblock()
    handleAction 'prev600'
    return

  'next30': ->
    @unblock()
    handleAction 'next30'
    return

  'next600': ->
    @unblock()
    handleAction 'next600'
    return
