tp = require 'torrent-project-api'
Q = require 'q'
fsw = require 'chokidar'
Path = require 'path'

allDone = (promises) ->
  deferred = Q.defer()
  Q.allSettled(promises).then (results) ->
    values = []
    i = 0
    while i < results.length
      if results[i].state == 'rejected'
        deferred.reject new Error(results[i].reason)
        return
      else if results[i].state == 'fulfilled'
        values.push results[i].value
      else
        deferred.reject new Error('Unexpected promise state ' + results[i].state)
        return
      i++
    deferred.resolve values
    return
  deferred.promise

###*
  @param query (String) - the search query the user entered
  @param options (Object) - an options object
  Searches the pirate bay for videos with the given query and returns
  a list of torrent objects
###

SearchTorrent = Q.nfbind tp.search
SearchLocal = (where, what) ->
  files = []
  reStr = what.replace /\ /g, '.'
  regexp = new RegExp reStr, 'i'
  watcher = fsw.watch where,
    persistent: true
    ignorePermissionErrors: true
    followSymlinks: true
    alwaysStat: true

  watcher.on 'add', (path, stats) ->
    console.log 'got', path, stats
    if files.length < 20 and path.match regexp
      name = Path.basename path
      console.log 'matched', path, name
      files.push name: name, path: path, size: stats.size

  new Q.Promise (accept, reject) ->
    watcher.on 'ready', ->
      console.log 'finished'
      watcher.close()
      res = total: files.length
      res.files = files
      accept res
    .on 'error', (err) ->
      console.log 'error', err
      watcher.close()
      reject err

searchCommand = (query, order, category) ->
  allDone [SearchTorrent(query, {
    filter: category
    order: order
  }), SearchLocal '/tmp/webtorrent', query]
  .then (results) ->
    console.log 'results', results
    process.send results: results
  .catch (err) ->
    process.send error: "Caught exception: #{err}"

process.on 'message', (m) ->
  console.log 'SEARCH message received', m
  {order, category, what} = m
  searchCommand(what, order, category).thenResolve()

process.env['NODE_TLS_REJECT_UNAUTHORIZED'] = '0'

process.send? { program: 'Search Engine for VideoBox', version: '0.1.0' }
