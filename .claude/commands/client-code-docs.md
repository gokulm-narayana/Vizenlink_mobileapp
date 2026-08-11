---
name: client-code-docs
description: Document a client Dart file from client_code_inbox/ as a markdown table of its functions/classes (name, signature, purpose, used for).
aliases: ["/client-code-docs", "/doc-client-code"]
---

# /client-code-docs

## Usage
`/client-code-docs <filename.dart>` — filename only assumes `client_code_inbox/<filename.dart>`; an explicit path overrides that.

## Action
Invoke the `client-code-docs` skill on the given file. If no filename is given, list the `.dart` files currently in `client_code_inbox/` and ask which one to document.
