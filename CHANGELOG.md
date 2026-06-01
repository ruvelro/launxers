# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato se basa en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto sigue [Versionado Semántico](https://semver.org/lang/es/).

## [No publicado]

## [1.1.6] - 2026-06-01

### Fixed
- **Selección de un solo launcher** no funcionaba: al elegir un único número, la
  lista de un elemento se "desenvolvía" a un escalar y el bucle de instalación no
  lo recorría. Ahora la selección se fuerza a array con `@(...)`.
- **Bloqueo tras instalar Battle.net**: su instalador es un *bootstrapper* que no
  termina (lanza la app y sigue vivo), por lo que `Start-Process -Wait` se quedaba
  esperando para siempre. Nuevo campo `FallbackNoWait`: se lanza el instalador y
  el script continúa sin esperar (y sin borrar el archivo que sigue en uso).

### Added
- Campo de catálogo `FallbackNoWait` para instaladores que no finalizan su
  proceso (bootstrappers).

## [1.1.5] - 2026-06-01

### Fixed
- **Fallback roto** para launchers con `FallbackArgs` vacíos: `Start-Process
  -ArgumentList @()` lanzaba "argumento null" y la descarga directa fallaba.
  Ahora solo se pasa `-ArgumentList` cuando hay flags.
- **Battle.net**: `--ignore-security-hash` provocaba `INVALID_CL_ARGUMENTS`
  porque winget **no puede saltarse el hash mismatch estando elevado como
  Administrador** (limitación conocida de winget-cli). Battle.net pasa a
  instalarse **directamente desde el instalador oficial** de Blizzard, saltándose
  winget (nuevo campo de catálogo `SkipWinget`).

### Added
- Campo de catálogo `SkipWinget`: fuerza a un launcher a instalarse por descarga
  directa, omitiendo winget. `-Update` lo informa como no soportado para esos.

## [1.1.4] - 2026-06-01

### Fixed
- **Battle.net** seguía fallando con `INSTALLER_HASH_MISMATCH` pese a `--force`:
  ahora se añade también `--ignore-security-hash`, y como red de seguridad se
  configura una **descarga directa del instalador oficial** de Blizzard
  (`getInstallerForGame`) por si winget no consigue instalarlo.

### Changed
- Descripción de Battle.net en el catálogo simplificada a "Cliente de Blizzard."
- Nueva entrada de FAQ en el README explicando que Battle.net puede no ser 100%
  desatendido.

## [1.1.3] - 2026-06-01

### Fixed
- **Bloqueo en consolas elevadas por UAC**: al capturar la salida de `winget`
  desde una consola recién elevada, el script se quedaba colgado en la pantalla
  "Launchers disponibles" (durante `winget list`). Ahora todas las llamadas a
  winget (detección de instalados e instalación/actualización) se ejecutan en
  *jobs* en segundo plano sin consola, con timeout de seguridad, de modo que
  nunca pueden bloquear el script.

### Changed
- La detección de estado del catálogo (`Initialize-WingetListCache`) corre en un
  job con límite de 25 s; si no responde, el menú se muestra sin marcadores
  `[OK]` y la ejecución continúa.
- `Invoke-Winget` admite `-TimeoutSeconds` (1200 s por defecto; 60 s para las
  comprobaciones de estado) y añade `--accept-source-agreements` a las consultas.

## [1.1.2] - 2026-06-01

### Fixed
- **Battle.net** fallaba con `INSTALLER_HASH_MISMATCH` (0x8A150011): el
  bootstrapper online de Blizzard cambia con frecuencia y el hash del manifiesto
  de winget queda obsoleto. Se añade `--force` a sus `WingetExtraArgs` para
  anular la comprobación de hash (además del `--location` ya existente).

## [1.1.1] - 2026-06-01

