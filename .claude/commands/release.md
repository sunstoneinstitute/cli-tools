# Release cli-tools

You are performing a release of cli-tools. Arguments: $ARGUMENTS

## Step 1: Determine bump level

Parse `$ARGUMENTS` for `--bump {major,minor,patch}`. If no `--bump` argument is provided, determine the bump level automatically:

1. Find the latest version tag: `git tag --sort=-v:refname | head -1` (none means first release, compare against the root commit).
2. Get the commits since that tag: `git log <tag>..HEAD --oneline`
3. Classify:
   - **minor**: any new tool, new command, or new option
   - **patch**: only fixes, docs, refactoring, tests, CI
   - **NEVER bump major** unless the user explicitly passed `--bump major`

State the bump level and why.

## Step 2: Ensure documentation is up to date

Review the commits since the last tag and check that README.md and CLAUDE.md reflect them (new tools, changed usage, layout or workflow changes). Fix anything stale now, or flag it to the user. If everything is current, say so and move on.

## Step 3: Generate changelog entry

If CHANGELOG.md has entries under `## [Unreleased]`, start from those and supplement with commits they don't cover. Otherwise write the entry from the commits.

One line per change, prefixed with the category:

- `- Added:` new tools or features
- `- Changed:` changes in existing functionality
- `- Improved:` material performance improvement
- `- Fixed:` bug fixes
- `- Removed:` removed tools or features

Name the tool each line is about. Keep lines user-focused: CI, agent instructions and other housekeeping don't belong. Do NOT include the version header line, the release script adds it and clears `[Unreleased]`.

## Step 4: Confirm with user

Show the current version → new version, the bump level and reasoning, and the changelog entry. Ask for confirmation before proceeding and revise if asked.

## Step 5: Run the release script

```bash
scripts/release.py --bump <level> <<'CHANGELOG'
<changelog entry>
CHANGELOG
```

## Step 6: Report result

Show the new tag and remind the user to push when ready:

```
git push && git push --tags
```

The tag push runs `.github/workflows/release.yml`, which builds bottles, creates the GitHub release and updates `Formula/cli-tools.rb` in sunstoneinstitute/homebrew-tap.
