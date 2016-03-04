# Set 'default' App values
App.set 'animationName', 'fade'
App.set 'showNavs', true
App.set 'showFooter', true

# Update current torrent data as new peers are connecting...
Logs.addListener 'peers', (peers) ->
  torrent = App.get 'currentFile'
  return unless torrent
  torrent.peers = peers
  App.set 'currentFile', torrent
  return
