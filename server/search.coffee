{spawn} = Meteor.npmRequire 'child_process'
path = Meteor.npmRequire 'path'
Future = Meteor.npmRequire 'fibers/future'

Meteor.methods
  search: (what, category) ->
    @unblock()
    search = spawn 'coffee', ["#{path.resolve '.'}/assets/app/search.coffee"], {env: process.env, cwd: process.cwd, stdio: [0,1,2,'ipc']}

    fut = new Future()
    ext = Config.findOne key: 'videoExt'
    reExt = new RegExp ext.value, 'i'
    search.on 'message', (m) ->
      console.log 'SEARCH PARENT got message', m
      {error, results} = m
      if error
        console.error error
        fut.return error
      else if results
        {torrents} = results[0]
        {files} = results[1]
        res =
          torrents: torrents
          files: files.filter (file) -> reExt.test file.name
        fut.return res

    search.on 'exit', (code) ->
      console.log 'Search exit code', code

    search.send {order: 'seeds', category: 'all', what: what}

    fut.wait()
