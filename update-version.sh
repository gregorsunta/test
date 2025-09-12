#!/bin/bash
set -e

# Config
PHP_CONFIG="config.php"

# Get current version
if [[ -n "$GITHUB_REF" && "$GITHUB_REF" == refs/tags/* ]]; then
    CURRENT_TAG=${GITHUB_REF#refs/tags/}
else
    CURRENT_TAG=$(git rev-parse --short HEAD)
fi

# Get information from GitHub Actions environment
if [[ -n "$GITHUB_ACTIONS" && -n "$LAST_STABLE_TAG" ]]; then
    # Use raw data from GitHub Actions workflow
    PREV_TAG="$LAST_STABLE_TAG"
    CHANGED_FILES="$CHANGED_FILES"
    
    echo "Processing information from GitHub Actions:"
    echo "  Stable tag: $PREV_TAG"
    echo "  Changed files: $CHANGED_FILES"
else
    echo "ERROR: This script must be run in GitHub Actions with required environment variables"
    echo "Required: LAST_STABLE_TAG, CHANGED_FILES"
    exit 1
fi

# If we're running on a release tag and it's the same as the stable tag,
# we should still update the version to reflect the current release
if [[ "$CURRENT_TAG" == "$PREV_TAG" ]]; then
    echo "⚠️  Running on release tag $CURRENT_TAG - will update version to reflect current release"
fi

echo "Comparing $PREV_TAG -> $CURRENT_TAG"

# Process the changed files to determine what needs updating
echo "🔍 Analyzing changed files..."

# Check for CSS changes
CSS_CHANGED="false"
echo "🔍 Checking for CSS changes in: '$CHANGED_FILES'"
if echo "$CHANGED_FILES" | grep -qE '\.(css|less|scss)$'; then
    CSS_CHANGED="true"
    echo "✅ CSS files detected in changed files"
else
    echo "❌ No CSS files found in changed files"
fi

# Check for JS changes  
JS_CHANGED="false"
echo "🔍 Checking for JS changes in: '$CHANGED_FILES'"
if echo "$CHANGED_FILES" | grep -qE '\.(js|ts|jsx|tsx)$'; then
    JS_CHANGED="true"
    echo "✅ JS files detected in changed files"
else
    echo "❌ No JS files found in changed files"
fi

echo "Analysis results:"
echo "  CSS changed: $CSS_CHANGED"
echo "  JS changed: $JS_CHANGED"

# Read current versions
CURRENT_CSS=$(grep "WEBSITE_CSS_VERSION" "$PHP_CONFIG" | grep -oE '[0-9]+' || echo "0")
CURRENT_JS=$(grep "WEBSITE_JS_VERSION" "$PHP_CONFIG" | grep -oE '[0-9]+' || echo "0")

# Update CSS version if CSS files changed
if [[ "$CSS_CHANGED" == "true" ]]; then
    NEW_CSS=$((CURRENT_CSS + 1))
    sed -i.bak "s/const WEBSITE_CSS_VERSION = .*/const WEBSITE_CSS_VERSION = $NEW_CSS;/" "$PHP_CONFIG"
    echo "CSS: $CURRENT_CSS -> $NEW_CSS"
fi

# Update JS version if JS files changed
if [[ "$JS_CHANGED" == "true" ]]; then
    NEW_JS=$((CURRENT_JS + 1))
    sed -i.bak "s/const WEBSITE_JS_VERSION = .*/const WEBSITE_JS_VERSION = $NEW_JS;/" "$PHP_CONFIG"
    echo "JS: $CURRENT_JS -> $NEW_JS"
fi

# Always update website version
echo "🔄 Updating WEBSITE_VERSION to: $CURRENT_TAG"
sed -i.bak "s/const WEBSITE_VERSION = '.*'/const WEBSITE_VERSION = '$CURRENT_TAG'/" "$PHP_CONFIG"

# Show what changed
echo "📝 Version update details:"
echo "  Previous WEBSITE_VERSION: $(grep "WEBSITE_VERSION" "$PHP_CONFIG.bak" | head -1)"
echo "  New WEBSITE_VERSION: $(grep "WEBSITE_VERSION" "$PHP_CONFIG" | head -1)"

# Check if there are actual changes
if ! git diff --quiet "$PHP_CONFIG"; then
    echo "✅ Changes detected in config.php"
    git diff "$PHP_CONFIG"
else
    echo "ℹ️  No changes detected - version already up to date"
fi

# Clean up backup files
rm -f "$PHP_CONFIG.bak"

# Verify PHP syntax
php -l "$PHP_CONFIG" >/dev/null

# Commit if changes exist
if ! git diff --quiet "$PHP_CONFIG"; then
    git config user.name "github-actions"
    git config user.email "actions@github.com"
    git add "$PHP_CONFIG"
    git commit -m "Update versions for $CURRENT_TAG"
    git push
fi

echo "Done!"