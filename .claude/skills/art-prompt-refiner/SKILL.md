---
name: art-prompt-refiner
description: Restructures a raw prompt (or an existing .claude/ command/skill file) into The ART Framework format — Act as, Request, Terms. Used by /art-refine; produces a preview only, does not write files itself.
---

# art-prompt-refiner

Restructures prompt text into three sections, without changing its intent:

1. **Act as** — role/title, domain expertise, tone and behavioral traits the agent should adopt.
2. **Request** — the primary task, relevant context/inputs, ordered action steps, and expected deliverables.
3. **Terms** — strict prohibitions (❌), formatting requirements, and quality/safety standards (✅).

## Input

Either:
- Raw prompt text handed to you inline, or
- The current content of an existing file under `.claude/` (command, skill, or rule) that needs restructuring.

## Process

1. Read the input in full. If it's a file path, read the file — don't guess its contents.
2. Identify existing frontmatter (`name`, `description`, `aliases`, etc.). Preserve all of it; only update fields that must change to stay accurate to the refined content.
3. Extract persona cues (explicit or implied) → **Act as**.
4. Extract the task, inputs/context, and any step-by-step process → **Request**, with action steps as an ordered list.
5. Extract constraints, prohibitions, and formatting/quality requirements → **Terms**, using ❌ for prohibitions and ✅ for requirements.
6. Do not invent new behavior, scope, or constraints that weren't present or clearly implied in the source — this is a restructuring pass, not a redesign.
7. Return the fully drafted ART-formatted markdown (frontmatter + the three sections) as your output. Do not write it to disk — the calling command owns preview/approval/save.

## Output shape

```markdown
---
name: ...
description: ...
aliases: [...]   # only if the original had aliases or the command form needs one
---

# <title>

## 1. Act as (Identity & Persona)
...

## 2. Request (Task & Objectives)
...

## 3. Terms (Constraints)
...
```
