{spawn} = Meteor.npmRequire 'child_process'
path = Meteor.npmRequire 'path'
Future = Meteor.npmRequire 'fibers/future'

search = spawn 'coffee', ["#{path.resolve '.'}/assets/app/search.coffee"], {env: process.env, cwd: process.cwd, stdio: [0,1,2,'ipc']}

search.on 'exit', (code) ->
  console.log 'Search exit code', code

search.on 'message', Meteor.bindEnvironment (m) ->
  console.log 'SEARCH PARENT got message', m
  {error, results} = m
  if error
    console.error error
    Logs.emit 'message', 'error', error
  else if results
    res = {}
    results.forEach (result) ->
      {torrents, local} = result
      if torrents then res.torrents = torrents
      if local
        res.local = local.filter (file) -> reExt.test file.name
    Logs.emit 'message', 'results', res

reExt = null

Meteor.methods
  search: (searchType, what, category) ->
    @unblock()
    if typeof searchType is 'string'
      searchType = [ searchType ]
    unless Array.isArray searchType
      throw new Meteor.Error 500, 'Wrong parameters: need to know what to search!'

    ext = Config.findOne key: 'videoExt'
    reExt = new RegExp ext.value, 'i'

    search.send {search: searchType, order: 'seeds', category: category, what: what}
