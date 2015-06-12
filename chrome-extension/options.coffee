
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
    command += "TEXT_AID_TOO_SECRET=\"#{escape secretElement.value}\""
    command += " text-aid-to"
    command += " --port #{portElement.value}"
    commandElement.textContent = command

  chrome.storage.sync.get [ "port", "secret" ], (items) ->
    unless chrome.runtime.lastError
      port.value = items.port if items.port?
      secret.value = items.secret if items.secret?

      for element in [ portElement, secretElement ]
        do (element) ->
          element.addEventListener "change", ->
            obj = {}
            obj[element.id] = element.value.trim()
            chrome.storage.sync.set obj
            maintainServerCommand()

          element.addEventListener "keydown", (event) ->
            element.blur() if event.keyCode == 27

          maintainServerCommand()
          element.addEventListener "keyup", maintainServerCommand
