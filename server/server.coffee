
config =
  port: "9293"
  host: "localhost"

optimist = require "optimist"
args = optimist.usage("Usage: $0 [--port=PORT]")
  .alias("h", "help")
  .default("port", config.port)
  .argv

if args.help
  optimist.showHelp()
  process.exit(0)

WSS  = require("ws").Server
wss  = new WSS port: args.port, host: args.host

wss.on "connection",
  (ws) ->
    ws.on "message", handler ws

handler = (ws) -> (message) ->
  request = JSON.parse message
  request.text = "server"
  ws.send JSON.stringify request

