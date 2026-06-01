<#
.SYNOPSIS
    Instala automaticamente, en modo silencioso, los principales launchers de
    videojuegos para Windows (Steam, Epic, EA app, Ubisoft, GOG, Battle.net,
    Amazon Games, Rockstar, Xbox, itch.io, Playnite...).

.DESCRIPTION
    Usa winget (Windows Package Manager) como motor principal de instalacion
    silenciosa. Si winget no esta disponible o un paquete falla, recurre a la
    descarga directa del instalador oficial ejecutado con flags silenciosos.

    El script se auto-eleva a Administrador (UAC) y genera un log junto al
    propio fichero, mostrando al final una tabla resumen con el resultado de
    cada launcher.

.PARAMETER All
    Instala TODOS los launchers del catalogo sin mostrar el menu interactivo.

.PARAMETER List
    Muestra el catalogo de launchers y termina sin instalar nada.

.PARAMETER NoFallback
    Desactiva la descarga directa de respaldo: usa unicamente winget.

.PARAMETER Update
    En lugar de instalar, actualiza (winget upgrade) los launchers seleccionados
    que ya esten instalados.

.PARAMETER DryRun
    Simula la operacion: muestra que se haria sin instalar ni actualizar nada.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Install-GameLaunchers.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Install-GameLaunchers.ps1 -All

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Install-GameLaunchers.ps1 -List

.NOTES
    Proyecto: launxers
    Licencia: MIT
    Requisitos: Windows 10 1809+ / Windows 11, ejecutar como Administrador.
#>

[CmdletBinding()]
param(
    [switch]$All,
    [switch]$List,
    [switch]$NoFallback,
    [switch]$Update,
    [switch]$DryRun
)

# ---------------------------------------------------------------------------
# Constantes y rutas
# ---------------------------------------------------------------------------
$ScriptVersion = '1.1.3'
$ScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$LogFile = Join-Path $ScriptRoot 'Install-GameLaunchers.log'

# Base "Program Files (x86)" con respaldo por si no existe (Windows de 32 bits).
$ProgramFilesX86 = ${env:ProgramFiles(x86)}
if ([string]::IsNullOrEmpty($ProgramFilesX86)) { $ProgramFilesX86 = $env:ProgramFiles }

