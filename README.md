# Currensee

Track every World of Warcraft currency across all your characters — from current Midnight Dawncrests to legacy currencies from every past expansion.

No hard-coded IDs. No patches needed. The addon reads your currency list directly from the game, so it works with every expansion automatically.

## Commands

```
/cs                      — Show all currencies across all characters
/cs <name>               — Search currencies by partial name (e.g. /cs dawncrest, /cs honor, /cs valor)
/cs char                 — Show all currencies for your current character
/cs char <name>          — Show all currencies for a specific character
/cs ilvl                 — Equipped item level across all characters
/cs reset                — Clear all saved data
```

**Examples:**
```
/cs myth                 — Find Myth Dawncrest counts across your alts
/cs trader               — Find Trader's Tender across your alts
/cs conquest             — Find Conquest across your alts
/cs char Arthas          — Show everything saved for a character named Arthas
```

## Install

1. Download and extract into `World of Warcraft/_retail_/Interface/AddOns/` as a folder named `Currensee`
2. Enable it in the AddOns list at character select
3. Log into each character — data is captured automatically on login and logout

## How It Works

On login and logout, Currensee walks your full currency list using `C_CurrencyInfo.GetCurrencyListInfo()` and saves every currency you currently hold into account-wide SavedVariables. This means:

- **All currencies are tracked automatically** — no list to maintain
- **Works across all expansions** — current and legacy currencies alike
- **Future-proof** — new currencies added in future patches are picked up with no addon update needed
- **Weekly cap tracking** — for currencies with weekly caps, shows earned this week vs. the cap

## Version History

- **2.0.0** — Full rewrite. Dynamic currency enumeration replaces hard-coded IDs. Now tracks every currency in the game across all expansions. Added character view, name search, and weekly cap display.
- **1.0.0** — Original release for Battle for Azeroth (patch 8.3). Tracked BfA-specific currencies only.
