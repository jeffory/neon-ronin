#!/usr/bin/env bash
set -euo pipefail

# Deploy Neon Ronin web build to Cloudflare Pages + R2
#
# Usage:
#   ./deploy_web.sh <r2-bucket-url>
#
# Example:
#   ./deploy_web.sh https://assets.neonronin.com
#
# This script:
#   1. Builds the game for web (if not already built)
#   2. Splits output into pages/ (small files) and r2/ (large files)
#   3. Injects the asset base URL into the Pages HTML
#   4. Prints instructions for uploading each set of files

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build/web"
PAGES_DIR="$PROJECT_DIR/build/deploy-pages"
R2_DIR="$PROJECT_DIR/build/deploy-r2"
SIZE_LIMIT=$((25 * 1024 * 1024))  # 25 MB

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <r2-base-url>"
    echo ""
    echo "  r2-base-url: The public URL where R2 assets will be served from."
    echo "               e.g. https://assets.example.com/neon-ronin"
    echo ""
    echo "This splits the build into two directories:"
    echo "  build/deploy-pages/  → upload to Cloudflare Pages"
    echo "  build/deploy-r2/     → upload to Cloudflare R2 (or any CDN)"
    exit 1
fi

R2_BASE_URL="${1%/}"

# Build if needed
if [[ ! -f "$BUILD_DIR/index.html" ]]; then
    echo "Building game..."
    "$PROJECT_DIR/build_web.sh"
fi

# Clean deploy dirs
rm -rf "$PAGES_DIR" "$R2_DIR"
mkdir -p "$PAGES_DIR" "$R2_DIR"

# Split files by size
echo ""
echo "Splitting build output..."
echo ""

for file in "$BUILD_DIR"/*; do
    name="$(basename "$file")"
    size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file")

    if [[ $size -gt $SIZE_LIMIT ]]; then
        cp "$file" "$R2_DIR/"
        printf "  %-40s %6sM → R2\n" "$name" "$((size / 1024 / 1024))"
    else
        cp "$file" "$PAGES_DIR/"
        printf "  %-40s %6sK → Pages\n" "$name" "$((size / 1024))"
    fi
done

# Inject asset base URL into the Pages HTML
sed -i "s|const assetBaseURL = window.ASSET_BASE_URL|const assetBaseURL = window.ASSET_BASE_URL \|\| '${R2_BASE_URL}'|" "$PAGES_DIR/index.html"

# Copy _headers for Cloudflare Pages (cross-origin isolation)
cp "$PROJECT_DIR/web/_headers" "$PAGES_DIR/_headers"

echo ""
echo "Done! Deploy directories ready:"
echo ""
echo "  Cloudflare Pages:  build/deploy-pages/  ($(du -sh "$PAGES_DIR" | cut -f1))"
echo "  Cloudflare R2:     build/deploy-r2/     ($(du -sh "$R2_DIR" | cut -f1))"
echo ""
echo "Upload instructions:"
echo ""
echo "  1. R2 bucket — upload build/deploy-r2/ contents"
echo "     Make sure the bucket is publicly accessible at: $R2_BASE_URL"
echo "     Set CORS headers to allow your Pages domain:"
echo ""
echo "       Access-Control-Allow-Origin: <your-pages-domain>"
echo "       Access-Control-Allow-Methods: GET, HEAD"
echo "       Cross-Origin-Resource-Policy: cross-origin"
echo ""
echo "  2. Pages — upload build/deploy-pages/ via wrangler or git push"
echo "     The HTML already points to your R2 URL for large assets."
echo ""
echo "  3. Pages headers — create build/deploy-pages/_headers with:"
echo ""
echo "       /*"
echo "         Cross-Origin-Opener-Policy: same-origin"
echo "         Cross-Origin-Embedder-Policy: require-corp"
echo ""
