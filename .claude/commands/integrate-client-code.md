---
name: integrate-client-code
description: Wire a client Dart file from client_code_inbox/ into the existing mobilecctvapp UI without modifying the client file unless unavoidable.
aliases: ["/integrate-client-code", "/integrate-client"]
---

# /integrate-client-code

## Usage
`/integrate-client-code <filename.dart>` — filename only assumes `client_code_inbox/<filename.dart>`; an explicit path overrides that.

## Action
Invoke the `integrate-client-code` skill on the given file. If no filename is given, list the `.dart` files currently in `client_code_inbox/` and ask which one to integrate.
