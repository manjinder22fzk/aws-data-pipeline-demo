#!/usr/bin/env bash
set -euo pipefail

# Resolve paths
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAMBDA_DIR="$ROOT_DIR/app/lambda_transform"
BUILD_DIR="$LAMBDA_DIR/build"
DIST_DIR="$LAMBDA_DIR/dist"

echo "[build-lambda] Root dir:      $ROOT_DIR"
echo "[build-lambda] Lambda dir:    $LAMBDA_DIR"
echo "[build-lambda] Build dir:     $BUILD_DIR"
echo "[build-lambda] Dist dir:      $DIST_DIR"

# Clean previous builds
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR"

echo "[build-lambda] Copying source..."
cp -r "$LAMBDA_DIR/src/." "$BUILD_DIR/"

echo "[build-lambda] Installing requirements..."
pip install --no-cache-dir -r "$LAMBDA_DIR/requirements.txt" -t "$BUILD_DIR"

echo "[build-lambda] Creating zip..."
cd "$BUILD_DIR"
zip -r "$DIST_DIR/lambda.zip" .

echo "[build-lambda] Done. Output: $DIST_DIR/lambda.zip"
