-- || Made by and for Weird Vibes of Turtle WoW || --

local DEV_MODE = false -- set to true to keep config frame open on reload

local function print(msg)
  DEFAULT_CHAT_FRAME:AddMessage(msg)
end

local function debug_print(msg)
  if DEBUG then DEFAULT_CHAT_FRAME:AddMessage(msg) end
end

local function el_print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cffffff00LazyWeirdo:|r "..msg)
end

-- Addon ---------------------

-- /// Util functions /// --

local function ItemLinkToName(link)
  if ( link ) then
    return gsub(link,"^.*%[(.*)%].*$","%1");
  end
end

local function PostHookFunction(original,hook)
  return function(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10)
    original(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10)
    hook(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10)
  end
end

local function InGroup()
  return (GetNumPartyMembers() + GetNumRaidMembers() > 0)
end

local function PlayerCanRaidMark()
  return InGroup() and (IsRaidOfficer() or IsPartyLeader())
end

-- You may mark when you're a lead, assist, or you're doing soloplay
local function PlayerCanMark()
  return PlayerCanRaidMark() or not InGroup()
end

local function TitleCase(str)
  return (string.gsub(str, "(%a)([%a']*)", function(first, rest)
    return string.upper(first) .. rest
  end))
end

-- lazypigs
function IsGuildMate(name)
	if IsInGuild() then
		local ngm = GetNumGuildMembers()
		for i=1, ngm do
			n, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName = GetGuildRosterInfo(i);
			if strlower(n) == strlower(name) then
			  return true
			end
		end
	end
	return nil
end

-- lazypigs
function IsFriend(name)
	for i = 1, GetNumFriends() do
    -- print(GetFriendInfo(i))
    -- print(name)

		if strlower(GetFriendInfo(i)) == strlower(name) then
			return true
		end
	end
	return nil
end



------------------------------
-- Vars
------------------------------

local LazyWeirdo = CreateFrame("Frame","LazyWeirdo")

local binds = {}
local ITEM_COLOR = "|cff88bbdd"

------------------------------
-- Constants (single table = one upvalue)
------------------------------

local C = {
  -- Loot mode values
  OFF   = -1,
  PASS  = 0,
  NEED  = 1,
  GREED = 2,

  -- Tooltip title color (WoW standard gold)
  TOOLTIP_R       = 1,
  TOOLTIP_G       = 0.82,
  TOOLTIP_B       = 0,

  -- Config frame
  FRAME_W         = 260,
  FRAME_H         = 325,

  -- Grid layout (main config panel)
  GRID_START_Y    = -52,         -- first grid row y offset on main panel
  GRID_ROW_HEIGHT = 28,          -- vertical spacing per grid row
  GRID_LEFT       = 20,          -- x position of grid labels
  GRID_ROW_H      = 20,          -- grid row button height
  ICON_COL        = 65,          -- x position of icon column (arrow / Other icon)

  -- Icons and highlights
  ICON_SIZE       = 24,          -- loot mode icon dimensions
  ICON_HIGHLIGHT  = 36,          -- glow border around popup icons
  ICON_SPACING    = 28,          -- horizontal gap between popup icons
  ARROW_SIZE      = 28,          -- arrow texture size
  DIM_ALPHA       = 0.3,         -- inactive icon vertex color
  GLOW_ALPHA      = 0.8,         -- highlight glow alpha

  -- Popup layout (raid category popup)
  MAX_POPUP_ROWS  = 0,           -- computed from raid_config after it's defined
  ROW_HEIGHT      = 26,          -- vertical spacing per popup row
  ROW_START_Y     = -28,         -- first popup row y offset (below title)
  POPUP_PAD       = 10,          -- popup internal padding
  POPUP_TITLE_Y   = -10,         -- popup title y offset
  POPUP_ANCHOR_X  = 8,           -- popup x offset from anchor
  POPUP_ANCHOR_Y  = 4,           -- popup y offset from anchor
  SEPARATOR_GAP   = 4,           -- extra gap before separator rows (e.g. Other)

  -- Dropdown positioning
  DROPDOWN_OFFSET = 210,         -- UIDropDownMenu x correction factor
  DROPDOWN_WIDTH  = 110,         -- standard dropdown width

  -- Static popup edit-box dimensions
  EDITBOX_BASE_W    = 240,       -- edit box width when expanded
  EDITBOX_DEFAULT_W = 130,       -- edit box width when collapsed
  POPUP_BASE_W      = 420,       -- popup width when expanded
  POPUP_DEFAULT_W   = 320,       -- popup width when collapsed
  BORDER_TEX_W      = 256,       -- border texture base width for tex coords
}

-- These depend on the values above, so they're set after the table
C.MODE_ORDER    = { C.NEED, C.GREED, C.PASS, C.OFF }
C.NUM_LOOT_MODES = table.getn(C.MODE_ORDER)

-- Local aliases for brevity (used heavily in loot logic)
local OFF, PASS, NEED, GREED = C.OFF, C.PASS, C.NEED, C.GREED

------------------------------
-- Table Functions
------------------------------

local function elem(t,item)
  for _,k in pairs(t) do
    if item == k then
      return true
    end
  end
  return false
end

local function fuzzy_elem(t,item)
  if type(item) == "string" then
    item = string.lower(item)
    for _,v in pairs(t) do
      local name = type(v) == "table" and v.name or v
      local enabled = type(v) ~= "table" or v.enabled ~= false
      if enabled and string.find(string.lower(name),item,nil,true) then
        return true
      end
    end
  end
  return elem(t,item)
end

local function key(t,key)
  for k,_ in pairs(t) do
    if item == k then
      return true
    end
  end
  return false
end

local function tsize(t)
  local c = 0
  for _ in pairs(t) do c = c + 1 end
  return c
end

function deepcopy(original)
  local copy = {}
  for k, v in pairs(original) do
      if type(v) == "table" then
          copy[k] = deepcopy(v)  -- Recursively copy nested tables
      else
          copy[k] = v
      end
  end
  return copy
end

-- Function to return an iterator that sorts a table by its keys (low to high)
function ixpairs(t)
  -- Create a list of keys
  local keys = {}
  for k in pairs(t) do
      table.insert(keys, k)
  end

  -- Sort the keys
  table.sort(keys)

  -- Iterator function
  local i = 0
  return function()
      i = i + 1
      local key = keys[i]
      if key then
          return key, t[key]
      end
  end
end

-- don't skip trainer, they're often used for untalenting
-- skip spirit healer, it has a confirmation anyway
local gossips = { "taxi", --[["trainer",--]] "battlemaster", "vendor", "banker", "healer" }
local gossips_skip_lines = {
  bwl = "my hand on the orb",
  mc = "me to the Molten Core",
  wv = "Happy Winter Veil",
  nef1 = "made no mistakes",
  nef2 = "have lost your mind",
  rag1 = "challenged us and we have come",
  rag2 = "else do you have to say",
  ironbark = "Thank you, Ironbark",
  pusilin1 = "Game %? Are you crazy %?",
  pusilin2 = "Why you little",
  pusilin3 = "DIE!",
  meph = "Touch the Portal",
  kara = "Teleport me back to Kara",
  mizzle1 = "^I'm the new king%?",
  mizzle2 = "^It's good to be King!",
}

------------------------------
-- Loot Data
------------------------------

local zg_coin = {
  "Bloodscalp Coin",
  "Gurubashi Coin",
  "Hakkari Coin",
  "Razzashi Coin",
  "Sandfury Coin",
  "Skullsplitter Coin",
  "Vilebranch Coin",
  "Witherbark Coin",
  "Zulian Coin",
}

local zg_bijou = {
  "Blue Hakkari Bijou",
  "Bronze Hakkari Bijou",
  "Gold Hakkari Bijou",
  "Green Hakkari Bijou",
  "Orange Hakkari Bijou",
  "Purple Hakkari Bijou",
  "Red Hakkari Bijou",
  "Silver Hakkari Bijou",
  "Yellow Hakkari Bijou",
}

local zg_trash_bop = {
  "Sceptre of Smiting",
  "Blood Scythe",
}

local scarab = {
  "Bone Scarab",
  "Bronze Scarab",
  "Clay Scarab",
  "Crystal Scarab",
  "Gold Scarab",
  "Ivory Scarab",
  "Silver Scarab",
  "Stone Scarab",
}

local idol_aq20 = {
  "Azure Idol",
  "Onyx Idol",
  "Lambent Idol",
  "Amber Idol",
  "Jasper Idol",
  "Obsidian Idol",
  "Vermillion Idol",
  "Alabaster Idol",
}

local mc_mat = {
  "Fiery Core",
  "Lava Core",
  "Blood of the Mountain",
  "Essence of Fire",
  "Essence of Earth",
}

local idol_aq40 = {
  "Idol of the Sun",
  "Idol of Night",
  "Idol of Death",
  "Idol of the Sage",
  "Idol of Rebirth",
  "Idol of Life",
  "Idol of Strife",
  "Idol of War",
}

local scrap = {
  "Wartorn Chain Scrap",
  "Wartorn Cloth Scrap",
  "Wartorn Leather Scrap",
  "Wartorn Plate Scrap",
}

local mc_trash_bop = {
  "Lavashard Axe",
  "Boots of Blistering Flames",
  "Core Forged Helmet",
  "Lost Dark Iron Chain",
  "Shoulderpads of True Flight",
  "Ashskin Belt",
}

local bwl_trash_bop = {
  "Doom's Edge",
  "Band of Dark Dominion",
  "Essence Gatherer",
  "Draconic Maul",
  "Cloak of Draconic Might",
  "Boots of Pure Thought",
  "Draconic Avenger",
  "Ringo's Blizzard Boots",
  "Interlaced Shadow Jerkin",
}

local aq40_mount = {
  "Blue Qiraji Resonating Crystal",
  "Green Qiraji Resonating Crystal",
  "Yellow Qiraji Resonating Crystal",
}

local aq40_trash_bop = {
  "Shard of the Fallen Star",
  "Gloves of the Redeemed Prophecy",
  "Gloves of the Fallen Prophet",
  "Anubisath Warhammer",
  "Ritssyn's Ring of Chaos",
  "Neretzek, The Blood Drinker",
  "Gloves of the Immortal",
  "Garb of Royal Ascension",
}

local naxx_trash_bop = {
  "Ring of the Eternal Flame",
  "Misplaced Servo Arm",
  "Ghoul Skin Tunic",
  "Necro-Knight's Garb",
  "Stygian Buckler",
  "Harbinger of Doom",
  "Spaulders of the Grand Crusader",
  "Leggings of the Grand Crusader",
  "Leggings of Elemental Fury",
  "Girdle of Elemental Fury",
  "Belt of the Grand Crusader",
}