# ---------------------------------------------------------------------------
# Catalogo de launchers
#   Name         -> Nombre visible
#   WingetId     -> ID en el repositorio de winget (motor principal)
#   WingetSource -> 'winget' (por defecto) o 'msstore'
#   FallbackUrl  -> URL directa del instalador oficial (respaldo)
#   FallbackArgs -> Flags para instalacion silenciosa del instalador directo
#   Notes        -> Aclaraciones
# ---------------------------------------------------------------------------
$Launchers = @(
    [pscustomobject]@{
        Name = 'Steam'; WingetId = 'Valve.Steam'; WingetSource = 'winget'
        FallbackUrl = 'https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe'
        FallbackArgs = @('/S'); Notes = 'Cliente de Valve.'
    }
    [pscustomobject]@{
        Name = 'Epic Games'; WingetId = 'EpicGames.EpicGamesLauncher'; WingetSource = 'winget'
        FallbackUrl = 'https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi'
        FallbackArgs = @('/quiet', '/norestart'); Notes = 'Instalador MSI.'
    }
    [pscustomobject]@{
        Name = 'EA app'; WingetId = 'ElectronicArts.EADesktop'; WingetSource = 'winget'
        FallbackUrl = $null
        FallbackArgs = @(); Notes = 'Sustituto de Origin. Preferir winget (silent directo fragil).'
    }
    [pscustomobject]@{
        Name = 'Ubisoft Connect'; WingetId = 'Ubisoft.Connect'; WingetSource = 'winget'
        FallbackUrl = 'https://ubistatic3-a.akamaihd.net/orbit/launcher_installer/UbisoftConnectInstaller.exe'
        FallbackArgs = @('/S'); Notes = 'Antes Uplay.'
    }
    [pscustomobject]@{
        Name = 'GOG Galaxy'; WingetId = 'GOG.Galaxy'; WingetSource = 'winget'
        FallbackUrl = $null
        FallbackArgs = @('/VERYSILENT', '/NORESTART'); Notes = 'Preferir winget (URL versionada).'
    }
    [pscustomobject]@{
        Name = 'Battle.net'; WingetId = 'Blizzard.BattleNet'; WingetSource = 'winget'
        WingetExtraArgs = @('--location', (Join-Path $ProgramFilesX86 'Battle.net'), '--force')
        FallbackUrl = $null
        FallbackArgs = @(); Notes = 'Cliente de Blizzard. winget requiere --location y --force (hash del bootstrapper cambia a menudo).'
    }
    [pscustomobject]@{
        Name = 'Amazon Games'; WingetId = 'Amazon.Games'; WingetSource = 'winget'
        FallbackUrl = 'https://download.amazongames.com/AmazonGamesSetup.exe'
        FallbackArgs = @('/S'); Notes = 'Incluye juegos de Prime Gaming.'
    }
    [pscustomobject]@{
        Name = 'Rockstar Games Launcher'; WingetId = 'RockstarGames.Launcher'; WingetSource = 'winget'
        FallbackUrl = $null
        FallbackArgs = @('/S'); Notes = 'GTA, Red Dead, etc. (winget; URL directa no estable).'
    }
    [pscustomobject]@{
        Name = 'Xbox / Game Pass'; WingetId = '9MV0B5HZVK9Z'; WingetSource = 'msstore'
        FallbackUrl = $null
        FallbackArgs = @(); Notes = 'App Xbox (Game Pass). Suele venir preinstalada en Windows.'
    }
    [pscustomobject]@{
        Name = 'itch.io'; WingetId = 'ItchIo.Itch'; WingetSource = 'winget'
        FallbackUrl = 'https://itch.io/app/download?platform=windows'
        FallbackArgs = @('/quiet', '/norestart'); Notes = 'Juegos indie.'
    }
    [pscustomobject]@{
        Name = 'Playnite'; WingetId = 'Playnite.Playnite'; WingetSource = 'winget'
        FallbackUrl = $null
        FallbackArgs = @('/VERYSILENT', '/NORESTART'); Notes = 'Meta-launcher: unifica todas tus bibliotecas.'
    }
)

