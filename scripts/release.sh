#!/usr/bin/env bash
# Bump the app version in pubspec.yaml, always incrementing the build number,
# and move the CHANGELOG.md "Unreleased" section under a new version heading.
#
# Usage: scripts/release.sh <major|minor|patch>

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

BUMP="${1:-}"
if [[ "$BUMP" != "major" && "$BUMP" != "minor" && "$BUMP" != "patch" ]]; then
  echo "Usage: $0 <major|minor|patch>" >&2
  exit 1
fi

CURRENT_LINE=$(grep -E '^version:' pubspec.yaml)
CURRENT_VERSION=$(echo "$CURRENT_LINE" | sed -E 's/^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)/\1+\2/')
SEMVER="${CURRENT_VERSION%+*}"
BUILD="${CURRENT_VERSION#*+}"

IFS='.' read -r MAJOR MINOR PATCH <<< "$SEMVER"

case "$BUMP" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
esac

NEW_BUILD=$((BUILD + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}+${NEW_BUILD}"

sed -i -E "s/^version:.*/version: ${NEW_VERSION}/" pubspec.yaml

TODAY=$(date +%Y-%m-%d)
NEW_HEADING="## [${MAJOR}.${MINOR}.${PATCH}] - ${TODAY}"

# Insert a fresh empty Unreleased section, and retitle the old one.
python3 - "$NEW_HEADING" <<'EOF'
import re
import sys

heading = sys.argv[1]
path = "CHANGELOG.md"
with open(path) as f:
    content = f.read()

empty_unreleased = (
    "## [Unreleased]\n\n"
    "### Added\n\n"
    "### Changed\n\n"
    "### Fixed\n\n"
    "### Removed\n\n"
)

content = content.replace("## [Unreleased]\n\n", empty_unreleased + heading + "\n\n", 1)

with open(path, "w") as f:
    f.write(content)
EOF

echo "Bumped version to ${MAJOR}.${MINOR}.${PATCH}+${NEW_BUILD}"
echo "Review CHANGELOG.md, fill in the new section, then commit as:"
echo "  git commit -am \"chore: release v${MAJOR}.${MINOR}.${PATCH}\""
echo "  git tag v${MAJOR}.${MINOR}.${PATCH}"
