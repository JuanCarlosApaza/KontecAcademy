<#
.SYNOPSIS
  TERMINAL 1 — Arranca el backend en http://localhost:3000

.DESCRIPTION
  Por defecto arranca el backend recomendado: Node.js + TypeScript (server/).
  Con hot reload (tsx watch): al guardar un archivo se recarga solo.

  Alternativa: el backend original en Dart Frog (api/) se mantiene como
  referencia con -Runtime dart.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tool\dev-api.ps1              # Node (recomendado)

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tool\dev-api.ps1 -Runtime dart # Dart Frog
#>
param(
  [ValidateSet('node', 'dart')]
  [string]$Runtime = 'node',

  [int]$Port = 3000
)

Write-Host "=> TERMINAL 1 · Backend ($Runtime)" -ForegroundColor Cyan
Write-Host "   API:  http://localhost:$Port" -ForegroundColor DarkGray
Write-Host '   Endpoints: GET / · GET /todos · POST /todos' -ForegroundColor DarkGray
Write-Host ''

if ($Runtime -eq 'node') {
  $serverDir = Join-Path $PSScriptRoot '..\server'
  Set-Location $serverDir

  if (-not (Test-Path 'node_modules')) {
    Write-Host 'Instalando dependencias (solo la primera vez)...' -ForegroundColor DarkGray
    npm install
    if ($LASTEXITCODE -ne 0) { exit 1 }
  }

  Write-Host '   (hot reload automático al guardar cambios)' -ForegroundColor DarkGray
  Write-Host ''
  $env:PORT = "$Port"
  npm run dev
} else {
  $frog = Join-Path $env:LOCALAPPDATA 'Pub\Cache\bin\dart_frog.bat'
  if (-not (Test-Path $frog)) {
    Write-Host '✗ No se encontró dart_frog. Instálalo con:' -ForegroundColor Red
    Write-Host '  dart pub global activate dart_frog_cli' -ForegroundColor Yellow
    exit 1
  }

  Set-Location (Join-Path $PSScriptRoot '..\api')
  Write-Host '   (hot reload automático al guardar cambios)' -ForegroundColor DarkGray
  Write-Host ''
  & $frog dev --port $Port --hostname localhost
}
