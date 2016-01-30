fs = require 'fs'
WebTorrent = require 'webtorrent'

client = new WebTorrent()

playCommand = (link, extensions) ->
  client.add link, (torrent) ->
    # Got torrent metadata!
    {infoHash, path} = torrent
    process.send log: "Client is downloading: #{infoHash} to #{path}"
    torrent.files.forEach (file) ->
      {name} = file
      console.log 'testing', name, 'against', extensions
      if extensions.test name
        process.send log: "downloading file: #{name}"
        sS = file.createReadStream()
        .once 'data', ->
          process.send log: "Got stream!", hasData: true, file: "#{path}/#{file.path}"
          return
        .on 'error', (e) ->
          process.send error: "Pipe error: #{e}"
          @end()
          return
      return
    return
  return

rUrl = new RegExp /magnet:\?xt=urn:btih:[a-z0-9]{20,50}&/

process.on 'message', (msg) ->
  return unless msg
  {url, ext} = msg

  url = null unless rUrl.test url
  rExt = new RegExp ext
  console.log 'what we have now', url
  if !url
    console.log 'Wrong parameters! Need a "path" and a magnet:link...'
  else
    playCommand url, rExt
  return

process.env['NODE_TLS_REJECT_UNAUTHORIZED'] = '0'

if process.send
  process.send { program: 'Player Engine for VideoBox', version: '0.1.0'}
