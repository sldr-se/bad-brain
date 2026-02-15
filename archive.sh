#!/usr/bin/env bash
set -euo pipefail

TARGETS_FILE="targets.json"
METRICS_DIR="analysis/metrics"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Ensure metrics directory exists
mkdir -p "$METRICS_DIR"

usage() {
    cat <<EOF
Usage: $0 <command>

Commands:
  web       Archive all URLs via Web Archive
  web-test  Archive only web-type URLs (for testing)
  metrics   Scrape all APIs for statistics
  github    Scrape GitHub repository metrics (stars, issues, forks)
  npm       Scrape npm package download statistics
  pypi      Scrape PyPI package download statistics
  crates    Scrape crates.io download statistics
  all       Run all archival and scraping tasks

EOF
    exit 1
}

archive_web() {
    local filter="${1:-.archival[].url}"
    echo "Archiving web targets..."

    jq -r "$filter" "$TARGETS_FILE" | while read -r url; do
        echo -e "\033[1;34mArchiving: $url\033[0m"

        # Web Archive
        curl -s -o /dev/null "https://web.archive.org/save/$url" && echo "  ✓ web.archive.org" || echo "  ✗ web.archive.org failed"

        sleep 1 # Be polite to the archive services
    done
}

scrape_github() {
    echo "Scraping GitHub metrics..."

    CSV="$METRICS_DIR/github.csv"

    # Create CSV header if it doesn't exist
    if [[ ! -f "$CSV" ]]; then
        echo "date,repo,stars,forks,open_issues,watchers,contributors" >"$CSV"
    fi

    jq -r '.archival[] | select(.type=="github" and (.url | contains("/memvid/"))) | .url' "$TARGETS_FILE" | while read -r url; do
        # Extract owner/repo from URL
        repo=$(echo "$url" | sed -E 's|https://github.com/([^/]+/[^/]+).*|\1|')

        if [[ "$repo" == "memvid" ]]; then
            continue # Skip the org page
        fi

        echo -e "\033[1;34mFetching: $repo\033[0m"

        response=$(curl -s "https://api.github.com/repos/$repo")

        stars=$(echo "$response" | jq -r '.stargazers_count // "N/A"')
        forks=$(echo "$response" | jq -r '.forks_count // "N/A"')
        issues=$(echo "$response" | jq -r '.open_issues_count // "N/A"')
        watchers=$(echo "$response" | jq -r '.watchers_count // "N/A"')

        # Fetch contributor count (GitHub defaults to per_page=30, we'll fetch up to 100)
        contributors=$(curl -s "https://api.github.com/repos/$repo/contributors?per_page=100" | jq '. | length')

        echo "$TIMESTAMP,$repo,$stars,$forks,$issues,$watchers,$contributors" >>"$CSV"
        echo "  Stars: $stars | Forks: $forks | Issues: $issues | Contributors: $contributors"

        sleep 1 # Avoid rate limiting
    done

    echo "GitHub metrics saved to $CSV"
}

scrape_npm() {
    echo "Scraping npm download statistics..."

    CSV="$METRICS_DIR/npm.csv"

    # Create CSV header if it doesn't exist
    if [[ ! -f "$CSV" ]]; then
        echo "date,package,downloads_last_week" >"$CSV"
    fi

    jq -r '.archival[] | select(.type=="npm" and has("package")) | .package' "$TARGETS_FILE" | while read -r package; do
        echo -e "\033[1;34mFetching: $package\033[0m"

        response=$(curl -s "https://api.npmjs.org/downloads/point/last-week/$package")
        downloads=$(echo "$response" | jq -r '.downloads // "N/A"')

        echo "$TIMESTAMP,$package,$downloads" >>"$CSV"
        echo "  Downloads (last week): $downloads"

        sleep 0.5
    done

    echo "npm metrics saved to $CSV"
}

scrape_pypi() {
    echo "Scraping PyPI download statistics..."

    CSV="$METRICS_DIR/pypi.csv"

    # Create CSV header if it doesn't exist
    if [[ ! -f "$CSV" ]]; then
        echo "date,package,downloads_last_week" >"$CSV"
    fi

    jq -r '.archival[] | select(.type=="pypi" and has("package")) | .package' "$TARGETS_FILE" | while read -r package; do
        echo -e "\033[1;34mFetching: $package\033[0m"

        # PyPI doesn't have an official download stats API, so we use pypistats.org
        response=$(curl -s "https://pypistats.org/api/packages/$package/recent?period=week")
        downloads=$(echo "$response" | jq -r '.data.last_week // "N/A"')

        echo "$TIMESTAMP,$package,$downloads" >>"$CSV"
        echo "  Downloads (last week): $downloads"

        sleep 0.5
    done

    echo "PyPI metrics saved to $CSV"
}

scrape_crates() {
    echo "Scraping crates.io download statistics..."

    CSV="$METRICS_DIR/crates.csv"

    # Create CSV header if it doesn't exist
    if [[ ! -f "$CSV" ]]; then
        echo "date,crate,total_downloads,recent_downloads" >"$CSV"
    fi

    jq -r '.archival[] | select(.type=="crates" and has("package")) | .package' "$TARGETS_FILE" | while read -r crate; do
        echo -e "\033[1;34mFetching: $crate\033[0m"

        response=$(curl -s "https://crates.io/api/v1/crates/$crate")
        total=$(echo "$response" | jq -r '.crate.downloads // "N/A"')
        recent=$(echo "$response" | jq -r '.crate.recent_downloads // "N/A"')

        echo "$TIMESTAMP,$crate,$total,$recent" >>"$CSV"
        echo "  Total downloads: $total | Recent: $recent"

        sleep 0.5
    done

    echo "crates.io metrics saved to $CSV"
}

# Main script logic
if [[ $# -eq 0 ]]; then
    usage
fi

case "$1" in
    web)
        archive_web '.archival[].url'
        ;;
    web-test)
        archive_web '.archival[] | select(.type=="web") | .url'
        ;;
    metrics)
        scrape_github
        scrape_npm
        scrape_pypi
        scrape_crates
        ;;
    github)
        scrape_github
        ;;
    npm)
        scrape_npm
        ;;
    pypi)
        scrape_pypi
        ;;
    crates)
        scrape_crates
        ;;
    all)
        archive_web
        scrape_github
        scrape_npm
        scrape_pypi
        scrape_crates
        ;;
    *)
        echo "Unknown command: $1"
        usage
        ;;
esac

echo -e "\n\033[1;32mDone!\033[0m"
