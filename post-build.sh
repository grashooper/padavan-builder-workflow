#!/bin/bash

set -e
echo "=== Post-build: Adding obfs4proxy ==="

FW_FILE=$(find padavan-ng/trunk/images -name "*.trx" -o -name "*.bin" | head -1)
if [ -z "$FW_FILE" ]; then
  echo "ERROR: Firmware file not found"
  exit 1
fi
echo "Found firmware: $FW_FILE"

if ! command -v unsquashfs &> /dev/null; then
  echo "WARNING: squashfs-tools not available"
  exit 0
fi

TEMP_DIR="/tmp/obfs4-firmware-mod"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

unsquashfs -d "$TEMP_DIR/rootfs" "$FW_FILE" 2>/dev/null || {
  echo "WARNING: Could not extract firmware"
  exit 0
}

echo "Downloading obfs4proxy for MIPS..."
curl -L -o "$TEMP_DIR/obfs4proxy" "https://github.com/nickcollins/obfs4/releases/latest/download/obfs4proxy-linux-mipsle" 2>/dev/null || true

if [ ! -f "$TEMP_DIR/obfs4proxy" ]; then
  echo "Building obfs4proxy from source..."
  cd "$TEMP_DIR"
  git clone --depth 1 https://github.com/nickcollins/obfs4.git obfs4-src 2>/dev/null || true
  cd obfs4-src
  if command -v go &> /dev/null; then
    export GOOS=linux
    export GOARCH=mips
    export GOMIPS=softfloat
    go build -o "$TEMP_DIR/obfs4proxy" ./cmd/obfs4proxy 2>/dev/null || true
    chmod +x "$TEMP_DIR/obfs4proxy"
  fi
fi

if [ -f "$TEMP_DIR/obfs4proxy" ]; then
  cp "$TEMP_DIR/obfs4proxy" "$TEMP_DIR/rootfs/usr/sbin/obfs4proxy"
  chmod +x "$TEMP_DIR/rootfs/usr/sbin/obfs4proxy"
  echo "obfs4proxy installed to /usr/sbin/obfs4proxy"
fi

cd "$TEMP_DIR"
mksquashfs rootfs "${FW_FILE}.new" -noappend -comp xz 2>/dev/null || true
mv "${FW_FILE}.new" "$FW_FILE"
rm -rf "$TEMP_DIR"
echo "=== Post-build complete ==="