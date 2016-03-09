fs = require 'fs'
WebTorrent = require 'webtorrent'
util = require 'util'

client = new WebTorrent()

download = (link, extensions) ->
  client.add link, (torrent) ->
    # Got torrent metadata!
    {infoHash, path} = torrent
    process.send log: "Client is downloading: #{infoHash} to #{path}"

    filesToDownload = []
    torrent.files.forEach (file) ->
      {name, length} = file
      console.log 'testing', name, '(', length, ') against', extensions
      if extensions.test name
        filesToDownload.push file
      return

    torrent.on 'wire', (wire, addr) ->
      process.send peer: addr
      return

    # We have a list of files to download, depending on what we have in the torrent file
    # it may be interesting to apply some 'optimizations' on which file should be downloaded first.
    # So if only two video files are in the torrent, it *might* be a movie and its sample video.
    # We will play the sample first, so order our download list as smallest file first.
    # If there are more files, it probably is a whole season, sort by file name.
    # That should probably be better to somewhat 'analyze' the file names to make sure it is in
    # order but this should probably handle 90% of the cases.
    switch filesToDownload.length
      when 1 then sortedFiles = filesToDownload
      when 2 then sortedFiles = filesToDownload.sort (a,b) -> a.length - b.length
      else
        sortedFiles = filesToDownload.sort (a,b) -> (a.name > b.name) - (a.name < b.name)

    # And start downloading them
    maxFiles = sortedFiles.length
    sortedFiles.forEach (file, index) ->
      {name, length} = file
      process.send log: "downloading file: #{name} (#{length} bytes)"
      sS = file.createReadStream()
      .once 'data', ->
        process.send
          log: "Got stream!"
          hasData: true
          file: "#{path}/#{file.path}"
          index: index
          size: length
          max: maxFiles
        return
      .on 'error', (e) ->
        process.send error: "Pipe error: #{e}"
        @end()
        return
      .once 'end', (code) ->
        console.log '[TORRENT] end event'
        process.send
          log: 'Finished download'
          finishedDownload: true

    return
  return

reMagnet = new RegExp /magnet:\?xt=urn:btih:[a-z0-9]{20,50}&/

process.on 'message', (msg) ->
  return unless msg
  {url, ext} = msg

  magnet = null unless reMagnet.test url
  rExt = new RegExp ext
  console.log 'what we have now', url
  if magnet is null
    process.send error: "Wrong parameter, need a valid magnet URI, not: #{util.inspect url}"
  else
    download url, rExt
  return

process.env['NODE_TLS_REJECT_UNAUTHORIZED'] = '0'

if process.send
  process.send { program: 'Torrents Downloader Engine for VideoBox', version: '0.3.0'}
