#!/usr/bin/env bash
set -euo pipefail

# verify-ots.sh - Verify OpenTimestamps files against Bitcoin blockchain via public API
# Usage: ./verify-ots.sh [file.ots]
#   If no file provided, verifies all .ots files in current directory

# Colors
BLUE_BOLD='\033[1;34m'
CYAN='\033[0;36m'
GREEN_BOLD='\033[1;32m'
RED_BOLD='\033[1;31m'
RESET='\033[0m'

# Verify a single OTS file
verify_single_file() {
    local OTS_FILE="$1"

    if [ ! -f "$OTS_FILE" ]; then
        echo -e "${RED_BOLD}Error: File not found: $OTS_FILE${RESET}"
        return 1
    fi

    # Get the attestation info from OTS
    echo -e "${BLUE_BOLD}Checking OTS file: $OTS_FILE${RESET}"
    OTS_INFO=$(ots --no-bitcoin verify "$OTS_FILE" 2>&1 || true)

    # Extract all block numbers and merkleroot pairs from OTS output
    # An OTS file can have multiple attestations
    mapfile -t BLOCKS < <(echo "$OTS_INFO" | grep -oP 'Bitcoin block \K[0-9]+' || echo "")
    mapfile -t MERKLEROOTS < <(echo "$OTS_INFO" | grep -oP 'merkleroot \K[a-f0-9]+' || echo "")

    if [ ${#BLOCKS[@]} -eq 0 ] || [ ${#MERKLEROOTS[@]} -eq 0 ]; then
        echo -e "${RED_BOLD}Error: Could not extract attestation info from OTS file${RESET}"
        echo "Output was:"
        echo "$OTS_INFO"
        return 1
    fi

    # Check if there are multiple attestations
    if [ ${#BLOCKS[@]} -gt 1 ]; then
        echo "Found ${#BLOCKS[@]} attestations in this OTS file"
        echo ""
    fi

    # Verify each attestation
    local ALL_VERIFIED=true
    for i in "${!BLOCKS[@]}"; do
        local BLOCK="${BLOCKS[$i]}"
        local MERKLEROOT="${MERKLEROOTS[$i]}"

        if [ ${#BLOCKS[@]} -gt 1 ]; then
            echo "Attestation $((i + 1))/${#BLOCKS[@]}:"
        fi

        echo "OTS claims:"
        echo "  Block: $BLOCK"
        echo "  Merkleroot: $MERKLEROOT"
        echo ""

        # Query blockstream.info API for the actual block
        echo -e "${CYAN}Querying blockstream.info for block $BLOCK...${RESET}"
        BLOCK_HASH=$(curl -sf "https://blockstream.info/api/block-height/$BLOCK" || echo "")

        if [ -z "$BLOCK_HASH" ]; then
            echo -e "${RED_BOLD}Error: Could not fetch block hash from blockstream.info${RESET}"
            ALL_VERIFIED=false
            echo ""
            continue
        fi

        echo "Block hash: $BLOCK_HASH"

        # Get full block info
        BLOCK_INFO=$(curl -sf "https://blockstream.info/api/block/$BLOCK_HASH" || echo "")

        if [ -z "$BLOCK_INFO" ]; then
            echo -e "${RED_BOLD}Error: Could not fetch block info from blockstream.info${RESET}"
            ALL_VERIFIED=false
            echo ""
            continue
        fi

        # Extract actual merkleroot
        ACTUAL_MERKLEROOT=$(echo "$BLOCK_INFO" | jq -r '.merkle_root')
        BLOCK_TIME=$(echo "$BLOCK_INFO" | jq -r '.timestamp')
        BLOCK_TIME_HUMAN=$(date -d "@$BLOCK_TIME" -u '+%Y-%m-%d %H:%M:%S UTC' 2>/dev/null || date -r "$BLOCK_TIME" -u '+%Y-%m-%d %H:%M:%S UTC' 2>/dev/null || echo "unknown")

        echo "Blockchain says:"
        echo "  Merkleroot: $ACTUAL_MERKLEROOT"
        echo "  Block time: $BLOCK_TIME_HUMAN"
        echo ""

        # Compare
        if [ "$MERKLEROOT" = "$ACTUAL_MERKLEROOT" ]; then
            echo -e "${GREEN_BOLD}✓ VERIFIED: Merkleroot matches!${RESET}"
            echo "  Block mined at: $BLOCK_TIME_HUMAN"
        else
            echo -e "${RED_BOLD}✗ VERIFICATION FAILED: Merkleroot mismatch!${RESET}"
            echo "  Expected: $MERKLEROOT"
            echo "  Got:      $ACTUAL_MERKLEROOT"
            ALL_VERIFIED=false
        fi
        echo ""
    done

    if [ "$ALL_VERIFIED" = true ]; then
        if [ ${#BLOCKS[@]} -gt 1 ]; then
            echo -e "${GREEN_BOLD}All ${#BLOCKS[@]} attestations for ${OTS_FILE} verified successfully!${RESET}"
        fi
        return 0
    else
        echo -e "${RED_BOLD}One or more attestations for ${OTS_FILE} failed verification${RESET}"
        return 1
    fi
}

# Main logic
if [ $# -eq 0 ]; then
    # Find all .ots files recursively
    echo "No file specified, searching for all .ots files..."
    OTS_FILES=$(find . -type f -name "*.ots" | sort)

    if [ -z "$OTS_FILES" ]; then
        echo -e "${RED_BOLD}No .ots files found${RESET}"
        exit 1
    fi

    TOTAL=0
    PASSED=0
    FAILED=0

    while IFS= read -r file; do
        TOTAL=$((TOTAL + 1))
        if verify_single_file "$file"; then
            PASSED=$((PASSED + 1))
        else
            FAILED=$((FAILED + 1))
        fi
        echo ""
    done <<<"$OTS_FILES"

    echo "========================================="
    echo "Summary: $TOTAL files checked"
    echo -e "${GREEN_BOLD}Passed: $PASSED${RESET}"
    if [ $FAILED -gt 0 ]; then
        echo -e "${RED_BOLD}Failed: $FAILED${RESET}"
        exit 1
    fi
else
    # Single file verification
    verify_single_file "$1"
fi
