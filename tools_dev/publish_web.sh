#!/bin/bash
# Exports the Web preset and publishes it to the gh-pages branch of `origin` (served by GitHub Pages).
# The branch is replaced by a single commit each time, so old 40 MB builds never pile up in history.
# Usage: ./tools_dev/publish_web.sh            export + publish
#        ./tools_dev/publish_web.sh --no-push  export only (build/web/)
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-./tools_dev/godot.sh}"

rm -rf build/web
mkdir -p build/web
timeout 600 "$GODOT" --headless --path . --export-release "Web" build/web/index.html
test -s build/web/index.wasm && test -s build/web/index.pck
touch build/web/.nojekyll
echo "exported build/web ($(du -sh build/web | cut -f1))"
[ "${1:-}" = "--no-push" ] && exit 0

url=$(git remote get-url origin)
rev=$(git rev-parse --short HEAD)
name=$(git config user.name)
email=$(git config user.email)
cd build/web
rm -rf .git
git init -q -b gh-pages
git add -A
git -c user.name="$name" -c user.email="$email" commit -q -m "Web build of $rev"
git push -q -f "$url" gh-pages
rm -rf .git
echo "published $rev to gh-pages"
