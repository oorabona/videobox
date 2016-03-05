path = Meteor.npmRequire 'path'
{spawn} = Meteor.npmRequire 'child_process'
through2 = Meteor.npmRequire 'through2'
fs = Meteor.npmRequire 'fs'

Tracker.autorun ->
  config = Config.findOne key: 'transcoder'
  return unless config

  transcodeFn = config.value.cmd
  transcodeArgs = config.value.args

  # If we should not be here, go back
  return unless !!transcodeFn

  # FIXME: might change to allow multiple transcodings happening in the background
  isTranscoding = App.get 'transcoding'
  return if isTranscoding

  playing = App.get 'playing'
  return unless playing

  hasFinishedDownload = App.get 'finishedDownload'
  return unless hasFinishedDownload

  # Do we already have a .web version of that video ?
  {file, size} = playing
  convertedFile = "#{file}.web"

  try
    stat = fs.lstatSync convertedFile
  catch e
    stat = null

  # If we have something, do not do twice the same job..
  return if !!stat and stat?.size > 0

  console.log '[TRANSCODE] play.file', file
  console.log '[TRANSCODE] hasFinishedDownload', hasFinishedDownload
  console.log '[TRANSCODE] running', transcodeFn, transcodeArgs

  # If already mp4, drop it for now..
  return if '.mp4' is path.extname file

  cpTranscode = spawn transcodeFn, transcodeArgs
  cpTranscode.on 'error', (e) -> console.log 'error', e
  cpTranscode.on 'exit', (code) -> console.log 'exit', code

  pipe = fs.createReadStream file
  .pipe cpTranscode.stdin

  cpTranscode.stdout.pipe through2 (chunk, enc, cb) ->
    # If we are right about this, we should have data only on a per key frame basis.
    console.log 'got data', chunk.length
    @push chunk
    cb()
  .pipe fs.createWriteStream convertedFile
