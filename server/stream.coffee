# Stream current video file to corresponding client(s)
fs = Meteor.npmRequire 'fs'
path = Meteor.npmRequire 'path'
util = Meteor.npmRequire 'util'
{spawn} = Meteor.npmRequire 'child_process'

transcoder = spawn 'coffee', ["#{path.resolve '.'}/assets/app/transcoder.coffee"], {env: process.env, cwd: process.cwd, stdio: [0,1,2,'ipc']}

transcoder.on 'exit', (code) ->
  console.log 'TRANSCODER Plugin exit code', code

transcoder.on 'message', Meteor.bindEnvironment (m) ->
  console.log 'TRANSCODER PARENT got message', m
  {error, log} = m
  if error
    console.error error
    Logs.emit 'message', 'error', error
  else if log
    Logs.emit 'message', 'log', log

WebApp.connectHandlers.use '/video/vtt', (request, response, next) ->
  {query} = request

  playing = App.get 'playing'
  unless playing
    returnResponse response, '500', 'Could not find current playing file.'
    return

  {file, size} = playing

  # FIXME: Of course this should be configurable !
  file += '.srt'
  console.log 'current file playing', file

  if fs.existsSync file
    text = fs.readFileSync file
  else
    text = ''

  response.writeHead 200,
    'Content-Length': text.length
    'Content-Type':   "text/plain"
  response.end text

###*
  @name createExtensionStream helps create a endpoint handler
  @param outputExtension (String) - media type to create (h)
###
createExtensionStream = (outputExtension) ->
  (request, response, next) ->
    {query} = request

    playing = App.get 'playing'
    unless playing
      return returnResponse response, '404', 'Playing file not found!'

    {file, size} = playing
    unless file
      return returnResponse response, '404', 'Playing file not found!'

    console.log 'current file playing', file

    unless fs.existsSync file
      return returnResponse response, '404', file

    # If we do not have this extension, we will need to transcode first.
    if ".#{outputExtension}" isnt path.extname file
      # Check if we have a transcoded file with the corresponding extension at our disposal.
      convertedFile = "#{file}.#{outputExtension}"

      # If such file exists, we keep on using it. Otherwise, check if we match our
      # expected output file format.
      if fs.existsSync convertedFile
        file = convertedFile
      else
        config = Config.findOne key: "transcoder_#{outputExtension}"
        config = config?.value
        console.log 'transcoding', config, outputExtension
        unless config
          return returnResponse response, 500, 'No transcoding possible with these parameters.'

        config.input = file
        config.output = convertedFile
        transcoder.send config
        return returnResponse response, '503', file

    partiral     = false
    reqRange     = false
    fileStats    = fs.statSync file

    # If we do not have the same file sizes between the original file and the
    # transcode file, set size to be the transcoded file. This also impact when
    # movie is currently being transcoded!
    if fileStats.size isnt size
      {size} = fileStats

    if query.download and query.download == 'true'
      dispositionType = 'attachment; '
    else
      dispositionType = 'inline; '

    # Extract file name from the path
    name = path.basename file
    dispositionName = "filename=\"#{encodeURIComponent(name)}\"; filename=*UTF-8\"#{encodeURIComponent(name)}\"; "
    dispositionEncoding = 'charset=utf-8'

    response.setHeader 'Content-Type', "video/#{outputExtension}"
    response.setHeader 'Content-Disposition', dispositionType + dispositionName + dispositionEncoding
    response.setHeader 'Accept-Ranges', 'bytes'
    response.setHeader 'Last-Modified', fileStats.updatedAt?.toUTCString() if fileStats.updatedAt?.toUTCString()
    response.setHeader 'Connection', 'keep-alive'
    response.setHeader 'Cache-Control', 'no-cache'

    # FIXME: definitely the way to go for good streaming, but needs to be adjusted.
    # response.setHeader 'X-Content-Duration', '2586'

    if request.headers.range
      partiral = true
      array    = request.headers.range.split /bytes=([0-9]*)-([0-9]*)/
      start    = parseInt array[1]
      end      = parseInt array[2]
      if isNaN(end)
        end    = if (start + chunkSize) < fileStats.size then start + chunkSize else fileStats.size
      take     = end - start
    else
      start    = 0
      end      = undefined
      take     = chunkSize

    if take > 4096000
      take = 4096000
      end  = start + take

    if partiral or (query.play and query.play == 'true')
      reqRange = {start, end}
      if isNaN(start) and not isNaN end
        reqRange.start = end - take
        reqRange.end   = end
      if not isNaN(start) and isNaN end
        reqRange.start = start
        reqRange.end   = start + take

      reqRange.end = fileStats.size - 1 if ((start + take) >= fileStats.size)
      response.setHeader 'Pragma', 'private'
      response.setHeader 'Expires', new Date(+new Date + 1000*32400).toUTCString()
      # response.setHeader 'Cache-Control', 'private, maxage=10800, s-maxage=32400'

      if (strict and not request.headers.range) or reqRange.start >= fileStats.size or reqRange.end > fileStats.size
        returnResponse response, '416', file, size, reqRange, take
      else
        returnResponse response, '206', file, size, reqRange, take
    else
      response.setHeader 'Cache-Control', 'public, max-age=31536000, s-maxage=31536000'
      returnResponse response, '200', file, size

WebApp.connectHandlers.use '/video/h264', createExtensionStream 'mp4'
WebApp.connectHandlers.use '/video/webm', createExtensionStream 'webm'
