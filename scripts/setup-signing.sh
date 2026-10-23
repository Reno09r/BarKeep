#!/bin/bash
# Создаёт локальный самоподписанный сертификат для стабильной подписи BarKeep.
# Нужен, чтобы macOS не сбрасывала разрешения Accessibility после каждой пересборки.
set -euo pipefail

CERT_NAME="BarKeep Dev"
KEYCHAIN="$HOME/Library/Keychains/barkeep-dev.keychain-db"
KEYCHAIN_PASS="barkeep"
WORK_DIR="${TMPDIR:-/tmp}/barkeep-signing"

if security find-certificate -c "$CERT_NAME" "$KEYCHAIN" >/dev/null 2>&1; then
    echo "Сертификат «${CERT_NAME}» уже есть в $KEYCHAIN"
    security unlock-keychain -p "$KEYCHAIN_PASS" "$KEYCHAIN" >/dev/null
    exit 0
fi

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
    -keyout barkeep.key -out barkeep.crt \
    -subj "/CN=$CERT_NAME" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning" \
    -addext "basicConstraints=critical,CA:false" 2>/dev/null

openssl pkcs12 -export -out barkeep.p12 \
    -inkey barkeep.key -in barkeep.crt \
    -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1 \
    -passout "pass:$KEYCHAIN_PASS" 2>/dev/null

security create-keychain -p "$KEYCHAIN_PASS" "$KEYCHAIN" 2>/dev/null || true
security set-keychain-settings -lut 21600 "$KEYCHAIN"
security unlock-keychain -p "$KEYCHAIN_PASS" "$KEYCHAIN"
security import barkeep.p12 -k "$KEYCHAIN" -P "$KEYCHAIN_PASS" \
    -T /usr/bin/codesign -T /usr/bin/security >/dev/null
security set-key-partition-list -S apple-tool:,apple:,codesign: \
    -s -k "$KEYCHAIN_PASS" "$KEYCHAIN" >/dev/null

# Добавляем keychain в список поиска, сохраняя существующие.
EXISTING=$(security list-keychains -d user | tr -d '"')
security list-keychains -d user -s "$KEYCHAIN" $EXISTING

rm -f barkeep.key barkeep.p12
echo "Готово: «${CERT_NAME}» в ${KEYCHAIN}"
security find-certificate -c "$CERT_NAME" "$KEYCHAIN" | head -3
