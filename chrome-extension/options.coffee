
$ = (id) -> document.getElementById id

document.addEventListener "DOMContentLoaded", ->
  versionElement = $("version")
  versionElement.textContent = chrome.runtime.getManifest().version

  portElement = $("port")
  secretElement = $("secret")
  commandElement = $("command")

  escape = (str) ->
    str = str.replace /\\/g, "\\\\"
    str = str.replace /"/g, "\\\""

  maintainServerCommand = ->
    command = "\n"
    command += " export TEXT_AID_TOO_SECRET=\"#{escape secretElement.value.trim()}\"\n" if secretElement.value.trim()
    command += " text-aid-too --port #{portElement.value.trim()}\n"
    command += "\n"
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

  chrome.storage.sync.get "key", (items) ->
    unless chrome.runtime.lastError
      batchUpdate = false
      keys = [ "ctrlKey", "altKey", "shiftKey" ]
      key = items.key

      $("keyCode").textContent = key.keyCode
      $("setKey").value = "Set keyboard shortcut"

      saveKey = ->
        newKey = {}
        newKey[k] = $(k).checked for k in keys
        newKey.keyCode = parseInt $("keyCode").textContent
        chrome.storage.sync.set key: newKey

      for k in keys
        do (k) ->
          $(k).checked = key[k]
          $(k).addEventListener "change", ->
            saveKey() unless batchUpdate

      $("setKey").addEventListener "click", ->
        $("setKey").disabled = true
        $("setKey").value = "Type your keyboard shortcut..."

        cancel = ->
          window.removeEventListener "keydown", keydown
          window.removeEventListener "keyup", keyup
          $("setKey").disabled = false
          $("setKey").value = "Set keyboard shortcut"

        window.addEventListener "keydown", keydown = (event) ->
          if event.keyCode not in [16..18] # Ctrl, Alt and Shift.
            batchUpdate = true
            $(k).checked = event[k] for k in keys
            $("keyCode").textContent = event.keyCode
            saveKey()
            batchUpdate = false
            cancel()

        window.addEventListener "keyup", keyup = -> cancel()

  maintainStatus = do ->
    status = $("status")
    messageTexts = true: "connected", false: "cannot connect"
    messageColours = true: "Green", false: "Red"
    ->
      chrome.runtime.sendMessage { name: "ping" }, (response) ->
        status.textContent = messageTexts[response.isUp]
        status.style.color = messageColours[response.isUp]
        Common.setTimeout 1000, maintainStatus

  maintainStatus()