local es_trash_bop = {
  "Lucid Nightmare",
  "Corrupted Reed",
  "Verdant Dreamer's Boots",
  "Nature's Gift",
  "Lasher's Whip",
  "Infused Wildthorn Bracers",
  "Sleeper's Ring",
  "Emerald Rod",
}

local kara_trash_bop = {
  "Slivers of Nullification",
  "The End of All Ambitions",
  "Ques' Gauntlets of Precision",
  "Boots of Elemental Fury",
  "Gauntlets of Elemental Fury",
  "Boots of the Grand Crusader",
  "Gauntlets of the Grand Crusader",
  "Dragunovi's Sash of Domination",
  "Ring of Holy Light",
  "Brand of Karazhan",
}

------------------------------
-- Raid Config
------------------------------

local raid_config = {
  { zone = "Zul'Gurub", short = "ZG", categories = {
    { label = "Coins", items = zg_coin, key = "zg_coin", default = NEED },
    { label = "Bijou", items = zg_bijou, key = "zg_bijou", default = NEED },
    { label = "Trash BoPs", items = zg_trash_bop, key = "zg_trash", default = OFF },
    { label = "BoEs", key = "zg_boe", default = NEED, is_boe = true },
  }},
  { zone = "Ruins of Ahn'Qiraj", short = "AQ20", categories = {
    { label = "Idols", items = idol_aq20, key = "aq20_idol", default = NEED },
    { label = "Scarabs", items = scarab, key = "aq20_scarab", default = NEED },
    {},
    { label = "BoEs", key = "aq20_boe", default = NEED, is_boe = true },
  }},
  { zone = "Molten Core", short = "MC", categories = {
    { label = "Sulfuron Ingot", items = {"Sulfuron Ingot"}, key = "mc_ingot", default = OFF },
    { label = "Mats", items = mc_mat, key = "mc_mat", default = OFF },
    { label = "Trash BoPs", items = mc_trash_bop, key = "mc_trash", default = OFF },
    { label = "BoEs", key = "mc_boe", default = OFF, is_boe = true },
  }},
  { zone = "Blackwing Lair", short = "BWL", categories = {
    { label = "Elementium Ore", items = {}, key = "bwl_mat", default = OFF },
    {},
    { label = "Trash BoPs", items = bwl_trash_bop, key = "bwl_trash", default = OFF },
    { label = "BoEs", key = "bwl_boe", default = OFF, is_boe = true },
  }},
  { zone = "Emerald Sanctum", short = "ES", categories = {
    { label = "Scales+Fading", items = {"Dreamscale", "Fading Dream Fragment"}, key = "es_mat", default = OFF },
    {},
    { label = "Trash BoPs", items = es_trash_bop, key = "es_trash", default = OFF },
    { label = "BoEs", key = "es_boe", default = OFF, is_boe = true },
  }},
  { zone = "Ahn'Qiraj", short = "AQ40", categories = {
    { label = "Idols", items = idol_aq40, key = "aq40_idol", default = OFF },
    { label = "Scarabs", items = scarab, key = "aq40_scarab", default = OFF },
    { label = "Red Mount", items = {"Red Qiraji Resonating Crystal"}, key = "aq40_red_mount", default = OFF },
    { label = "B/Y/G Mounts", items = aq40_mount, key = "aq40_mount", default = OFF },
    { label = "Trash BoPs", items = aq40_trash_bop, key = "aq40_trash", default = OFF },
    { label = "BoEs", key = "aq40_boe", default = OFF, is_boe = true },
  }},
  { zone = "Naxxramas", short = "Naxx", categories = {
    { label = "Scraps", items = scrap, key = "naxx_scrap", default = OFF },
    {},
    { label = "Trash BoPs", items = naxx_trash_bop, key = "naxx_trash", default = OFF },
    { label = "BoEs", key = "naxx_boe", default = OFF, is_boe = true },
  }},
  { zone = "Tower of Karazhan", aliases = {"The Rock of Desolation"}, short = "Kara40", categories = {
    { label = "Pristine Ley Crystal", items = {"Pristine Ley Crystal"}, key = "kara_mat", default = OFF },
    { label = "Overcharged Ley Energy", items = {"Overcharged Ley Energy"}, key = "kara_energy", default = OFF },
    { label = "Trash BoPs", items = kara_trash_bop, key = "kara_trash", default = OFF },
    { label = "BoEs", key = "kara_boe", default = OFF, is_boe = true },
  }},
}

-- Derive max popup rows from raid_config (so adding categories never needs a manual bump)
for _, raid in ipairs(raid_config) do
  local n = 0
  for _, cat in ipairs(raid.categories) do if cat.key then n = n + 1 end end
  if n > C.MAX_POPUP_ROWS then C.MAX_POPUP_ROWS = n end
end

------------------------------
-- Loot Functions
------------------------------

local function prettify_roll_type(roll_type)
  if roll_type == NEED then
    return "Need"
  elseif roll_type == GREED then
    return "Greed"
  elseif roll_type == PASS then
    return "Pass"
  end
  return "Off"
end

local toggle_options = {
  { label = "Accept Invite",     setting = "auto_invite",     default = true,  tooltip = "Always accept invites from friends or guild members." },
  { label = "Accept Summon",    setting = "auto_summon",     default = false,  tooltip = "Automatically accept summons." },
  { label = "Accept Resurrect", setting = "auto_resurrect",  default = false,  tooltip = "Automatically accept resurrections." },
  { label = "Sell Greys", setting = "auto_sell_greys", default = true,  tooltip = "Automatically sell grey items when opening a vendor (hold Ctrl to disable)." },
  { label = "Auto-Repair",     setting = "auto_repair",     default = true,  tooltip = "Repair at any valid vendor (hold Ctrl to disable)." },
  { label = "Auto-Dismount",   setting = "auto_dismount",   default = true,  tooltip = "Automatically dismount when trying to use most actions on a mount." },
  { label = "Auto-Unshift",   setting = "auto_unshift",    default = false, tooltip = "Cancel shapeshift form on shapeshifted error messages when out of combat.", class = "DRUID" },
  { label = "Auto-Stand",      setting = "auto_stand",      default = true,  tooltip = "Automatically stand when trying to use actions while sitting." },
  { label = "Auto-Weeklies",  setting = "auto_weeklies",   default = true,  tooltip = "Automatically accept Call to Arms weekly quests (hold Ctrl to disable)." },
  { label = "Auto-Gossip",     setting = "auto_gossip",     default = true,  tooltip = "Automatically choose the most common gossip options (hold Ctrl to disable)." },
  { label = "Combat Plates",  setting = "combat_plates",   default = false, tooltip = "Only show enemy nameplates in combat, hide when leaving combat." },
  { label = "Combat Names",  setting = "combat_names",    default = false, tooltip = "Hide player and NPC names in combat, restore when leaving combat." },
  { label = "Shift to Loot",   setting = "shift_to_loot",   default = false, tooltip = "Invert Shift behavior: only autoloot when Shift is held." },
  { label = "Pass on Greys",   setting = "pass_greys",      default = false, tooltip = "Do not loot grey items." },
  { label = "Untrack in Raid", setting = "raid_untrack",   default = false, tooltip = "Remove Find Herbs and Find Minerals tracking when entering a raid instance." },
  { label = "Holy Water Only", setting = "only_holy",       default = false, tooltip = "Only loot holy water from Stratholme Chests." },
}

local default_settings = {
  general_boe_rule = GREED,
  auto_buy = true,
  auto_sell_list = true,
  need_whitelist = true,
  greed_whitelist = true,
  pass_whitelist = true,
}

for _,opt in ipairs(toggle_options) do
  default_settings[opt.setting] = opt.default
end
for _,raid in ipairs(raid_config) do
  for _,cat in ipairs(raid.categories) do
    if cat.key then default_settings[cat.key] = cat.default end
  end
end

-- Determine what kind of roll we want for the item and do the pass, or roll of need or greed
-- returns the roll type and whether it matched a whitelist
function LazyWeirdo:HandleItem(name, item_info)
  -- check specific lists first
  if LazyWeirdoDB.settings.need_whitelist and fuzzy_elem(LazyWeirdoDB.needlist,name) then
    return NEED, true
  elseif LazyWeirdoDB.settings.greed_whitelist and fuzzy_elem(LazyWeirdoDB.greedlist,name) then
    return GREED, true
  elseif LazyWeirdoDB.settings.pass_whitelist and fuzzy_elem(LazyWeirdoDB.passlist,name) then
    return PASS, true
  end

  local is_bop = item_info and item_info.bop

  -- check raid zone item lists
  local zone = GetRealZoneText()
  for _,raid in ipairs(raid_config) do
    if raid.zone == zone or (raid.aliases and elem(raid.aliases, zone)) then
      local boe_cat = nil
      for _,cat in ipairs(raid.categories) do
        if cat.is_boe then
          boe_cat = cat
        elseif cat.items and elem(cat.items, name) then
          return LazyWeirdoDB.settings[cat.key], false
        end
      end
      -- BoP items not on an explicit list: don't auto-roll
      if is_bop then return OFF, false end
      -- BoE fallback for the zone
      if boe_cat then
        return LazyWeirdoDB.settings[boe_cat.key], false
      end
      return LazyWeirdoDB.settings.general_boe_rule, false
    end
  end
  if is_bop then return OFF, false end
  return LazyWeirdoDB.settings.general_boe_rule, false
end

-- 0 pass, 1 need, 2 greed
function LazyWeirdo:START_LOOT_ROLL(roll_id,time_left)
  local _texture, name, _count, quality, bop = GetLootRollItemInfo(roll_id)
  local r = LazyWeirdo:HandleItem(name, {bop = bop})
  if r >= 0 then RollOnLoot(roll_id,r) end
end

function LazyWeirdo:LOOT_BIND_CONFIRM(slot)
  -- solo play, queue the loot for accepting
  if not InGroup() then
    debug_print("solo bind")
    table.insert(binds,slot)
    return
  end

  -- check whitelists if in group, say if everyone passed already
  -- could happen if you shift-click the boss and don't autoloot
  local _texture, item, _quantity, quality = GetLootSlotInfo(slot)
  local r = LazyWeirdo:HandleItem(item, {bop = true})
  if r > 0 then
    debug_print("party bind")
    table.insert(binds,slot)
    return
  end
end

