---
name: client-code-docs
description: Analyze a senior engineer's client-side Dart file (business logic/data/API layer, state, or model/DTO classes with no UI) and document every function/method/class — and, for API files, every endpoint call — in a companion markdown table. Use whenever a new client Dart file is shared, before or alongside integrating it into the UI.
---

# client-code-docs

The senior engineer's client Dart files (business logic, API/network layer, state, model/DTO classes) often arrive undocumented and with no UI at all — pure logic files. This skill reads such a file and produces a companion markdown doc summarizing every callable and every API call it makes — so it's clear what exists and what it's for before wiring it into the UI (see `integrate-client-code`).

## Process

0. Look in `client_code_inbox/` first for the file(s) to document — that's where shared client Dart files are placed. If the user names a file without a path, assume it's there. Only look elsewhere if it's not found or the user gives an explicit path.
1. Read the client Dart file in full.
2. Identify every class, and within each class every public method/function, constructor, getter/setter, and exposed field/stream/notifier relevant to the UI.
3. Determine if the file is (or contains) an **API/network layer** — look for HTTP client usage (`http`, `dio`, `Dio`, raw `HttpClient`), request builders, `fromJson`/`toJson` on request/response types, base URLs, endpoint path strings, or repository/service classes that wrap such calls. A file can be part-API, part-plain-logic — handle each method with whichever table applies.
4. For each **plain method/function**, determine:
   - **Name** — exact identifier as written in code
   - **Signature** — parameters and return type
   - **Purpose** — what it does, in plain language (infer from implementation, naming, and comments)
   - **Used for** — what a UI screen would call it for (e.g. "fetch camera list for dashboard", "stream live alert events")
5. For each **API-calling method**, additionally capture:
   - **HTTP method** — GET/POST/PUT/PATCH/DELETE etc.
   - **Endpoint** — path/URL as written (note if it's built from a base URL + path, or fully dynamic)
   - **Request model** — the type sent as the body/params (name it; note fields if the type isn't separately documented elsewhere in the same file)
   - **Response model** — the type parsed from the response (same treatment)
   - **Auth/headers** — anything notable (bearer token, API key, custom headers) if visible in the code
   - **Error handling** — what exceptions/error types it throws or returns on failure (status codes handled, custom exception types, etc.)
6. If the file defines standalone **model/DTO classes** (constructors + `fromJson`/`toJson`, no behavior), list them in their own table: class name, fields (name + type), and which API method(s) from step 5 use them as request/response types.
7. Write the output to `docs/client_code/<source_file_name>.md` (snake_case, matching the Dart file's name, e.g. `camera_service.dart` → `docs/client_code/camera_service.md`). Create the `docs/client_code/` directory if it doesn't exist.
8. Structure the doc as:
   ```markdown
   # <ClassName> (`client_code_inbox/<source_file_name>.dart`)

   ## Methods
   | Name | Signature | Purpose | Used for |
   |------|-----------|---------|----------|
   | fetchCameras | `Future<List<Camera>> fetchCameras()` | ... | ... |

   ## API calls
   | Name | HTTP method | Endpoint | Request model | Response model | Auth/headers | Errors |
   |------|-------------|----------|----------------|-----------------|--------------|--------|
   | fetchCameras | GET | `/api/v1/cameras` | — | `List<Camera>` | Bearer token | throws `ApiException` on non-200 |

   ## Models
   | Class | Fields | Used by |
   |-------|--------|---------|
   | Camera | id: String, name: String, ... | fetchCameras (response) |
   ```
   Omit whichever section doesn't apply to a given file (e.g. a pure model file has no Methods/API calls section). One set of tables per class if the file has multiple classes.
9. Do not modify the client Dart file itself — this is a read-only documentation pass.
10. Report the path of the doc written and a short summary of what the file contains (e.g. "N methods, M API endpoints, K model classes").

## Notes

- This is separate from `docs/screens/*.md` (UI element docs) — client-code docs describe the logic/data/API layer, not screens or design IDs.
- API-only files with no UI are expected and normal — this skill never assumes a file needs a UI counterpart to be worth documenting.
- If a function's purpose, or an endpoint's exact contract, can't be confidently inferred from the code, mark it clearly (e.g. `Purpose: unclear — ask senior`) rather than guessing silently.
- Keep the doc in sync if the client file is updated later — re-run this skill on the changed file.
