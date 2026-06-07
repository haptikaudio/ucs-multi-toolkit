# UCS Multi Toolkit

**UCS Multi Toolkit** is a REAPER script for sound designers and editors working with the [Universal Category System (UCS)](https://universalcategorysystem.com/). It combines spacing, glue, normalization, UCS renaming, and rendering into one dockable workflow.

By [Haptik Audio](https://haptikaudio.com).

## Features

- **Workflow presets** — Clean Slate, variation stacks, dialogue/VO, SFX batch, and custom saves
- **Smart suggest** — Parse item names into UCS category, subcategory, and optional fields
- **Pre-flight checks** — Confirm pipeline/render before running (Enter / Esc)
- **REAPER render** — Export with `$item` or **region** output (`$region`)
- **Post-render import** — Place rendered files on the track below the source item
- **Keyboard shortcuts** — `S` suggest · `R` render · `P` pipeline

## Requirements

- **REAPER 6.0+** (tested on 6.x; region features use modern marker APIs)
- No SWS, ReaImGui, or other extensions required

## Installation

### ReaPack (recommended)

1. In REAPER: **Extensions → ReaPack → Import repositories**
2. Paste this URL and click **OK**:

   ```
   https://raw.githubusercontent.com/haptikaudio/ucs-multi-toolkit/main/index.xml
   ```

3. **Extensions → ReaPack → Browse packages**
4. Search for **UCS Multi Toolkit** (category: Workflow) and install.
5. Run from the Action List: search **UCS Multi Toolkit** (shortcut: **?** or **F4**).

ReaPack installs both the script and logo into `Scripts/Haptik Audio/Workflow/`. After install or update, open the Action List and filter by `UCS` — the script must have a `.lua` filename to appear automatically.

### Manual

1. Download `Workflow/UCS Multi Toolkit.lua` and `Workflow/Haptik_Audio_logo.png` from this repo.
2. Place **both files in the same folder** inside your REAPER Scripts directory, e.g.:
   - macOS: `~/Library/Application Support/REAPER/Scripts/UCS Multi Toolkit/`
   - Windows: `%APPDATA%\REAPER\Scripts\UCS Multi Toolkit\`
3. In REAPER: **Actions → Show action list → ReaScript → Load…**
4. Select `UCS Multi Toolkit.lua` and click **Run**.

### Docking

Use the **DOCK** button in the script window header, or assign the script to a toolbar/dock slot via the Actions list.

### Upgrading from `UCS Audio Tool.lua`

If you previously used the old single-file install:

1. Install the new folder as above.
2. Update your action shortcut to point at `UCS Multi Toolkit/UCS Multi Toolkit.lua`.
3. Remove the old `UCS Audio Tool.lua` when ready (a legacy redirect stub may still be present).

Your settings are stored under the `UCSAudioTool` ExtState section and will carry over.

## Quick start

1. Select one or more media items.
2. Load the **Clean Slate** preset (default).
3. Press **S** or **SUGGEST FROM NAME** to fill UCS fields from the item name.
4. Review the **Preview** bar — fix any validation warnings.
5. Run **SPACE + GLUE + NORM + RENAME** for the processing pipeline, or **RENDER** to export.

## Render modes

| Mode | How to use | Output name |
|------|------------|-------------|
| **Items** (default) | Select items, render | `$item` (take name) |
| **Regions** | Enable *Render regions*, click a region / time selection / items inside regions | `$region` (region name) |

**Note:** Post-render import matches **region names** when region render is enabled, not take names. Name regions accordingly, or disable post-import for region batches.

## Settings persistence

Workflow settings, presets, window size, and scroll position are saved automatically to REAPER's ExtState (`UCSAudioTool` / `UCSAudioToolPresets`).

## Support

- Issues: [GitHub Issues](https://github.com/haptikaudio/ucs-multi-toolkit/issues)
- Update the `@link` in the script header if your repo URL differs

## License

MIT — see [LICENSE](LICENSE).
