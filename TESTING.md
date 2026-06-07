# Smoke test checklist

Run through this list on a **fresh REAPER profile** (or after clearing `UCSAudioTool` ExtState) before publishing a release.

## Install

- [ ] ReaPack import URL loads: `https://raw.githubusercontent.com/haptikaudio/ucs-multi-toolkit/main/index.xml`
- [ ] ReaPack install places script + logo in the same folder
- [ ] Both `UCS Multi Toolkit.lua` and `Haptik_Audio_logo.png` load without errors
- [ ] Logo appears in the window header
- [ ] Footer shows `v1.0.0 · By Haptik Audio`

## Window

- [ ] Floating window opens and resizes
- [ ] Dock / undock works; header and status bar remain usable
- [ ] Main panel scrolls smoothly with mouse wheel

## Presets

- [ ] **Clean Slate** is first preset and clears UCS fields
- [ ] Built-in presets load expected spacing/normalize values
- [ ] Save / delete user preset works

## Suggest & naming

- [ ] **S** fills cat/sub from a UCS-style item name
- [ ] Multi-word subcategory preview has no spaces (uses underscores)
- [ ] Long preview and input text stay clipped inside fields
- [ ] **Apply UCS name** renames selected item(s)

## Pipeline

- [ ] Pre-flight opens; **Run** / **Cancel** and Enter / Esc work
- [ ] Pre-flight buttons visible when docked on a short panel
- [ ] Pipeline spaces, glues, normalizes (if enabled), and renames

## Render

- [ ] Item render produces file with take-based name
- [ ] Region render works with clicked region / time selection
- [ ] Post-render import places file on track below (when enabled)
- [ ] Export root browse sets folder correctly

## Persistence

- [ ] Close and reopen script — settings and preset index restored
- [ ] Window size remembered