### Fixed
- `Write-Log` fallaba con las líneas vacías que emite winget (spam de errores
  rojos en consola). Ahora se filtran las líneas en blanco y el parámetro acepta
  cadena vacía (`Invoke-Winget`, `[AllowEmptyString()]`).
- Corregido el winget ID de **Rockstar Games Launcher**:
  `RockstarGames.RockstarGamesLauncher` → `RockstarGames.Launcher` (el anterior
  daba `NO_APPLICATIONS_FOUND`). Eliminada su URL de fallback (404, no estable).
- **Battle.net** fallaba con `INSTALL_LOCATION_REQUIRED`: ahora se pasa
  `--location` mediante el nuevo campo de catálogo `WingetExtraArgs`.

### Added
- Clasificación ampliada de códigos de salida de winget: se reconocen como
  correctos los de "ya instalado" (`PACKAGE_ALREADY_INSTALLED`,
  `INSTALL_ALREADY_INSTALLED`, `INSTALL_DOWNGRADE`) y los de reinicio pendiente
  (estado `Instalado (requiere reinicio)`).
- **Verificación post-fallo** (`Test-InstalledNow`): si winget devuelve error
  pero el paquete acaba presente, se marca como instalado.
- Notas y FAQ sobre el error de certificado de la app Xbox (problema de la fuente
  msstore, no del script) y sobre el estado de reinicio pendiente.

## [1.1.0] - 2026-05-31

### Added
- Flag `-Update`: actualiza (winget upgrade) los launchers seleccionados que ya
  estén instalados, con función `Update-ViaWinget`.
- Flag `-DryRun`: simula la instalación o actualización sin tocar el sistema (y
  sin solicitar permisos de Administrador).
- Detección de launchers ya instalados (`Test-LauncherInstalled`, con caché de
  `winget list`): el catálogo y el menú muestran un indicador `[OK]`.
- Contador de progreso `[i/N]` durante el proceso de instalación/actualización.

### Removed
- Launchers **Origin (legacy)** y **Paradox Launcher** del catálogo.

## [1.0.0] - 2026-05-31

### Added
- Script principal `Install-GameLaunchers.ps1` para instalar launchers de
  videojuegos en Windows en modo silencioso.
- Motor de instalación basado en **winget** con **fallback** a descarga directa
  del instalador oficial (flags silenciosos) cuando winget no está disponible o
  un paquete falla.
- **Menú interactivo** de selección, más flags `-All` (instalar todo), `-List`
  (mostrar catálogo) y `-NoFallback` (solo winget).
- **Auto-elevación UAC**: el script se relanza como Administrador si es necesario.
- **Registro** en `Install-GameLaunchers.log` y **tabla resumen** del resultado
  por launcher.
- Catálogo de 13 launchers: Steam, Epic Games, EA app, Origin (legacy),
  Ubisoft Connect, GOG Galaxy, Battle.net, Amazon Games, Rockstar Games Launcher,
  Xbox / Game Pass, itch.io, Playnite y Paradox Launcher.
- Documentación del proyecto: `README.md` (guía de usuario), `AGENTS.md` (guía de
  desarrollo y reglas de mantenimiento), `CLAUDE.md` (puntero a `AGENTS.md`),
  `LICENSE` (MIT) y este `CHANGELOG.md`.

[No publicado]: https://github.com/ruvelro/launxers/compare/v1.1.6...HEAD
[1.1.6]: https://github.com/ruvelro/launxers/compare/v1.1.5...v1.1.6
[1.1.5]: https://github.com/ruvelro/launxers/compare/v1.1.4...v1.1.5
[1.1.4]: https://github.com/ruvelro/launxers/compare/v1.1.3...v1.1.4
[1.1.3]: https://github.com/ruvelro/launxers/compare/v1.1.2...v1.1.3
[1.1.2]: https://github.com/ruvelro/launxers/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/ruvelro/launxers/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/ruvelro/launxers/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/ruvelro/launxers/releases/tag/v1.0.0
