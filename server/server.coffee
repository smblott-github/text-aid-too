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
  "fs"
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
  editor: "urxvt -T textaid -geometry 100x30+80+20 -e vim"

defaultEditor =
  if process.env.TEXT_AID_TOO_EDITOR
    process.env.TEXT_AID_TOO_EDITOR
  else
    config.editor

pjson = require "../package.json"
version = pjson.version

helpText =
  """
  Usage:
    text-aid-too [--port PORT] [--editor EDITOR-COMMAND] [--markdown]

  Example:
    export TEXT_AID_TOO_EDITOR="gvim"
    TEXT_AID_TOO_SECRET=hul8quahJ4eeL1Ib text-aid-too --port 9293

  Markdown (experimental):
    With the "--markdown" flag, text-aid-too tries to find naked text
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

# A simple cache. Entries used within two expiry periods are retained, otherwise they are discarded.
# At most 2 * @entries entries are retained.
class SimpleCache
  # expiry: expiry time in milliseconds (default, one hour)
  # entries: maximum number of entries in @cache (there may be up to this many entries in @previous, too)
  constructor: (@expiry = 60 * 60 * 1000, @entries = 1000) ->
    @cache = {}
    @previous = {}
    @lastRotation = new Date()

  has: (key) ->
    @rotate()
    (key of @cache) or key of @previous

  # Set value, and return that value.  If value is null, then delete key.
  set: (key, value = null) ->
    @rotate()
    delete @previous[key]
    if value?
      @cache[key] = value
    else
      delete @cache[key]
      null

  get: (key) ->
    @rotate()
    if key of @cache
      @cache[key]
    else if key of @previous
      @cache[key] = @previous[key]
      delete @previous[key]
      @cache[key]
    else
      null

  rotate: (force = false) ->
    if force or @entries < Object.keys(@cache).length or @expiry < new Date() - @lastRotation
      console.log "rotating reverse cache"
      @lastRotation = new Date()
      @previous = @cache
      @cache = {}

  clear: ->
    @rotate true
    @rotate true

# This is used for HTML/contentEditable only.  When we ship the HTML to the browser, we record a mapping from
# the HTML to the original text which we read from the file.  If we later receive the same HTML to edit, then
# we replace it with the original text.  This allows the user to edit their original text, without having to
# deal with HTML markup add by markdown-mode.
reverseCache = new SimpleCache 1000 * 60 * 60, 50
getCacheKey = (data) -> data.trim().split(/\s+/).join " "

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

  username = process.env.USER ? "unknown"
  directory = process.env.TMPDIR ? "/tmp"
  timestamp = process.hrtime().join "-"
  suffix = if request.isContentEditable then "html" else "txt"
  filename = "#{directory}/#{username}-text-aid-too-#{timestamp}.#{suffix}"

  console.log "edit:", filename
  onExit.push -> console.log "  done:", filename

  cacheKey = getCacheKey request.text
  if reverseCache.has cacheKey
    # We re-use the text we cached previously.
    request.text = reverseCache.get cacheKey
  cacheKey = null

  fs.writeFile filename, request.text, (error) ->
    return exit() if error
    onExit.push -> fs.unlink filename

    sendText = (continuation = null) ->
      fs.readFile filename, "utf8", (error, data) ->
        return exit() if error
        console.log "  send:", filename
        request.text =
          if request.isContentEditable
            formattedData = formatParagraphs data
            formattedKey = getCacheKey formattedData
            # Cache the original text, we may have to re-use it later (but only if we're exiting).
            reverseCache.set getCacheKey(formattedData), data if continuation == exit
            formattedData
          else
            data
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

isHTML = (text) ->
  /^</.test(text) and />$/.test text

formatParagraphs = (text) ->
  paragraphs =
    for paragraph in text.split "\n\n"
      paragraph = paragraph.trim()
      if paragraph.length == 0 or isHTML paragraph
        # Leave HTML and empty "paragraphs" alone.
        paragraph
      else if args.markdown
        # Parse as Markdown.
        try
          text = html.prettyPrint markdown.markdown.toHTML paragraph
          text.replace(/<p>/g, "<p>\n").replace(/<\/p>/g, "\n<\/p>")
        catch
          paragraph
      else
        # Surround the paragraph with <p></p> tags.
        "<p>\n#{paragraph}\n</p>"

  paragraphs.join "\n\n"