# ---------------------------------------------------------------------------
# Utilidades de log y consola
# ---------------------------------------------------------------------------
function Write-Log {
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'OK')] [string]$Level = 'INFO',
        [System.ConsoleColor]$Color = 'Gray',
        [switch]$NoConsole
    )
    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$stamp [$Level] $Message" | Out-File -FilePath $LogFile -Append -Encoding utf8
    if (-not $NoConsole) {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Write-Banner {
    $line = '=' * 64
    Write-Host ''
    Write-Host $line -ForegroundColor DarkCyan
    Write-Host "  launxers  -  Instalador de launchers de videojuegos  v$ScriptVersion" -ForegroundColor Cyan
    Write-Host "  winget + fallback  |  modo silencioso  |  Windows 10/11" -ForegroundColor DarkGray
    Write-Host $line -ForegroundColor DarkCyan
    Write-Host ''
}

# ---------------------------------------------------------------------------
# Auto-elevacion (UAC)
# ---------------------------------------------------------------------------
function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($id)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-SelfElevation {
    if (Test-Admin) { return }
    Write-Host 'Se requieren permisos de Administrador. Relanzando con UAC...' -ForegroundColor Yellow

    $argList = [System.Collections.Generic.List[string]]::new()
    $argList.Add('-NoProfile')
    $argList.Add('-ExecutionPolicy'); $argList.Add('Bypass')
    $argList.Add('-File'); $argList.Add("`"$PSCommandPath`"")
    if ($All)        { $argList.Add('-All') }
    if ($List)       { $argList.Add('-List') }
    if ($NoFallback) { $argList.Add('-NoFallback') }

    try {
        Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs
    } catch {
        Write-Host "No se pudo elevar el proceso: $($_.Exception.Message)" -ForegroundColor Red
    }
    exit
}

# ---------------------------------------------------------------------------
# winget: deteccion y bootstrap
# ---------------------------------------------------------------------------
function Test-Winget {
    return [bool](Get-Command winget.exe -ErrorAction SilentlyContinue)
}

function Initialize-Winget {
    if (Test-Winget) { return $true }

    Write-Log 'winget no esta disponible en este sistema.' -Level WARN -Color Yellow
    Write-Host 'winget (App Installer) no se ha encontrado.' -ForegroundColor Yellow
    Write-Host 'Puedes instalarlo desde Microsoft Store ("App Installer") y volver a ejecutar.' -ForegroundColor Yellow

    $answer = Read-Host '¿Intentar abrir la pagina de App Installer en Store ahora? (s/N)'
    if ($answer -match '^(s|si|y|yes)$') {
        try { Start-Process 'ms-windows-store://pdp/?productid=9NBLGGH4NNS1' } catch {}
    }

    if (-not (Test-Winget)) {
        Write-Log 'Continuando sin winget: solo se usara el fallback de descarga directa.' -Level WARN -Color Yellow
        return $false
    }
    return $true
}

# Codigos de salida de winget que tratamos como "ya instalado / sin accion".
$script:WingetBenignCodes = @(
    -1978335189,  # 0x8A15002B UPDATE_NOT_APPLICABLE: ya instalado y al dia
    -1978335135,  # 0x8A150061 PACKAGE_ALREADY_INSTALLED
    -1978334963,  # 0x8A15010D INSTALL_ALREADY_INSTALLED
    -1978334962   # 0x8A15010E INSTALL_DOWNGRADE: ya hay una version superior
)
# Codigos que indican instalacion correcta pero con reinicio pendiente.
$script:WingetRebootCodes = @(
    -1978334967,  # 0x8A150109 REBOOT_REQUIRED_TO_FINISH
    -1978334966,  # 0x8A15010A REBOOT_REQUIRED_FOR_INSTALL
    -1978334965   # 0x8A15010B REBOOT_INITIATED
)

# Ejecuta winget en un job en segundo plano (sin consola), registra su salida y
# devuelve el exit code. Hacerlo en un job evita que winget se cuelgue al capturar
# su salida en consolas elevadas por UAC, y permite un timeout de seguridad.
function Invoke-Winget {
    param(
        [Parameter(Mandatory)] [string[]]$Arguments,
        [int]$TimeoutSeconds = 1200
    )
    Write-Log "winget $($Arguments -join ' ')" -Level INFO -NoConsole
    try {
        $job = Start-Job -ScriptBlock {
            param($wgArgs)
            $out = & winget.exe @wgArgs 2>&1 | Out-String
            [pscustomobject]@{ Code = $LASTEXITCODE; Output = $out }
        } -ArgumentList (, $Arguments)

        if (-not (Wait-Job $job -Timeout $TimeoutSeconds)) {
            Stop-Job $job -ErrorAction SilentlyContinue
            Remove-Job $job -Force -ErrorAction SilentlyContinue
            Write-Log "winget excedio el tiempo limite ($TimeoutSeconds s) y se cancelo." -Level ERROR -NoConsole
            return 1
        }

        $r = Receive-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -Force -ErrorAction SilentlyContinue
        if ($null -eq $r) { return 1 }

        if ($r.Output) {
            $r.Output -split "`r?`n" |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                ForEach-Object { Write-Log $_ -Level INFO -NoConsole }
        }
        return [int]$r.Code
    } catch {
        Write-Log "Error ejecutando winget: $($_.Exception.Message)" -Level ERROR -NoConsole
        return 1
    }
}

# Comprueba en caliente (sin cache) si el launcher esta instalado segun winget.
function Test-InstalledNow {
    param([Parameter(Mandatory)] $Launcher)
    if (-not (Test-Winget)) { return $false }
    $code = Invoke-Winget -Arguments @(
        'list', '--id', $Launcher.WingetId, '--exact',
        '--accept-source-agreements', '--disable-interactivity'
    ) -TimeoutSeconds 60
    return ($code -eq 0)
}

# Carga (una sola vez y con limite de tiempo) el listado de winget para detectar
# que launchers ya estan instalados. Se ejecuta en un job aparte para que NUNCA
# bloquee el script: en consolas elevadas por UAC 'winget list' puede colgarse al
# capturar su salida, asi que si tarda demasiado se descarta la deteccion.
$script:WingetListCache = $null
function Initialize-WingetListCache {
    if ($null -ne $script:WingetListCache) { return }
    $script:WingetListCache = ''   # por defecto: sin deteccion
    if (-not (Test-Winget)) { return }
    try {
        $job = Start-Job -ScriptBlock {
            winget list --accept-source-agreements --disable-interactivity 2>$null | Out-String
        }
        if (Wait-Job $job -Timeout 25) {
            $out = Receive-Job $job -ErrorAction SilentlyContinue
            if ($out) { $script:WingetListCache = [string]$out }
        }
        Remove-Job $job -Force -ErrorAction SilentlyContinue
    } catch { }
}

function Test-LauncherInstalled {
    param([Parameter(Mandatory)] $Launcher)
    if ([string]::IsNullOrEmpty($script:WingetListCache)) { return $false }
    return $script:WingetListCache -match [regex]::Escape($Launcher.WingetId)
}

# ---------------------------------------------------------------------------
# Instalacion / actualizacion de un launcher
# ---------------------------------------------------------------------------
function Install-ViaWinget {
    param([Parameter(Mandatory)] $Launcher)

    $wgArgs = @(
        'install', '--id', $Launcher.WingetId, '--source', $Launcher.WingetSource,
        '--silent', '--accept-package-agreements', '--accept-source-agreements',
        '--disable-interactivity'
    )
    if ($Launcher.WingetSource -eq 'winget') { $wgArgs += '--exact' }
    if ($Launcher.WingetExtraArgs) { $wgArgs += $Launcher.WingetExtraArgs }

    $code = Invoke-Winget -Arguments $wgArgs

    if ($code -eq 0) { return @{ Ok = $true; Status = 'Instalado (winget)' } }
    if ($script:WingetBenignCodes -contains $code) { return @{ Ok = $true; Status = 'Ya estaba instalado' } }
    if ($script:WingetRebootCodes -contains $code) { return @{ Ok = $true; Status = 'Instalado (requiere reinicio)' } }
    # Ultimo recurso: aunque winget devuelva error, comprobar si quedo instalado.
    if (Test-InstalledNow -Launcher $Launcher) { return @{ Ok = $true; Status = 'Ya estaba instalado' } }
    return @{ Ok = $false; Status = "winget fallo (codigo $code)" }
}

function Update-ViaWinget {
    param([Parameter(Mandatory)] $Launcher)

    $wgArgs = @(
        'upgrade', '--id', $Launcher.WingetId, '--source', $Launcher.WingetSource,
        '--silent', '--accept-package-agreements', '--accept-source-agreements',
        '--disable-interactivity'
    )
    if ($Launcher.WingetSource -eq 'winget') { $wgArgs += '--exact' }

    $code = Invoke-Winget -Arguments $wgArgs

    if ($code -eq 0) { return @{ Ok = $true; Status = 'Actualizado (winget)' } }
    if ($script:WingetBenignCodes -contains $code) { return @{ Ok = $true; Status = 'Ya estaba al dia' } }
    return @{ Ok = $false; Status = "Actualizacion fallo (codigo $code)" }
}

function Install-ViaFallback {
    param([Parameter(Mandatory)] $Launcher)

    if ([string]::IsNullOrWhiteSpace($Launcher.FallbackUrl)) {
        return @{ Ok = $false; Status = 'Sin fallback disponible' }
    }

    $isMsi = $Launcher.FallbackUrl -match '\.msi(\?|$)'
    $ext = if ($isMsi) { '.msi' } else { '.exe' }
    $safeName = ($Launcher.Name -replace '[^\w]', '_')
    $dest = Join-Path $env:TEMP "launxers_$safeName$ext"

    try {
        Write-Log "Descargando $($Launcher.Name) desde $($Launcher.FallbackUrl)" -Level INFO -Color Gray
        $oldPref = $ProgressPreference; $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Launcher.FallbackUrl -OutFile $dest -UseBasicParsing
        $ProgressPreference = $oldPref
    } catch {
        return @{ Ok = $false; Status = "Descarga fallo: $($_.Exception.Message)" }
    }

    try {
        if ($isMsi) {
            $msiArgs = @('/i', "`"$dest`"") + $Launcher.FallbackArgs
            $p = Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArgs -Wait -PassThru
        } else {
            $p = Start-Process -FilePath $dest -ArgumentList $Launcher.FallbackArgs -Wait -PassThru
        }
        $code = $p.ExitCode
    } catch {
        return @{ Ok = $false; Status = "Ejecucion fallo: $($_.Exception.Message)" }
    } finally {
        Remove-Item $dest -ErrorAction SilentlyContinue
    }

    if ($code -eq 0 -or $code -eq 3010) {
        return @{ Ok = $true; Status = 'Instalado (fallback)' }
    }
    return @{ Ok = $false; Status = "Fallback fallo (codigo $code)" }
}

