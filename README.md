## Text-Aid-Too

*Text-aid-too* is a variation on the *text-aid* theme: it allows you to edit
web inputs in your native text editor, such as Vim or Emacs.  It's a
combination of a Chrome extension and a server.


But *Text-aid-too* is different:
- In addition to traditional HTML inputs, it also works for `contentEditable`
  inputs (such as those used by GMail).
- It checks inputs dynamically, so it works on sites (such as Google's Inbox)
  which toggle the `contentEditable` status on-the-fly.
- It updates the input's contents whenever the file is written, so you can
  preview your changes as you go along.
- The temporary file name has the appropriate suffix for the input type (`.txt`
  or `.html`, as appropriate).  Therefore, your text editor can detect the file
  type and set its bindings and highlighting accordingly.

### Installation

Currently:
- Clone the repo.
- Install the server with `npm install -g .`.
- Run the server with `text-aid-too`.
- Build the extension with `coffee -c ./chrome-extension/*.coffee` (or just `make build`).
- Install the extension as an unpacked extension (I'll put it on the Chrome Store
  soon).  The extension is in `./chrome-extension/`.

    Visit the extension's options page to configure the port and shared secret,
    if required (see below).

    To activate the editor, use `<Ctrl-;>`. (Sorry, there's no user interface yet for changing this.)

### Important

*Text-aid-too* will not work with other *text-aid* servers.  Those use HTTP,
whereas *Text-aid-too* uses its own a web-socket based protocol.  This allows
it to update the input's contents on-the-fly (that is, on file write).

### The Editor Command

The editor command is set when the server is launched.  Use one of...

    # Like this...
    text-aid-too --editor "urxvt -T textaid -geometry 100x30+80+20 -e vim"

    # Or like this...
    export TEXT_AID_TOO_EDITOR="urxvt -T textaid -geometry 100x30+80+20 -e vim"
    text-aid-too

The command line takes priority.

### Port

The default port is `9293`.
If you use a different port, then you'll have to change it on the extension's options page too.

    text-aid-too --port 9293

### Security

By default, there's no security.  Any process on the local machine can access
the server.  That's not great.

To enable basic shared-secret security, set the `TEXT_AID_TOO_SECRET` environment variable.

    export TEXT_AID_TOO_SECRET="something-secret"
    text-aid-too

You'll then have to configure the same secret on the extension's options page, of course.

(You cannot set the shared secret on the command line, for obvious reasons.)

