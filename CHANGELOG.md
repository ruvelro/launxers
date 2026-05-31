# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato se basa en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto sigue [Versionado Semántico](https://semver.org/lang/es/).

## [No publicado]

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

[No publicado]: https://github.com/ruvelro/launxers/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/ruvelro/launxers/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/ruvelro/launxers/releases/tag/v1.0.0
