#!/usr/bin/env coffee

# Required modules:
#   npm install watchr
#   npm install optimist
#   npm install ws
#   npm install markdown
#   npm install html
#   npm install coffee-script

# Set the environment variable below, and the server will refuse to serve clients who don't know the secret.
secret = process.env.TEXT_AID_TOO_SECRET

for module in [
  # The first of these must be installed via "npm".
  "watchr"
  "optimist"
  "ws"
  "markdown"
  "html"
  # These are standard.
  "os"
  "fs"
  "path"
  "child_process"
  ]
  try
    global[module] = require module
  catch
    console.log "ERROR\n#{module} is not available: sudo npm install -g #{module}"
    process.exit 1

config =
  port: "9293"
  host: "localhost"
  editor: "gvim -f"

defaultEditor =
  if process.env.TEXT_AID_TOO_EDITOR
    process.env.TEXT_AID_TOO_EDITOR
  else
    config.editor

pjson = require path.join "..", "package.json"
version = pjson.version

helpText =
  """
  Usage:
    text-aid-too [--port PORT] [--editor EDITOR-COMMAND] [--markdown]

  Example:
    export TEXT_AID_TOO_EDITOR="gvim -f"
    TEXT_AID_TOO_SECRET=hul8quahJ4eeL1Ib text-aid-too --port 9293

  Markdown (experimental):
    With the "--markdown" flag, text-aid-too tries to find non-HTML
    paragraphs in HTML texts and parses them as markdown.  This only
    applies to texts from contentEditable elements (e.g. the GMail
    compose window).

  Environment variables:
    TEXT_AID_TOO_EDITOR: the editor command to use.
    TEXT_AID_TOO_SECRET: the shared secret; set this in the extension too.

  Version: #{version}
  """

args = optimist.usage(helpText)
  .alias("h", "help")
  .default("port", config.port)
  .default("editor", defaultEditor)
  .default("markdown", false)
  .argv

if args.help
  optimist.showHelp()
  process.exit(0)

console.log """
  server  ws://#{config.host}:#{args.port}
  secret  #{if secret? then secret else '<NONE>'}
  editor  #{args.editor}
  version #{version}
  """

WSS  = ws.Server
wss  = new WSS port: args.port, host: config.host
wss.on "connection", (ws) -> ws.on "message", handler ws

getEditCommand = (filename) ->
  command = if 0 <= args.editor.indexOf "%s" then args.editor.replace "%s", filename else "#{args.editor} #{filename}"
  console.log "exec:", command
  command

handler = (ws) -> (message) ->
  request = JSON.parse message

  onExit = []
  onExit.push -> ws.close()
  exit = (continuation = null) ->
    callback() for callback in onExit.reverse()
    onExit = []
    continuation?()

  if secret? and 0 < secret.length
    unless request.secret? and request.secret == secret
      console.log """
        mismatched or invalid secret; aborting request:
          required secret: #{secret}
          received secret: #{request.secret}
        """
      return exit()

  sendResponse = (response, continuation = null) ->
    response.serverVersion = version
    ws.send JSON.stringify response
    continuation?()

  handlers =
    ping: ->
      console.log "ping: ok"
      request.isOk = true
      sendResponse request, exit

    edit: ->
      username = process.env.USER ? "unknown"
      directory = process.env.TMPDIR ? os.tmpdir()
      timestamp = process.hrtime().join "-"
      suffix = if request.isContentEditable then "html" else "txt"
      filename = path.join directory, "#{username}-text-aid-too-#{timestamp}.#{suffix}"

      console.log "edit:", filename
      onExit.push -> console.log "  done:", filename

      fs.writeFile filename, (request.originalText ? request.text), (error) ->
        return exit() if error
        onExit.push -> fs.unlink filename

        sendText = (continuation = null) ->
          fs.readFile filename, "utf8", (error, data) ->
            return exit() if error
            console.log "  send: #{filename} [#{data.length}]"
            data = data.replace /\n$/, ""
            request.text = request.originalText = data
            request.text = formatMarkdown data if request.isContentEditable and args.markdown
            sendResponse request, continuation

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
          if error then exit() else sendText exit

  if handlers[request.name]?
    handlers[request.name]()
  else
    console.log "error; unknown request:", request

markdownToHtml = (text) ->
  try
    html.prettyPrint markdown.markdown.toHTML text
  catch
    text

# This is best-effort markdown handling.  Paragraphs are separated by "\n\n".  We collect together as many
# paragraphs which don't seem to contain HTML as we can, and process them as markdown. Everything else just gets
# passed through.
formatMarkdown = (text) ->
  [ output, texts, input ] = [ [], [], text.split("\n\n").reverse() ]

  flushMarkdown = ->
    if 0 < texts.length
      output.push markdownToHtml texts.join "\n\n"
      texts = []

  while 0 < input.length
    paragraph = input.pop()
    if /<\/?[a-zA-Z]+/.test paragraph
      flushMarkdown()
      output.push paragraph
    else
      texts.push paragraph

  flushMarkdown()
  output.join "\n\n"

