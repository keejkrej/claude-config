# claude-config

Portable config for [Claude Code](https://code.claude.com), copied into `~/.claude/`.

## Files

| File | Purpose | Installed as |
| --- | --- | --- |
| `CLAUDE.md` | Global instructions for every session: the Ambient memory block plus a short "review before done" rule | `~/.claude/CLAUDE.md` |
| `mcp.json` | MCP servers: paper (local `paper mcp`), ambient (local HTTP), mobbin (through `mcp-remote`, which owns the OAuth login), browse (local `browse mcp`) | registered at user scope via `claude mcp add-json` |
| `agents/reviewer.md` | `reviewer` subagent: an independent, read-only code reviewer with the same brief as the other agents' reviewers | `~/.claude/agents/reviewer.md` |

Nothing is linked. `install.sh` (Git Bash, macOS, Linux) and `install.ps1` (PowerShell) copy the
files and back up anything they replace as `*.bak.<timestamp>`; re-run the installer after editing.

## New machine

Run `./install.sh` or `./install.ps1`. The script needs `claude` on `PATH` to register the MCP
servers; without it, register them by hand from `mcp.json`:

```bash
claude mcp add-json --scope user <name> '<json from mcp.json>'
```

The `paper` server runs the `paper` CLI that Paper Desktop installs into `~/.paper/bin`;
add that directory to `PATH` (on Windows: `%USERPROFILE%\.paper\bin` in the user `Path`).
The `browse` server runs the `browse` CLI from `~/.local/bin`; keep that directory on `PATH`
(on Windows: `%USERPROFILE%\.local\bin`) and install the browse extension in your Chrome-family browser.

`mobbin` runs through [`mcp-remote`](https://github.com/geelen/mcp-remote). The first time an agent
starts it, a browser opens for the Mobbin login (Pro/Team/Enterprise plan required). The token is
stored once in `~/.mcp-auth` and shared by every agent that starts the same `mcp-remote` command,
so there is no per-agent login. On Windows, `npx` must resolve to a real executable (mise shims
do this); npm's own `npx.cmd` cannot be spawned without a shell, and the documented workaround is
`cmd /c npx -y mcp-remote …`.

Check everything with `claude mcp list`.

## Reviewer

`reviewer` is a native Claude Code subagent with the read tools plus `Bash` for `git diff` and
tests; its prompt tells it to report, never fix. It inherits the session model. `CLAUDE.md` asks
the main thread to run it on the diff before reporting any non-trivial change done.

## Ambient memory

The `ambient` server is the MCP endpoint inside the running [Ambient](https://alexandria.so)
desktop app (`http://127.0.0.1:8765/mcp`); its tools are unavailable when the app is closed.

`CLAUDE.md` carries the same "always check Ambient memory" block Ambient writes into this file
itself, with the same `ambient-memory:begin/end` markers, so Ambient keeps managing it. The
Ambient app also installs a Claude Code plugin that provides the same MCP server; if that plugin
stays enabled you will see the ambient tools twice, so disable one of the two routes.
