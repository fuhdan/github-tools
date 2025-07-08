#!/bin/bash
# GitHub Container Registry (GHCR) Image Cleanup Script
# Deletes old Docker images from GitHub Container Registry

set -euo pipefail

# Configuration
REPO_OWNER=""
PACKAGE_NAME=""
DAYS_OLD=30
KEEP_LATEST=0
PRESERVE_SPECIAL=true
INCLUDE_UNTAGGED=false
PROJECT_FILTER=""
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
DRY_RUN=false
LIST_PACKAGES=false
LIST_VERSIONS=false
VERBOSE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GOLD='\033[1;33m'
DARK_GRAY='\033[1;30m'
NC='\033[0m'

usage() {
    echo "Usage: $0 [OPTIONS] REPO_OWNER [PACKAGE_NAME]"
    echo ""
    echo "Delete old Docker images from GitHub Container Registry (ghcr.io)."
    echo ""
    echo "Options:"
    echo "  -d, --days DAYS        Delete images older than DAYS (default: 30)"
    echo "  -k, --keep NUMBER      Keep latest NUMBER images"
    echo "  -u, --include-untagged Include untagged versions in calculations"
    echo "  -p, --project PROJECT  Only process packages matching PROJECT prefix"
    echo "  -s, --skip-special     Don't preserve 'latest' and 'staging-latest' tagged images"
    echo "  -t, --token TOKEN      GitHub personal access token"
    echo "  -n, --dry-run          Show what would be deleted without actually deleting"
    echo "  -l, --list-packages    List all packages for the owner"
    echo "  -i, --list-versions    List all versions for a specific package"
    echo "  -v, --verbose          Show detailed information"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  # List packages"
    echo "  $0 -l myuser                        # List all packages"
    echo "  $0 -l -p dns myuser                 # List packages starting with 'dns'"
    echo ""
    echo "  # Single package cleanup"
    echo "  $0 -k 5 myuser mypackage            # Keep 5 latest tagged + special tags"
    echo "  $0 -k 5 -u myuser mypackage         # Keep 5 latest (tagged+untagged) + special tags"
    echo "  $0 -d 7 myuser mypackage            # Delete tagged >7 days, delete all untagged"
    echo "  $0 -d 7 -u myuser mypackage         # Delete all versions >7 days"
    echo ""
    echo "  # Bulk cleanup (ALL packages)"
    echo "  $0 myuser                           # Delete tagged >30 days, delete all untagged"
    echo "  $0 -k 2 myuser                      # Keep 2 latest tagged per package + special tags"
    echo "  $0 -k 2 -p dns myuser               # Clean 'dns*' packages only"
    echo "  $0 -d 7 -u myuser                   # Delete all versions >7 days in all packages"
    echo ""
    echo "Behavior:"
    echo "  • Special tags ('latest', 'staging-latest', 'main', 'master') are preserved by default"
    echo "  • -k NUMBER keeps NUMBER regular versions PLUS special tagged versions"
    echo "  • Without -u: Untagged versions are deleted (considered build artifacts)"
    echo "  • With -u: Untagged versions are included in keep/age calculations"
    echo "  • -v shows detailed output, without -v shows summary only"
    echo ""
    echo "Authentication:"
    echo "  Requires GitHub token with 'read:packages' and 'delete:packages' scopes."
    echo ""
    exit 1
}

show_login_instructions() {
    echo -e "${YELLOW}GitHub Authentication Required${NC}"
    echo ""
    echo "Your token needs these scopes: read:packages, delete:packages, repo"
    echo ""
    echo "Options:"
    echo "1. Environment variable: export GITHUB_TOKEN=your_token"
    echo "2. Command line: $0 -t your_token ..."
    echo "3. GitHub CLI: gh auth login --scopes \"read:packages,delete:packages,repo\""
    echo ""
    echo "Get token at: https://github.com/settings/tokens"
}

