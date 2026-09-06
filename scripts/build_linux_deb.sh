#!/bin/bash
set -e

echo "🐧 [NEXUS APP HUB] Iniciando Pipeline de Build e Empacotamento Debian (.deb)..."

PROJECT_DIR="/home/server/build/NexusAppHub"
BUILD_OUTPUT="$PROJECT_DIR/build/linux/x64/release/bundle"
STAGE_DIR="/tmp/nexus_app_hub_deb_stage"
DEB_NAME="nexus-app-hub_0.3.26_amd64.deb"

export PATH="/opt/flutter/bin:$PATH"

cd "$PROJECT_DIR"

echo "📦 Atualizando dependencias com Flutter..."
flutter pub get

echo "⚙ Compilando release nativa GTK3 para Linux x86_64..."
flutter build linux --release

if [ ! -d "$BUILD_OUTPUT" ]; then
    echo "❌ Erro: Diretorio de bundle nao encontrado em $BUILD_OUTPUT"
    exit 1
fi

echo "📂 Criando estrutura do pacote Debian..."
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR/DEBIAN"
mkdir -p "$STAGE_DIR/opt/nexus-app-hub"
mkdir -p "$STAGE_DIR/usr/bin"
mkdir -p "$STAGE_DIR/usr/share/applications"
mkdir -p "$STAGE_DIR/usr/share/pixmaps"

# Copiar bundle da aplicacao
cp -r "$BUILD_OUTPUT"/* "$STAGE_DIR/opt/nexus-app-hub/"

# Symlink global
ln -sf /opt/nexus-app-hub/nexus_app_hub "$STAGE_DIR/usr/bin/nexus-app-hub"
ln -sf /opt/nexus-app-hub/nexus_app_hub "$STAGE_DIR/usr/bin/nexus-hub"

# Icone
if [ -f "$PROJECT_DIR/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" ]; then
    cp "$PROJECT_DIR/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" "$STAGE_DIR/usr/share/pixmaps/nexus_app_hub.png"
fi

# Atalho .desktop
cat << 'DESK_EOF' > "$STAGE_DIR/usr/share/applications/nexus-app-hub.desktop"
[Desktop Entry]
Name=Nexus App Hub
Comment=Loja e Launcher Oficial do Ecossistema Antigravity
Exec=/usr/bin/nexus-app-hub
Icon=nexus_app_hub
Terminal=false
Type=Application
Categories=Utility;PackageManager;System;
StartupWMClass=nexus_app_hub
DESK_EOF

chmod 644 "$STAGE_DIR/usr/share/applications/nexus-app-hub.desktop"

# Arquivo de controle Debian
INSTALLED_SIZE=$(du -sk "$STAGE_DIR" | cut -f1)

cat << CTRL_EOF > "$STAGE_DIR/DEBIAN/control"
Package: nexus-app-hub
Version: 0.3.26
Architecture: amd64
Maintainer: Andre & Aria <antigravity@nexus.cluster>
Installed-Size: $INSTALLED_SIZE
Depends: libc6 (>= 2.34), libgtk-3-0, liblzma5, libgl1
Section: utils
Priority: optional
Description: Loja e Launcher Oficial do Ecossistema Antigravity
 Central unificada de aplicativos, jogos e ferramentas do cluster Antigravity.
 Suporta instalacao, atualizacao e execucao nativa de pacotes Debian, Flatpak e AppImage.
CTRL_EOF

# Empacotar .deb
echo "🔨 Gerando pacote .deb..."
dpkg-deb --build --root-owner-group "$STAGE_DIR" "/tmp/$DEB_NAME"

# Publicar no CDN de instaladores e no pool do APT
echo "🚀 Publicando artefato..."
sudo cp "/tmp/$DEB_NAME" "/var/www/html/installers/$DEB_NAME"
sudo cp "/tmp/$DEB_NAME" "/var/www/html/apt/pool/main/$DEB_NAME"
sudo chmod 644 "/var/www/html/installers/$DEB_NAME" "/var/www/html/apt/pool/main/$DEB_NAME"

# Atualizar repositorio APT
echo "🔄 Atualizando catalogo APT..."
sudo /usr/local/bin/update-nexus-apt-repo.sh

echo "✔ Build e publicacao do Nexus App Hub Linux v0.3.26 concluidos com sucesso!"
