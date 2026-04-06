# Currensee

Keep an overview of your World of Warcraft currencies across all your characters.

Updated for **WoW Midnight (patch 12.0.x)** — now tracks the full Dawncrests progression currency system.

## What It Tracks

| Currency | Slash Command |
|---|---|
| Adventurer Dawncrest | `/cs adventurer` |
| Veteran Dawncrest | `/cs veteran` |
| Champion Dawncrest | `/cs champion` |
| Hero Dawncrest | `/cs hero` |
| Myth Dawncrest | `/cs myth` |
| Equipped Item Level | `/cs ilvl` |

Data is stored account-wide, so currencies update whenever you log into any character.

## Install

1. Download and extract to your `World of Warcraft/_retail_/Interface/AddOns/` folder as `Currensee/`
2. Restart WoW or reload the UI (`/reload`)

## Usage

```
/cs all         — Show all currencies and item levels across characters
/cs myth        — Show Myth Dawncrest counts, sorted highest first
/cs ilvl        — Show equipped item level across characters
/cs reset       — Clear all saved data
```

`/currensee` also works as an alias for `/cs`.

## How It Works

On login and logout, the addon snapshots your current currency counts and item level into account-wide SavedVariables (`Currensee_Data`). This means you only need to have logged into a character once for it to appear in the output.

## Version History

- **2.0.0** — Full rewrite for WoW Midnight. Replaced BfA systems (Azerite, Prismatic Manapearls, War Resources) with the Dawncrests currency system. Cleaned up architecture: proper namespace, single SavedVariables table, dynamic command routing.
- **1.0.0** — Original release for Battle for Azeroth (patch 8.3).
