_logsDDP = new EventDDP 'logs'
_logs = {}

@Logs =
  replay: -> _logs
  emit: (type, key, value) ->
    if type is 'message'
      if typeof key isnt 'string'
        throw new TypeError "Cannot parse #{key}"
      _logs[key] = value
    _logsDDP.emit type, key, value
  addListener: ->
    _logsDDP.addListener.apply _logsDDP, arguments

if Meteor.isClient
  Logs.addListener 'message', ->
    console.log 'client received', _.toArray arguments
