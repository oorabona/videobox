# Keep an in memory non reactive version of key value pairs so that we can send
# them back when page loads.
Meteor.methods
  replayLog: ->
    @unblock()
    Logs.replay()
