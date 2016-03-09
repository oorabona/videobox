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

searchTorrent = Q.nfbind tp.search
searchLocal = (where, what) ->
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
      accept 
        total: files.length
        local: files
    .on 'error', (err) ->
      console.log 'error', err
      watcher.close()
      reject err

process.on 'message', (m) ->
  console.log 'SEARCH message received', m
  {search, order, category, what} = m
  if typeof search is 'string'
    search = [ search ]

  searchFn = search.map (searchType) ->
    switch searchType
      when 'torrents'
        searchTorrent what, {
          filter: category
          order: order
        }
      when 'local'
        searchLocal '/tmp/webtorrent', what
      when 'subs'
        -> console.log 'looking for subs', m
      else
        console.error 'Do not know what to do with:', searchType, search

  allDone searchFn
  .then (results) ->
    console.log 'results', results
    process.send results: results
  .catch (err) ->
    process.send error: "Caught exception: #{err}"

process.env['NODE_TLS_REJECT_UNAUTHORIZED'] = '0'

process.send? { program: 'Search Engine for VideoBox', version: '0.3.0' }
