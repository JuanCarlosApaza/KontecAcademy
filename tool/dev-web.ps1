<#
.SYNOPSIS
  Arranca la app en web con el CORS DESACTIVADO (solo desarrollo local).

.DESCRIPTION
  El navegador (Edge) se abre con --disable-web-security usando un perfil
  temporal aislado, por lo que la app puede llamar a cualquier API aunque
  ese backend no tenga cabeceras CORS configuradas.

  ⚠️ SOLO sirve en tu máquina de desarrollo. En producción el navegador
  de los usuarios bloqueará esas peticiones: hay que habilitar CORS en
  el backend (Access-Control-Allow-Origin).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tool\dev-web.ps1

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tool\dev-web.ps1 -ApiUrl http://localhost:3000
#>
param(
  [int]$Port = 8080,
  # Por defecto apunta a la API local que arranca tool\dev-api.ps1
  [string]$ApiUrl = 'http://localhost:3000'
)

# Perfil de navegador persistente y AISLADO para desarrollo:
# en él vive la instancia de Edge con el CORS desactivado, sin tocar tu
# Edge normal (cookies, sesiones y pestañas intactas).
$noCorsProfile = Join-Path $PSScriptRoot '..\.dart_tool\nocors-profile'
$flutterArgs = @(
  'run', '-d', 'edge',
  '--web-port', "$Port",
  '--web-hostname', 'localhost',
  '--web-browser-flag=--disable-web-security',
  "--web-browser-flag=--user-data-dir=$noCorsProfile"
)
if ($ApiUrl) {
  $flutterArgs += "--dart-define=API_URL=$ApiUrl"
}

Write-Host '=> Web en desarrollo con CORS libre (Edge, perfil temporal aislado)' -ForegroundColor Cyan
Write-Host "   URL: http://localhost:$Port" -ForegroundColor DarkGray
Write-Host "   API: $ApiUrl" -ForegroundColor DarkGray
Write-Host ''

flutter @flutterArgs
