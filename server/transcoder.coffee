path = Meteor.npmRequire 'path'
{spawn} = Meteor.npmRequire 'child_process'
through2 = Meteor.npmRequire 'through2'
fs = Meteor.npmRequire 'fs'

Tracker.autorun ->
  # Do not do anything until we really need it !
  transcodeTo = App.get 'transcoding'
  return unless transcodeTo

  {input, output, cmd, args} = transcodeTo

  try
    stat = fs.lstatSync convertedFile
  catch e
    stat = null

  # If we have something, do not do twice the same job..
  return if !!stat and stat?.size > 0

  console.log '[TRANSCODE] input file', input
  console.log '[TRANSCODE] output file', output
  console.log '[TRANSCODE] running', cmd, args

  cpTranscode = spawn cmd, args
  cpTranscode.on 'error', (e) -> console.log 'error', e
  cpTranscode.on 'exit', (code) -> console.log 'exit', code

  pipe = fs.createReadStream input
  .pipe cpTranscode.stdin

  cpTranscode.stdout.pipe through2 (chunk, enc, cb) ->
    # If we are right about this, we should have data only on a per key frame basis.
    console.log '[TRANSCODE] got data', chunk.length
    @push chunk
    cb()
  .pipe fs.createWriteStream output
