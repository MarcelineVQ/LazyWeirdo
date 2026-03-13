# LazyWeirdo 1.8.0
Automatic loot rules for instances and groups. Have loot handle itself.
---
`/lazyweirdo` or `/lw` for in game options. `/lazyweirdo reset` or `/lw reset` to reset frame position.
Best used with [SuperWow](https://github.com/balakethelock/SuperWoW/) enabled.

### SuperWoW & Auto-loot
* LazyWeirdo handles all autolooting itself, deciding what to pick up based on your settings. If SuperAPI is detected, LazyWeirdo disables its built-in auto-loot setting to prevent conflicts.
* If you see "Already looted" messages, your client likely has a patch that enables auto-loot by default. Disable it and let LazyWeirdo handle looting instead to avoid this message.

### Raid Loot Options
* Per-raid loot rules with icon toggles for ZG, AQ20, MC, BWL, ES, AQ40, Naxx, and Kara.
* * Configure coins, bijous, idols, scarabs, mats, trash BoPs, and BoE items per raid.
* * General BoE rule for world and dungeon drops.

### Vendor Options
* Auto-buy reagent list. Specify items and quantities to automatically restock at vendors.
* * Individual items can be toggled on/off.
* Auto-sell specific items list.
* * Individual items can be toggled on/off.
* Auto-sell grey items.
* Auto-repair.

### Quality of Life Options
* Auto-accept invites from friends and guildmates.
* Auto-accept summons.
* Auto-accept resurrections.
* Auto-dismount and auto-stand.
* Auto-unshift for druids when their form disallows actions (outside of combat).
* Auto-accept Call to Arms weekly quests.
* Automation of many common gossip actions.
* Automatically turn in Bijou by clicking on Altar of Zanza.
* Combat plates: show enemy nameplates in combat, hide outside.
* Combat names: hide player, NPC, and own names in combat, restore when leaving.
* Raid untrack: automatically remove Find Herbs and Find Minerals tracking when entering a raid instance.

### Looting Options
* Autoloot behavior selection.
* Pass on greys option.
* Holy Water Only option for Stratholme chests.

> **Note:** If you see "Already looted" messages, your client likely has a patch that enables auto-loot by default. You don't need this with EasyLoot since it handles autolooting itself. You can disable the client-side auto-loot patch to avoid conflicts.

### Whitelists
* Whitelists for making specific items always roll need, greed, or pass. Includes BoP items.
* * Each whitelist can be toggled on/off independently.
* * Hunters would want to specify Doomshot here for example.
___
Get quest completion with [QuestRepeat](https://github.com/MarcelineVQ/QuestRepeat)

___
* Made by and for Weird Vibes of Turtle Wow
