<p align="center"><img src="Media/logo.png" width="160" alt="Baganator - Reagent Bag Category"></p>

# Baganator - Reagent Bag Category

A small plugin for [Baganator](https://www.curseforge.com/wow/addons/baganator) that shows **everything inside your reagent bag as its own category** in Baganator's category view – no matter which default category the items would otherwise belong to.

## Features

- **Own category for the reagent bag** – herbs, ores, cloth etc. from the reagent bag stay together instead of being spread across "Trade Goods", "Consumables", …
- **Created automatically** on first start in the current Baganator profile and placed at the top (after "Recent items", if present)
- **Fully customisable** – rename, recolour or move it in Baganator's category settings like any other category
- **No changes to Baganator or Syndicator** – the plugin hooks into the category view and uses Baganator's own "added items" mechanism
- **Nothing is stored permanently** – the item assignments are temporary and removed on logout, so Baganator's settings stay clean
- **English and German** localisation

## Requirements

- [Baganator](https://www.curseforge.com/wow/addons/baganator)
- [Syndicator](https://www.curseforge.com/wow/addons/syndicator)

## Installation

1. Download the latest release zip (or the CurseForge file).
2. Extract it into `World of Warcraft\_retail_\Interface\AddOns\`, so the folder structure is:
   ```
   Interface\AddOns\Baganator_ReagentBagCategory\Baganator_ReagentBagCategory.toc
   ```
3. Restart the game or type `/reload`.

To install from source, clone the repository into a folder named exactly `Baganator_ReagentBagCategory` – WoW only loads the addon if the folder name matches the `.toc` file.

## Usage

Switch Baganator's backpack to the **category view** – the "Reagent Bag" category appears automatically.

| Command | Description |
|---|---|
| `/brk` | Open the settings and show the current status |
| `/brk on` | Show the reagent bag as its own category |
| `/brk off` | Sort reagent bag items into the normal categories again |
| `/brk create` | (Re)create the category in the current Baganator profile |
| `/brk help` | List the commands in chat |
| `/reagentbag` | Same as `/brk` (German alias: `/reagenzientasche`) |

Settings are also available under **Options → AddOns → Baganator - Reagent Bag Category**.

**Notes**
- Keep the category's priority high, otherwise other categories may claim the items first.
- The category is only created automatically once per profile. If you delete it, use `/brk create` or the button in the settings to get it back.
- Works for the currently logged in character, not in the offline view of other characters.

## Project Structure

| File | Purpose |
|---|---|
| `Baganator_ReagentBagCategory.toc` | Addon metadata and load order |
| `Main.lua` | Hook into Baganator's category view, category creation, settings panel, slash commands |
| `Media/logo.tga` | Logo used in the addon list, settings panel and chat |
| `Media/logo.png` | Logo for the README and CurseForge (not part of the addon package) |

Settings are stored in the saved variable `BAGANATOR_RBC_CONFIG`.

## Releasing

Releases are built by the [BigWigs packager](https://github.com/BigWigsMods/packager) via GitHub Actions (`.github/workflows/release.yml`):

```sh
git tag v1.0.0
git push origin v1.0.0
```

This builds the zip, creates a GitHub release and uploads it to CurseForge. Tags containing `alpha` or `beta` are released as alpha/beta. The version in the `.toc` is taken from the tag. The CurseForge upload needs `## X-Curse-Project-ID` in the `.toc` and the repository secret `CF_API_KEY`.
