# rcList = '0123456789'
# id = ''
# i = 0
# while i < 4
#   id += "#{Random.choice rcList}"
#   i++
# Config.upsert {key: 'remoteCode'}, $set: value: id

Meteor.publish 'config', ->
  Config.find()
