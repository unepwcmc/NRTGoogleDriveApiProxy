express = require('express')
bodyParser = require('body-parser')
request = require('request')
fs = require('fs')

app = express()
app.use(bodyParser.json())

CLIENT_SECRET_FILE = "./client_secret_token"

readClientSecret = ->
  if fs.existsSync(CLIENT_SECRET_FILE)
    return fs.readFileSync(CLIENT_SECRET_FILE, "UTF8")
  else
    throw new Error("Please put the client-secret from the google developer console in a file named #{CLIENT_SECRET_FILE}")

DOMAIN = "https://secure.nrt.io"
CLIENT_ID = "996507169218-amsh4j7r138o7pdrurojv2ppmp991p3k.apps.googleusercontent.com"
CLIENT_SECRET = readClientSecret()

EXPECTED_REFERRER = /https:\/\/accounts.google.com\/.*/

isFromGoogle = (req) ->
  EXPECTED_REFERRER.exec req.headers['referer']

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
     scope=https://www.googleapis.com/auth/drive&
     state=%2Fprofile&
     redirect_uri=#{DOMAIN}/request_token_callback&
     response_type=code&
     client_id=#{CLIENT_ID}&
     access_type=offline"

  googleAuthUrl = googleAuthUrl.replace(/[\s|\n]/g, '')
  console.log "Redirecting to #{googleAuthUrl}"

  res.redirect(googleAuthUrl)
)

app.get('/request_token_callback', (req, res) ->
  if isFromGoogle(req)
    code = req.query.code

    request.post({
      uri: "http://accounts.google.com/o/oauth2/token"
      form:
        code: code
        client_id: CLIENT_ID
        client_secret: CLIENT_SECRET
        redirect_uri: "#{DOMAIN}/store_refresh_token"
        grant_type: "authorization_code"
    }, (err) ->
      if err?
        console.log "Error requesting refresh token"
        console.log err
        res.send(500, "Error requesting refresh token")
      else
        res.send(200, "Send request for refresh token, should be written to FS soon")

    )
  else
    res.send(401, "Request must be a redirect from google")
)

app.get('/store_refresh_token', ->
  if isFromGoogle(req)
    refreshToken = req.query.refresh_token
    console.log "Got refresh token: #{refreshToken}"

    writeRefreshToken(refreshToken, (err) ->
      if err?
        console.log "Error writing refresh token"
        console.log err.stack
        res.send(500, "Got token, but unable to write to FS")
      else
        res.send(201, "Successfully wrote refresh token to FS")
    )
  else
    res.send(401, "Request must be a redirect from google")
)

server = app.listen(3001, ->
  console.log('Listening on port %d', server.address().port)
)
