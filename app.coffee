express = require('express')
bodyParser = require('body-parser')
request = require('request')

app = express()
app.use(bodyParser.json())

DOMAIN = "https://secure.nrt.io"

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

app.get('/request_refresh_token', (req, res) ->
  googleAuthUrl = "https://accounts.google.com/o/oauth2/auth?
     scope=email%20profile&
     state=%2Fprofile&
     redirect_uri=#{DOMAIN}/store_refresh_token&
     response_type=code&
     client_id=996507169218-amsh4j7r138o7pdrurojv2ppmp991p3k.apps.googleusercontent.com&
     access_type=offline"

  googleAuthUrl = googleAuthUrl.replace(/[\s|\n]/g, '')
  console.log "Redirecting to #{googleAuthUrl}"

  res.redirect(googleAuthUrl)
)

EXPECTED_REFERRER = /https:\/\/accounts.google.com\/.*/

app.get('/store_refresh_token', (req, res) ->
  if EXPECTED_REFERRER.match req.headers['referer']
    console.log req.params
  else
    res.send(401, "Request must be a redirect from google")
)

server = app.listen(3001, ->
  console.log('Listening on port %d', server.address().port)
)