function LazyWeirdo:LOOT_SLOT_CLEARED(slot)
end

-- a BoP item ask, these can be autorolled but only by explicit whitelist
function LazyWeirdo:CONFIRM_LOOT_ROLL(roll_id,roll_type)
  local _texture, name, _count, quality, bop = GetLootRollItemInfo(roll_id)
  local r = LazyWeirdo:HandleItem(name, {bop = bop})

  if r == OFF then return end
  if r == roll_type then
    ConfirmLootRoll(roll_id,roll_type)
    StaticPopup_Hide("CONFIRM_LOOT_ROLL")
  elseif r == PASS then
    StaticPopup_Hide("CONFIRM_LOOT_ROLL")
  end
end


local elTooltip = CreateFrame("GameTooltip", "elTooltip", UIParent, "GameTooltipTemplate")

-- item info cache keyed by item name
-- values: { bop = bool, boe = bool, quest = bool, unique = bool }
local item_info_cache = {}

local function ScanLootItem(slot)
  local _texture, name = GetLootSlotInfo(slot)
  if not name then return nil end
  if item_info_cache[name] then return item_info_cache[name] end

  elTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
  elTooltip:SetLootItem(slot)

  local info = { bop = false, boe = false, quest = false, unique = false }
  for i = 2, elTooltip:NumLines() do
    local line = getglobal("elTooltipTextLeft"..i)
    if line then
      local text = line:GetText()
      if text then
        if text == "Soulbound" or text == "Binds when picked up" then
          info.bop = true
        elseif text == "Binds when equipped" then
          info.boe = true
        elseif text == "Quest Item" then
          info.quest = true
        elseif text == "Unique" then
          info.unique = true
        end
      end
    end
  end

  item_info_cache[name] = info
  return info
end

-- obnoxious hook to solve pfui not clearing itself properly
local orig_pfUI_UpdateLootFrame = function () end
if pfUI and pfUI.loot then
  orig_pfUI_UpdateLootFrame = pfUI.loot.UpdateLootFrame
  pfUI.loot.UpdateLootFrame = function () end
end

function LazyWeirdo:LOOT_OPENED()
  local shift = IsShiftKeyDown()
  if (not LazyWeirdoDB.settings.shift_to_loot and shift) or (LazyWeirdoDB.settings.shift_to_loot and not shift) then
    orig_pfUI_UpdateLootFrame()
    return
  end
  local numLootItems = GetNumLootItems()

  -- strat chest check
  if LazyWeirdoDB.settings.only_holy and GetRealZoneText() == "Stratholme" then
    local water = string.lower("Stratholme Holy Water")
    for slot = 1, numLootItems do
      local _texture, item, _quantity, quality = GetLootSlotInfo(slot)
      if LootSlotIsCoin(slot) then
        LootSlot(slot,true)
      elseif LootSlotIsItem(slot) and string.lower(item) == water then
        LootSlot(slot,true)
        return
      end
    end
  end

  for slot = 1, numLootItems do
    if LootSlotIsCoin(slot) then
      LootSlot(slot,true)
    elseif LootSlotIsItem(slot) then
      local loot_method = GetLootMethod()
      local _texture, item, _quantity, quality = GetLootSlotInfo(slot)
      local info = ScanLootItem(slot)
      local r, on_whitelist = LazyWeirdo:HandleItem(item, info)
      local is_bind = info and (info.bop or info.boe)

      -- determine loot to skip
      if on_whitelist and (r == PASS) then
        -- loot is on our pass list
        debug_print("passlist "..item)

      -- quest items are always personal loot, grab them regardless of group/ML state
      -- unless they're also BoP and we are the master looter
      elseif info and info.quest then
        if info.bop then
          local _, _, mlRaidId = GetLootMethod()
          if mlRaidId and UnitIsUnit("player", "raid" .. mlRaidId) then
            debug_print("questloot bop ML skip "..item)
          else
            debug_print("questloot bop "..item)
            LootSlot(slot,true)
          end
        else
          debug_print("questloot "..item)
          LootSlot(slot,true)
        end
      elseif (quality == 0 and LazyWeirdoDB.settings.pass_greys) and not (r > 0 and on_whitelist) then
        -- do nothing, unless it's a whitelist item
        debug_print("passgrey " .. item)
      elseif (r == OFF or r == PASS) and InGroup() and is_bind then
        -- BoP/BoE item set to pass/off in group, skip looting
        debug_print("passgroup "..item)
      elseif InGroup() and (loot_method == "master") then
        debug_print("masterloot on "..item)

      -- finally loot whatever wasn't handled above
      else
        debug_print("looting "..item)
        LootSlot(slot,true)
      end
    end
    -- it the above looting caused a bind, resolve it
    -- seems like an odd place/way to do it, but trying it any other way wasn't consistent
    if next(binds) then
      LootSlot(table.remove(binds))
      StaticPopup_Hide("LOOT_BIND")
    end
  end
  debug_print("binds left: " .. tsize(binds))

  -- we're done looting, allow pfui to try
  orig_pfUI_UpdateLootFrame()
end

function LazyWeirdo:LOOT_CLOSED()
  -- binds = {}
end

------------------------------
-- Other Functions
------------------------------

local combat_name_cvars = { "UnitNamePlayer", "UnitNameNPC", "UnitNameOwn" }

local function HideNameCVars()
  if LazyWeirdoDB.names_hidden then return end
  LazyWeirdoDB.saved_name_cvars = {}
  for _,cvar in ipairs(combat_name_cvars) do
    LazyWeirdoDB.saved_name_cvars[cvar] = GetCVar(cvar)
    SetCVar(cvar, "0")
  end
  LazyWeirdoDB.names_hidden = true
end

local function RestoreNameCVars()
  if not LazyWeirdoDB.names_hidden then return end
  for _,cvar in ipairs(combat_name_cvars) do
    if LazyWeirdoDB.saved_name_cvars and LazyWeirdoDB.saved_name_cvars[cvar] then
      SetCVar(cvar, LazyWeirdoDB.saved_name_cvars[cvar])
    end
  end
  LazyWeirdoDB.names_hidden = false
end

function LazyWeirdo:PLAYER_REGEN_ENABLED()
  if LazyWeirdoDB.settings.combat_plates then HideNameplates() end
  RestoreNameCVars()
end

function LazyWeirdo:PLAYER_REGEN_DISABLED()
  if LazyWeirdoDB.settings.combat_plates then ShowNameplates() end
  if LazyWeirdoDB.settings.combat_names then HideNameCVars() end
end

function LazyWeirdo:PLAYER_ENTERING_WORLD()
  if LazyWeirdoDB.settings.combat_plates and not UnitAffectingCombat("player") then
    HideNameplates()
  end
  if LazyWeirdoDB.names_hidden and not UnitAffectingCombat("player") then
    RestoreNameCVars()
  end
end

function LazyWeirdo:ZONE_CHANGED_NEW_AREA()
  if LazyWeirdoDB.settings.combat_plates and not UnitAffectingCombat("player") then
    HideNameplates()
  end

  if LazyWeirdoDB.settings.raid_untrack and IsInInstance() and GetNumRaidMembers() > 1 then
    LazyWeirdo:RemoveGatherTracking()
  end
end

function LazyWeirdo:VARIABLES_LOADED()
  LazyWeirdo:Load()

  LazyWeirdo:RegisterEvent("START_LOOT_ROLL")
  LazyWeirdo:RegisterEvent("LOOT_OPENED")
  LazyWeirdo:RegisterEvent("LOOT_CLOSED")
  LazyWeirdo:RegisterEvent("LOOT_BIND_CONFIRM")
  LazyWeirdo:RegisterEvent("LOOT_SLOT_CLEARED")
  LazyWeirdo:RegisterEvent("CONFIRM_LOOT_ROLL")
  LazyWeirdo:RegisterEvent("PARTY_INVITE_REQUEST")
  LazyWeirdo:RegisterEvent("MERCHANT_SHOW")
  LazyWeirdo:RegisterEvent("MERCHANT_CLOSED")
  LazyWeirdo:RegisterEvent("GOSSIP_SHOW")
  LazyWeirdo:RegisterEvent("QUEST_GREETING")
  LazyWeirdo:RegisterEvent("QUEST_DETAIL")
  LazyWeirdo:RegisterEvent("ITEM_TEXT_BEGIN")
  LazyWeirdo:RegisterEvent("PLAYER_REGEN_ENABLED")
  LazyWeirdo:RegisterEvent("PLAYER_REGEN_DISABLED")
  LazyWeirdo:RegisterEvent("UI_ERROR_MESSAGE")
  LazyWeirdo:RegisterEvent("CONFIRM_SUMMON")
  LazyWeirdo:RegisterEvent("RESURRECT_REQUEST")
  LazyWeirdo:RegisterEvent("PLAYER_ENTERING_WORLD")
  LazyWeirdo:RegisterEvent("ZONE_CHANGED_NEW_AREA")

  -- hook away superapi's autoloot functionality and set autloot to off since this handles it
  if IfShiftAutoloot then
    IfShiftAutoloot = function () return end
  end
  -- other method
  if SuperAPI then
    SuperAPI.IfShiftAutoloot = function () SetAutoloot(0) end
    SuperAPI.IfShiftNoAutoloot = function () SetAutoloot(0) end
    -- SuperAPI.frame:SetScript("OnUpdate", nil)
  elseif SetAutoloot then -- superwow but no superapi
    SetAutoloot(0)
  end

  LazyWeirdo:CreateConfig()

  -- Restore saved frame position (must be after CreateConfig)
  if LazyWeirdoDB.position then
    LazyWeirdoConfigFrame:ClearAllPoints()
    LazyWeirdoConfigFrame:SetPoint(
      LazyWeirdoDB.position.point, UIParent,
      LazyWeirdoDB.position.relPoint,
      LazyWeirdoDB.position.x, LazyWeirdoDB.position.y
    )
  end
end

function LazyWeirdo:CONFIRM_SUMMON()
  if LazyWeirdoDB.settings.auto_summon then
    ConfirmSummon()
    StaticPopup_Hide("CONFIRM_SUMMON")
  end
end

function LazyWeirdo:RESURRECT_REQUEST()
  if LazyWeirdoDB.settings.auto_resurrect then
    AcceptResurrect()
    StaticPopup_Hide("RESURRECT_NO_SICKNESS")
  end
end

