{spawn} = Meteor.npmRequire 'child_process'
path = Meteor.npmRequire 'path'
Future = Meteor.npmRequire 'fibers/future'

Meteor.methods
  search: (what, category) ->
    @unblock()
    # search = fork "#{path.resolve '.'}/assets/app/search.js", null, {env: process.env, cwd: process.cwd}
    search = spawn 'coffee', ["#{path.resolve '.'}/assets/app/search.coffee", 'seeds', 'all', what], {env: process.env, cwd: process.cwd, stdio: ['ipc']}
    fut = new Future()
    search.on 'message', (m) ->
      console.log 'SEARCH PARENT got message', m
      {error, results} = m
      if error
        console.error error
        fut.return error
      else if results
        fut.return results
    # search.send {hello:'world'}
    fut.wait()
