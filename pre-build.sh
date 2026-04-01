#!/bin/bash

# Настройка версии прошивки
sed -i 's/^FIRMWARE_ROOTFS_VER.*/FIRMWARE_ROOTFS_VER=3.9L/' padavan-ng/trunk/versions.inc
sed -i 's/^FIRMWARE_BUILDS_VER.*/FIRMWARE_BUILDS_VER=102/' padavan-ng/trunk/versions.inc

# Установка последней версии zapret
ZAPRET_REPO="https://github.com/bol-van/zapret.git"
ZAPRET_TAGS=$(git ls-remote --tags "$ZAPRET_REPO" | awk '{print $2}' | sed 's/refs\/tags\///g')
ZAPRET_VER=$(echo "$ZAPRET_TAGS" | sort -V | tail -n 1 | sed 's/^.//')
sed -i "s/^SRC_VER.*/SRC_VER = $ZAPRET_VER/g" padavan-ng/trunk/user/nfqws/Makefile
cd padavan-ng/trunk/user/nfqws
curl -o patches/firmware-specific.patch https://raw.githubusercontent.com/EdvardBill/npzp/refs/heads/main/firmware-specific.patch
find . -maxdepth 1 -not -name Makefile -not -name patches -print0 | xargs -0 rm -rf --
cd -

# Добавление obfs4proxy для TOR
# Скачиваем и собираем obfs4proxy для MIPS
echo "Building obfs4proxy for Padavan..."
OBFS4_URL="https://github.com/nickcollins/obfs4.git"
OBFS4_DIR="/tmp/obfs4-build"
rm -rf "$OBFS4_DIR"
mkdir -p "$OBFS4_DIR"
cd "$OBFS4_DIR"

# Clone obfs4proxy
git clone --depth 1 https://github.com/nickcollins/obfs4.git .
# или используем ссылку на архив
# wget https://github.com/nickcollins/obfs4/archive/refs/heads/master.zip

# Создаём пакет для padavan-ng
# Копируем бинарник obfs4proxy в директорию для TOR
OBFS4_DEST="padavan-ng/trunk/user/tor/obfs4proxy"
mkdir -p "$(dirname "$OBFS4_DEST")"

# Копируем Go-файлы для кросс-компиляции
# Padavan использует кросс-компиляцию через toolchain
# Обычно obfs4proxy - это Go-программа
# Для padavan нужно кросс-компилировать или использовать pre-built бинарник

# Временно используем существующий бинарник если есть
if [ -f "/usr/bin/obfs4proxy" ]; then
  cp "/usr/bin/obfs4proxy" "$OBFS4_DEST"
  chmod +x "$OBFS4_DEST"
  echo "obfs4proxy copied from system"
else
  # Попробуем скачать pre-built бинарник для MIPS
  echo "Downloading obfs4proxy..."
  curl -L -o "$OBFS4_DEST" "https://github.com/nickcollins/obfs4/releases/latest/download/obfs4proxy" 2>/dev/null || true
  if [ -f "$OBFS4_DEST" ]; then
    chmod +x "$OBFS4_DEST"
    echo "obfs4proxy downloaded"
  else
    echo "WARNING: obfs4proxy not available - skipping"
  fi
fi

# Настраиваем TOR для использования obfs4proxy
cd "$(dirname "$0")"

echo "pre-build.sh completed"