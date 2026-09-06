#!/bin/bash
set -e

APT_DIR=/var/www/html/apt
cd "$APT_DIR"

mkdir -p dists/stable/main/binary-amd64 dists/stable/main/binary-all pool/main /var/www/html/installers/linux

# Copiar pacotes .deb de varios pontos de entrega para pool/main
cp -u /var/www/html/installers/*.deb pool/main/ 2>/dev/null || true
cp -u /var/www/html/installers/linux/*.deb pool/main/ 2>/dev/null || true
cp -u /home/server/godot_linux/build_stage/*.deb pool/main/ 2>/dev/null || true
cp -u /tmp/*.deb pool/main/ 2>/dev/null || true

# Escanear pacotes
dpkg-scanpackages --multiversion pool/ > dists/stable/main/binary-amd64/Packages
cp dists/stable/main/binary-amd64/Packages dists/stable/main/binary-all/Packages
gzip -k -f dists/stable/main/binary-amd64/Packages
gzip -k -f dists/stable/main/binary-all/Packages

# Gerar arquivo Release
cd "$APT_DIR/dists/stable"

DATE_STR=$(date -Ru)
PKG_PATH="main/binary-amd64/Packages"
PKG_GZ_PATH="main/binary-amd64/Packages.gz"

PKG_SIZE=$(stat -c%s "$PKG_PATH")
PKG_SHA256=$(sha256sum "$PKG_PATH" | awk '{print $1}')
PKG_MD5=$(md5sum "$PKG_PATH" | awk '{print $1}')

GZ_SIZE=$(stat -c%s "$PKG_GZ_PATH")
GZ_SHA256=$(sha256sum "$PKG_GZ_PATH" | awk '{print $1}')
GZ_MD5=$(md5sum "$PKG_GZ_PATH" | awk '{print $1}')

cat << EOF > Release
Origin: Nexus Linux Repository
Label: Nexus
Suite: stable
Codename: stable
Architectures: amd64 all
Components: main
Description: Repositorio Oficial de Aplicativos Nexus para Linux
Date: $DATE_STR
MD5Sum:
 $PKG_MD5 $PKG_SIZE $PKG_PATH
 $GZ_MD5 $GZ_SIZE $PKG_GZ_PATH
SHA256:
 $PKG_SHA256 $PKG_SIZE $PKG_PATH
 $GZ_SHA256 $GZ_SIZE $PKG_GZ_PATH
EOF

chmod -R 775 "$APT_DIR"
chmod 644 "$APT_DIR/dists/stable/Release"
chmod 644 "$APT_DIR"/dists/stable/main/binary-*/*
echo "✔ Repositorio APT atualizado com sucesso!"