local mount_searches = {"Increases speed based", "Slow and steady", "Speed scales with your"}
local gather_searches = {"Find Herbs", "Find Minerals"}
local shapeshift_searches = {"Cat Form", "Bear Form", "Dire Bear Form", "Tree of Life Form", "Moonkin Form", "Aquatic Form", "Travel Form", "Swift Travel Form"}

-- Cancel buffs matching search patterns. check_by: "name" or "desc"
-- Returns list of cancelled buff names
local function CancelBuffsBySearch(searches, check_by)
  local removed = {}
  local counter = -1
  while true do
    counter = counter + 1
    local index, untilCancelled = GetPlayerBuff(counter)
    if index == -1 then break end
    if untilCancelled then
      elTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
      elTooltip:SetPlayerBuff(index)
      local name = elTooltipTextLeft1:GetText() or ""
      local text = check_by == "desc" and (elTooltipTextLeft2:GetText() or "") or name
      for _, pattern in ipairs(searches) do
        if string.find(text, pattern) then
          CancelPlayerBuff(counter)
          table.insert(removed, name)
          break
        end
      end
    end
  end
  return removed
end

function LazyWeirdo:Dismount()
  CancelBuffsBySearch(mount_searches, "desc")
end

function LazyWeirdo:CancelShapeshift()
  CancelBuffsBySearch(shapeshift_searches, "name")
end

function LazyWeirdo:RemoveGatherTracking()
  local removed = CancelBuffsBySearch(gather_searches, "name")
  for _, name in ipairs(removed) do
    el_print("Removed "..ITEM_COLOR..name.."|r")
  end
end

function LazyWeirdo:UI_ERROR_MESSAGE(msg)
  if LazyWeirdoDB.settings.auto_dismount and string.find(arg1, "mounted") then
    LazyWeirdo:Dismount()
    UIErrorsFrame:Clear()
  end
  if LazyWeirdoDB.settings.auto_unshift and not UnitAffectingCombat("player") and (string.find(arg1, "while shapeshifted") or string.find(arg1, "in shapeshift form")) then
    LazyWeirdo:CancelShapeshift()
    UIErrorsFrame:Clear()
  end
  if LazyWeirdoDB.settings.auto_stand and string.find(arg1, "must be standing") then
    SitOrStand()
    UIErrorsFrame:Clear()
  end
  if string.find(arg1, "still being rolled") then
    UIErrorsFrame:Clear()
  end
end

------------------------------

-- Register events
LazyWeirdo:RegisterEvent("VARIABLES_LOADED")
LazyWeirdo:SetScript("OnEvent", function ()
  LazyWeirdo[event](this,arg1,arg2,arg3,arg4,arg6,arg7,arg8,arg9,arg9,arg10)
end)

function LazyWeirdo:Load()
  LazyWeirdoDB = LazyWeirdoDB or {}
  LazyWeirdoDB.needlist = LazyWeirdoDB.needlist or {}
  LazyWeirdoDB.greedlist = LazyWeirdoDB.greedlist or {}
  LazyWeirdoDB.passlist = LazyWeirdoDB.passlist or {}
  -- migrate plain-string entries to toggleable { name, enabled } objects
  for _,list in ipairs({ LazyWeirdoDB.needlist, LazyWeirdoDB.greedlist, LazyWeirdoDB.passlist }) do
    for i,v in ipairs(list) do
      if type(v) == "string" then list[i] = { name = v, enabled = true } end
    end
  end
  LazyWeirdoDB.buylist = LazyWeirdoDB.buylist or {}
  LazyWeirdoDB.selllist = LazyWeirdoDB.selllist or {}

  LazyWeirdoDB.settings = LazyWeirdoDB.settings or default_settings
  for k,v in pairs(default_settings) do
    if LazyWeirdoDB.settings[k] == nil then
      LazyWeirdoDB.settings[k] = v
    end
  end
end


-- lazypigs
function LazyWeirdo:AcceptGroupInvite()
	AcceptGroup()
	StaticPopup_Hide("PARTY_INVITE")
	PlaySoundFile("Sound\\Doodad\\BellTollNightElf.wav")
	UIErrorsFrame:AddMessage("Group Auto Accept")
end

function LazyWeirdo:PARTY_INVITE_REQUEST(who)
  if LazyWeirdoDB.settings.auto_invite and (IsGuildMate(who) or IsFriend(who)) then
    LazyWeirdo:AcceptGroupInvite()
  end
end

local function FormatMoney(copper)
  local g = math.floor(copper / 10000)
  local s = math.floor(math.mod(copper / 100, 100))
  local c = math.floor(math.mod(copper, 100))
  local parts = ""
  if g > 0 then parts = parts .. format("|cffffd700%dg|r", g) end
  if s > 0 then parts = parts .. format("|cffc7c7cf%ds|r", s) end
  if c > 0 or parts == "" then parts = parts .. format("|cffeda55f%dc|r", c) end
  return parts
end

function LazyWeirdo:MERCHANT_SHOW()
  if IsControlKeyDown() then return end

  -- auto repair
  if LazyWeirdoDB.settings.auto_repair and CanMerchantRepair() then
    local rcost = GetRepairAllCost()
    if rcost and rcost ~= 0 then
      if rcost > GetMoney() then
        el_print("Not Enough Money to Repair.")
      else
        RepairAllItems()
        el_print("Equipment repaired for: " .. FormatMoney(rcost))
      end
    end
  end

  -- auto sell (greys + sell list, one per frame, SortBags-style throttling)
  local sell_queue = {}
  if LazyWeirdoDB.settings.auto_sell_greys then
    for bag = 0, 4 do
      for slot = 1, GetContainerNumSlots(bag) do
        local link = GetContainerItemLink(bag, slot)
        if link and string.find(link, "ff9d9d9d") then
          local _, count = GetContainerItemInfo(bag, slot)
          local _, _, itemStr = string.find(link, "(item:%d+:%d+:%d+:%d+)")
          local _, _, _, _, _, _, _, _, _, sellPrice = GetItemInfo(itemStr)
          table.insert(sell_queue, { bag = bag, slot = slot, name = "Grey Items", count = count or 1, is_grey = true, price = (sellPrice or 0) * (count or 1) })
        end
      end
    end
  end
  if LazyWeirdoDB.settings.auto_sell_list and LazyWeirdoDB.selllist then
    for bag = 0, 4 do
      for slot = 1, GetContainerNumSlots(bag) do
        local link = GetContainerItemLink(bag, slot)
        if link then
          local name = ItemLinkToName(link)
          if name then
            local lname = string.lower(name)
            for _,entry in ipairs(LazyWeirdoDB.selllist) do
              if entry.enabled ~= false and string.find(lname, string.lower("^" .. entry.name .. "$")) then
                local _, count = GetContainerItemInfo(bag, slot)
                local _, _, itemStr = string.find(link, "(item:%d+:%d+:%d+:%d+)")
                local _, _, _, _, _, _, _, _, _, sellPrice = GetItemInfo(itemStr)
                table.insert(sell_queue, { bag = bag, slot = slot, name = name, count = count or 1, price = (sellPrice or 0) * (count or 1) })
                break
              end
            end
          end
        end
      end
    end
  end
  if sell_queue[1] then
    if not LazyWeirdo.vendorSellFrame then
      LazyWeirdo.vendorSellFrame = CreateFrame("Frame")
    end
    local f = LazyWeirdo.vendorSellFrame
    f.queue = sell_queue
    f.index = 1
    f.results = {}
    f.result_order = {}
    f:SetScript("OnUpdate", function()
      if (this.tick or 1) > GetTime() then return else this.tick = GetTime() + 0.1 end
      local item = this.queue[this.index]
      if not item then
        for _, key in ipairs(this.result_order) do
          local r = this.results[key]
          if r.earned > 0 then
            local display = r.is_grey and key or (ITEM_COLOR .. key .. "|r")
            el_print(format("Sold %dx %s for: %s", r.count, display, FormatMoney(r.earned)))
          end
        end
        this:SetScript("OnUpdate", nil)
        this.result_order = nil
        this.results = nil
        return
      end
      local key = item.name
      if not this.results[key] then
        this.results[key] = { count = 0, earned = 0, is_grey = item.is_grey }
        table.insert(this.result_order, key)
      end
      this.results[key].count = this.results[key].count + item.count
      this.results[key].earned = this.results[key].earned + item.price
      ClearCursor()
      UseContainerItem(item.bag, item.slot)
      this.index = this.index + 1
    end)
  end

  -- auto buy items from purchase list
  if LazyWeirdoDB.settings.auto_buy and LazyWeirdoDB.buylist then
    for _,entry in ipairs(LazyWeirdoDB.buylist) do
      if entry.enabled ~= false then
        -- count how many of this item are already in bags
        local inBags = 0
        for bag = 0, 4 do
          for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
              local bagName = ItemLinkToName(link)
              if bagName and string.find(string.lower(bagName), string.lower("^" .. entry.name .. "$")) then
                local _,count = GetContainerItemInfo(bag, slot)
                inBags = inBags + (count or 1)
              end
            end
          end
        end
        local needed = entry.count - inBags
        if needed > 0 then
          for i = 1, GetMerchantNumItems() do
            local mName, _, _, stackSize = GetMerchantItemInfo(i)
            if mName and string.find(string.lower(mName), string.lower("^" .. entry.name .. "$")) then
              stackSize = stackSize or 1
              local stacks = math.ceil(needed / stackSize)
              BuyMerchantItem(i, stacks)
              el_print(format("Bought %dx "..ITEM_COLOR.."%s|r", stacks * stackSize, entry.name))
              break
            end
          end
        end
      end
    end
  end
end

function LazyWeirdo:MERCHANT_CLOSED()
  local f = LazyWeirdo.vendorSellFrame
  if f and f.result_order then
    for _, key in ipairs(f.result_order) do
      local r = f.results[key]
      if r.earned > 0 then
        local display = r.is_grey and key or (ITEM_COLOR .. key .. "|r")
        el_print(format("Sold %dx %s for: %s", r.count, display, FormatMoney(r.earned)))
      end
    end
    f:SetScript("OnUpdate", nil)
    f.result_order = nil
    f.results = nil
  end
end

function LazyWeirdo:ITEM_TEXT_BEGIN()
  if IsControlKeyDown() then return end
  if ItemTextGetItem() ~= "Altar of Zanza" then return end

  for bag = 0, 4 do
    for slot = 1, GetContainerNumSlots(bag) do
      local l = GetContainerItemLink(bag,slot)
      if l then
        _,_,itemId = string.find(l,"item:(%d+)")
        local name,_link,_,_lvl,_type,subtype = GetItemInfo(itemId)
        if string.find(name,".- Hakkari Bijou") then
          UseContainerItem(bag, slot)
          CloseItemText()
          return
        end
      end
    end
  end
  el_print("No Bijou found in inventory.")
  CloseItemText()
