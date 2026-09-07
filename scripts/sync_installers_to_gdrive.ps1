# [CITADEL] Script de Sincronizacao de Instaladores: OneDrive -> Google Drive (Disco W:)
# Mantem a paridade total entre o armazenamento primario e o espelho no RaiDrive

param(
    [string]$SourcePath = "D:\OneDrive\Antigravity Projects\Installers",
    [string]$DestinationPath = "W:\Antigravity Projects\Installers"
)

Write-Host "🛡 [CITADEL] Iniciando Sincronizacao de Instaladores..." -ForegroundColor Cyan
Write-Host "   Origem : $SourcePath" -ForegroundColor Gray
Write-Host "   Destino: $DestinationPath" -ForegroundColor Gray

if (-not (Test-Path $SourcePath)) {
    Write-Host "❌ [ERRO] Diretorio de origem nao encontrado: $SourcePath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "W:\")) {
    Write-Host "⚠️ [AVISO] Disco W: (RaiDrive / Google Drive) nao esta acessivel ou montado." -ForegroundColor Yellow
    exit 2
}

if (-not (Test-Path $DestinationPath)) {
    New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
}

$robocopyArgs = @(
    $SourcePath,
    $DestinationPath,
    "*.*",
    "/XO",
    "/FFT",
    "/R:1",
    "/W:2",
    "/NP"
)

Write-Host "🚀 Executando Robocopy incremental..." -ForegroundColor Yellow
$process = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -NoNewWindow -Wait -PassThru

if ($process.ExitCode -le 7) {
    Write-Host "✔ [CITADEL] Sincronizacao concluida com sucesso! Codigo de saida: $($process.ExitCode)" -ForegroundColor Green
} else {
    Write-Host "⚠️ [CITADEL] Robocopy reportou codigo $($process.ExitCode)." -ForegroundColor Yellow
}
