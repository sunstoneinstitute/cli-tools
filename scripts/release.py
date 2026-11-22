#!/usr/bin/env python3
"""Release automation for cli-tools.

Reads a changelog entry from stdin, bumps VERSION, moves the entry into a new
version section of CHANGELOG.md, commits, and tags. Pushing the tag triggers
.github/workflows/release.yml.

Usage:
    echo "changelog text" | scripts/release.py --bump minor
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VERSION = ROOT / "VERSION"
CHANGELOG = ROOT / "CHANGELOG.md"


def current_version() -> str:
    version = VERSION.read_text().strip()
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        sys.exit(f"Expected semver x.y.z in VERSION, got {version!r}")
    return version


def bump_version(version: str, bump: str) -> str:
    major, minor, patch = (int(p) for p in version.split("."))
    if bump == "major":
        return f"{major + 1}.0.0"
    if bump == "minor":
        return f"{major}.{minor + 1}.0"
    return f"{major}.{minor}.{patch + 1}"


def update_changelog(new_version: str, entry: str) -> None:
    """Insert the new section after [Unreleased], dropping whatever was under it."""
    header = f"## [{new_version}] - {date.today().isoformat()}"
    section = f"{header}\n\n{entry.strip()}\n\n"
    text = CHANGELOG.read_text()
    unreleased = re.compile(r"(## \[Unreleased\]\n)(?:.*?\n)*?(?=## \[|\Z)")
    if not unreleased.search(text):
        sys.exit("CHANGELOG.md has no '## [Unreleased]' section")
    text = unreleased.sub(lambda m: f"{m.group(1)}\n{section}", text, count=1)
    CHANGELOG.write_text(text.rstrip("\n") + "\n")


def git_commit_and_tag(version: str) -> None:
    tag = f"v{version}"
    subprocess.run(["git", "add", "VERSION", "CHANGELOG.md"], cwd=ROOT, check=True)
    subprocess.run(["git", "commit", "-m", f"Release {tag}"], cwd=ROOT, check=True)
    subprocess.run(["git", "tag", "-a", tag, "-m", f"Release {tag}"], cwd=ROOT, check=True)
    print(f"Created commit and tag {tag}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Release cli-tools")
    parser.add_argument("--bump", choices=["major", "minor", "patch"], required=True)
    parser.add_argument("--dry-run", action="store_true", help="Show what would happen without making changes")
    args = parser.parse_args()

    entry = sys.stdin.read().strip()
    if not entry:
        sys.exit("No changelog entry provided on stdin")

    old = current_version()
    new = bump_version(old, args.bump)
    print(f"Version: {old} -> {new}")
    print(f"Changelog:\n{entry}\n")
    if args.dry_run:
        print("(dry run, no changes made)")
        return

    VERSION.write_text(f"{new}\n")
    update_changelog(new, entry)
    git_commit_and_tag(new)


if __name__ == "__main__":
    main()
