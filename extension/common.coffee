
Common =
  # Give objects (including elements) distinct identities.
  identity: do ->
    identities = []
    getId: (obj) ->
      index = identities.indexOf obj
      if index < 0
        index = identities.length
        identities.push obj
      index
    getObj: (id) -> identities[id]

  # Convenience wrapper for setTimeout (with the arguments around the other way).
  setTimeout: (ms, func) -> setTimeout func, ms

  # Like Nodejs's nextTick.
  nextTick: (func) -> @setTimeout 0, func

  default:
    server: "http://localhost:9293"
    key:
      altKey: false
      ctrlKey: true
      shiftKey: false
      keyCode: 186 # ";"

root = exports ? window
root.Common = Common
