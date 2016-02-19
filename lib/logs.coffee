_logsDDP = new EventDDP 'logs'
@App = new ReactiveDict

@Logs =
  replay: -> App.keys
  emit: (type, key, value) ->
    if type is 'message'
      if typeof key isnt 'string'
        throw new TypeError "Cannot parse #{key}"
      App.set key, value
    _logsDDP.emit type, key, value
  addListener: ->
    _logsDDP.addListener.apply _logsDDP, arguments

Logs.addListener 'message', ->
  console.info 'message received', _.toArray arguments
