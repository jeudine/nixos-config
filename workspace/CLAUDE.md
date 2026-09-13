# Workspace

`/workspace` holds all my projects, one subdirectory per project. Each project is its own
git repository; `/workspace` itself is not. Agents are started from here and controlled
remotely, so don't wait on interactive prompts and report clearly what you did.

Before working on a project, `cd` into it and read its own README / CLAUDE.md if present.

## Git rules (apply to every project)

- **Never commit unless explicitly asked.** Making changes does not imply permission to commit.
- **When you commit, always push** right after (`git push`, with `-u origin <branch>` for a new
  branch). If pushing is impossible (no remote, auth failure, network), say so explicitly.
- **Never commit on `main`** (or `master`) unless explicitly asked to commit on main. If asked to
  commit while on main, create a new branch first.
- **New branch names start with `dev_`**, e.g. `dev_fix_midi_clock`.
- Never force-push, rewrite published history, or delete branches unless explicitly asked.
- Stage files by explicit path, never `git add -A` / `git add .`: the share is mounted from macOS,
  so `._*` AppleDouble files exist everywhere and must never be committed.

## Missing tools

The machine runs NixOS; tools are installed declaratively from `~/nixos-config`
(flake, host `server`). Don't try to install anything yourself (no `nix-env`, `nix profile`,
`cargo install`, `pip install --user`, curl-to-shell installers, …).

If you need a tool that isn't installed:

1. Tell me which tool and why.
2. Give me the exact change to apply in `~/nixos-config/configuration.nix`, usually adding the
   nixpkgs attribute to `environment.systemPackages`, e.g.
   `environment.systemPackages = with pkgs; [ git vim htop cargo rustc ]`
3. Give the command to apply it: `sudo nixos-rebuild switch --flake ~/nixos-config#server --impure`

Don't edit `~/nixos-config` yourself unless asked. Continue with whatever work doesn't need the tool.

## Projects

| Directory | What | Remote |
| --- | --- | --- |
| `mseq/` | Rust MIDI sequencer framework (Cargo workspace) | `MF-Room/mseq` |
| `mseq_pcb/` | KiCad 10 PCB for MSeq embedded (STM32F413) | `MF-Room/mseq_pcb` |

Add a row when a new project is added.
