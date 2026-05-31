<div align="center">

# 🎮 launxers

### Instala **todos** tus launchers de videojuegos en Windows, en silencio y de un tirón.

*Un solo script de PowerShell. winget como motor, descarga directa de respaldo. Cero asistentes, cero clics de "Siguiente, Siguiente, Siguiente".*

![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)
![winget](https://img.shields.io/badge/winget-powered-blueviolet)
![Versión](https://img.shields.io/badge/versión-1.0.0-success)
![Licencia](https://img.shields.io/badge/licencia-MIT-green)

</div>

---

## ✨ ¿Qué hace?

Montas un PC nuevo, formateas, o simplemente quieres tener todas tus tiendas de juegos listas sin perder media tarde. **launxers** lo resuelve:

- 🤫 **Instalación silenciosa de verdad** — sin asistentes ni ventanas de "Siguiente".
- 📦 **winget primero** — usa el gestor de paquetes nativo de Windows, siempre actualizado.
- 🛟 **Fallback automático** — si winget no está o un paquete falla, descarga el instalador oficial y lo lanza con flags silenciosos.
- 🧩 **Menú interactivo** — elige cuáles quieres… o instala **todos** con un flag.
- 🛡️ **Auto-elevación UAC** — se relanza como Administrador solo cuando hace falta.
- 📝 **Log + tabla resumen** — sabes exactamente qué se instaló y qué falló.

---

## 🚀 Inicio rápido

Abre **PowerShell** y ejecuta:

```powershell
powershell -ExecutionPolicy Bypass -File .\Install-GameLaunchers.ps1
```

Aparecerá el menú. Escribe los números que quieras (`1 3 5`), `A` para **todos** o `Q` para salir. Eso es todo. ☕

> 💡 ¿Quieres instalarlo **todo** sin preguntar? Añade `-All`.

---

## 🕹️ Uso

| Comando | Qué hace |
|---|---|
| `.\Install-GameLaunchers.ps1` | Menú interactivo para elegir launchers. |
| `.\Install-GameLaunchers.ps1 -All` | Instala **toda** la lista sin interacción. |
| `.\Install-GameLaunchers.ps1 -List` | Muestra el catálogo y sale (no instala nada). |
| `.\Install-GameLaunchers.ps1 -NoFallback` | Usa **solo** winget, sin descarga directa de respaldo. |

Recuerda anteponer `powershell -ExecutionPolicy Bypass -File` si tu política de ejecución lo requiere.

---

## 📚 Launchers soportados

| # | Launcher | Motor principal (winget) | Notas |
|---|---|---|---|
| 1 | **Steam** | `Valve.Steam` | Cliente de Valve. |
| 2 | **Epic Games** | `EpicGames.EpicGamesLauncher` | Instalador MSI. |
| 3 | **EA app** | `ElectronicArts.EADesktop` | Sustituto de Origin. Solo winget. |
| 4 | **Origin (legacy)** | `ElectronicArts.Origin` | Cliente antiguo de EA. |
| 5 | **Ubisoft Connect** | `Ubisoft.Connect` | Antes Uplay. |
| 6 | **GOG Galaxy** | `GOG.Galaxy` | Juegos sin DRM. |
| 7 | **Battle.net** | `Blizzard.BattleNet` | Blizzard. Solo winget. |
| 8 | **Amazon Games** | `Amazon.Games` | Incluye Prime Gaming. |
| 9 | **Rockstar Launcher** | `RockstarGames.RockstarGamesLauncher` | GTA, Red Dead… |
| 10 | **Xbox / Game Pass** | `9MV0B5HZVK9Z` (Store) | App Xbox vía Microsoft Store. |
| 11 | **itch.io** | `ItchIo.Itch` | Juegos indie. |
| 12 | **Playnite** | `Playnite.Playnite` | Meta-launcher: unifica todas tus bibliotecas. |
| 13 | **Paradox Launcher** | `ParadoxInteractive.ParadoxLauncher` | Paradox Interactive. |

---

## 🧰 Requisitos

- **Windows 10 (1809+) o Windows 11.**
- **winget** (App Installer) — viene preinstalado en Windows 11 y en Windows 10 actualizado. Si falta, el script te ofrece abrir Microsoft Store para instalarlo, y mientras tanto usa el fallback de descarga directa.
- Ejecutar como **Administrador** (el script se auto-eleva con UAC).

---

## ❓ FAQ

<details>
<summary><b>¿Por qué algunos launchers solo se instalan por winget?</b></summary>

**EA app** y **Battle.net** tienen instaladores cuya instalación silenciosa por descarga directa es muy frágil y cambia a menudo. winget los gestiona de forma fiable, así que para ellos se prioriza ese camino.
</details>

<details>
<summary><b>¿Inicia sesión en mis cuentas?</b></summary>

No. launxers **solo instala los clientes**. Iniciar sesión en Steam, Epic, etc. lo haces tú la primera vez que los abras.
</details>

<details>
<summary><b>¿Dónde está el registro de lo que hizo?</b></summary>

En `Install-GameLaunchers.log`, junto al script. Cada ejecución añade entradas con fecha/hora.
</details>

<details>
<summary><b>¿Se puede volver a ejecutar sin problemas?</b></summary>

Sí. Es idempotente: winget detecta lo ya instalado y lo omite.
</details>

---

## 🖼️ Demo

> _(Próximamente: captura/GIF del menú interactivo en acción.)_

---

## 🤝 Contribuir

¿Quieres añadir un launcher o ajustar un flag? Lee **[AGENTS.md](AGENTS.md)** — explica la estructura del catálogo y las reglas de mantenimiento (actualizar docs + CHANGELOG en cada cambio).

---

## 📜 Licencia

[MIT](LICENSE) · Historial de cambios en **[CHANGELOG.md](CHANGELOG.md)**.

<div align="center">

*Hecho para que jugar empiece antes. 🎮*

</div>
