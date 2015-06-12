#!/usr/bin/env coffee

# Set the environment variable below, and the server will refuse to serve clients who don't know the secret.
secret = process.env.TEXT_AID_TOO_SECRET

# The first three of these must be installed via "npm".
for module in [ "watchr", "optimist", "ws", "fs", "child_process" ]
  try
    global[module] = require module
  catch
    console.log "ERROR\n#{module} is not available: sudo npm install -g #{module}"
    process.exit 1

config =
  port: "9293"
  host: "localhost"
  editor: "urxvt -T textaid -geometry 100x30+80+20 -e vim"

defaultEditor =
  if process.env.TEXT_AID_TOO_EDITOR
    process.env.TEXT_AID_TOO_EDITOR
  else
    config.editor

helpText =
  """
  Usage:
    text-aid-too [--port PORT] [--editor EDITOR-COMMAND]

  Example:
    export TEXT_AID_TOO_EDITOR="gvim"
    TEXT_AID_TOO_SECRET=hul8quahJ4eeL1Ib text-aid-too --port 9293

  Environment variables:
    TEXT_AID_TOO_EDITOR: the editor command to use.
    TEXT_AID_TOO_SECRET: the shared secret; set this in the extension too.

  """

args = optimist.usage helpText
  .alias "h", "help"
  .default "port", config.port
  .default "editor", defaultEditor
  .argv

if args.help
  optimist.showHelp()
  process.exit(0)

console.log "editor: #{args.editor}"
console.log "server: ws://#{config.host}:#{args.port}"

WSS  = ws.Server
wss  = new WSS port: args.port, host: config.host
wss.on "connection", (ws) -> ws.on "message", handler ws

getEditCommand = (filename) ->
  "#{args.editor} #{filename}"

handler = (ws) -> (message) ->
  request = JSON.parse message

  onExit = []
  onExit.push -> ws.close()
  exit = ->
    callback() for callback in onExit.reverse()
    onExit = []

  if secret? and 0 < secret.length
    unless request.secret? and request.secret == secret
      console.log """
        mismatched or invalid secret; aborting request:
          required secret: #{secret}
          received secret: #{request.secret}
        """
      return exit()

  text = request.message
  username = process.env.USER ? "unknown"
  directory = process.env.TMPDIR ? "/tmp"
  timestamp = process.hrtime().join "-"
  suffix = if request.isContentEditable then "html" else "txt"
  filename = "#{directory}/#{username}-text-aid-too-#{timestamp}.#{suffix}"

  console.log "edit:", filename
  onExit.push -> console.log "  done:", filename

  fs.writeFile filename, request.text, (error) ->
    return exit() if error
    onExit.push -> fs.unlink filename

    sendText = (continuation = null) ->
      fs.readFile filename, "utf8", (error, data) ->
        return exit() if error
        console.log "  send:", filename
        request.text = data
        ws.send JSON.stringify request
        continuation?()

    monitor = watchr.watch
      path: filename
      listener: sendText
      # This is only used for the "watch" method.
      catchupDelay: 400
      # Unfortunately, the "watch" method isn't reliable.  So we're actually using the "watchFile" method
      # instead.  See https://github.com/bevry/watchr/issues/33.
      preferredMethods: [ 'watchFile', 'watch' ]
      interval: 500
    onExit.push -> monitor.close()

    child = child_process.exec getEditCommand filename
    child.on "exit", (error) ->
      return exit() if error
      sendText exit

