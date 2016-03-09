path = require 'path'
{spawn} = require 'child_process'
through2 = require 'through2'
fs = require 'fs'

process.on 'message', (m) ->
  console.log '[TRANSCODE] message received', m
  {input, output, cmd, args} = m

  try
    stat = fs.lstatSync output
  catch e
    stat = null

  # If we have something, do not do twice the same job..
  return if !!stat and stat?.size > 0

  console.log '[TRANSCODE] input file', input
  console.log '[TRANSCODE] output file', output
  console.log '[TRANSCODE] running', cmd, args

  # Spawn transcoder and listen on events
  cpTranscode = spawn cmd, args
  cpTranscode.on 'error', (e) ->
    console.log 'error', e
    process.send error: e

  cpTranscode.on 'exit', (code) ->
    console.log 'exit', code
    process.send log: 'Transcoder exited.'

  # We first open the input file and pipe it to the encoding program...
  pipe = fs.createReadStream input
  .pipe cpTranscode.stdin

  # Then take the output and pipe it through a log callback and directly to the output file
  cpTranscode.stdout.pipe through2 (chunk, enc, cb) ->
    # If we are right about this, we should have data only on a per key frame basis.
    console.log '[TRANSCODE] got data', chunk.length
    @push chunk
    cb()
  .pipe fs.createWriteStream output


process.send? { program: 'Transcoder Engine for VideoBox', version: '0.3.0' }
