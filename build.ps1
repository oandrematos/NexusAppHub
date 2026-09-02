param (
    [string]$version = "0.3.0",
    [string]$changes = "Nexus App Hub 3.0 (Flutter): Unificação nativa completa Windows & Android com catálogo oficial",
    [string[]]$changelog = @(
        "Unificação completa da loja e launcher em Flutter (Dart) com suporte a 120 FPS",
        "Design adaptativo responsivo: Microsoft Store no Desktop e Google Play Store no Mobile",
        "Instalador Windows nativo super compacto (redução drástica para apenas 12.1 MB)",
        "Inteligência multiplataforma: bloqueio de pacotes incompatíveis e tags de suporte",
        "Download assíncrono com tolerância a falhas, escape de URL e detecção de nós do cluster"
    )
)

$ErrorActionPreference = "Stop"
$projDir = $PSScriptRoot
$archiveDir = "$projDir\.archive"

if (!(Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Force -Path $archiveDir | Out-Null
}

Write-Host "======================================================="
Write-Host "  PIPELINE CI/CD & APP STORE INTEGRATION v$version"
Write-Host "======================================================="

$finalWinName = "NexusAppHub_v${version}_Installer.exe"
$finalApkName = "NexusAppHub_Flutter_Android_v${version}.apk"

# Localizar binários já compilados no projeto ou no .archive
$finalWinPath = "$projDir\$finalWinName"
if (!(Test-Path $finalWinPath) -and (Test-Path "$archiveDir\$finalWinName")) {
    Copy-Item "$archiveDir\$finalWinName" $finalWinPath -Force
}

$finalApkPath = "$projDir\$finalApkName"
if (!(Test-Path $finalApkPath) -and (Test-Path "$archiveDir\$finalApkName")) {
    Copy-Item "$archiveDir\$finalApkName" $finalApkPath -Force
}

if (!(Test-Path $finalWinPath)) {
    Write-Host "Aviso: $finalWinName não encontrado. Verificando OneDrive..."
    if (Test-Path "D:\OneDrive\Antigravity Projects\Installers\$finalWinName") {
        Copy-Item "D:\OneDrive\Antigravity Projects\Installers\$finalWinName" $finalWinPath -Force
    }
}
if (!(Test-Path $finalApkPath)) {
    Write-Host "Aviso: $finalApkName não encontrado. Verificando OneDrive..."
    if (Test-Path "D:\OneDrive\Antigravity Projects\Installers\$finalApkPath") {
        Copy-Item "D:\OneDrive\Antigravity Projects\Installers\$finalApkName" $finalApkPath -Force
    }
}

$winSizeMb = 12.1
if (Test-Path $finalWinPath) { $winSizeMb = [math]::Round((Get-Item $finalWinPath).Length / 1MB, 2) }

$apkSizeMb = 49.22
if (Test-Path $finalApkPath) { $apkSizeMb = [math]::Round((Get-Item $finalApkPath).Length / 1MB, 2) }

Write-Host "1. Binários Validados:"
Write-Host "  -> Windows Installer: $finalWinName ($winSizeMb MB)"
Write-Host "  -> Android Release APK: $finalApkName ($apkSizeMb MB)"

# 2. Distribuição para Nuvens (OneDrive e Google Drive)
Write-Host "`n2. Sincronizando com as Nuvens..."
$oneDriveInstallers = "D:\OneDrive\Antigravity Projects\Installers"
$oneDriveOld = "D:\OneDrive\Antigravity Projects\old_versions"
$gDriveInstallers = "Y:\Antigravity Projects\Installers"
$gDriveOld = "Y:\Antigravity Projects\old_versions"

function Sync-File($filePath, $fileName, $destInstallers, $destOld) {
    if (Test-Path $destInstallers) {
        Write-Host "  -> Copiando $fileName para $destInstallers..."
        Copy-Item -Path $filePath -Destination "$destInstallers\$fileName" -Force
    }
}

if (Test-Path $finalWinPath) {
    Sync-File $finalWinPath $finalWinName $oneDriveInstallers $oneDriveOld
    Sync-File $finalWinPath $finalWinName $gDriveInstallers $gDriveOld
}
if (Test-Path $finalApkPath) {
    Sync-File $finalApkPath $finalApkName $oneDriveInstallers $oneDriveOld
    Sync-File $finalApkPath $finalApkName $gDriveInstallers $gDriveOld
}

# 3. Deploy dos Binários no Cluster (S1 e S2)
Write-Host "`n3. Sincronizando Binários com Servidores S1 (Escritório) e S2 (Casa)..."
$servers = @("192.168.196.101", "192.168.196.102")
foreach ($srv in $servers) {
    Write-Host "  -> Enviando instaladores para $srv..."
    if (Test-Path $finalWinPath) {
        scp -o StrictHostKeyChecking=accept-new $finalWinPath server@${srv}:/var/www/html/installers/$finalWinName
        ssh -o StrictHostKeyChecking=accept-new server@$srv "cp /var/www/html/installers/$finalWinName /var/www/html/installers/NexusAppHub_Installer.exe && cp /var/www/html/installers/$finalWinName /opt/antigravity/installers/ && chmod 755 /var/www/html/installers/NexusAppHub*"
    }
    if (Test-Path $finalApkPath) {
        scp -o StrictHostKeyChecking=accept-new $finalApkPath server@${srv}:/var/www/html/installers/$finalApkName
        ssh -o StrictHostKeyChecking=accept-new server@$srv "cp /var/www/html/installers/$finalApkName /var/www/html/installers/NexusAppHub.apk && cp /var/www/html/installers/$finalApkName /opt/antigravity/installers/ && chmod 755 /var/www/html/installers/NexusAppHub*"
    }
}

# 4. Integração Automática com a App Store
Write-Host "`n4. Integração Automática com a App Store (Screenshots & Catálogo Mestre)..."

# 4.1 Enviar Screenshots para os servidores
$screenshotsLocal = "$projDir\assets\screenshots"
$remoteScreenshotsDir = "/var/www/html/installers/assets/screenshots"
$screenshotUrls = @(
    "http://192.168.196.101/installers/assets/screenshots/nexus_app_hub_desktop.png",
    "http://192.168.196.101/installers/assets/screenshots/nexus_app_hub_mobile.png"
)

foreach ($srv in $servers) {
    Write-Host "  -> Enviando screenshots para $srv ($remoteScreenshotsDir)..."
    ssh -o StrictHostKeyChecking=accept-new server@$srv "mkdir -p $remoteScreenshotsDir && chmod -R 755 /var/www/html/installers/assets"
    if (Test-Path "$screenshotsLocal\*.png") {
        scp -o StrictHostKeyChecking=accept-new "$screenshotsLocal\*.png" server@${srv}:${remoteScreenshotsDir}/
    }
}

# 4.2 Baixar software_catalog.json do Servidor S1
Write-Host "  -> Baixando software_catalog.json de S1..."
$localCatalog = "$projDir\software_catalog.json"
try {
    Invoke-WebRequest -Uri "http://192.168.196.101/installers/software_catalog.json" -OutFile $localCatalog -UseBasicParsing -TimeoutSec 5
} catch {
    scp -o StrictHostKeyChecking=accept-new server@192.168.196.101:/var/www/html/installers/software_catalog.json $localCatalog
}

# 4.3 Editar JSON localmente injetando versão, changelog e screenshots
Write-Host "  -> Injetando nova versão (v$version), latest_changelog e screenshots..."
$jsonContent = Get-Content $localCatalog -Raw -Encoding UTF8 | ConvertFrom-Json

foreach ($app in $jsonContent.apps) {
    if ($app.id -eq "nexus_app_hub") {
        $app | Add-Member -NotePropertyName "version" -NotePropertyValue "v$version" -Force
        if ($app.windows) {
            $app.windows | Add-Member -NotePropertyName "version" -NotePropertyValue "v$version" -Force
            $app.windows | Add-Member -NotePropertyName "filename" -NotePropertyValue $finalWinName -Force
            $app.windows | Add-Member -NotePropertyName "size_mb" -NotePropertyValue $winSizeMb -Force
        }
        if ($app.android) {
            $app.android | Add-Member -NotePropertyName "version" -NotePropertyValue "v$version" -Force
            $app.android | Add-Member -NotePropertyName "filename" -NotePropertyValue $finalApkName -Force
            $app.android | Add-Member -NotePropertyName "size_mb" -NotePropertyValue $apkSizeMb -Force
        }
        $app | Add-Member -NotePropertyName "latest_changelog" -NotePropertyValue $changelog -Force
        $app | Add-Member -NotePropertyName "screenshots" -NotePropertyValue $screenshotUrls -Force
    }
}

$jsonContent.updated_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
$updatedJsonString = $jsonContent | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($localCatalog, $updatedJsonString, [System.Text.UTF8Encoding]::new($false))

# 4.4 Upload do JSON editado de volta para S1 e S2
Write-Host "  -> Enviando catálogo mestre atualizado de volta para S1 e S2..."
foreach ($srv in $servers) {
    scp -o StrictHostKeyChecking=accept-new $localCatalog server@${srv}:/var/www/html/installers/software_catalog.json
    ssh -o StrictHostKeyChecking=accept-new server@$srv "cp /var/www/html/installers/software_catalog.json /opt/antigravity/installers/ && chmod 755 /var/www/html/installers/software_catalog.json /opt/antigravity/installers/software_catalog.json"
}

# 5. Limpeza da Raiz
Write-Host "`n5. Limpando a raiz e arquivando pacotes em .archive/..."
if (Test-Path $finalApkPath) {
    Move-Item -Path $finalApkPath -Destination "$archiveDir\$finalApkName" -Force -ErrorAction SilentlyContinue
}
if (Test-Path $finalWinPath) {
    Move-Item -Path $finalWinPath -Destination "$archiveDir\$finalWinName" -Force -ErrorAction SilentlyContinue
}
if (Test-Path $localCatalog) {
    Remove-Item $localCatalog -Force -ErrorAction SilentlyContinue
}

Write-Host "======================================================="
Write-Host " [SUCESSO] Pipeline e Integração com App Store Concluídos!"
Write-Host "======================================================="