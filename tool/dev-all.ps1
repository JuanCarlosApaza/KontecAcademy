<#
.SYNOPSIS
  Abre DOS terminales: una con el backend (API) y otra con el frontend (web).

.DESCRIPTION
  Terminal 1: tool\dev-api.ps1   -> API Dart Frog en http://localhost:3000
  Terminal 2: tool\dev-web.ps1   -> Flutter web en http://localhost:8080 (CORS libre)

  Ambas mantienen hot reload: cada una se recarga al guardar sus archivos.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tool\dev-all.ps1
#>
$root = Split-Path -Parent $PSScriptRoot

Write-Host 'Abriendo dos terminales... (1 = backend · 2 = frontend)' -ForegroundColor Cyan

# Terminal 1 — Backend
Start-Process powershell -ArgumentList @(
  '-NoExit', '-ExecutionPolicy', 'Bypass', '-NoProfile',
  '-Command', "Set-Location '$root'; Write-Host 'TERMINAL 1 · Backend (Dart Frog)' -ForegroundColor Cyan; & '$PSScriptRoot\dev-api.ps1'"
)

# Terminal 2 — Frontend
Start-Process powershell -ArgumentList @(
  '-NoExit', '-ExecutionPolicy', 'Bypass', '-NoProfile',
  '-Command', "Set-Location '$root'; Write-Host 'TERMINAL 2 · Frontend (Flutter web)' -ForegroundColor Green; & '$PSScriptRoot\dev-web.ps1'"
)