test_auth() {
    local token="$1"
    echo -e "${YELLOW}Testing authentication...${NC}"
    
    local response
    response=$(curl -s -w "%{http_code}" \
        -H "Authorization: token $token" \
        "https://api.github.com/user" \
        -o /tmp/auth_test.json 2>/dev/null)
    
    local code="${response: -3}"
    if [ "$code" = "200" ]; then
        local user
        user=$(jq -r '.login' /tmp/auth_test.json 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✓ Authenticated as: $user${NC}"
        rm -f /tmp/auth_test.json
        return 0
    else
        echo -e "${RED}✗ Authentication failed (HTTP $code)${NC}"
        rm -f /tmp/auth_test.json
        return 1
    fi
}

url_encode() {
    echo "$1" | sed 's|/|%2F|g'
}

get_versions() {
    local owner="$1"
    local package="$2"
    local encoded
    encoded=$(url_encode "$package")
    
    local all_versions=""
    local page=1
    
    while true; do
        local versions
        # Try user endpoint first
        versions=$(curl -s \
            -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/users/$owner/packages/container/$encoded/versions?per_page=100&page=$page" 2>/dev/null)
        
        # Try org endpoint if user failed
        if echo "$versions" | jq -e '.message' >/dev/null 2>&1; then
            versions=$(curl -s \
                -H "Authorization: token $GITHUB_TOKEN" \
                "https://api.github.com/orgs/$owner/packages/container/$encoded/versions?per_page=100&page=$page" 2>/dev/null)
        fi
        
        # Break on error or empty
        if echo "$versions" | jq -e '.message' >/dev/null 2>&1 || [ -z "$versions" ] || [ "$versions" = "[]" ]; then
            break
        fi
        
        local count
        count=$(echo "$versions" | jq '. | length')
        if [ "$count" -eq 0 ]; then
            break
        fi
        
        # Merge results
        if [ -z "$all_versions" ]; then
            all_versions="$versions"
        else
            all_versions=$(echo "$all_versions $versions" | jq -s 'add')
        fi
        
        # Break if less than full page
        if [ "$count" -lt 100 ]; then
            break
        fi
        
        page=$((page + 1))
    done
    
    echo "$all_versions"
}

get_packages() {
    local owner="$1"
    
    local packages
    # Try user packages first
    packages=$(curl -s \
        -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/users/$owner/packages?package_type=container" 2>/dev/null)
    
    # Try org packages if user failed or empty
    if [ "$packages" = "[]" ] || echo "$packages" | jq -e '.message' >/dev/null 2>&1; then
        packages=$(curl -s \
            -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/orgs/$owner/packages?package_type=container" 2>/dev/null)
    fi
    
    echo "$packages"
}

is_special_tag() {
    local tag="$1"
    
    if [ "$PRESERVE_SPECIAL" = true ]; then
        case "$tag" in
            latest|staging-latest|main|master) return 0 ;;
        esac
    fi
    return 1
}

has_special_tag() {
    local tags="$1"
    
    if [ -z "$tags" ] || [ "$tags" = "null" ]; then
        return 1
    fi
    
    IFS=',' read -ra tag_array <<< "$tags"
    for tag in "${tag_array[@]}"; do
        tag=$(echo "$tag" | xargs)
        if is_special_tag "$tag"; then
            return 0
        fi
    done
    return 1
}

delete_version() {
    local owner="$1"
    local package="$2"
    local version_id="$3"
    local tags="$4"
    
    if [ "$DRY_RUN" = true ]; then
        [ "$VERBOSE" = true ] && echo -e "${YELLOW}[DRY RUN] Would delete: $version_id ($tags)${NC}"
        return 0
    fi
    
    [ "$VERBOSE" = true ] && echo -e "${RED}Deleting: $version_id ($tags)${NC}"
    
    local encoded
    encoded=$(url_encode "$package")
    
    # Try user endpoint first
    local response
    response=$(curl -s -w "%{http_code}" -X DELETE \
        -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/users/$owner/packages/container/$encoded/versions/$version_id" \
        -o /dev/null 2>/dev/null)
    
    local code="${response: -3}"
    
    # Try org endpoint if user failed
    if [ "$code" != "204" ]; then
        response=$(curl -s -w "%{http_code}" -X DELETE \
            -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/orgs/$owner/packages/container/$encoded/versions/$version_id" \
            -o /dev/null 2>/dev/null)
        code="${response: -3}"
    fi
    
    if [ "$code" = "204" ]; then
        [ "$VERBOSE" = true ] && echo -e "${GREEN}✓ Deleted: $version_id${NC}"
        return 0
    else
        [ "$VERBOSE" = true ] && echo -e "${RED}✗ Failed: $version_id (HTTP $code)${NC}"
        return 1
    fi
}

cleanup_package() {
    local owner="$1"
    local package="$2"
    
    [ "$VERBOSE" = true ] && echo -e "${BLUE}Processing: $owner/$package${NC}"
    
    local versions
    versions=$(get_versions "$owner" "$package")
    
    if [ -z "$versions" ] || [ "$versions" = "[]" ]; then
        echo -e "${RED}No versions found${NC}"
        return 1
    fi
    
    # Sort by date (newest first)
    local sorted
    sorted=$(echo "$versions" | jq 'sort_by(.updated_at) | reverse')
    
    # Separate special tagged from regular versions
    local special_versions regular_versions
    special_versions="[]"
    regular_versions="[]"
    
    echo "$sorted" | jq -c '.[]' | while read -r version; do
        local tags
        tags=$(echo "$version" | jq -r '.metadata.container.tags // [] | join(",")')
        
        if has_special_tag "$tags"; then
            special_versions=$(echo "$special_versions [$version]" | jq -s 'add')
        else
            regular_versions=$(echo "$regular_versions [$version]" | jq -s 'add')
        fi
    done
    
    # Re-read the separated versions (due to subshell)
    special_versions=$(echo "$sorted" | jq '[.[] | select(.metadata.container.tags // [] | map(select(. == "latest" or . == "staging-latest" or . == "main" or . == "master")) | length > 0)]')
    regular_versions=$(echo "$sorted" | jq '[.[] | select(.metadata.container.tags // [] | map(select(. == "latest" or . == "staging-latest" or . == "main" or . == "master")) | length == 0)]')
    
    local preserved=0 kept=0 deleted=0
    
    # Always preserve special tagged versions
    if [ "$PRESERVE_SPECIAL" = true ]; then
        preserved=$(echo "$special_versions" | jq '. | length')
        if [ "$VERBOSE" = true ] && [ "$preserved" -gt 0 ]; then
            echo "$special_versions" | jq -c '.[]' | while read -r version; do
                local id tags
                id=$(echo "$version" | jq -r '.id')
                tags=$(echo "$version" | jq -r '.metadata.container.tags // [] | join(",")')
                echo -e "${GREEN}Preserving special: $id ($tags)${NC}"
            done
        fi
    fi
    
    # Process regular versions
    local cutoff_time
    cutoff_time=$(date -d "$DAYS_OLD days ago" +%s)
    
    # Filter regular versions by untagged preference
    local target_versions
    if [ "$INCLUDE_UNTAGGED" = true ]; then
        # Include all regular versions (tagged + untagged)
        target_versions="$regular_versions"
    else
        # Only include tagged regular versions, delete all untagged
        target_versions=$(echo "$regular_versions" | jq '[.[] | select(.metadata.container.tags != null and (.metadata.container.tags | length) > 0)]')
        
        # Delete untagged versions
        local untagged_versions
        untagged_versions=$(echo "$regular_versions" | jq '[.[] | select(.metadata.container.tags == null or (.metadata.container.tags | length) == 0)]')
        
        echo "$untagged_versions" | jq -c '.[]' | while read -r version; do
            local id
            id=$(echo "$version" | jq -r '.id')
            if delete_version "$owner" "$package" "$id" "(untagged)"; then
                deleted=$((deleted + 1))
            fi
        done
    fi
    
    # Process target versions (tagged regular, or all regular if -u is used)
    echo "$target_versions" | jq -c '.[]' | while read -r version; do
        local id updated_at tags
        id=$(echo "$version" | jq -r '.id')
        updated_at=$(echo "$version" | jq -r '.updated_at')
        tags=$(echo "$version" | jq -r '.metadata.container.tags // [] | join(",")')
        
        local timestamp
        timestamp=$(date -d "$updated_at" +%s 2>/dev/null || echo "0")
        
        local should_keep=false
        
        if [ "$KEEP_LATEST" -gt 0 ]; then
            # Keep mode: keep N latest regular versions
            if [ "$kept" -lt "$KEEP_LATEST" ]; then
                should_keep=true
                kept=$((kept + 1))
            fi
        else
            # Age mode: keep if newer than cutoff
            if [ "$timestamp" -ge "$cutoff_time" ]; then
                should_keep=true
                kept=$((kept + 1))
            fi
        fi
        
        if [ "$should_keep" = true ]; then
            [ "$VERBOSE" = true ] && echo -e "${GREEN}Keeping: $id ($tags)${NC}"
        else
            if delete_version "$owner" "$package" "$id" "$tags"; then
                deleted=$((deleted + 1))
            fi
        fi
    done
    
    # Get final counts (due to subshell issue, recalculate)
    local final_preserved final_kept final_deleted
    final_preserved=$(echo "$special_versions" | jq '. | length')
    
    # Count what we actually kept/deleted by comparing before/after
    local total_before total_after
    total_before=$(echo "$sorted" | jq '. | length')
    
    # For summary, estimate the counts
    if [ "$INCLUDE_UNTAGGED" = false ]; then
        local untagged_count
        untagged_count=$(echo "$regular_versions" | jq '[.[] | select(.metadata.container.tags == null or (.metadata.container.tags | length) == 0)] | length')
        final_deleted=$untagged_count
    else
        final_deleted=0
    fi
    
    local target_count
    target_count=$(echo "$target_versions" | jq '. | length')
    
    if [ "$KEEP_LATEST" -gt 0 ]; then
        final_kept=$([ "$target_count" -lt "$KEEP_LATEST" ] && echo "$target_count" || echo "$KEEP_LATEST")
        final_deleted=$((final_deleted + target_count - final_kept))
    else
        # Age-based: count how many are recent
        local recent_count
        recent_count=$(echo "$target_versions" | jq --argjson cutoff "$cutoff_time" '[.[] | select((.updated_at | strptime("%Y-%m-%dT%H:%M:%SZ") | mktime) >= $cutoff)] | length')
        final_kept=$recent_count
        final_deleted=$((final_deleted + target_count - recent_count))
    fi
    
    # Summary
    if [ "$VERBOSE" = false ]; then
        if [ "$final_kept" -gt 0 ] || [ "$final_deleted" -gt 0 ] || [ "$final_preserved" -gt 0 ]; then
            echo "Kept: $final_kept, Deleted: $final_deleted, Preserved: $final_preserved"
        else
            echo "No changes needed"
        fi
    fi
    
    return 0
}

list_packages() {
    local owner="$1"
    
    echo -e "${BLUE}Fetching packages for: $owner${NC}"
    if [ -n "$PROJECT_FILTER" ]; then
        echo -e "${BLUE}Filter: packages starting with '$PROJECT_FILTER'${NC}"
    fi
    
    local packages
    packages=$(get_packages "$owner")
    
    if [ -z "$packages" ] || [ "$packages" = "[]" ]; then
        echo -e "${RED}No packages found${NC}"
        return 1
    fi
    
    if echo "$packages" | jq -e '.message' >/dev/null 2>&1; then
        echo -e "${RED}Error: $(echo "$packages" | jq -r '.message')${NC}"
        return 1
    fi
    
    # Filter packages if needed
    if [ -n "$PROJECT_FILTER" ]; then
        local filtered
        filtered=$(echo "$packages" | jq --arg filter "$PROJECT_FILTER" '[.[] | select(.name | startswith($filter))]')
        
        if [ "$(echo "$filtered" | jq '. | length')" -eq 0 ]; then
            echo -e "${RED}No packages found matching '$PROJECT_FILTER'${NC}"
            echo -e "${YELLOW}Available packages:${NC}"
            echo "$packages" | jq -r '.[].name' | sed 's/^/  /'
            return 1
        fi
        packages="$filtered"
    fi
    
    echo -e "${GREEN}Container packages:${NC}"
    echo ""
    
    echo "$packages" | jq -r '.[] | "\(.name)\t\(.updated_at)\t\(.visibility)"' | while IFS=$'\t' read -r name updated visibility; do
        local date
        date=$(date -d "$updated" +"%Y-%m-%d %H:%M" 2>/dev/null || echo "$updated")
        
        local vis_color="${GREEN}"
        [ "$visibility" = "private" ] && vis_color="${YELLOW}"
        
        # Get stats
        local versions
        versions=$(get_versions "$owner" "$name")
        local total=0 tagged=0 untagged=0
        
        if [ -n "$versions" ] && [ "$versions" != "[]" ]; then
            total=$(echo "$versions" | jq '. | length')
            tagged=$(echo "$versions" | jq '[.[] | select(.metadata.container.tags != null and (.metadata.container.tags | length) > 0)] | length')
            untagged=$((total - tagged))
        fi
        
        local info=""
        if [ "$total" -gt 0 ]; then
            info=" - ${BLUE}$total versions${NC}"
            if [ "$tagged" -gt 0 ] && [ "$untagged" -gt 0 ]; then
                info="$info (${GREEN}$tagged tagged${NC}, ${YELLOW}$untagged untagged${NC})"
            elif [ "$tagged" -gt 0 ]; then
                info="$info (${GREEN}all tagged${NC})"
            else
                info="$info (${YELLOW}all untagged${NC})"
            fi
        fi
        
        echo -e "📦 ${BLUE}$name${NC} (${vis_color}$visibility${NC}) - $date$info"
        
        # Verbose mode: show version details
        if [ "$VERBOSE" = true ] && [ "$total" -gt 0 ]; then
            echo -e "  ${BLUE}Versions:${NC}"
            echo "$versions" | jq 'sort_by(.updated_at) | reverse' | jq -c '.[]' | while read -r version; do
                local id updated_at
                id=$(echo "$version" | jq -r '.id')
                updated_at=$(echo "$version" | jq -r '.updated_at')
                
                local vdate
                vdate=$(date -d "$updated_at" +"%Y-%m-%d %H:%M" 2>/dev/null || echo "$updated_at")
                
                echo -e "  - ${CYAN}$id${NC} ($vdate)"
                
                local tag_count
                tag_count=$(echo "$version" | jq '.metadata.container.tags | length')
                
                if [ "$tag_count" -gt 0 ]; then
                    echo "$version" | jq -r '.metadata.container.tags[]' | while read -r tag; do
                        if is_special_tag "$tag"; then
                            echo -e "    - ${GOLD}⭐ $tag${NC}"
                        else
                            echo "    - $tag"
                        fi
                    done
                else
                    echo -e "    - ${DARK_GRAY}(no tags)${NC}"
                fi
            done
        fi
    done
    
    local count
    count=$(echo "$packages" | jq '. | length')
    echo ""
    echo -e "${BLUE}Total: $count packages${NC}"
}

list_versions() {
    local owner="$1"
    local package="$2"
    
    echo -e "${BLUE}Versions for: $owner/$package${NC}"
    
    local versions
    versions=$(get_versions "$owner" "$package")
    
    if [ -z "$versions" ] || [ "$versions" = "[]" ]; then
        echo -e "${RED}No versions found${NC}"
        return 1
    fi
    
    echo ""
    echo "$versions" | jq 'sort_by(.updated_at) | reverse' | jq -r '.[] | "\(.id)\t\(.updated_at)\t\(.metadata.container.tags // [] | join(","))"' | while IFS=$'\t' read -r id updated tags; do
        local date
        date=$(date -d "$updated" +"%Y-%m-%d %H:%M" 2>/dev/null || echo "$updated")
        
        local tag_display="${YELLOW}untagged${NC}"
        if [ -n "$tags" ] && [ "$tags" != "null" ] && [ "$tags" != "" ]; then
            if has_special_tag "$tags"; then
                tag_display="${GOLD}⭐ $tags${NC}"
            else
                tag_display="$tags"
            fi
        fi
        
        echo -e "🐳 ${CYAN}$id${NC} - $tag_display - $date"
    done
    
    local count
    count=$(echo "$versions" | jq '. | length')
    echo ""
    echo -e "${BLUE}Total: $count versions${NC}"
}

cleanup_all_packages() {
    local owner="$1"
    
    local packages
    packages=$(get_packages "$owner")
    
    if [ -z "$packages" ] || [ "$packages" = "[]" ]; then
        echo -e "${RED}No packages found${NC}"
        return 1
    fi
    
    # Filter packages if needed
    if [ -n "$PROJECT_FILTER" ]; then
        packages=$(echo "$packages" | jq --arg filter "$PROJECT_FILTER" '[.[] | select(.name | startswith($filter))]')
        
        if [ "$(echo "$packages" | jq '. | length')" -eq 0 ]; then
            echo -e "${RED}No packages found matching '$PROJECT_FILTER'${NC}"
            return 1
        fi
    fi
    
    local total
    total=$(echo "$packages" | jq '. | length')
    echo -e "${GREEN}Processing $total packages${NC}"
    if [ -n "$PROJECT_FILTER" ]; then
        echo "Filter: '$PROJECT_FILTER'"
    fi
    echo ""
    
    local failed=0
    
    echo "$packages" | jq -r '.[].name' | while read -r package; do
        echo -e "${BLUE}━━━ $package ━━━${NC}"
        if ! cleanup_package "$owner" "$package"; then
            failed=$((failed + 1))
        fi
        echo ""
    done
    
    echo -e "${GREEN}━━━ Summary ━━━${NC}"
    echo "Packages processed: $total"
    if [ "$failed" -gt 0 ]; then
        echo -e "${RED}Failed: $failed${NC}"
    else
        echo -e "${GREEN}All packages processed successfully${NC}"
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--days) DAYS_OLD="$2"; shift 2 ;;
        -k|--keep) KEEP_LATEST="$2"; shift 2 ;;
        -u|--include-untagged) INCLUDE_UNTAGGED=true; shift ;;
        -p|--project) PROJECT_FILTER="$2"; shift 2 ;;
        -s|--skip-special) PRESERVE_SPECIAL=false; shift ;;
        -t|--token) GITHUB_TOKEN="$2"; shift 2 ;;
        -n|--dry-run) DRY_RUN=true; shift ;;
        -l|--list-packages) LIST_PACKAGES=true; shift ;;
        -i|--list-versions) LIST_VERSIONS=true; shift ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -h|--help) usage ;;
        -*) echo "Unknown option: $1"; usage ;;
        *) 
            if [ -z "$REPO_OWNER" ]; then
                REPO_OWNER="$1"
            elif [ -z "$PACKAGE_NAME" ]; then
                PACKAGE_NAME="$1"
            else
                echo "Too many arguments"; usage
            fi
            shift ;;
    esac
