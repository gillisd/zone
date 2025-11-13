# Git Commit Protocol

This document outlines the protocol for creating git commits in this project.

## Git Safety Protocol

- NEVER update the git config
- NEVER run destructive/irreversible git commands (like push --force, hard reset, etc) unless the user explicitly requests them
- NEVER skip hooks (--no-verify, --no-gpg-sign, etc) unless the user explicitly requests it
- NEVER run force push to main/master, warn the user if they request it
- Avoid git commit --amend. ONLY use --amend when either (1) user explicitly requested amend OR (2) adding edits from pre-commit hook (additional instructions below)
- Before amending: ALWAYS check authorship (git log -1 --format='%an %ae')
- NEVER commit changes unless the user explicitly asks you to. It is VERY IMPORTANT to only commit when explicitly asked, otherwise the user will feel that you are being too proactive.

## Commit Steps

### 1. Gather Information

Run these bash commands in parallel:
- Run a git status command to see all untracked files
- Run a git diff command to see both staged and unstaged changes that will be committed
- Run a git log command to see recent commit messages, so that you can follow this repository's commit message style

### 2. Draft Commit Message

Analyze all staged changes (both previously staged and newly added) and draft a commit message:
- Summarize the nature of the changes (new feature, enhancement, bug fix, refactoring, test, docs, etc.)
- Ensure the message accurately reflects the changes and their purpose (i.e. "add" means a wholly new feature, "update" means an enhancement, "fix" means a bug fix, etc.)
- Do not commit files that likely contain secrets (.env, credentials.json, etc). Warn the user if they specifically request to commit those files
- Draft a concise (1-2 sentences) commit message that focuses on the "why" rather than the "what"
- Ensure it accurately reflects the changes and their purpose

### 3. Execute Commit

Run the following commands:
- Add relevant untracked files to the staging area
- Create the commit with a message ending with:
  ```
  🤖 Generated with [Claude Code](https://claude.com/claude-code)

  Co-Authored-By: Claude <noreply@anthropic.com>
  ```
- Run git status after the commit completes to verify success

### 4. Handle Pre-commit Hook Changes

If the commit fails due to pre-commit hook changes, retry ONCE. If it succeeds but files were modified by the hook, verify it's safe to amend:
- Check authorship: `git log -1 --format='%an %ae'`
- Check not pushed: git status shows "Your branch is ahead"
- If both true: amend your commit. Otherwise: create NEW commit (never amend other developers' commits)

## Important Notes

- NEVER run additional commands to read or explore code, besides git bash commands
- NEVER use the TodoWrite or Task tools
- DO NOT push to the remote repository unless the user explicitly asks you to do so
- IMPORTANT: Never use git commands with the -i flag (like git rebase -i or git add -i) since they require interactive input which is not supported
- If there are no changes to commit (i.e., no untracked files and no modifications), do not create an empty commit

## Commit Message Format

In order to ensure good formatting, ALWAYS pass the commit message via a HEREDOC, like this example:

```bash
git commit -m "$(cat <<'EOF'
Commit message here.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

## Example Workflow

```bash
# 1. Check status and review changes
git status
git diff

# 2. Stage files
git add file1.rb file2.rb

# 3. Commit with proper format
git commit -m "$(cat <<'EOF'
Add new feature to improve user experience

This change adds X functionality which allows users to Y.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"

# 4. Verify commit
git status
```