end

local weekly_quests = {
  "Call to Arms: Dungeon Delving",
  "Call to Arms: Molten Assault",
  "Call to Arms: Cleansing the Corruption",
}
local accepting_weekly = false

function LazyWeirdo:GOSSIP_SHOW()
  -- auto-accept weekly quests from gossip frame
  if LazyWeirdoDB.settings.auto_weeklies and not IsControlKeyDown() then
    local avail = { GetGossipAvailableQuests() }
    for i = 1, tsize(avail), 2 do
      local title = avail[i]
      if title and elem(weekly_quests, title) then
        accepting_weekly = true
        SelectGossipAvailableQuest(math.floor(i / 2) + 1)
        return
      end
    end
  end

  if not LazyWeirdoDB.settings.auto_gossip or IsControlKeyDown() then return end
  -- brainwasher is weird, skip it
  if UnitName("npc") == "Goblin Brainwashing Device" then
    return
  end

  -- If there's something more to do than just gossip, don't automate
  if GetGossipAvailableQuests() or GetGossipActiveQuests() then return end

  local t = { GetGossipOptions() }
  local t2 = {}
  for i=1,tsize(t),2 do
    table.insert(t2, { text = t[i], gossip = t[i+1] })
  end

  -- only one option, and not a gossip? click it
  if t2[1] and not t2[2] and t2[1].gossip ~= "gossip" then SelectGossipOption(1) end

  for i,entry in ipairs(t2) do
    -- check for dialogue types we'd always want to click
    if elem(gossips, entry.gossip) then
      SelectGossipOption(i); break
    end
    -- check for specific gossips to skip
    if entry.gossip == "gossip" then
      for _,line in gossips_skip_lines do
        if string.find(entry.text, line) then
          SelectGossipOption(i); break
        end
      end
    end
  end
end

function LazyWeirdo:QUEST_GREETING()
  if not LazyWeirdoDB.settings.auto_weeklies or IsControlKeyDown() then return end
  for i = 1, GetNumAvailableQuests() do
    if elem(weekly_quests, GetAvailableTitle(i)) then
      accepting_weekly = true
      SelectAvailableQuest(i)
      return
    end
  end
end

function LazyWeirdo:QUEST_DETAIL()
  if accepting_weekly then
    accepting_weekly = false
    AcceptQuest()
  end
end

