# Router.route '/video/:_hash', ->
#   {_hash} = @params
#   # {response} = @
#   # response.setHeader 'video/mp4'
#   path = App.get 'playing'
#   console.log 'got path', path
#   unless path
#     response.statusCode = 404
#     @response.end 'Video not found!'
#     return
#   sendFile @response, path
# , {where: 'server'}