function Install-Launcher {
    param(
        [Parameter(Mandatory)] $Launcher,
        [bool]$WingetAvailable,
        [int]$Index = 0,
        [int]$Total = 0
    )

    $progress = if ($Total -gt 0) { "[$Index/$Total] " } else { '' }
    Write-Host ''
    Write-Host "$progress>> $($Launcher.Name)" -ForegroundColor White

    # Modo simulacion: no toca el sistema.
    if ($DryRun) {
        $action = if ($Update) { 'actualizaria' } else { 'instalaria' }
        $status = "Simulado: se $action via $($Launcher.WingetSource)"
        Write-Log "$($Launcher.Name): $status" -Level INFO -Color Cyan
        return $status
    }

    # Modo actualizacion: solo winget upgrade.
    if ($Update) {
        if (-not $WingetAvailable) {
            $status = 'Update requiere winget (no disponible)'
            Write-Log "$($Launcher.Name): $status" -Level ERROR -Color Red
            return $status
        }
        $up = Update-ViaWinget -Launcher $Launcher
        $lvl = if ($up.Ok) { 'OK' } else { 'ERROR' }
        $col = if ($up.Ok) { 'Green' } else { 'Red' }
        Write-Log "$($Launcher.Name): $($up.Status)" -Level $lvl -Color $col
        return $up.Status
    }

    $result = $null
    if ($WingetAvailable) {
        $result = Install-ViaWinget -Launcher $Launcher
        if ($result.Ok) {
            Write-Log "$($Launcher.Name): $($result.Status)" -Level OK -Color Green
            return $result.Status
        }
        Write-Log "$($Launcher.Name): $($result.Status)" -Level WARN -Color Yellow
    }

    if (-not $NoFallback) {
        $fb = Install-ViaFallback -Launcher $Launcher
        if ($fb.Ok) {
            Write-Log "$($Launcher.Name): $($fb.Status)" -Level OK -Color Green
            return $fb.Status
        }
        Write-Log "$($Launcher.Name): $($fb.Status)" -Level ERROR -Color Red
        return $fb.Status
    }

    $status = if ($result) { $result.Status } else { 'No instalado' }
    Write-Log "$($Launcher.Name): $status" -Level ERROR -Color Red
    return $status
}

