# Agent notes

## Flashing firmware

Flashing is interactive — the human must see the terminal and drive it.

- Do **not** run flashing steps (`bin/flash.sh`, drive watching, `cp` to
  `ADV360PRO`, etc.) in background terminals/tasks.
- Run them in a **Herdr side pane** so the user can watch and respond:
  verify `HERDR_ENV=1`, then e.g.
  `herdr pane split --current --direction right --cwd "$PWD" --no-focus`
  and `herdr pane run <pane-id> "bin/flash.sh"` (see the herdr skill).
- Watching a GitHub Actions build (`gh run watch`) in the background is fine;
  only the flash itself must be foreground/visible.

## Building locally

- `bin/build-local.sh` (Docker, no CI round-trip) is safe to run in
  background tasks.
- `bin/flash.sh --local` flashes the newest local build — same interactive
  wizard, so the flashing rules above apply.
