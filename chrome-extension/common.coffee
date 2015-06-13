
Common =

  # Default values.
  default:
    key:
      altKey: false
      ctrlKey: true
      shiftKey: false
      keyCode: 186 # ";"

    port: "9293"
    secret: "BETTER-FIX-ME-ON-THE-OPTIONS-PAGE"

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

  # Extend an object with additional properties.
  extend: (hash1, hash2) ->
    hash1[key] = value for own key, value of hash2
    hash1

  chromeStoreKey: "klbcooigafjpbiahdjccmajnaehomajc"

  isChromeStoreVersion: do ->
    0 == chrome.extension.getURL("").indexOf "chrome-extension://klbcooigafjpbiahdjccmajnaehomajc"

  log: (args...) ->
    console.log args... unless @isChromeStoreVersion

root = exports ? window
root.Common = Common
