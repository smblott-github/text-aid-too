
$ = (id) -> document.getElementById id

document.addEventListener "DOMContentLoaded", ->
  portElement = $("port")
  secretElement = $("secret")
  commandElement = $("command")

  escape = (str) ->
    str = str.replace /\\/g, "\\\\"
    str = str.replace /"/g, "\\\""

  maintainServerCommand = ->
    command = ""
    command += "TEXT_AID_TOO_SECRET=\"#{escape secretElement.value.trim()}\""
    command += " text-aid-to"
    command += " --port #{portElement.value.trim()}"
    commandElement.textContent = command

  chrome.storage.sync.get [ "port", "secret" ], (items) ->
    unless chrome.runtime.lastError
      port.value = items.port if items.port?
      secret.value = items.secret if items.secret?
      maintainServerCommand()

      for element in [ portElement, secretElement ]
        do (element) ->
          element.addEventListener "change", ->
            value = element.value.trim()

            # Ensure that port is a number.
            if element == portElement and not /^[1-9][0-9]*$/.test value
              element.value = value = Common.default.port

            obj = {}
            obj[element.id] = value
            chrome.storage.sync.set obj
            maintainServerCommand()

          element.addEventListener "keydown", (event) ->
            element.blur() if event.keyCode == 27

          element.addEventListener "keyup", maintainServerCommand
