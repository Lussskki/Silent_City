# Silent City canonical workspace

- The only canonical working directory for the Silent City project is `D:\Godot Games\silent-city-steam`.
- Always perform Silent City reads, edits, tests, builds, and Git operations directly in that directory.
- Never use or modify any `.codex\worktrees` copy of the Silent City repository.
- Before starting Silent City work, verify the working directory and repository root match the canonical path exactly; switch to the canonical directory if they do not.

## Strict task scope

- Only perform tasks the user explicitly requests.
- Never add features, refactor code, redesign systems, fix unrelated issues, or make additional improvements without permission.
- Briefly mention unrelated problems without fixing them.
- Do not install dependencies, delete files, or execute destructive commands without user approval.
- If a request is ambiguous, ask one concise clarification instead of guessing.

## Token and usage efficiency

- Keep responses short, direct, and relevant; do not generate lengthy explanations unless requested.
- Read only files necessary for the requested task. Do not scan the entire project unless explicitly requested.
- Use targeted searches instead of large file dumps; do not repeatedly read unchanged files.
- Avoid unnecessary tool calls, commands, and repeated tests.
- Do not create extra documentation or files without permission.
- Use the existing project structure and dependencies; prefer small, targeted edits over large rewrites.
- Do not repeat information already established.

## Development rules

- Preserve existing functionality and follow existing coding conventions.
- Change only files relevant to the requested task; never perform unrelated work.
- Run only relevant tests when necessary.
- Explain completed changes in 1–3 concise sentences.

## Session management

- Keep `PROGRESS.md` concise and accurate; include only verified information.
- Update it after meaningful completed tasks, not after every message.
- Record important decisions, unresolved issues, and next steps.
- Do not automatically begin the next task. Wait for the user's next instruction after completing the requested work.

## Story and art direction (user-provided, partial)

- The starting area should be less dark than the gothic village draft; preserve the established game art style.
- Lifts travel up and down, providing upper and lower routes toward the cemetery.
- The routes eventually reconnect and lead into the cemetery, where the final boss will be.
- This is an incomplete story outline, not a finished level design. Do not invent the remaining story or implement changes without a request.
- Never turn off or disable the existing Godot scene when working on artwork.
