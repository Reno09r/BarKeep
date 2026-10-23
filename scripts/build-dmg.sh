#!/usr/bin/env bash
set -euo pipefail

# Создаёт готовый .dmg дистрибутив для BarKeep.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="$ROOT_DIR/build/Build/Products/Debug/BarKeep.app"
DIST_DIR="$ROOT_DIR/dist"
DMG_PATH="$DIST_DIR/BarKeep.dmg"
STAGE_DIR="$(mktemp -d /tmp/barkeep-dmg-XXXXXX)"

trap 'rm -rf "$STAGE_DIR"' EXIT

echo "=== Сборка BarKeep DMG ==="

if [[ ! -d "$APP_PATH" ]]; then
    echo "BarKeep.app не найден, запускаем сборку..."
    make -C "$ROOT_DIR" build
fi

mkdir -p "$DIST_DIR"
rm -f "$DMG_PATH"

echo "Копирование файлов..."
cp -R "$APP_PATH" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

echo "Создание DMG-образа..."
hdiutil create \
    -volname "BarKeep" \
    -srcfolder "$STAGE_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "✅ DMG успешно создан: $DMG_PATH"