function LazyWeirdo:CreateConfig()

  -- Create main frame for the configuration menu
  local LazyWeirdoConfigFrame = CreateFrame("Frame", "LazyWeirdoConfigFrame", UIParent)
  LazyWeirdoConfigFrame:SetWidth(C.FRAME_W)
  LazyWeirdoConfigFrame:SetHeight(C.FRAME_H)
  LazyWeirdoConfigFrame:SetPoint("CENTER", UIParent, "CENTER")  -- Centered frame
  LazyWeirdoConfigFrame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 32, edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 }
  })
  if not DEV_MODE then LazyWeirdoConfigFrame:Hide() end
  table.insert(UISpecialFrames, "LazyWeirdoConfigFrame")

  -- Make the frame draggable
  LazyWeirdoConfigFrame:SetMovable(true)
  LazyWeirdoConfigFrame:EnableMouse(true)
  LazyWeirdoConfigFrame:RegisterForDrag("LeftButton")
  LazyWeirdoConfigFrame:SetScript("OnDragStart", function() this:StartMoving() end)
  LazyWeirdoConfigFrame:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local point, _, relPoint, x, y = this:GetPoint()
    LazyWeirdoDB.position = { point = point, relPoint = relPoint, x = x, y = y }
  end)

  -- Add a close button
  local closeButton = CreateFrame("Button", nil, LazyWeirdoConfigFrame, "UIPanelCloseButton")
  closeButton:SetPoint("TOPRIGHT", LazyWeirdoConfigFrame, "TOPRIGHT", -5, -5)
  closeButton:SetScript("OnClick", function()
      LazyWeirdoConfigFrame:Hide()  -- Hides the frame when the close button is clicked
  end)


  -- Title text
  local title = LazyWeirdoConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  title:SetPoint("TOP", 0, -20)
  title:SetText("LazyWeirdo " .. GetAddOnMetadata("LazyWeirdo","Version") .. " Configuration")

  -- Function to toggle the config frame
  SLASH_LAZYWEIRDO1 = "/lazyweirdo"
  SLASH_LAZYWEIRDO2 = "/lw"
  SlashCmdList["LAZYWEIRDO"] = function(msg)
      if msg == "reset" then
          LazyWeirdoConfigFrame:ClearAllPoints()
          LazyWeirdoConfigFrame:SetPoint("CENTER", UIParent, "CENTER")
          LazyWeirdoDB.position = nil
          el_print("Frame position reset.")
          if not LazyWeirdoConfigFrame:IsShown() then LazyWeirdoConfigFrame:Show() end
      elseif LazyWeirdoConfigFrame:IsShown() then
          LazyWeirdoConfigFrame:Hide()
      else
          LazyWeirdoConfigFrame:Show()
      end
  end

  -- Dropdown creation function
  local function CreateDropdown(parent, label, items, defaultValue, x, y, name, setting)
      local dropdown = CreateFrame("Button", name, parent, "UIDropDownMenuTemplate")  -- Name the frame properly
      -- dropdown:SetPoint("TOPLEFT", x, y)
      
      local dropdownLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      dropdownLabel:SetPoint("TOP", x - C.DROPDOWN_OFFSET, y)
      dropdownLabel:SetText(label)
      dropdown:SetPoint("TOP", dropdownLabel, "BOTTOM", 0, 0)

      local selectedValue = defaultValue

      -- Function to handle item selection
      -- TODO this needs to set config settings
      local function OnClick(self)
        local v = tonumber(LazyWeirdo[string.upper(self:GetText())])
        if v then
          UIDropDownMenu_SetSelectedName(dropdown, self:GetText())
          LazyWeirdoDB.settings[setting] = v
        end
        -- print(UIDropDownMenu_GetSelectedValue(dropdown))
      end

      -- Manual initialization for the dropdown
      local function InitializeDropdown()
          for i, item in ixpairs(items) do
              local info = {}  -- Create a new info table for each dropdown entry
              info.text = item  -- The text displayed in the dropdown
              info.value = item -- The value stored when the item is selected
              info.func = function () OnClick(this) end   -- Attach the OnClick handler
              UIDropDownMenu_AddButton(info)  -- Add the dropdown option to the list
          end
      end

      -- Set up the dropdown, ensuring it is properly initialized with a named frame
      UIDropDownMenu_Initialize(dropdown, InitializeDropdown)
      UIDropDownMenu_SetWidth(60,dropdown)  -- Set the width of the dropdown
      UIDropDownMenu_SetSelectedValue(dropdown, selectedValue)

      return dropdown
  end

  -- Icon state definitions for raid loot toggles
  local state_icons = {
    [NEED]  = { tex = "Interface\\Buttons\\UI-GroupLoot-Dice-Up", label = "Need", y = -1.5 },
    [GREED] = { tex = "Interface\\Buttons\\UI-GroupLoot-Coin-Up", label = "Greed", y = -2.5 },
    [PASS]  = { tex = "Interface\\Buttons\\UI-GroupLoot-Pass-Up", label = "Pass", y = 0 },
    [OFF]   = { tex = "Interface\\FrameXML\\LFT\\images\\readycheck-notready", label = "Off", y = 0 },
  }
  local state_cycle = { [NEED] = GREED, [GREED] = PASS, [PASS] = OFF, [OFF] = NEED }

  ------------------------------------------------------------------
  -- Raid loot popup (shared, populated per-raid on click)
  ------------------------------------------------------------------
  local activeLabel = nil -- track which raid label has a locked highlight

  local popupOverlay = CreateFrame("Frame", "LazyWeirdoPopupOverlay", UIParent)
  popupOverlay:SetFrameStrata("FULLSCREEN_DIALOG")
  popupOverlay:SetAllPoints(UIParent)
  popupOverlay:EnableMouse(true)
  popupOverlay:Hide()
  popupOverlay:SetScript("OnMouseDown", function()
    popupOverlay:Hide()
  end)
  popupOverlay:SetScript("OnHide", function()
    if activeLabel then
      activeLabel:UnlockHighlight()
      activeLabel = nil
    end
  end)
  table.insert(UISpecialFrames, "LazyWeirdoPopupOverlay")

  local raidPopup = CreateFrame("Frame", "LazyWeirdoRaidPopup", popupOverlay)
  raidPopup:SetWidth(245)
  raidPopup:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  raidPopup:SetBackdropColor(0.05, 0.05, 0.05, 1)
  raidPopup:EnableMouse(true)

  local popupTitle = raidPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  popupTitle:SetPoint("TOP", 0, C.POPUP_TITLE_Y)

  -- Pre-create popup rows
  local popupRows = {}
  for i = 1, C.MAX_POPUP_ROWS do
    local row = {}
    local yOff = C.ROW_START_Y - (i - 1) * C.ROW_HEIGHT

    row.label = raidPopup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.label:SetPoint("TOPLEFT", C.POPUP_PAD, yOff - 4)
    row.label:SetJustifyH("LEFT")

    row.buttons = {}
    for j = 1, C.NUM_LOOT_MODES do
      local btn = CreateFrame("Button", nil, raidPopup)
      btn:SetWidth(C.ICON_SIZE)
      btn:SetHeight(C.ICON_SIZE)
      btn:SetPoint("TOPLEFT", (j - 1) * C.ICON_SPACING, yOff)

      local tex = btn:CreateTexture(nil, "ARTWORK")
      tex:SetWidth(C.ICON_SIZE)
      tex:SetHeight(C.ICON_SIZE)
      tex:SetPoint("CENTER", 0, 0)
      btn.icon = tex

      local hl = btn:CreateTexture(nil, "OVERLAY")
      hl:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
      hl:SetBlendMode("ADD")
      hl:SetWidth(C.ICON_HIGHLIGHT)
      hl:SetHeight(C.ICON_HIGHLIGHT)
      hl:SetPoint("CENTER", 0, 0)
      hl:SetAlpha(C.GLOW_ALPHA)
      hl:Hide()
      btn.highlight = hl

      btn.mode = C.MODE_ORDER[j]
      row.buttons[j] = btn
    end

    popupRows[i] = row
  end

  local function UpdatePopupRow(rowIdx, currentMode)
    local row = popupRows[rowIdx]
    for j = 1, C.NUM_LOOT_MODES do
      local btn = row.buttons[j]
      local info = state_icons[btn.mode]
      btn.icon:SetTexture(info.tex)
      btn.icon:ClearAllPoints()
      btn.icon:SetPoint("CENTER", 0, info.y or 0)
      if btn.mode == currentMode then
        btn.icon:SetVertexColor(1, 1, 1)
      else
        btn.icon:SetVertexColor(C.DIM_ALPHA, C.DIM_ALPHA, C.DIM_ALPHA)
      end
      btn.highlight:Hide()
    end
  end

  local function ShowRaidPopup(raid, anchor)
    -- Unlock previous label highlight, lock the new one
    if activeLabel then activeLabel:UnlockHighlight() end
    activeLabel = anchor
    anchor:LockHighlight()

    popupTitle:SetText(raid.zone)

    -- First pass: set labels and measure widest
    local rowIdx = 0
    local maxLabelW = 0
    for _, cat in ipairs(raid.categories) do
      if cat.key then
        rowIdx = rowIdx + 1
        local row = popupRows[rowIdx]
        row.label:SetText(cat.label)
        row.label:Show()
        local w = row.label:GetStringWidth()
        if w > maxLabelW then maxLabelW = w end
      end
    end

    -- Compute icon column and popup width
    local iconsX = C.POPUP_PAD + maxLabelW + C.POPUP_PAD
    local popupW = iconsX + C.NUM_LOOT_MODES * C.ICON_SPACING + C.POPUP_PAD

    -- Second pass: position buttons and set up handlers
    local idx = 0
    for _, cat in ipairs(raid.categories) do
      if cat.key then
        idx = idx + 1
        local row = popupRows[idx]

        for j = 1, C.NUM_LOOT_MODES do
          local btn = row.buttons[j]
          btn.cat_key = cat.key
          btn.rowIdx = idx
          btn:ClearAllPoints()
          btn:SetPoint("TOPLEFT", iconsX + (j - 1) * C.ICON_SPACING, C.ROW_START_Y - (idx - 1) * C.ROW_HEIGHT)
          btn:Show()

          btn:SetScript("OnClick", function()
            LazyWeirdoDB.settings[this.cat_key] = this.mode
            UpdatePopupRow(this.rowIdx, this.mode)
          end)

          btn:SetScript("OnEnter", function()
            this.highlight:Show()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            local info = state_icons[this.mode]
            GameTooltip:SetText(info.label, C.TOOLTIP_R, C.TOOLTIP_G, C.TOOLTIP_B)
            GameTooltip:Show()
          end)
          btn:SetScript("OnLeave", function()
            this.highlight:Hide()
            GameTooltip:Hide()
          end)
        end

        UpdatePopupRow(idx, LazyWeirdoDB.settings[cat.key])
      end
    end

    for i = idx + 1, C.MAX_POPUP_ROWS do
      popupRows[i].label:Hide()
      for j = 1, C.NUM_LOOT_MODES do
        popupRows[i].buttons[j]:Hide()
      end
    end

    raidPopup:SetWidth(popupW)
    raidPopup:SetHeight(C.POPUP_PAD - C.ROW_START_Y + idx * C.ROW_HEIGHT)
    raidPopup:ClearAllPoints()
    raidPopup:SetPoint("TOPLEFT", anchor, "TOPRIGHT", C.POPUP_ANCHOR_X, C.POPUP_ANCHOR_Y)
    popupOverlay:Show()
  end

  -- Grid button sizing
  local raidBtnWidth = (C.ICON_COL - C.GRID_LEFT) + C.ARROW_SIZE
  -- Right column dropdown x: UIDropDownMenu visual left ≈ C.FRAME_W/2 + (x - C.DROPDOWN_OFFSET) - 55
  -- Solve for x so visual left = raidBtnRight + padding
  local raidBtnRight = C.GRID_LEFT + raidBtnWidth
  local rightColX = raidBtnRight + 15 - C.FRAME_W / 2 + C.DROPDOWN_OFFSET + 55  -- aligns dropdown visual left to grid right edge

  -- Grid rows: raids + "Other" (cycle_key marks it as a cycling row instead of popup)
  local grid_rows = {}
  for _,raid in ipairs(raid_config) do
    table.insert(grid_rows, raid)
  end
  table.insert(grid_rows, {
    zone = "World and Dungeon", short = "Other", separator = true,
    cycle_key = "general_boe_rule",
  })

  local raid_y = C.GRID_START_Y
  for _,row in ipairs(grid_rows) do
    if row.separator then raid_y = raid_y - C.SEPARATOR_GAP end

    local zone_name = row.zone
    local this_row = row

    local labelFrame = CreateFrame("Button", nil, LazyWeirdoConfigFrame)
    labelFrame:SetHeight(C.GRID_ROW_H)
    labelFrame:SetWidth(raidBtnWidth)
    labelFrame:SetPoint("TOPLEFT", C.GRID_LEFT, raid_y - 2)

    local raidLabel = labelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    raidLabel:SetPoint("LEFT", 0, 0)
    raidLabel:SetJustifyH("LEFT")
    raidLabel:SetText(row.short)

    local iconTex = labelFrame:CreateTexture(nil, "ARTWORK")
    iconTex:SetWidth(C.ARROW_SIZE)
    iconTex:SetHeight(C.ARROW_SIZE)
    iconTex:SetPoint("LEFT", C.ICON_COL - C.GRID_LEFT, 0)

    labelFrame:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    labelFrame:GetHighlightTexture():SetBlendMode("ADD")

    if this_row.cycle_key then
      -- Cycling row (Other): icon shows current mode, click cycles
      local function UpdateIcon()
        local state = LazyWeirdoDB.settings[this_row.cycle_key]
        local info = state_icons[state] or state_icons[OFF]
        iconTex:SetTexture(info.tex)
        iconTex:ClearAllPoints()
        iconTex:SetPoint("LEFT", C.ICON_COL - C.GRID_LEFT, info.y or 0)
        if info.r then
          iconTex:SetVertexColor(info.r, info.g, info.b)
        else
          iconTex:SetVertexColor(1, 1, 1)
        end
      end
      UpdateIcon()

      local function ShowCycleTooltip()
        GameTooltip:SetOwner(labelFrame, "ANCHOR_RIGHT")
        GameTooltip:SetText(zone_name, C.TOOLTIP_R, C.TOOLTIP_G, C.TOOLTIP_B)
        local info = state_icons[LazyWeirdoDB.settings[this_row.cycle_key]] or state_icons[OFF]
        GameTooltip:AddLine("Current: " .. info.label, 1, 1, 1)
        GameTooltip:AddLine("Click to cycle", 0.5, 0.5, 0.5)
        GameTooltip:Show()
      end

      labelFrame:SetScript("OnClick", function()
        LazyWeirdoDB.settings[this_row.cycle_key] = state_cycle[LazyWeirdoDB.settings[this_row.cycle_key]] or NEED
        UpdateIcon()
        ShowCycleTooltip()
      end)
      labelFrame:SetScript("OnEnter", function()
        ShowCycleTooltip()
      end)
    else
      -- Raid row: arrow icon, click opens popup
      iconTex:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")

      labelFrame:SetScript("OnClick", function()
        ShowRaidPopup(this_row, this)
      end)
      labelFrame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText(zone_name, C.TOOLTIP_R, C.TOOLTIP_G, C.TOOLTIP_B)
        GameTooltip:AddLine("Click to configure", 0.5, 0.5, 0.5)
        GameTooltip:Show()
      end)
    end

    labelFrame:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)

    raid_y = raid_y - C.GRID_ROW_HEIGHT
  end

  ----------------------------------------------------------------------
  -- Additional Options section
  local optionsDropdown = CreateFrame("Button", "LazyWeirdoOptionsDropdown", LazyWeirdoConfigFrame, "UIDropDownMenuTemplate")

  local _, playerClass = UnitClass("player")

  local function InitializeOptionsDropdown()
    local btnIdx = 0
    for _,opt in ipairs(toggle_options) do
      if opt.class and opt.class ~= playerClass then
        -- skip options for other classes
      else
        local setting_key = opt.setting
        local info = {}
        info.text = opt.label
        info.keepShownOnClick = 1
        info.checked = LazyWeirdoDB.settings[setting_key] and 1 or nil
        info.func = function ()
          LazyWeirdoDB.settings[setting_key] = not LazyWeirdoDB.settings[setting_key]
          if setting_key == "combat_plates" then
            if LazyWeirdoDB.settings.combat_plates and not UnitAffectingCombat("player") then
              HideNameplates()
            end
          elseif setting_key == "combat_names" then
            if not LazyWeirdoDB.settings.combat_names then
              RestoreNameCVars()
            end
          end
        end
        UIDropDownMenu_AddButton(info)
        btnIdx = btnIdx + 1

        local btn = getglobal("DropDownList1Button"..btnIdx)
        if btn then
          if not btn.el_orig_enter then
            btn.el_orig_enter = btn:GetScript("OnEnter")
            btn.el_orig_leave = btn:GetScript("OnLeave")
          end
          btn.el_label = opt.label
          btn.el_tooltip = opt.tooltip
          btn:SetScript("OnEnter", function()
            if this.el_orig_enter then this.el_orig_enter() end
            if UIDROPDOWNMENU_OPEN_MENU ~= "LazyWeirdoOptionsDropdown" then return end
            GameTooltip:SetOwner(LazyWeirdoOptionsDropdown, "ANCHOR_BOTTOMRIGHT")
            GameTooltip:SetText(this.el_label, C.TOOLTIP_R, C.TOOLTIP_G, C.TOOLTIP_B)
            GameTooltip:AddLine(this.el_tooltip, 1, 1, 1, true)
            GameTooltip:Show()
          end)
          btn:SetScript("OnLeave", function()
            if this.el_orig_leave then this.el_orig_leave() end
            GameTooltip:Hide()
          end)
        end
      end -- else (class filter)
    end
  end

  UIDropDownMenu_Initialize(optionsDropdown, InitializeOptionsDropdown)
  UIDropDownMenu_SetWidth(C.DROPDOWN_WIDTH, optionsDropdown)
  UIDropDownMenu_SetText("Options", optionsDropdown)

  ------------------------------------

  -- Function to show the popup for adding an item
  local function ShowAddItemPopup(items)
    local foo = StaticPopup_Show("ADD_ITEM_NAME")
    foo.do_add = true
    foo.data = items
  end

  local function ShowRemoveItemPopup(items,rem_item)
    local foo = StaticPopup_Show("REM_ITEM_NAME")
    foo.data = { items, rem_item }
  end

  -- Dropdown creation function (as per your provided working code)
  -- Unified dropdown for all item lists (whitelists, sell list, buy list)
  -- opts: { items, label, name, tooltip, popup (dialog name), tooltip_extra, toggleable }
  local function CreateItemListDropdown(parent, x, y, opts)
    local items = opts.items
    local label = opts.label
    local frameName = opts.name
    local tooltip = opts.tooltip
    local popup = opts.popup or "ADD_ITEM_NAME"
    local tooltip_extra = opts.tooltip_extra

    local dropdown = CreateFrame("Button", frameName, parent, "UIDropDownMenuTemplate")
    dropdown.el_default_text = label
    dropdown:SetPoint("TOP", x - C.DROPDOWN_OFFSET, y)

    local function InitializeDropdown()
      local btnIdx = 0

      -- Enabled / Disabled toggle header
      if opts.setting then
        local enabled = LazyWeirdoDB.settings[opts.setting]
        local info = {}
        info.text = enabled and "Enabled" or "Disabled"
        info.textR = enabled and 1 or 0.5
        info.textG = enabled and 1 or 0.5
        info.textB = enabled and 1 or 0.5
        info.checked = enabled and 1 or nil
        info.keepShownOnClick = 1
        info.func = function ()
          LazyWeirdoDB.settings[opts.setting] = not LazyWeirdoDB.settings[opts.setting]
          local en = LazyWeirdoDB.settings[opts.setting]
          local btn = getglobal("DropDownList1Button1")
          if btn then
            local r, g, b = en and 1 or 0.5, en and 1 or 0.5, en and 1 or 0.5
            btn:SetText(en and "Enabled" or "Disabled")
            btn:SetTextColor(r, g, b)
            btn:SetHighlightTextColor(r, g, b)
          end
        end
        UIDropDownMenu_AddButton(info)
        btnIdx = btnIdx + 1
      end

      -- "Add New item" entry
      local info = {}
      info.text = "Add New item"
      info.func = function ()
        local add = StaticPopup_Show(popup, label)
        add.data = { items = items, label = label, toggleable = opts.toggleable }
        local editbox = getglobal(add:GetName().."EditBox")

        local orig_ContainerFrameItemButton_OnClick = (function ()
          local orig = ContainerFrameItemButton_OnClick
          ContainerFrameItemButton_OnClick = function (button,ignoreModifiers,a3,a4,a5,a6,a7,a8,a9,a10)
            if (button == "LeftButton" and IsShiftKeyDown() and not ignoreModifiers and editbox:IsShown()) then
                editbox:Insert(ItemLinkToName(GetContainerItemLink(this:GetParent():GetID(), this:GetID())))
            else
              orig(button,ignoreModifiers,a3,a4,a5,a6,a7,a8,a9,a10)
            end
          end
          return orig
        end)()

        local orig_ChatFrame_OnHyperlinkShow = (function ()
          local orig = ChatFrame_OnHyperlinkShow
          ChatFrame_OnHyperlinkShow = function (link,text,button,a3,a4,a5,a6,a7,a8,a9,a10)
            if (button == "LeftButton" and IsShiftKeyDown() and not ignoreModifiers and editbox:IsShown()) then
              editbox:Insert(ItemLinkToName(text))
            else
              orig(link,text,button,a3,a4,a5,a6,a7,a8,a9,a10)
            end
          end
          return orig
        end)()

        add:SetScript("OnHide", function()
          getglobal(this:GetName() .. "EditBox"):SetText("")
          ContainerFrameItemButton_OnClick = orig_ContainerFrameItemButton_OnClick
          ChatFrame_OnHyperlinkShow = orig_ChatFrame_OnHyperlinkShow
        end)
      end
      info.textR = 0.1
      info.textG = 0.8
      info.textB = 0.1
      UIDropDownMenu_AddButton(info)
      btnIdx = btnIdx + 1

      -- tooltip on "Add New item" button
      local addBtn = getglobal("DropDownList1Button"..btnIdx)
      if addBtn then
        if not addBtn.el_orig_enter then
          addBtn.el_orig_enter = addBtn:GetScript("OnEnter")
          addBtn.el_orig_leave = addBtn:GetScript("OnLeave")
        end
        addBtn.el_dropdown_owner = frameName
        addBtn:SetScript("OnEnter", function()
          if this.el_orig_enter then this.el_orig_enter() end
          if UIDROPDOWNMENU_OPEN_MENU ~= this.el_dropdown_owner then return end
          GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
          GameTooltip:SetText(label, C.TOOLTIP_R, C.TOOLTIP_G, C.TOOLTIP_B)
          if tooltip_extra then GameTooltip:AddLine(tooltip_extra, 1, 1, 1, true) end
          GameTooltip:AddLine(tooltip, 1, 1, 1, true)
          GameTooltip:AddLine("Right-click an item to remove it.", 0.5, 0.5, 0.5, true)
          GameTooltip:Show()
        end)
        addBtn:SetScript("OnLeave", function()
          if this.el_orig_leave then this.el_orig_leave() end
          GameTooltip:Hide()
        end)
      end

      -- item entries (toggleable = { name, enabled [, count] } objects; plain = flat strings)
      if opts.toggleable then
        for _,entry in ipairs(items) do
          if entry.enabled == nil then entry.enabled = true end
          local displayText = entry.count and (entry.count .. "x " .. entry.name) or entry.name
          local thisEntry = entry
          local info = {}
          info.text = displayText
          info.value = entry.name
          info.keepShownOnClick = 1
          info.checked = entry.enabled and 1 or nil
          info.func = function ()
            thisEntry.enabled = not thisEntry.enabled
          end
          UIDropDownMenu_AddButton(info)
          btnIdx = btnIdx + 1

          local btn = getglobal("DropDownList1Button"..btnIdx)
          if btn then
            btn.el_remove_entry = entry
            btn.el_dropdown_owner = frameName
            btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            btn:SetScript("OnClick", function()
              if UIDROPDOWNMENU_OPEN_MENU == this.el_dropdown_owner and arg1 == "RightButton" then
                CloseDropDownMenus()
                local pop = StaticPopup_Show("REM_ITEM_NAME", this.el_remove_entry.name, label)
                pop.data = { items = items, item = this.el_remove_entry.name, label = label, dropdown = dropdown }
              else
                UIDropDownMenuButton_OnClick()
              end
            end)
          end
        end
      else
        for i, item in ixpairs(items) do
          local info = {}
          info.text = item
          info.value = item
          UIDropDownMenu_AddButton(info)
          btnIdx = btnIdx + 1

          local btn = getglobal("DropDownList1Button"..btnIdx)
          if btn then
            btn.el_remove_item = item
            btn.el_dropdown_owner = frameName
            btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            btn:SetScript("OnClick", function()
              if UIDROPDOWNMENU_OPEN_MENU == this.el_dropdown_owner and arg1 == "RightButton" then
                CloseDropDownMenus()
                local pop = StaticPopup_Show("REM_ITEM_NAME", this.el_remove_item, label)
                pop.data = { items = items, item = this.el_remove_item, label = label, dropdown = dropdown }
              else
                UIDropDownMenuButton_OnClick()
              end
            end)
          end
        end
      end
    end

    UIDropDownMenu_Initialize(dropdown, InitializeDropdown)
    UIDropDownMenu_SetWidth(C.DROPDOWN_WIDTH, dropdown)
    UIDropDownMenu_SetText(dropdown.el_default_text, dropdown)

    return dropdown
  end

