fs = Meteor.npmRequire 'fs'
Throttle = Meteor.npmRequire 'throttle'

###*
  @name returnReponse
  @param response (Object) - response object from WS middleware
  @param responseType (Integer) - HTTP return code
  @param file (String) - file name to stream from
  @param reqRange (Object) - request range bytes
  @param take (Integer) - how many bytes to stream
###
@returnResponse = (response, responseType, file, size, reqRange, take) ->
  streamErrorHandler = (error) ->
    response.writeHead 500
    response.end error.toString()

  switch responseType
    when '503'
      console.warn "Debugger: [503] Server processing your request: #{file}" if debug
      isTranscoding = App.get 'transcoding'
      text = "Server processing your request: #{file}"
      response.writeHead 503,
        'Content-Type':   'text/plain'
        'Cache-Control':  'no-cache'
        'Content-Length': text.length
        'Retry-After': '10'
      response.end text
      break
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
        'Cache-Control':  'no-cache'
        'Content-Type':   "text/plain"
      response.end text
      break
    when '416'
      console.info "Debugger: [416] Content-Range is not specified!: #{file}" if debug
      response.writeHead 416,
        'Content-Range': "bytes */#{size}"
        'Cache-Control':  'no-cache'
      response.end()
      break
    when '200'
      console.info "Debugger: [200]: #{file}" if debug
      stream = fs.createReadStream file
      stream.on('open', =>
        response.writeHead 200
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
        ).on('error', streamErrorHandler
        ).on('end', -> response.end()
        ).pipe( new Throttle {bps: throttle, chunksize: chunkSize}
        ).pipe response
      else
        stream = fs.createReadStream file, {start: reqRange.start, end: reqRange.end}
        current = reqRange.start
        stream.on('open', =>
          response.writeHead 206
        ).on('error', streamErrorHandler
        ).on('close', ->
        ).on('data', (chunk) ->
          response.write chunk
        ).on 'end', ->
          response.end()

      break
    else
      console.info "Debugger: [#{responseType}]: #{file}" if debug
      text = file   # A bit hacky though...
      response.writeHead 404,
        'Content-Length': text.length
        'Cache-Control':  'no-cache'
        'Content-Type':   "text/plain"
      response.end text
