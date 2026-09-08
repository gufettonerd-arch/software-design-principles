#!/bin/bash
# Warns if the locally installed software-design-principles plugin is pinned
# to a commit older than the repo's current tip. The plugin does not
# auto-update silently (see benchmarks/README.md, "Before trusting a
# with-skill run") — a stale install has already cost one benchmark run a
# same-day fix it didn't have. Run this before trusting any with-skill run.
#
# Usage: benchmarks/check-plugin-sync.sh [branch]
#   branch defaults to "master".
#
# Exit codes: 0 = in sync, 1 = stale (or fetch failed), 2 = plugin not installed.

set -euo pipefail

OWNER="gufettonerd-arch"
REPO="software-design-principles"
BRANCH="${1:-master}"
INSTALLED_PLUGINS="${INSTALLED_PLUGINS_JSON:-$HOME/.claude/plugins/installed_plugins.json}"

if [ ! -f "$INSTALLED_PLUGINS" ]; then
    echo "❌ Can't find $INSTALLED_PLUGINS — is the plugin installed?"
    exit 2
fi

INSTALLED_SHA=$(python3 -c "
import json, sys
try:
    data = json.load(open('$INSTALLED_PLUGINS'))
    entries = data.get('plugins', {}).get('$REPO@$REPO', [])
    print(entries[0]['gitCommitSha'] if entries else '')
except Exception:
    print('')
")

if [ -z "$INSTALLED_SHA" ]; then
    echo "❌ $REPO isn't in $INSTALLED_PLUGINS (or has no gitCommitSha yet) — is it installed?"
    exit 2
fi

LATEST_SHA=$(curl -sf "https://api.github.com/repos/$OWNER/$REPO/commits/$BRANCH" \
    | python3 -c "import json,sys; print(json.load(sys.stdin).get('sha',''))" 2>/dev/null || true)

if [ -z "$LATEST_SHA" ]; then
    echo "❌ Couldn't fetch the latest commit on $BRANCH from GitHub (network? rate limit?)."
    echo "   Installed: $INSTALLED_SHA"
    exit 1
fi

if [ "$INSTALLED_SHA" = "$LATEST_SHA" ]; then
    echo "✅ In sync — installed plugin is at $BRANCH's current tip ($INSTALLED_SHA)."
    exit 0
fi

BEHIND_COUNT=$(curl -sf "https://api.github.com/repos/$OWNER/$REPO/compare/$INSTALLED_SHA...$LATEST_SHA" \
    | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('ahead_by','?'))" 2>/dev/null || echo "?")

echo "⚠️  STALE — installed plugin is $BEHIND_COUNT commit(s) behind $BRANCH's tip."
echo "   Installed: $INSTALLED_SHA"
echo "   Latest:    $LATEST_SHA"
echo "   Any with-skill run right now reads the OLD version. Update the plugin"
echo "   (or reinstall it) before trusting the result of a with-skill session."
exit 1