-- Function to add item to dropdown (toggleable = { name, enabled } objects; plain = flat strings)
local function AddItemToDropdown(dropdown_list, item, list_label, toggleable)
  item = TitleCase(item)
  for _,v in ipairs(dropdown_list) do
    local existing = type(v) == "table" and v.name or v
    if string.lower(existing) == string.lower(item) then return end
  end
  if toggleable then
    table.insert(dropdown_list, { name = item, enabled = true })
  else
    table.insert(dropdown_list, item)
  end
  el_print("Added "..ITEM_COLOR..item.."|r to "..list_label..".")
end

local function RemoveItemFromDropdown(dropdown_list, item, list_label)
  for i,v in ipairs(dropdown_list) do
    local match = (v == item) or (type(v) == "table" and v.name == item)
    if match then
      local display = type(v) == "table" and v.name or v
      table.remove(dropdown_list, i)
      el_print("Removed "..ITEM_COLOR..display.."|r from "..list_label..".")
      break
    end
  end
end

-- Hidden fontstring for measuring edit box text width (EditBox lacks GetStringWidth in 1.12)
local _popupMeasureFS = UIParent:CreateFontString(nil, "ARTWORK", "ChatFontNormal")

-- Shared popup helpers for wide edit boxes
local function PopupEditBoxOnTextChanged()
  local popup = this:GetParent()
  _popupMeasureFS:SetText(this:GetText())
  local textWidth = _popupMeasureFS:GetStringWidth()
  local overflow = textWidth - C.EDITBOX_BASE_W + 20
  if overflow > 0 then
    popup:SetWidth(C.POPUP_BASE_W + overflow)
    this:SetWidth(C.EDITBOX_BASE_W + overflow)
    if this._borderLeft then
      local newWidth = this._borderLeftWidth + (C.EDITBOX_BASE_W - C.EDITBOX_DEFAULT_W) + overflow
      this._borderLeft:SetWidth(newWidth)
      this._borderLeft:SetTexCoord(0, math.min(1, newWidth / C.BORDER_TEX_W), 0, 1)
    end
  else
    popup:SetWidth(C.POPUP_BASE_W)
    this:SetWidth(C.EDITBOX_BASE_W)
    if this._borderLeft then
      local newWidth = this._borderLeftWidth + (C.EDITBOX_BASE_W - C.EDITBOX_DEFAULT_W)
      this._borderLeft:SetWidth(newWidth)
      this._borderLeft:SetTexCoord(0, math.min(1, newWidth / C.BORDER_TEX_W), 0, 1)
    end
  end
end

