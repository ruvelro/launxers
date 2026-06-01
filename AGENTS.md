# AGENTS.md

Guía para agentes de IA y colaboradores humanos que trabajen en **launxers**.
Este es el documento de referencia del proyecto. `CLAUDE.md` solo remite aquí.

---

## 🎯 Propósito del proyecto

Un único script de PowerShell (`Install-GameLaunchers.ps1`) que instala, en modo
**silencioso**, los principales launchers de videojuegos para Windows. Motor
principal: **winget**. Respaldo: **descarga directa** del instalador oficial con
flags silenciosos.

---

## 🗂️ Estructura del repositorio

| Archivo | Responsabilidad |
|---|---|
| `Install-GameLaunchers.ps1` | Script principal: catálogo, menú, instalación, log, resumen. |
| `README.md` | Documentación de usuario (qué hace, cómo se usa, FAQ). |
| `AGENTS.md` | Este archivo: guía de desarrollo y reglas de mantenimiento. |
| `CLAUDE.md` | Puntero a `AGENTS.md`. No duplicar contenido aquí. |
| `CHANGELOG.md` | Historial de cambios (Keep a Changelog + SemVer). |
| `.gitignore` | Ignora logs e instaladores temporales. |
| `LICENSE` | Licencia MIT. |

---

## 🧱 Arquitectura del script

Secciones, en orden, dentro de `Install-GameLaunchers.ps1`:

1. **Cabecera de ayuda** (`<# .SYNOPSIS ... #>`) + `param()` (`-All`, `-List`, `-NoFallback`, `-Update`, `-DryRun`).
2. **Constantes**: `$ScriptVersion`, `$ScriptRoot`, `$LogFile`.
3. **Catálogo `$Launchers`**: array de `pscustomobject` (ver abajo).
4. **Utilidades**: `Write-Log`, `Write-Banner`.
5. **Auto-elevación**: `Test-Admin`, `Invoke-SelfElevation`.
6. **winget**: `Test-Winget`, `Initialize-Winget`, `Invoke-Winget` (ejecuta winget y registra su salida sin líneas vacías), `Test-InstalledNow` (comprobación en caliente), `Test-LauncherInstalled` (detección cacheada para el catálogo). Listas `$script:WingetBenignCodes` / `$script:WingetRebootCodes` para clasificar exit codes.
7. **Instalación/actualización**: `Install-ViaWinget` (con verificación post-fallo), `Update-ViaWinget`, `Install-ViaFallback`, `Install-Launcher` (gestiona `-Update`, `-DryRun` y el contador de progreso).
8. **UI**: `Show-Catalog` (muestra estado `[OK]`), `Select-Launchers`, `Show-Summary`.
9. **MAIN**: flujo principal al final del archivo.

### Cómo añadir un launcher

Añade un `pscustomobject` al array `$Launchers` con estos campos:

| Campo | Descripción |
|---|---|
| `Name` | Nombre visible en menú/resumen. |
| `WingetId` | ID en el repositorio de winget (motor principal). Verifícalo en winget-pkgs. |
| `WingetSource` | `'winget'` (por defecto) o `'msstore'` (apps de la Store). |
| `WingetExtraArgs` | (Opcional) Argumentos extra para winget, p. ej. `@('--location', '<ruta>')` cuando el paquete lo exige (Battle.net). |
| `FallbackUrl` | URL directa del instalador oficial, o `$null` si no hay. |
| `FallbackArgs` | Array de flags silenciosos (`@('/S')`, `@('/quiet','/norestart')`...). |
| `Notes` | Aclaración breve mostrada en el catálogo. |

Convención: si la instalación silenciosa directa de un launcher es frágil
(p. ej. EA app, Battle.net), deja `FallbackUrl = $null` y anótalo en `Notes`
para que dependa solo de winget.

---

## 🎨 Convenciones de estilo

- PowerShell compatible con **5.1** (Windows PowerShell) y 7+.
- Verbos aprobados en funciones (`Get-`, `Test-`, `Install-`, `Show-`, `Invoke-`).
- Sin acentos en strings de consola/log para evitar problemas de codificación en
  consolas heredadas; los acentos quedan para la documentación Markdown.
- Mensajes de usuario en **español**; nombres de funciones/variables en inglés.

---

## ✅ Verificación

Desarrollo en macOS, ejecución en Windows. Pasos recomendados:

1. **Estático**: revisar sintaxis; si hay PowerShell Core, `Invoke-ScriptAnalyzer`.
2. **En Windows 10/11**:
   - `winget search <nombre>` para confirmar cada `WingetId` del catálogo.
   - `.\Install-GameLaunchers.ps1 -List` → comprueba que el catálogo se imprime.
   - Probar primero un launcher ligero (Playnite, itch.io).
   - Probar el camino de fallback (p. ej. con un equipo sin winget).
   - `-All` en una VM para validar el lote completo + log + resumen.

---

## 📌 Reglas de mantenimiento (OBLIGATORIAS)

> Con **cada cambio funcional** en el proyecto:
>
> 1. **Actualiza la documentación afectada** — `README.md` y/o este `AGENTS.md`
>    (catálogo de launchers, flags, requisitos, FAQ...).
> 2. **Añade una entrada a `CHANGELOG.md`** siguiendo *Keep a Changelog*:
>    sección `[X.Y.Z] - AAAA-MM-DD` con la categoría correcta
>    (`Added` / `Changed` / `Fixed` / `Removed` / `Deprecated` / `Security`).
> 3. **Versiona con SemVer**: `MAJOR` (rupturas), `MINOR` (nuevas funciones,
>    p. ej. añadir un launcher), `PATCH` (correcciones).
> 4. **Sincroniza la versión** en `$ScriptVersion` (dentro del `.ps1`), en el
>    badge del `README.md` y en `CHANGELOG.md`.

Un cambio no se considera completo si la documentación y el changelog no reflejan
lo realizado.
