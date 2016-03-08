Meteor.publish 'config', ->
  Config.find()

# Add default configuration on startup
Meteor.startup ->
  console.log '=== [Init] ==='
  # Set default values for applications
  Config.upsert {key: 'apps'}, $set: value: [
    {
      name: 'movies'
      title: 'Movies'
      tagline: 'Browse latest movies, news, informations and watch the one you like!'
      image:'/movies.jpg'
    }
    {
      name: 'youtube'
      title: 'YouTube'
      tagline: 'Browse YouTube videos directly from here!'
      image:'/Youtube.png'
    }
  ]

  # FIXME: Can we deduce it from available processors ?
  Config.upsert {key: 'videoExt'}, $set: value: '.[mp4|avi|mkv|mpeg|mpg]$'

  # Transcoder options, these must accept input from stdin stream and output to
  # stdout stream. Some programs might not work like the default 'ffmpeg' example.
  # It might then be interesing to write a wrapper..
  Config.upsert {key: 'transcoder_h264'}, $set: value:
    cmd: '/usr/bin/ffmpeg'
    args: ['-i', 'pipe:0', '-c:v', 'libx264', '-c:a', 'copy', '-movflags', 'isml+frag_keyframe', '-f', 'mp4', '-']
  Config.upsert {key: 'transcoder_webm'}, $set: value:
    cmd: '/usr/bin/ffmpeg'
    args: ['-i', 'pipe:0', '-c:v', 'vp9', '-c:a', 'copy', '-movflags', 'isml+frag_keyframe', '-f', 'webm', '-']

  # Prefered video codecs when playing on the browser.
  Config.upsert {key: 'preferedVideoTypes'}, $set: value: ['h264', 'webm']

  # Default (supported) players command line arguments!
  Config.upsert {key: 'omxplayer'}, $set: value:
    cmd: 'omxplayer'
    args: ['-b']
  Config.upsert {key: 'mplayer'}, $set: value:
    cmd: 'mplayer'
    args: []

  Config.upsert {key: 'defaultPlayer'}, $set: value: 'mplayer'
