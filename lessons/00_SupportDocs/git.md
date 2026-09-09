# Git Cheat-Sheet

### In this cheat-sheet the following subjects are covered

1. The four areas a change moves through
1. Setup and starting a repository
1. Moving changes into the staging area
1. Committing staged changes
1. Undoing changes and moving things back
1. Branching and switching
1. Merging and rebasing
1. Syncing with a remote
1. Inspecting status and history
1. Stashing
1. Tags

<img width="2720" height="2104" alt="git_staging_areas_flow" src="https://github.com/user-attachments/assets/5ef86530-5fc2-4437-ab3f-fb9aea30397f" />

---
## The four areas a change moves through

Every file in a Git-tracked project sits in one of four places, and almost every command's job is to move a change from one of these to the next (or back):

- **Working directory** — the files as they are on disk, exactly what you see in your editor.
- **Staging area (the index)** — a holding area listing exactly what will go into the *next* commit.
- **Local repository** — the `.git` history on your machine: every commit you've made so far.
- **Remote repository** — the shared copy, usually on GitHub/GitLab (`origin`).

```
working directory  --git add-->  staging area  --git commit-->  local repository  --git push-->  remote repository
working directory  <-git restore-  staging area  <-git reset-  local repository  <-git fetch/pull-  remote repository
```

---
## Setup and starting a repository

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"

git init                       # start a new repo in the current folder
git clone <url>                # copy a remote repo (creates local repo + working dir)
```

---
## Moving changes into the staging area

```bash
git add <file>                 # stage one file
git add .                      # stage everything changed/new in the current folder
git add -p                     # stage interactively, chunk by chunk
```

---
## Committing staged changes

```bash
git commit -m "message"        # commit what's staged
git commit -am "message"       # stage + commit all tracked, modified files in one step
git commit --amend             # rewrite the last commit (message and/or content)
```

---
## Undoing changes and moving things back

```bash
git restore <file>             # discard working-dir changes, back to last commit
git restore --staged <file>    # unstage a file, keep the edit in the working dir
git reset --soft  HEAD~1       # undo last commit, keep changes staged
git reset --mixed HEAD~1       # undo last commit, keep changes in working dir (default)
git reset --hard  HEAD~1       # undo last commit and discard the changes entirely
git revert <commit>            # make a new commit that undoes an earlier one (safe on shared history)
```

---
## Branching and switching

```bash
git branch                     # list local branches
git branch <name>               # create a branch
git switch <name>               # switch to a branch
git switch -c <name>            # create and switch in one step
git branch -d <name>            # delete a merged branch
```

---
## Merging and rebasing

```bash
git merge <branch>              # bring <branch>'s commits into the current branch
git rebase <branch>              # replay current branch's commits on top of <branch>
git rebase -i HEAD~3              # interactively edit/squash the last 3 commits
```

---
## Syncing with a remote

```bash
git remote -v                    # list configured remotes
git fetch                        # download remote history, don't touch working dir
git pull                         # fetch + merge into the current branch
git push                         # upload local commits to the remote
git push -u origin <branch>      # push and set the upstream tracking branch
```

---
## Inspecting status and history

```bash
git status                       # what's staged, unstaged, untracked
git diff                         # unstaged changes vs the working dir
git diff --staged                # staged changes vs the last commit
git log --oneline --graph --all  # compact, visual commit history
git blame <file>                 # who last changed each line
```

---
## Stashing

```bash
git stash                        # shelve working-dir + staged changes
git stash list                   # see stashed sets
git stash pop                    # reapply the most recent stash and drop it
git stash apply                  # reapply without dropping it
```

---
## Tags

```bash
git tag v1.0.0                   # lightweight tag on the current commit
git tag -a v1.0.0 -m "message"   # annotated tag
git push origin v1.0.0           # tags aren't pushed by default — push explicitly
```
