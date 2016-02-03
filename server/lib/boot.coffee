{fork, spawn} = Meteor.npmRequire 'child_process'
path = Meteor.npmRequire 'path'

# @Worker = fork "#{path.resolve '.'}/assets/app/search.js", null, {env: process.env, cwd: process.cwd}
# @Worker = spawn 'coffee', ["#{path.resolve '.'}/assets/app/search.coffee"], {env: process.env, cwd: process.cwd, stdio: ['ipc']}
#
# Worker.on 'error', (e) ->
#   console.log 'error', e
#   return
#
# Worker.on 'exit', (e) ->
#   console.log 'exit', e
#   return