# ---------------------------------------------------------------------------
# Catalogo / menu
# ---------------------------------------------------------------------------
function Show-Catalog {
    if (Test-Winget) {
        Write-Host 'Comprobando estado de los launchers...' -ForegroundColor DarkGray
        Initialize-WingetListCache
    }
    $canDetect = -not [string]::IsNullOrEmpty($script:WingetListCache)
    if ($canDetect) {
        Write-Host 'Launchers disponibles (estado segun winget):' -ForegroundColor Cyan
    } else {
        Write-Host 'Launchers disponibles:' -ForegroundColor Cyan
    }
    for ($i = 0; $i -lt $Launchers.Count; $i++) {
        $n = '{0,2}' -f ($i + 1)
        if ($canDetect -and (Test-LauncherInstalled -Launcher $Launchers[$i])) {
            $tag = '[OK] '; $color = 'Green'
        } else {
            $tag = '[  ] '; $color = 'Gray'
        }
        Write-Host ("  {0}[{1}] {2,-26} {3}" -f $tag, $n, $Launchers[$i].Name, $Launchers[$i].Notes) -ForegroundColor $color
    }
    Write-Host ''
    if ($canDetect) {
        Write-Host '  [OK] = ya instalado' -ForegroundColor DarkGray
        Write-Host ''
    }
}

