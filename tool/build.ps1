<#
.SYNOPSIS
  Compila TODO y genera dos ZIPs listos para subir a Hostinger.

.DESCRIPTION
  Salida en dist\:
    kontec-web.zip  → contenido para public_html (frontend Flutter)
    kontec-api.zip  → proyecto del backend con dist\ ya compilado

  El build del front se hace en TU máquina (mismo toolchain siempre):
  así en el servidor solo hay que arrancarlo, sin sorpresas de compilación.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tool\build.ps1

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tool\build.ps1 -ApiUrl https://api.mitienda.com
#>
param(
  [string]$ApiUrl = 'https://api.tudominio.com',
  [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $root 'dist'

Write-Host '==> 1/4 Tests (opcional)' -ForegroundColor Cyan
if ($SkipTests) {
  Write-Host '    omitidos (-SkipTests)' -ForegroundColor DarkGray
} else {
  Push-Location $root
  flutter test
  if ($LASTEXITCODE -ne 0) { Pop-Location; exit 1 }
  Pop-Location

  Push-Location (Join-Path $root 'server')
  npm test
  if ($LASTEXITCODE -ne 0) { Pop-Location; exit 1 }
  Pop-Location
  Write-Host '    ✅ todos en verde' -ForegroundColor Green
}

Write-Host "==> 2/4 Frontend: flutter build web --dart-define=API_URL=$ApiUrl" -ForegroundColor Cyan
Push-Location $root
flutter build web --release --dart-define="API_URL=$ApiUrl"
$ok = $LASTEXITCODE -eq 0
Pop-Location
if (-not $ok) { exit 1 }

Write-Host '==> 3/4 Backend: npm run build' -ForegroundColor Cyan
Push-Location (Join-Path $root 'server')
npm run build
$ok = $LASTEXITCODE -eq 0
Pop-Location
if (-not $ok) { exit 1 }

Write-Host '==> 4/4 ZIPs en dist\' -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $dist | Out-Null

# (ZipWriter propio: incluye ficheros ocultos como .htaccess —que Compress-Archive
#  omite— y normaliza a '/' los separadores, imprescindible para que los ZIPs se
#  extraigan bien en Linux/File Manager de Hostinger)
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function New-ZipFromDirectory {
  param([string]$Source, [string]$Destination)

  if (Test-Path $Destination) { Remove-Item $Destination -Force }
  $sourceFull = (Resolve-Path $Source).Path
  $stream = [System.IO.File]::Open($Destination, [System.IO.FileMode]::CreateNew)
  $zip = New-Object System.IO.Compression.ZipArchive(
    $stream, [System.IO.Compression.ZipArchiveMode]::Create)
  try {
    Get-ChildItem -Path $sourceFull -Recurse -File -Force | ForEach-Object {
      $relative = $_.FullName.Substring($sourceFull.Length).TrimStart('\', '/') -replace '\\', '/'
      [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
        $zip, $_.FullName, $relative) | Out-Null
    }
  } finally {
    $zip.Dispose()
    $stream.Dispose()
  }
}

$webZip = Join-Path $dist 'kontec-web.zip'
New-ZipFromDirectory -Source (Join-Path $root 'build\web') -Destination $webZip

# Staging del backend: fuente + dist compilado, SIN node_modules
$staging = Join-Path $dist 'api-staging'
if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
New-Item -ItemType Directory -Force -Path $staging | Out-Null
$server = Join-Path $root 'server'
Copy-Item (Join-Path $server 'package.json') $staging
Copy-Item (Join-Path $server 'package-lock.json') $staging
Copy-Item (Join-Path $server 'tsconfig.json') $staging
Copy-Item (Join-Path $server 'tsconfig.build.json') $staging
Copy-Item (Join-Path $server 'Dockerfile') $staging
Copy-Item (Join-Path $server '.env.example') $staging
Copy-Item (Join-Path $server 'src') (Join-Path $staging 'src') -Recurse
Copy-Item (Join-Path $server 'tests') (Join-Path $staging 'tests') -Recurse
Copy-Item (Join-Path $server 'dist') (Join-Path $staging 'dist') -Recurse

$apiZip = Join-Path $dist 'kontec-api.zip'
New-ZipFromDirectory -Source $staging -Destination $apiZip
Remove-Item $staging -Recurse -Force

$webSize = [math]::Round((Get-Item $webZip).Length / 1KB, 1)
$apiSize = [math]::Round((Get-Item $apiZip).Length / 1KB, 1)

Write-Host ''
Write-Host '✅ LISTOS PARA SUBIR A HOSTINGER' -ForegroundColor Green
Write-Host "   dist\kontec-web.zip  ($webSize KB) → subir a public_html (File Manager)" -ForegroundColor White
Write-Host "   dist\kontec-api.zip  ($apiSize KB) → subir como app Node (o git push)" -ForegroundColor White
Write-Host ''
Write-Host '   Backend remoto: start = "npm start"  ·  build = "npm run build"' -ForegroundColor DarkGray
