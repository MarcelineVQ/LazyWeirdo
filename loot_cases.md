# Loot Case Matrix

## Settings for all cases (unless noted)
- `general_boe_rule = GREED`
- `pass_greys = false`
- `mc_boe = NEED`, `mc_trash = OFF`
- Need whitelist: `Righteous Orb`
- Pass whitelist: `Bijou`
- Loot threshold: Rare (quality 2)

---

## Case 1: Solo, looting a mob in MC

| Item | Tooltip | Quality | Expected |
|------|---------|---------|----------|
| 12s 34c | coin | — | Loot |
| Runecloth | (no bind) | White | Loot |
| Dark Iron Ore | (no bind) | Common | Loot |
| Core Leather | (no bind) | Common | Loot |
| Destroyed Item | (no bind) | Grey | Loot |
| Fiery Core | BoE | Epic | Loot (solo) |
| Lava Core | BoE | Epic | Loot (solo) |
| Vendorstrike | BoE | Epic | Loot (solo) |
| Righteous Orb | BoP | Epic | Loot (on need whitelist) |

---

## Case 2: Solo, `pass_greys = true`

| Item | Tooltip | Quality | Expected |
|------|---------|---------|----------|
| Destroyed Item | (no bind) | Grey | Skip (pass greys) |
| Runecloth | (no bind) | White | Loot |
| Righteous Orb | BoP | Epic | Loot (on need whitelist) |

---

## Case 3: 5-man group, group loot, threshold = Rare

| Item | Tooltip | Quality | Expected |
|------|---------|---------|----------|
| 8s 10c | coin | — | Loot |
| Runecloth | (no bind) | White | Loot (below threshold, no bind) |
| Silk Cloth | (no bind) | Common | Loot (below threshold, no bind) |
| Destroyed Item | (no bind) | Grey | Loot (below threshold) |
| Green Whelp Armor | BoE | Green | Skip (at threshold, roll will happen) |
| Lavishly Jeweled Ring | BoE | Blue | Skip (above threshold, roll) |
| Bijou | BoP | Green | Skip (on pass whitelist) |
| Righteous Orb | BoP | Epic | Loot (on need whitelist, bind confirm handles it) |
| Head of Broodlord | Quest Item | Epic | Loot (quest, personal) |

---

## Case 4: 5-man group, group loot, threshold = Epic

| Item | Tooltip | Quality | Expected |
|------|---------|---------|----------|
| Green Whelp Armor | BoE | Green | Loot (below threshold) |
| Lavishly Jeweled Ring | BoE | Blue | Loot (below threshold) |
| Vendorstrike | BoE | Epic | Skip (at threshold, roll) |
| Core Hound Tooth | BoP | Epic | Skip (BoP, not on whitelist, at threshold) |

---

## Case 5: Raid, group loot, threshold = Rare, in MC

| Item | Tooltip | Quality | Expected |
|------|---------|---------|----------|
| 12s 34c | coin | — | Loot |
| Runecloth | (no bind) | White | Loot (no bind, below threshold) |
| Dark Iron Ore | (no bind) | Common | Loot (no bind, below threshold) |
| Fiery Core | BoE | Epic | Skip (above threshold, roll via mc_boe) |
| Lava Core | BoE | Epic | Skip (above threshold, roll via mc_boe) |
| Lavashard Axe | BoP, on mc_trash | Epic | Skip (mc_trash = OFF, BoP not on whitelist) |
| Vendorstrike | BoE | Epic | Skip (above threshold, roll) |
| Core Hound Tooth | BoP | Epic | Skip (BoP not on whitelist) |
| Righteous Orb | BoP | Epic | Loot (on need whitelist, bind confirm) |
| Head of Broodlord | Quest Item | Epic | Loot (quest, personal) |
| Bijou | BoP | Green | Skip (on pass whitelist) |

---

## Case 6: Raid, group loot, threshold = Rare, in MC, `mc_trash = GREED`

| Item | Tooltip | Quality | Expected |
|------|---------|---------|----------|
| Fiery Core | BoE | Epic | Skip (above threshold, roll via mc_boe=GREED) |
| Lava Core | BoE | Epic | Skip (above threshold, roll via mc_boe=GREED) |
| Lavashard Axe | BoP, on mc_trash | Epic | Skip (above threshold, roll via mc_trash=GREED) |
| Vendorstrike | BoE | Epic | Skip (above threshold, roll) |
| Runecloth | (no bind) | White | Loot |

---

## Case 7: Raid, master loot, in MC

| Item | Tooltip | Quality | Expected |
|------|---------|---------|----------|
| 12s 34c | coin | — | Loot |
| Runecloth | (no bind) | White | ML controls — skip |
| Dark Iron Ore | (no bind) | Common | ML controls — skip |
| Fiery Core | BoE | Epic | ML controls — skip |
| Vendorstrike | BoE | Epic | ML controls — skip |
| Lavashard Axe | BoP, on mc_trash | Epic | ML controls — skip |
| Core Hound Tooth | BoP | Epic | ML controls — skip |
| Head of Broodlord | Quest Item | Epic | Loot (quest, personal) |
| Righteous Orb | BoP | Epic | ML controls — skip |
| Bijou | BoP | Green | Skip (on pass whitelist) |
| Destroyed Item | (no bind) | Grey | ML controls — skip |

---

## Case 8: Raid, master loot, `pass_greys = true`

| Item | Tooltip | Quality | Expected |
|------|---------|---------|----------|
| Destroyed Item | (no bind) | Grey | Skip (pass greys, before ML check) |
| Head of Broodlord | Quest Item | Epic | Loot (quest, personal) |

---

## Case 9: Looting a chest (container), in group

| Item | Tooltip | Quality | Expected |
|------|---------|---------|----------|
| Runecloth | (no bind) | White | Loot (container) |
| Green Whelp Armor | BoE | Green | Loot (container, bind confirm if BoP) |
| Bijou | BoP | Green | Skip (on pass whitelist, checked before container) |
| Head of Broodlord | Quest Item | Epic | Loot (quest, before container check) |

---

## Case 10: Raid, NBG loot, threshold = Rare, outside any raid zone

| Item | Tooltip | Quality | Expected |
|------|---------|---------|----------|
| Runecloth | (no bind) | White | Loot (below threshold, no bind) |
| Random Green | BoE | Green | Skip (at threshold, roll) |
| Random Blue BoP | BoP | Blue | Skip (BoP, not on whitelist) |
| Random White Quest | Quest Item | White | Loot (quest, personal) |
| Righteous Orb | BoP | Epic | Loot (on need whitelist, bind confirm) |

---

## Roll cases (START_LOOT_ROLL, no tooltip scan available)

| Item | bop flag | Quality | On whitelist? | Expected roll |
|------|----------|---------|---------------|---------------|
| Vendorstrike | false | Epic | No, in MC | mc_boe = NEED |
| Random BoE green | false | Green | No, outside raid | general_boe_rule = GREED |
| Core Hound Tooth | true | Epic | No | OFF (BoP, no whitelist) |
| Fiery Core | false | Epic | No, mc_boe applies | mc_boe = NEED |
| Lavashard Axe | true | Epic | On mc_trash (OFF) | OFF |
| Lavashard Axe | true | Epic | On mc_trash (GREED) | GREED |
| Righteous Orb | true | Epic | On need whitelist | NEED |
| Bijou | true | Green | On pass whitelist | PASS |
