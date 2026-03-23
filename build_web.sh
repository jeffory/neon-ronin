#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build/web"
PORT=8060

mkdir -p "$BUILD_DIR"

echo "Exporting Neon Ronin for Web..."
godot --headless --export-release "Web" "$BUILD_DIR/index.html"
echo "Build complete: $BUILD_DIR/"

if [[ "${1:-}" == "--serve" ]]; then
    echo ""
    echo "Starting local server at http://localhost:$PORT"
    echo "  (Cross-origin isolation headers enabled for SharedArrayBuffer)"
    echo "  Press Ctrl+C to stop."
    echo ""
    python3 -c "
import http.server, functools, sys

class COIHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()

handler = functools.partial(COIHandler, directory='$BUILD_DIR')
server = http.server.HTTPServer(('0.0.0.0', $PORT), handler)
try:
    server.serve_forever()
except KeyboardInterrupt:
    print('\nServer stopped.')
"
fi
