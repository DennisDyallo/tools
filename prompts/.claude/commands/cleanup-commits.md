# Cleanup Commits

Clean up messy commit history by intelligently regrouping commits into logical, cohesive conventional commits.

## Usage
- `/cleanup-commits` - will ask you for the commit range
- `/cleanup-commits HEAD~5..HEAD` - specify commit range directly
- `/cleanup-commits abc123..def456` - use specific commit hashes
- `/cleanup-commits HEAD~5..HEAD --dry-run` - preview proposed commit structure without making changes
- `/cleanup-commits HEAD~5..HEAD --interactive` - review and modify each proposed commit before creation

## What this does
1. **SAFELY BACKS UP** your current work to a timestamped backup branch
2. Analyzes all commits in the specified range (messages and file changes)  
3. **Intelligently regroups ALL changes into MULTIPLE logical commits** based on:
   - Functional relationships between files
   - Feature completeness (related files committed together)
   - Refactoring operations
   - API enhancements
   - Bug fixes and defensive programming
   - Test updates corresponding to source changes
4. Creates clean, descriptive conventional commit messages for each group
5. **Commits each logical group separately** - resulting in multiple focused commits

## Safety
- **ZERO DATA LOSS GUARANTEE** - creates backup branch before any changes
- Will NOT proceed if backup creation fails (unless --dry-run)
- Tells you exactly where your original commits are saved
- Use `--dry-run` to preview changes before committing

---

I need to intelligently reorganize messy commits into clean, logical conventional commits. Here's what I need to do:

1. **Parse options**: Check for --dry-run and --interactive flags in $ARGUMENTS

2. **Get commit range**: If not provided in $ARGUMENTS, ask the user for the commit range to clean up. Handle these formats:
   - "HEAD~5..HEAD" or "abc123..def456" (explicit range)
   - "abc123" (implicit range from abc123 to HEAD, convert to "abc123..HEAD")
   - No arguments (prompt user for range)

3. **CRITICAL SAFETY FIRST** (skip if --dry-run): 
   - Create timestamped backup branch before any destructive operations
   - If backup creation fails, abort immediately

4. **Analyze the commits**: 
   - Read all commit messages in the range to understand developer intent
   - Identify WIP/incomplete markers: "WIP", "fixup", "temp", "TODO", "hack", "debug", etc.
   - Analyze all file changes across the range (full diffs, not just file names)
   - Use existing commit messages to inform new commit message creation

5. **Reset and create multiple groups** (skip if --dry-run): 
   - Reset back to before the commit range
   - Analyze changes and create MULTIPLE separate logical groups
   - Each group becomes its own individual commit
   - Group criteria:
     - Files that work together for a feature/enhancement
     - Refactoring operations (moving/extracting code)
     - API improvements and enhancements  
     - Bug fixes and defensive programming
     - Test updates that correspond to source changes
     - Style/formatting fixes
   - Handle WIP/incomplete work appropriately:
     - Group experimental/debug code separately or exclude if non-functional
     - Merge fixup commits into their target commits
     - Complete partial implementations where possible

6. **Create multiple clean commits** (skip if --dry-run):
   - CRITICAL: Create one separate commit for each logical group identified above
   - Aim for multiple commits unless all changes genuinely form a single atomic unit
   - For each group:
     - Stage only the files belonging to that group
     - Create commit with conventional format (feat:, fix:, refactor:, test:, etc.)
     - Use descriptive commit messages combining insights from original messages and code analysis
     - Repeat for next group
   - Avoid the trap of putting unrelated changes in a single commit
   - Ensure each commit is logically complete and atomic
   - If --interactive: prompt user to approve/modify each proposed commit:
     - Show files, diff summary, original commit messages, and proposed message
     - Allow editing commit message
     - Allow adding/removing files from the commit
     - Allow skipping the commit entirely
     - Allow splitting commit into multiple commits

7. **Report results**: Show the multiple commits created and where the backup branch is stored.

Remember: NO DATA LOSS allowed. If anything goes wrong, the user can easily return to their backup branch.

**EXPECTED OUTCOME**: Multiple separate commits when changes serve different purposes, or one focused commit when all changes genuinely form a single logical unit.

Commit range to clean up: $ARGUMENTS

DO NOT add Claude footer in commit messages.

## Example

Starting with messy commit history:
```
abc123 | WIP auth stuff
def456 | fix bug
ghi789 | update tests  
jkl012 | more auth work
mno345 | fixup tests
pqr678 | temp disable logging
stu901 | auth working now
vwx234 | cleanup
```

File changes across all commits:
```
- src/Authentication/YubikeyAuth.cs (new FIDO2 method + bug fixes)
- src/Authentication/IYubikeyAuth.cs (interface updates)
- test/Authentication/YubikeyAuthTests.cs (comprehensive test suite)
- src/Utils/Logger.cs (logging level adjustment)
- src/Utils/CryptoHelper.cs (minor refactoring)
- README.md (updated examples)
```

Results in clean commits:
```
feat(auth): add FIDO2 resident key support
- src/Authentication/YubikeyAuth.cs
- src/Authentication/IYubikeyAuth.cs  
- test/Authentication/YubikeyAuthTests.cs

refactor(crypto): extract key validation logic
- src/Utils/CryptoHelper.cs

config(logging): reduce default log verbosity
- src/Utils/Logger.cs

docs: add FIDO2 usage examples
- README.md
```

**Example with mixed unrelated changes:**
```
Starting with commit that touches multiple areas:
abc123 | big update (touches auth + crypto + docs + config)

File changes:
- src/Authentication/YubikeyAuth.cs (FIDO2 feature)
- src/Authentication/IYubikeyAuth.cs (FIDO2 feature) 
- src/Crypto/Algorithms.cs (unrelated AES optimization)
- src/Utils/Config.cs (unrelated timeout setting)
- README.md (FIDO2 docs)
- package.json (dependency update)

Should be split into:
feat(auth): add FIDO2 resident key support
- src/Authentication/YubikeyAuth.cs
- src/Authentication/IYubikeyAuth.cs
- README.md (FIDO2 section only)

perf(crypto): optimize AES key generation
- src/Crypto/Algorithms.cs

config: increase default timeout to 30s
- src/Utils/Config.cs

chore: update dependencies
- package.json
```

Original intent preserved, but organized into logical, atomic commits with clear conventional commit messages.
