#!/bin/bash
# Run this from inside your digit_recognizer project folder
# Usage: bash apply_fixes.sh /path/to/digit_recognizer

PROJECT="${1:-.}"

echo "Applying Akshar fixes to: $PROJECT"

FILES=(
  "lib/app_theme.dart"
  "lib/screens/home_screen.dart"
  "lib/screens/draw_screen.dart"
  "lib/screens/camera_screen.dart"
  "lib/screens/image_screen.dart"
  "lib/widgets/mode_selector.dart"
  "lib/widgets/type_toggle.dart"
  "lib/widgets/results_panel.dart"
  "lib/widgets/drawing_canvas.dart"
)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for f in "${FILES[@]}"; do
  src="$SCRIPT_DIR/$f"
  dst="$PROJECT/$f"
  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "  ✓ $f"
  else
    echo "  ✗ MISSING: $f"
  fi
done

echo ""
echo "Done. Now run:"
echo "  cd $PROJECT"
echo "  git add ."
echo "  git commit -m 'fix: English-only UI, matte flat colors, remove all Hindi text and gradients'"
echo "  git push"
