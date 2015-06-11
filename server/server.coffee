#!/usr/bin/env coffee

# Set the environment variable below, and the server will refuse to serve clients who don't know the secret.
secret = process.env.TEXT_AID_TOO_SECRET

# These must be installed via "npm".
watchr = require "watchr"
optimist = require "optimist"

fs = require "fs"
child_process = require "child_process"

config =
  port: "9293"
  host: "localhost"

args = optimist.usage("Usage: $0 [--port=PORT]")
  .alias("h", "help")
  .default("port", config.port)
  .argv

if args.help
  optimist.showHelp()
  process.exit(0)

WSS  = require("ws").Server
wss  = new WSS port: args.port, host: args.host
wss.on "connection", (ws) -> ws.on "message", handler ws

getEditCommand = (filename) ->
  "urxvt -T textaid -geometry 100x30+80+20 -e vim #{filename}"

handler = (ws) -> (message) ->
  request = JSON.parse message

  onExit = []
  onExit.push -> ws.close()
  exit = ->
    callback() for callback in onExit.reverse()
    onExit = []

  if secret?
    unless request.secret? and request.secret == secret
      console.log "Mismatched or invalid secret; exiting:", secret, request.secret
      return exit()

  text = request.message
  username = process.env.USER ? "unknown"
  directory = process.env.TMPDIR ? "/tmp"
  timestamp = process.hrtime().join "-"
  suffix = if request.isContentEditable then "html" else "txt"
  filename = "#{directory}/#{username}-text-aid-too-#{timestamp}.#{suffix}"

  fs.writeFile filename, request.text, (error) ->
    return exit() if error
    onExit.push -> fs.unlink filename

    sendText = (continuation = null) ->
      fs.readFile filename, "utf8", (error, data) ->
        return exit() if error
        request.text = data
        ws.send JSON.stringify request
        continuation?()

    monitor = watchr.watch
      path: filename
      listener: sendText
    onExit.push -> monitor.close()

    child = child_process.exec getEditCommand filename
    child.on "exit", (error) ->
      return exit() if error
      sendText exit

