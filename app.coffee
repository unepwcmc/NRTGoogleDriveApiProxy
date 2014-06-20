express = require('express')
bodyParser = require('body-parser')
request = require('request')

app = express()
app.use(bodyParser.json())

app.post('/indicators/change_event', (req, res) ->

  eventCallbackUrl = req.body.token

  console.log("Got the eventCallbackUrl #{eventCallbackUrl}")

  request.post(
    eventCallbackUrl, (err, response, body) ->
      if err?
        return res.send(500, "Error posting to #{eventCallbackUrl}")
    
      res.send(201, "Notified #{eventCallbackUrl} of change event")
  )
)

server = app.listen(3001, ->
  console.log('Listening on port %d', server.address().port)
)
