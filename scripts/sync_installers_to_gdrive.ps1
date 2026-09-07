# [CITADEL] Script de Sincronizacao de Instaladores: OneDrive -> Google Drive (Disco W:)
# Mantem a paridade total entre o armazenamento primario e os espelhos no RaiDrive

param(
    [string]$SourcePath = "D:\OneDrive\Antigravity Projects\Installers",
    [string[]]$Destinations = @(
        "W:\Antigravity Projects\Installers",
        "W:\Installers"
    )
)

Write-Host "🛡 [CITADEL] Iniciando Sincronizacao Dupla de Instaladores..." -ForegroundColor Cyan
Write-Host "   Origem : $SourcePath" -ForegroundColor Gray

if (-not (Test-Path $SourcePath)) {
    Write-Host "❌ [ERRO] Diretorio de origem nao encontrado: $SourcePath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "W:\")) {
    Write-Host "⚠️ [AVISO] Disco W: (RaiDrive / Google Drive) nao esta acessivel ou montado." -ForegroundColor Yellow
    exit 2
}

foreach ($dest in $Destinations) {
    Write-Host "📂 Alvo: $dest" -ForegroundColor Cyan
    if (-not (Test-Path $dest)) {
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
    }

    $argLine = "`"$SourcePath`" `"$dest`" *.* /XO /FFT /R:1 /W:2 /NP"
    $process = Start-Process -FilePath "robocopy.exe" -ArgumentList $argLine -NoNewWindow -Wait -PassThru

    if ($process.ExitCode -le 7) {
        Write-Host "   ✔ Sincronizacao concluida em $dest! (Cod: $($process.ExitCode))" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ Robocopy reportou codigo $($process.ExitCode) para $dest." -ForegroundColor Yellow
    }
}