local function PopupOnShow()
  local editbox = getglobal(this:GetName() .. "EditBox")
  if not editbox._borderLeft then
    for _, region in pairs({editbox:GetRegions()}) do
      if region.GetTexture and region:GetTexture()
         and string.find(region:GetTexture(), "Left") then
        editbox._borderLeft = region
        editbox._borderLeftWidth = region:GetWidth()
        break
      end
    end
  end
  this:SetWidth(C.POPUP_BASE_W)
  editbox:SetWidth(C.EDITBOX_BASE_W)
  if editbox._borderLeft then
    local newWidth = editbox._borderLeftWidth + (C.EDITBOX_BASE_W - C.EDITBOX_DEFAULT_W)
    editbox._borderLeft:SetWidth(newWidth)
    editbox._borderLeft:SetTexCoord(0, math.min(1, newWidth / C.BORDER_TEX_W), 0, 1)
  end
  editbox:SetFocus()
end

local function PopupOnHide()
  local editbox = getglobal(this:GetName() .. "EditBox")
  this:SetWidth(C.POPUP_DEFAULT_W)
  editbox:SetWidth(C.EDITBOX_DEFAULT_W)
  if editbox._borderLeft then
    editbox._borderLeft:SetWidth(editbox._borderLeftWidth)
    editbox._borderLeft:SetTexCoord(0, editbox._borderLeftWidth / C.BORDER_TEX_W, 0, 1)
  end
  editbox:SetText("")
end

local function ParseBuyInput(text)
  local _,_,numStr,itemName = string.find(text, "^(%d+)x?%s+(.+)$")
  if not itemName then
    itemName = text
    numStr = "20"
  end
  local count = tonumber(numStr) or 20
  itemName = string.gsub(itemName, "^%s*", "")
  itemName = string.gsub(itemName, "%s*$", "")
  itemName = TitleCase(itemName)
  if itemName == "" then return end
  local found = false
  for _,entry in ipairs(LazyWeirdoDB.buylist) do
    if string.lower(entry.name) == string.lower(itemName) then
      entry.count = count
      entry.enabled = true
      found = true
      break
    end
  end
  if not found then
    table.insert(LazyWeirdoDB.buylist, { name = itemName, count = count, enabled = true })
  end
  el_print(format("Added %dx "..ITEM_COLOR.."%s|r to buy list.", count, itemName))
end

-- Static Popup Dialog for entering item names
StaticPopupDialogs["ADD_ITEM_NAME"] = {
  text = "Add item to %s:\nShift-click an item to insert its name.",
  button1 = "Add",
  button2 = "Cancel",
  hasEditBox = true,
  maxLetters = 255,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnAccept = function(data)
    local itemName = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
    if itemName ~= "" then
      AddItemToDropdown(data.items, itemName, data.label, data.toggleable)
    end
  end,
  EditBoxOnEnterPressed = function(data)
    local itemName = this:GetText()
    if itemName ~= "" then
      AddItemToDropdown(data.items, itemName, data.label, data.toggleable)
      this:GetParent():Hide()
    end
  end,
  EditBoxOnTextChanged = PopupEditBoxOnTextChanged,
  OnShow = PopupOnShow,
  OnHide = PopupOnHide,
  enterClicksFirstButton = true,
}

StaticPopupDialogs["REM_ITEM_NAME"] = {
  text = "Really remove %s from %s?",
  button1 = "Remove",
  button2 = "Cancel",
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnAccept = function(data)
    RemoveItemFromDropdown(data.items, data.item, data.label)
    data.dropdown.selected = nil
    UIDropDownMenu_SetText(data.dropdown.el_default_text or "", data.dropdown)
  end,
}

StaticPopupDialogs["ADD_BUY_ITEM"] = {
  text = "Enter quantity and item name:\n20 Sacred Candle\nShift-click an item to insert its name.",
  button1 = "Add",
  button2 = "Cancel",
  hasEditBox = true,
  maxLetters = 255,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnAccept = function()
    local text = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
    if text ~= "" then ParseBuyInput(text) end
  end,
  EditBoxOnEnterPressed = function()
    local text = this:GetText()
    if text ~= "" then ParseBuyInput(text) end
    this:GetParent():Hide()
  end,
  EditBoxOnTextChanged = PopupEditBoxOnTextChanged,
  OnShow = PopupOnShow,
  OnHide = PopupOnHide,
  enterClicksFirstButton = true,
}

-- Right-column dropdown layout (all positions in one spot)
local dd_idx = 0
local right_col_dropdowns = {
  { type = "options", y = -45  },
  { type = "list",   y = -80,   label = "Buy List",   list = "buylist",   setting = "auto_buy",        tooltip = "Auto-buy items from vendors.", popup = "ADD_BUY_ITEM", toggleable = true },
  { type = "list",   y = -115,  label = "Sell List",   list = "selllist",  setting = "auto_sell_list",  tooltip = "A list of items that will always be sold at vendors.", toggleable = true },
  { type = "list",   y = -215,  label = "Need List",  list = "needlist",  setting = "need_whitelist",  tooltip = "A list of items that will always be Needed, even BoP items.", toggleable = true },
  { type = "list",   y = -245,  label = "Greed List", list = "greedlist", setting = "greed_whitelist", tooltip = "A list of items that will always be Greeded, even BoP items.", toggleable = true },
  { type = "list",   y = -275,  label = "Pass List",  list = "passlist",  setting = "pass_whitelist",  tooltip = "A list of items that will always be Passed, and not auto-looted.", toggleable = true },
}
for _,dd in ipairs(right_col_dropdowns) do
  if dd.type == "options" then
    optionsDropdown:SetPoint("TOP", rightColX - C.DROPDOWN_OFFSET, dd.y)
  elseif dd.type == "list" then
    dd_idx = dd_idx + 1
    CreateItemListDropdown(LazyWeirdoConfigFrame, rightColX, dd.y, {
      items = LazyWeirdoDB[dd.list],
      label = dd.label,
      name = "LazyWeirdoDD"..dd_idx,
      tooltip = dd.tooltip,
      tooltip_extra = dd.tooltip_extra,
      popup = dd.popup,
      toggleable = dd.toggleable,
      setting = dd.setting,
    })
  end
end

  ----------------------------------------------------------------------
  -- Minimap button (shape-aware, based on MBF's snapMinimap approach)
  local MinimapShapes = {
    ["ROUND"]                   = {true, true, true, true},
    ["SQUARE"]                  = {false, false, false, false},
    ["CORNER-TOPLEFT"]          = {false, false, false, true},
    ["CORNER-TOPRIGHT"]         = {false, false, true, false},
    ["CORNER-BOTTOMLEFT"]       = {false, true, false, false},
    ["CORNER-BOTTOMRIGHT"]      = {true, false, false, false},
    ["SIDE-LEFT"]               = {false, true, false, true},
    ["SIDE-RIGHT"]              = {true, false, true, false},
    ["SIDE-TOP"]                = {false, false, true, true},
    ["SIDE-BOTTOM"]             = {true, true, false, false},
    ["TRICORNER-TOPLEFT"]       = {false, true, true, true},
    ["TRICORNER-TOPRIGHT"]      = {true, false, true, true},
    ["TRICORNER-BOTTOMLEFT"]    = {true, true, false, true},
    ["TRICORNER-BOTTOMRIGHT"]   = {true, true, true, false},
  }

  local function GetMinimapShapeCompat()
    if Squeenix then return "SQUARE" end
    if GetMinimapShape then return GetMinimapShape() or "ROUND" end
    if simpleMinimap_Skins then
      local skins = { "ROUND", "SQUARE", "CORNER-BOTTOMLEFT", "CORNER-BOTTOMRIGHT", "CORNER-TOPRIGHT", "CORNER-TOPLEFT" }
      return skins[simpleMinimap_Skins.db.profile.skin] or "ROUND"
    end
    if pfUI and pfUI_config and pfUI_config["disabled"] and pfUI_config["disabled"]["minimap"] ~= "1" then return "SQUARE" end
    return "ROUND"
  end

  local minimapBtn = CreateFrame("Button", "LazyWeirdoMinimapButton", Minimap)
  minimapBtn:SetWidth(32)
  minimapBtn:SetHeight(32)
  minimapBtn:SetFrameStrata("MEDIUM")
  minimapBtn:SetFrameLevel(8)
  minimapBtn:SetToplevel(true)
  minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local icon = minimapBtn:CreateTexture(nil, "ARTWORK")
  icon:SetTexture("Interface\\Icons\\INV_Box_02")
  icon:SetWidth(20)
  icon:SetHeight(20)
  icon:SetPoint("CENTER", 0, 0)

  local border = minimapBtn:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetWidth(56)
  border:SetHeight(56)
  border:SetPoint("TOPLEFT", 0, 0)

  local function MinimapButton_UpdatePosition(angle)
    local mapSize = (Minimap:GetWidth() / 2)
    local rad = math.rad(angle)
    local x = math.cos(rad)
    local y = math.sin(rad)

    -- determine quadrant and check if round or square in that corner
    local q = 1
    if x < 0 then q = q + 1 end
    if y > 0 then q = q + 2 end
    local quadTable = MinimapShapes[GetMinimapShapeCompat()] or MinimapShapes["ROUND"]
    if quadTable[q] then
      x = x * mapSize
      y = y * mapSize
    else
      local diagDist = math.sqrt(2 * mapSize * mapSize)
      x = math.max(-mapSize, math.min(x * diagDist, mapSize))
      y = math.max(-mapSize, math.min(y * diagDist, mapSize))
    end

    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
  end

  LazyWeirdoDB.minimap_angle = LazyWeirdoDB.minimap_angle or 220
  MinimapButton_UpdatePosition(LazyWeirdoDB.minimap_angle)

  minimapBtn:RegisterForDrag("LeftButton")
  minimapBtn:SetScript("OnDragStart", function()
    this.dragging = true
  end)
  minimapBtn:SetScript("OnDragStop", function()
    this.dragging = false
  end)
  minimapBtn:SetScript("OnUpdate", function()
    if not this.dragging then return end
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    cx, cy = cx / scale, cy / scale
    local angle = math.deg(math.atan2(cy - my, cx - mx))
    LazyWeirdoDB.minimap_angle = angle
    MinimapButton_UpdatePosition(angle)
  end)

  minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  minimapBtn:SetScript("OnClick", function()
    if LazyWeirdoConfigFrame:IsShown() then
      LazyWeirdoConfigFrame:Hide()
    else
      LazyWeirdoConfigFrame:Show()
    end
  end)
  minimapBtn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText("LazyWeirdo", C.TOOLTIP_R, C.TOOLTIP_G, C.TOOLTIP_B)
    GameTooltip:AddLine("Click to toggle config.", 1, 1, 1)
    GameTooltip:AddLine("Drag to move.", 0.5, 0.5, 0.5)
    GameTooltip:Show()
  end)
  minimapBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

end