# Currensee

Keep an overview of your World of Warcraft currencies across all your characters.

Updated for **WoW Midnight (patch 12.0.x)** — tracks all major currencies across every category.

## What It Tracks

**Dawncrests (Progression)**
Adventurer · Veteran · Champion · Hero · Myth

**Zone & World**
Voidlight Marl · Brimming Arcana · Unalloyed Abundance · Shard of Dundun · Luminous Dust · Remnant of Anguish · Angler Pearls

**Delves**
Coffer Key Shards · Undercoin

**PvP**
Conquest · Honor

**Professions** (Artisan's Moxie)
Alchemy · Blacksmithing · Enchanting · Engineering · Herbalism · Inscription · Jewelcrafting · Leatherworking · Mining · Skinning · Tailoring

**Events & Seasonal**
Residual Memories · Twilight's Blade Insignia

**Item Level** (equipped, across all alts)

---

## Install

1. Download and extract to `World of Warcraft/_retail_/Interface/AddOns/` as `Currensee/`
2. Restart WoW or `/reload`

---

## Usage

```
/cs              — Everything, grouped by category
/cs crests       — All Dawncrest tiers
/cs zone         — Zone & world currencies
/cs delves       — Delves currencies
/cs pvp          — Honor & Conquest
/cs professions  — All Artisan's Moxie currencies
/cs events       — Seasonal & event currencies
/cs ilvl         — Equipped item level
/cs myth         — Any individual currency by short name
/cs reset        — Clear all saved data
```

`/currensee` also works as an alias for `/cs`.

---

## How It Works

On login and logout, the addon snapshots all currency counts and item level into account-wide SavedVariables (`Currensee_Data`). Log in on each character once to populate it — after that, `/cs` gives you a full cross-character overview without switching.

---

## Version History

- **2.1.0** — Full currency coverage: all zone, Delves, PvP, all 11 profession Moxie currencies, and seasonal currencies. Category-based commands (/cs crests, /cs pvp, etc.).
- **2.0.0** — Full rewrite for WoW Midnight. Replaced BfA systems with Dawncrests. Proper namespace, single SavedVariables table.
- **1.0.0** — Original release for Battle for Azeroth (patch 8.3).
