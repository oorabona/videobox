{fork, spawn} = Meteor.npmRequire 'child_process'
path = Meteor.npmRequire 'path'
Future = Meteor.npmRequire 'fibers/future'

Player = null
pPlayer = null

# this should be part of Config ...
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

handleAction = (action) ->
  console.log 'new action', action
  if action and mapping[action] and pPlayer
    pPlayer.stdin.write mapping[action], -> console.log 'sent "', mapping[action],'"'

downloader = spawn 'coffee', ["#{path.resolve '.'}/assets/app/player.coffee"], {env: process.env, cwd: process.cwd, stdio: [0,1,2,'ipc']}

downloader.on 'exit', Meteor.bindEnvironment (code) ->
  Logs.emit 'message', 'debug', "Client script exited with code #{code}"
downloader.on 'error', Meteor.bindEnvironment (e) ->
  Logs.emit 'message', 'error', "Caught exception #{e}"
downloader.on 'message', Meteor.bindEnvironment (m) ->
  console.log 'DOWNLOADER got message', m
  {error, log, hasData, file} = m
  if error
    console.error error
  if log
    Logs.emit 'message', 'log', log
  if hasData and file and pPlayer is null
    Player = Config.findOne({key: 'player'})?.value
    unless Player
      Logs.emit 'message', 'error', "Cannot find player settings! Abort."
      return

    {cmd, args} = Player
    args = args.concat file
    console.log 'spawn', cmd, args
    pPlayer = spawn cmd, args, {env: process.env, cwd: process.cwd, stdio: ['pipe', 'pipe', 'pipe', 'ipc']}
    pPlayer.stdout.on 'data', (data) -> # console.log 'stdout', data.toString()
    pPlayer.on 'exit', Meteor.bindEnvironment (code) ->
      pPlayer = null
      Logs.emit 'message', 'log', "Player exited with code #{code}"
    pPlayer.on 'error', Meteor.bindEnvironment (e) ->
      Logs.emit 'message', 'error', "Player caught exception: #{e}"
    pPlayer.on 'message', Meteor.bindEnvironment (m) ->
      console.log 'pPlayer PARENT got message', m

Meteor.methods
  'play': (what) ->
    @unblock()
    console.log 'play', what
    return unless what
    if pPlayer
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
