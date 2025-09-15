#!/bin/bash

# WordPress Version Bump Helper Script
# Usage: ./scripts/bump-version.sh [website|css|js|all] [major|minor|patch|custom_value]

set -e

CONFIG_FILE="config.php"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Help function
show_help() {
    echo "WordPress Version Bump Helper"
    echo ""
    echo "Usage: $0 [TYPE] [BUMP_TYPE|VALUE]"
    echo ""
    echo "TYPE:"
    echo "  website  - Bump WEBSITE_VERSION (semantic versioning)"
    echo "  css      - Bump WEBSITE_CSS_VERSION (integer)"
    echo "  js       - Bump WEBSITE_JS_VERSION (integer)"
    echo "  all      - Show current versions only"
    echo ""
    echo "BUMP_TYPE (for website):"
    echo "  major    - Increment major version (X.0.0)"
    echo "  minor    - Increment minor version (X.Y.0)"
    echo "  patch    - Increment patch version (X.Y.Z)"
    echo ""
    echo "VALUE (for css/js or custom website version):"
    echo "  Any integer for css/js versions"
    echo "  Any semantic version for website (e.g., 8.0.0)"
    echo ""
    echo "Examples:"
    echo "  $0 website patch     # 7.2.3 → 7.2.4"
    echo "  $0 website minor     # 7.2.3 → 7.3.0"
    echo "  $0 website major     # 7.2.3 → 8.0.0"
    echo "  $0 website 8.1.2     # Set to specific version"
    echo "  $0 css 5             # Set CSS version to 5"
    echo "  $0 js 10             # Set JS version to 10"
    echo "  $0 all               # Show current versions"
}

# Function to get current versions
get_current_versions() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}Error: $CONFIG_FILE not found${NC}"
        exit 1
    fi
    
    WEBSITE_VERSION=$(grep "WEBSITE_VERSION = '" "$CONFIG_FILE" | sed "s/.*WEBSITE_VERSION = '\([^']*\)'.*/\1/" || echo "")
    CSS_VERSION=$(grep "WEBSITE_CSS_VERSION = " "$CONFIG_FILE" | sed 's/.*WEBSITE_CSS_VERSION = \([0-9]*\);.*/\1/' || echo "")
    JS_VERSION=$(grep "WEBSITE_JS_VERSION = " "$CONFIG_FILE" | sed 's/.*WEBSITE_JS_VERSION = \([0-9]*\);.*/\1/' || echo "")
    
    if [[ -z "$WEBSITE_VERSION" || -z "$CSS_VERSION" || -z "$JS_VERSION" ]]; then
        echo -e "${RED}Error: Could not parse version constants from $CONFIG_FILE${NC}"
        echo "Expected format:"
        echo "const WEBSITE_VERSION = '7.2.3';"
        echo "const WEBSITE_CSS_VERSION = 3;"
        echo "const WEBSITE_JS_VERSION = 4;"
        exit 1
    fi
}

# Function to show current versions
show_versions() {
    get_current_versions
    echo -e "${GREEN}Current Versions:${NC}"
    echo "Website: $WEBSITE_VERSION"
    echo "CSS: $CSS_VERSION"
    echo "JS: $JS_VERSION"
}

# Function to bump website version
bump_website_version() {
    local bump_type="$1"
    get_current_versions
    
    # Parse current version
    IFS='.' read -ra VERSION_PARTS <<< "$WEBSITE_VERSION"
    major=${VERSION_PARTS[0]}
    minor=${VERSION_PARTS[1]}
    patch=${VERSION_PARTS[2]}
    
    # Validate version format
    if [[ ! "$major" =~ ^[0-9]+$ ]] || [[ ! "$minor" =~ ^[0-9]+$ ]] || [[ ! "$patch" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: Invalid version format: $WEBSITE_VERSION${NC}"
        echo "Expected format: MAJOR.MINOR.PATCH (e.g., 7.2.3)"
        exit 1
    fi
    
    case "$bump_type" in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            # Custom version provided
            if [[ "$bump_type" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                new_version="$bump_type"
            else
                echo -e "${RED}Error: Invalid version format: $bump_type${NC}"
                echo "Use 'major', 'minor', 'patch', or a semantic version like '8.0.0'"
                exit 1
            fi
            ;;
    esac
    
    # Set new version if not custom
    if [[ -z "$new_version" ]]; then
        new_version="$major.$minor.$patch"
    fi
    
    echo -e "${YELLOW}Updating website version: $WEBSITE_VERSION → $new_version${NC}"
    
    # Update config file
    sed -i "" "s/const WEBSITE_VERSION = '$WEBSITE_VERSION';/const WEBSITE_VERSION = '$new_version';/" "$CONFIG_FILE"
    
    echo -e "${GREEN}✓ Website version updated to $new_version${NC}"
}

# Function to bump asset version (CSS or JS)
bump_asset_version() {
    local asset_type="$1"
    local new_value="$2"
    
    get_current_versions
    
    # Validate new value is integer
    if [[ ! "$new_value" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: Asset version must be an integer: $new_value${NC}"
        exit 1
    fi
    
    case "$asset_type" in
        "css")
            echo -e "${YELLOW}Updating CSS version: $CSS_VERSION → $new_value${NC}"
            sed -i "" "s/const WEBSITE_CSS_VERSION = $CSS_VERSION;/const WEBSITE_CSS_VERSION = $new_value;/" "$CONFIG_FILE"
            echo -e "${GREEN}✓ CSS version updated to $new_value${NC}"
            ;;
        "js")
            echo -e "${YELLOW}Updating JS version: $JS_VERSION → $new_value${NC}"
            sed -i "" "s/const WEBSITE_JS_VERSION = $JS_VERSION;/const WEBSITE_JS_VERSION = $new_value;/" "$CONFIG_FILE"
            echo -e "${GREEN}✓ JS version updated to $new_value${NC}"
            ;;
    esac
}

# Main script logic
case "${1:-}" in
    "website")
        if [[ -z "${2:-}" ]]; then
            echo -e "${RED}Error: Bump type required for website version${NC}"
            show_help
            exit 1
        fi
        bump_website_version "$2"
        ;;
    "css")
        if [[ -z "${2:-}" ]]; then
            echo -e "${RED}Error: New version value required for CSS${NC}"
            show_help
            exit 1
        fi
        bump_asset_version "css" "$2"
        ;;
    "js")
        if [[ -z "${2:-}" ]]; then
            echo -e "${RED}Error: New version value required for JS${NC}"
            show_help
            exit 1
        fi
        bump_asset_version "js" "$2"
        ;;
    "all"|"")
        show_versions
        ;;
    "-h"|"--help"|"help")
        show_help
        ;;
    *)
        echo -e "${RED}Error: Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac