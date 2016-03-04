Meteor.publish 'config', ->
  Config.find()

# Add default configuration on startup
Meteor.startup ->
  console.log '=== [Init] ==='
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
  Config.upsert {key: 'videoExt'}, $set: value: '.[mp4|avi|mkv|mpeg|mpg]$'