function Select-Launchers {
    Show-Catalog
    Write-Host 'Escribe los numeros separados por espacio/coma, "A" para todos, "Q" para salir.' -ForegroundColor DarkGray
    $choice = Read-Host 'Seleccion'

    if ([string]::IsNullOrWhiteSpace($choice)) { return @() }
    if ($choice -match '^(q|quit|salir)$') { return @() }
    if ($choice -match '^(a|all|todos)$') { return $Launchers }

    $selected = [System.Collections.Generic.List[object]]::new()
    foreach ($token in ($choice -split '[,\s]+' | Where-Object { $_ })) {
        if ($token -match '^\d+$') {
            $idx = [int]$token - 1
            if ($idx -ge 0 -and $idx -lt $Launchers.Count) {
                if (-not $selected.Contains($Launchers[$idx])) { $selected.Add($Launchers[$idx]) }
            } else {
                Write-Host "  Ignorado: '$token' fuera de rango." -ForegroundColor DarkYellow
            }
        } else {
            Write-Host "  Ignorado: '$token' no es un numero." -ForegroundColor DarkYellow
        }
    }
    return $selected
}

# ---------------------------------------------------------------------------
# Resumen
# ---------------------------------------------------------------------------
function Show-Summary {
    param([Parameter(Mandatory)] $Results)

    Write-Host ''
    Write-Host ('-' * 64) -ForegroundColor DarkCyan
    Write-Host '  RESUMEN' -ForegroundColor Cyan
    Write-Host ('-' * 64) -ForegroundColor DarkCyan
    foreach ($r in $Results) {
        $ok = $r.Status -match 'Instalado|Ya estaba|Actualizado|al dia|Simulado'
        $color = if ($ok) { 'Green' } else { 'Red' }
        $mark = if ($ok) { 'OK ' } else { '!! ' }
        Write-Host ("  {0}{1,-26} {2}" -f $mark, $r.Name, $r.Status) -ForegroundColor $color
    }
    Write-Host ''
    Write-Host "Log detallado: $LogFile" -ForegroundColor DarkGray
}

# ===========================================================================
# MAIN
# ===========================================================================
Write-Banner

if ($List) {
    Show-Catalog
    return
}

# -DryRun no toca el sistema, asi que no necesita permisos de Administrador.
if (-not $DryRun) { Invoke-SelfElevation }

Write-Log "=== Inicio de ejecucion (v$ScriptVersion) ===" -Level INFO -NoConsole

$wingetOk = Initialize-Winget
if ($wingetOk) {
    Write-Log 'winget disponible: se usara como motor principal.' -Level INFO -Color Green
} elseif ($Update) {
    Write-Host 'La actualizacion (-Update) requiere winget, que no esta disponible.' -ForegroundColor Red
    return
} elseif ($NoFallback) {
    Write-Host 'No hay winget y -NoFallback esta activo: nada que instalar.' -ForegroundColor Red
    return
}

$toInstall = if ($All) { $Launchers } else { Select-Launchers }

if (-not $toInstall -or $toInstall.Count -eq 0) {
    Write-Host 'No se ha seleccionado ningun launcher. Saliendo.' -ForegroundColor Yellow
    return
}

$verbo = if ($DryRun) { 'simularan' } elseif ($Update) { 'actualizaran' } else { 'instalaran' }
Write-Host ''
Write-Host "Se $verbo $($toInstall.Count) launcher(s)..." -ForegroundColor Cyan

$total = $toInstall.Count
$results = [System.Collections.Generic.List[object]]::new()
for ($i = 0; $i -lt $total; $i++) {
    $launcher = $toInstall[$i]
    $status = Install-Launcher -Launcher $launcher -WingetAvailable $wingetOk -Index ($i + 1) -Total $total
    $results.Add([pscustomobject]@{ Name = $launcher.Name; Status = $status })
}

Show-Summary -Results $results
Write-Log '=== Fin de ejecucion ===' -Level INFO -NoConsole

# En modo interactivo, evita que la ventana elevada por UAC se cierre de golpe.
if (-not $All) {
    Write-Host ''
    Read-Host 'Pulsa Enter para salir' | Out-Null
}