done

# Validate
if [ -z "$REPO_OWNER" ]; then
    echo -e "${RED}Error: Repository owner required${NC}"
    usage
fi

for tool in curl jq; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo -e "${RED}Error: $tool not installed${NC}"
        exit 1
    fi
done

# Get token
if [ -z "$GITHUB_TOKEN" ]; then
    if command -v gh >/dev/null 2>&1 && gh auth token >/dev/null 2>&1; then
        GITHUB_TOKEN=$(gh auth token)
        echo -e "${GREEN}✓ Using GitHub CLI token${NC}"
    else
        show_login_instructions
        exit 1
    fi
fi

# Validate numbers
for arg in DAYS_OLD KEEP_LATEST; do
    if ! [[ "${!arg}" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: $arg must be a number${NC}"
        exit 1
    fi
done

# Test auth
if ! test_auth "$GITHUB_TOKEN"; then
    show_login_instructions
    exit 1
fi

# Execute
if [ "$LIST_PACKAGES" = true ] || [ -z "$PACKAGE_NAME" ]; then
    if [ "$LIST_PACKAGES" = true ]; then
        list_packages "$REPO_OWNER"
    else
        # Cleanup mode
        echo ""
        echo -e "${GREEN}Starting cleanup...${NC}"
        echo "Owner: $REPO_OWNER"
        
        if [ "$KEEP_LATEST" -gt 0 ]; then
            if [ "$INCLUDE_UNTAGGED" = true ]; then
                echo "Mode: Keep $KEEP_LATEST latest versions (including untagged) + special tags"
            else
                echo "Mode: Keep $KEEP_LATEST latest tagged versions + special tags (delete all untagged)"
            fi
        else
            if [ "$INCLUDE_UNTAGGED" = true ]; then
                echo "Mode: Delete all versions older than $DAYS_OLD days"
            else
                echo "Mode: Delete tagged versions older than $DAYS_OLD days + special tags (delete all untagged)"
            fi
        fi
        
        echo "Special tags: $([ "$PRESERVE_SPECIAL" = true ] && echo "preserved" || echo "not preserved")"
        [ "$DRY_RUN" = true ] && echo -e "${YELLOW}DRY RUN MODE${NC}"
        echo ""
        
        cleanup_all_packages "$REPO_OWNER"
    fi
elif [ "$LIST_VERSIONS" = true ]; then
    list_versions "$REPO_OWNER" "$PACKAGE_NAME"
else
    # Single package cleanup
    echo ""
    echo -e "${GREEN}Starting cleanup...${NC}"
    echo "Package: $REPO_OWNER/$PACKAGE_NAME"
    
    if [ "$KEEP_LATEST" -gt 0 ]; then
        if [ "$INCLUDE_UNTAGGED" = true ]; then
            echo "Mode: Keep $KEEP_LATEST latest versions (including untagged) + special tags"
        else
            echo "Mode: Keep $KEEP_LATEST latest tagged versions + special tags (delete all untagged)"
        fi
    else
        if [ "$INCLUDE_UNTAGGED" = true ]; then
            echo "Mode: Delete all versions older than $DAYS_OLD days"
        else
            echo "Mode: Delete tagged versions older than $DAYS_OLD days + special tags (delete all untagged)"
        fi
    fi
    
    echo "Special tags: $([ "$PRESERVE_SPECIAL" = true ] && echo "preserved" || echo "not preserved")"
    [ "$DRY_RUN" = true ] && echo -e "${YELLOW}DRY RUN MODE${NC}"
    echo ""
    
    cleanup_package "$REPO_OWNER" "$PACKAGE_NAME"
fi

echo ""
echo -e "${GREEN}Done!${NC}"