# dotfiles-gc
Claude Code Git Commit Skill

## Installation

This skill is provided via the dotfiles `.claude/skills/` symlink. After syncing
the dotfiles, the symlink makes this skill available as `/dotfiles-gc`.

## Usage examples
```
/dotfiles-gc                                    Infers ticket from branch/commits/context, generates title
/dotfiles-gc GOLD-1924                          Uses that ticket, generates title
/dotfiles-gc -m "Fix avatar upload"             Infers ticket, uses your title
/dotfiles-gc GOLD-1924 -m "Fix avatar upload"   Uses both explicitly
```

## Notes

 - Claude will never auto-trigger this — it only runs when you explicitly type `/dotfiles-gc`. No surprise commits.
 - Confirmation gate before every commit — Claude always shows you the proposed message and waits for a Y before running git commit. If you don't like the message, you can just tell it what to change in plain English.
 - Ticket inference prompts Jira ticket key — if the ticket was inferred rather than explicit, Claude explains its reasoning and asks you to confirm, so there's no silent guessing.
 - allowed-tools: Bash(git *) — scopes the skill to only run git commands without asking for per-use approval each time.
