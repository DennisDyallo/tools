# Commit Local Changes

Intelligently organize uncommitted local changes into logical, cohesive conventional commits.

## Usage
- `/commit-local-changes` - analyze and organize all local changes
- `/commit-local-changes --staged` - only organize staged changes
- `/commit-local-changes --unstaged` - only organize unstaged changes
- `/commit-local-changes --dry-run` - preview proposed commit structure without making commits
- `/commit-local-changes --interactive` - review and modify each proposed commit before creation

## What this does
1. **SAFELY BACKS UP** your current work by creating a temporary commit with all changes
2. Resets to clean state and analyzes all changes from the backup commit  
3. Intelligently groups ALL changes into logical conventional commits based on:
   - Functional relationships between files
   - Feature completeness (related files committed together)
   - Refactoring operations
   - API enhancements
   - Bug fixes and defensive programming
   - Test updates corresponding to source changes
4. Creates clean, descriptive conventional commit messages
5. Commits each logical group separately

## Safety
- **ZERO DATA LOSS GUARANTEE** - creates temporary backup commit before any changes
- Will NOT proceed if backup commit creation fails
- Can be easily reverted with `git reset --hard <backup-commit-hash>`
- Backup commit becomes unreachable after success (cleaned up by git GC)

---

I need to intelligently organize uncommitted local changes into clean, logical conventional commits. Here's what I need to do:

1. **Parse options**: Check for --dry-run, --interactive, --staged, --unstaged flags in $ARGUMENTS

2. **CRITICAL SAFETY FIRST** (skip if --dry-run): 
   - Create temporary backup commit: `git add -A && git commit -m "TEMP: backup before commit-local-changes"`
   - Store backup hash: `backup_hash=$(git rev-parse HEAD)`
   - If backup commit creation fails, abort immediately

3. **Reset to clean state** (skip if --dry-run):
   - Reset to previous state keeping changes in working directory: `git reset --soft HEAD~1`

4. **Prepare changes for analysis** (skip if --dry-run):
   - Re-stage all changes for analysis: `git add -A`
   - Read all staged files and their diff content
   - Understand the nature and scope of each change
   - Identify logical groupings of related modifications
   - Handle filtering by --staged or --unstaged flags

5. **Intelligently group changes**: 
   - Group changes into cohesive commits based on:
     - Files that work together for a feature/enhancement
     - Refactoring operations (moving/extracting code)
     - API improvements and enhancements  
     - Bug fixes and defensive programming
     - Test updates that correspond to source changes
     - Style/formatting fixes
     - Configuration changes

6. **Create clean commits** (skip if --dry-run):
   - Use conventional commit format (feat:, fix:, refactor:, test:, etc.)
   - Group related files together in single commits
   - Write descriptive commit messages explaining the "why"
   - Ensure each commit is logically complete
   - Stage and commit each group individually
   - If --interactive: prompt user to approve/modify each proposed commit:
     - Show files, diff summary, and proposed message
     - Allow editing commit message
     - Allow adding/removing files from the commit
     - Allow skipping the commit entirely
     - Allow splitting commit into multiple commits

7. **Report results**: Show the multiple commits created and provide backup commit hash for emergency recovery.

**EXPECTED OUTCOME**: Multiple separate commits when changes serve different purposes, or one focused commit when all changes genuinely form a single logical unit.

Remember: NO DATA LOSS allowed. If anything goes wrong, user can restore with `git reset --hard <backup-commit-hash>`.

Options: $ARGUMENTS

DO NOT add Claude footer in commit messages.

## Example

Starting with messy local changes:
