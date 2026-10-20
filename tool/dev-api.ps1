<#
.SYNOPSIS
  TERMINAL 1 — Arranca el backend Node.js + TypeScript en http://localhost:3000

.DESCRIPTION
  Ejecútalo en tu primera terminal. Hot reload automático (tsx watch):
  al guardar un archivo del backend se recarga solo.

  Si no existen dependencias, las instala la primera vez (npm install).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tool\dev-api.ps1

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tool\dev-api.ps1 -Port 4000
#>
param(
  [int]$Port = 3000
)

$serverDir = Join-Path $PSScriptRoot '..\server'
Set-Location $serverDir

Write-Host '=> TERMINAL 1 · Backend (Node.js + TypeScript)' -ForegroundColor Cyan
Write-Host "   API:  http://localhost:$Port" -ForegroundColor DarkGray
Write-Host '   Endpoints: GET / · GET /todos · POST /todos' -ForegroundColor DarkGray
Write-Host '   (hot reload automático al guardar cambios)' -ForegroundColor DarkGray
Write-Host ''

if (-not (Test-Path 'node_modules')) {
  Write-Host 'Instalando dependencias (solo la primera vez)...' -ForegroundColor DarkGray
  npm install
  if ($LASTEXITCODE -ne 0) { exit 1 }
}

$env:PORT = "$Port"
npm run dev
