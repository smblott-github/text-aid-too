## Text-Aid-Too

*Text-aid-too* is a variation on the *text-aid* theme: it allows you to edit
web inputs in your native text editor, such as Vim or Emacs.  It's a
combination of a
[Chrome extension](https://chrome.google.com/webstore/detail/text-aid-too/klbcooigafjpbiahdjccmajnaehomajc) and a
[server](https://www.npmjs.com/package/text-aid-too).

*But Text-aid-too is different:*
- In addition to traditional HTML inputs, it also works for `contentEditable`
  inputs (such as the GMail compose window).
- It updates the input's contents whenever the file is written/saved, so you
  can preview your changes as you go along.
- In `contentEditable` inputs (e.g. on Gmail) you can optionally use Markdown
  mark up, so you can write rich text GMail messages in Markdown (experimental,
  see [below](https://github.com/smblott-github/text-aid-too#markdown)).
- The temporary file name has the appropriate extension for the input type (`.txt`
  or `.html`, as appropriate).  Therefore, your text editor can detect the file
  type appropriately.
- It checks inputs dynamically, so it works on sites (such as Google's Inbox)
  which toggle the `contentEditable` status on-the-fly.

The default keyboard shortcut is `<Ctrl-;>`, but you can set your own keyboard
shortcut on the extension's options page.

### Screenshot

![Screenshot](https://cloud.githubusercontent.com/assets/2641335/8124943/cd7c5ffe-10d8-11e5-8403-e14d18dc482d.png)

### Installation

#### The Easy Way

1. Install the [extension](https://chrome.google.com/webstore/detail/klbcooigafjpbiahdjccmajnaehomajc) from the Chrome Store.
1. Install the server (and its dependencies):

    `sudo npm install -g text-aid-too`

1. Configure the port and shared secret on the extension's options page
   (optional, but required if you want to use a non-default port or a shared
   secret).


Then, launch the server; which might be something like...

    export TEXT_AID_TOO_SECRET="<REPLACE-ME>"
    export TEXT_AID_TOO_EDITOR="gvim"

    # Use the default port (9293)...
    text-aid-server

    # Or...
    text-aid-server --port 9294

#### The Hard Way

1. Clone the repo.
1. `make build` - you will need Coffeescript.
1. Install the server with `npm install -g .`.
1. Run the server (as above).
1. Install the extension as an unpacked extension; it's in `./chrome-extension`.

    Visit the extension's options page to configure the port and shared secret,
    if required (see below).

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

### Markdown

*Note: this is an experimental feature.*

With the `--markdown` flag, the server parses non-HTML paragraphs as Markdown
(but only for text from `contentEditable` elements).  For example, you can use
Markdown to write messages in GMail.

![Markdown in GMail](https://cloud.githubusercontent.com/assets/2641335/8130117/dc12f86e-1107-11e5-9893-45ce83ed99b5.png).

Tip:

- Prefer not to exit/close the editor until your done.  Just write the file,
  and your changes will be updated in the corresponding element.
- Paragraphs (separated by `\\n\\n`) are handled separately.  So one paragraph
  can be HTML (is it is in the `contentEditable` input, which the next can be
  Markdown.

### Help Text

At the time of writing, the help text is...

```
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

Version: 1.1.1

Options:
  --port      [default: "9293"]
  --editor    [default: "urxvt -T textaid -geometry 100x30+80+20 -e vim"]
  --markdown  [default: false]
```
