tp = require 'torrent-project-api'
Q = require 'q'

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

###
# @param: query - the search query the user entered
# @param: options - an options object
# Searches the pirate bay for videos with the given query and returns
# a list of torrent objects
###

Search = Q.nfbind tp.search
searchCommand = (query, order, category) ->
  Search(query, {
    filter: category
    order: order
  }).then (res) ->
    process.send results: res
  .catch (err) ->
    process.send error: "Caught exception: #{err}"

if process.argv.length isnt 5
  process.exit 0

# process.on 'message', (m) -> console.log 'message received', m

order = process.argv[2]
category = process.argv[3]
what = process.argv[4]

process.env['NODE_TLS_REJECT_UNAUTHORIZED'] = '0'

process.send? { program: 'Search Engine for VideoBox', version: '0.1.0', order: order, category: category, what: what }

# console.log('searching', m.what, 'in', m.category)
searchCommand(what, order, category).thenResolve()
