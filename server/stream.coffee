# Stream current video file to corresponding client(s)
fs = Meteor.npmRequire 'fs'
Throttle = Meteor.npmRequire 'throttle'
path = Meteor.npmRequire 'path'
{exec} = Meteor.npmRequire 'child_process'
es = Meteor.npmRequire 'event-stream'

# FIXME: Some predefined variables that should definitely be parameters
debug            = true
strict           = false
chunkSize        = 272144
cacheControl     = 'public, max-age=31536000, s-maxage=31536000'
integrityCheck   = false
throttle         = false

###*
  @name returnReponse
  @param response (Object) - response object from WS middleware
  @param responseType (Integer) - HTTP return code
  @param file (String) - file name to stream from
  @param reqRange (Object) - request range bytes
  @param take (Integer) - how many bytes to stream
  @param transcodeFn (Function) - transcode function that will be pipelined while streaming response
###
returnResponse = (response, responseType, file, size, reqRange, take, transcodeFn) ->
  streamErrorHandler = (error) ->
    response.writeHead 500
    response.end error.toString()

  switch responseType
    when '400'
      console.warn "Debugger: [400] Content-Length mismatch!: #{file}" if debug
      text = "Content-Length mismatch!"
      response.writeHead 400,
        'Content-Type':   'text/plain'
        'Cache-Control':  'no-cache'
        'Content-Length': text.length
      response.end text
      break
    when '404'
      console.warn "Debugger: [404] File not found: #{file}" if debug
      text = "Not Found :("
      response.writeHead 404,
        'Content-Length': text.length
        'Content-Type':   "text/plain"
      response.end text
      break
    when '416'
      console.info "Debugger: [416] Content-Range is not specified!: #{file}" if debug
      response.writeHead 416,
        'Content-Range': "bytes */#{size}"
      response.end()
      break
    when '200'
      console.info "Debugger: [200]: #{file}" if debug
      stream = fs.createReadStream file
      stream.on('open', =>
        response.writeHead 200
        # Include transcode function in the pipeline
        if transcodeFn
          stream.pipe es.child exec transcodeFn
        if throttle
          stream.pipe( new Throttle {bps: throttle, chunksize: chunkSize}
          ).pipe response
        else
          stream.pipe response
      ).on 'error', streamErrorHandler
      break
    when '206'
      console.info "Debugger: [206]: #{file}" if debug
      response.setHeader 'Content-Range', "bytes #{reqRange.start}-#{reqRange.end}/#{size}"
      response.setHeader 'Content-Length', take
      response.setHeader 'Transfer-Encoding', 'chunked'
      if throttle
        stream = fs.createReadStream file, {start: reqRange.start, end: reqRange.end}
        stream.on('open', =>
          response.writeHead 206
          if transcodeFn
            stream.pipe es.child exec transcodeFn
        ).on('error', streamErrorHandler
        ).on('end', -> response.end()
        ).pipe( new Throttle {bps: throttle, chunksize: chunkSize}
        ).pipe response
      else
        stream = fs.createReadStream file, {start: reqRange.start, end: reqRange.end}
        stream.on('open', =>
          response.writeHead 206
          if transcodeFn
            stream.pipe es.child exec transcodeFn
        ).on('error', streamErrorHandler
        ).on('data', (chunk) -> response.write chunk
        ).on 'end', -> response.end()
      break

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

WebApp.connectHandlers.use '/video/mp4', (request, response, next) ->
  {query} = request

  {file, size} = App.get 'playing'
  console.log 'current file playing', file

  unless fs.existsSync file
    returnResponse response, '404', file

  partiral     = false
  reqRange     = false
  fileStats    = fs.statSync file

  if integrityCheck
    console.log 'checking', fileStats.size, 'expected', size
    if fileStats.size isnt size
      returnResponse response, '400', file, size

  if query.download and query.download == 'true'
    dispositionType = 'attachment; '
  else
    dispositionType = 'inline; '

  # Extract file name from the path
  name = path.basename file
  dispositionName     = "filename=\"#{encodeURIComponent(name)}\"; filename=*UTF-8\"#{encodeURIComponent(name)}\"; "
  dispositionEncoding = 'charset=utf-8'

  response.setHeader 'Content-Type', 'video/mp4'
  response.setHeader 'Content-Disposition', dispositionType + dispositionName + dispositionEncoding
  response.setHeader 'Accept-Ranges', 'bytes'
  response.setHeader 'Last-Modified', fileStats.updatedAt?.toUTCString() if fileStats.updatedAt?.toUTCString()
  response.setHeader 'Connection', 'keep-alive'

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

  # transcodeFn = 'ffmpeg -i pipe:0 -c:v libx264 -c:a copy pipe:1'
  transcodeFn = undefined

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
    response.setHeader 'Cache-Control', 'private, maxage=10800, s-maxage=32400'

    if (strict and not request.headers.range) or reqRange.start >= fileStats.size or reqRange.end > fileStats.size
      returnResponse response, '416', file, size, reqRange, take, transcodeFn
    else
      returnResponse response, '206', file, size, reqRange, take, transcodeFn
  else
    response.setHeader 'Cache-Control', cacheControl
    returnResponse response, '200', file, size, reqRange, take
