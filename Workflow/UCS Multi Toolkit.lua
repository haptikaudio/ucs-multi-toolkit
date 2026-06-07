-- @description UCS Multi Toolkit
-- @author Haptik Audio
-- @version 1.0.1
-- @about
--   UCS naming and batch workflow for REAPER: space, glue, normalize, rename,
--   and render. Includes UCS field suggest, workflow presets, pre-flight checks,
--   and optional region-based rendering.
--
--   Requires REAPER 6.0 or newer. No SWS or ReaImGui required.
--
--   Install via ReaPack (recommended) or copy Workflow/UCS Multi Toolkit.lua
--   and Haptik_Audio_logo.png into the same folder.
-- @link https://github.com/haptikaudio/ucs-multi-toolkit
-- @changelog
--   v1.0.1 Fix ReaPack Action List registration
--   v1.0.0 Initial public release
-- @provides
--   [main] .
--   Haptik_Audio_logo.png

-- ─── UCS DATA ───────────────────────────────────────────────
local UCS = {
  categories = {
    { id="AMB",   name="Ambience",      subs={"Exterior","Interior","Nature","Urban","Industrial","Underwater","Space","Weather"} },
    { id="ANML",  name="Animals",       subs={"Domestic","Wildlife","Birds","Insects","Aquatic","Reptiles","Livestock","Exotic"} },
    { id="BOOM",  name="Boom",          subs={"Explosion","Impact","Debris","Shockwave","Rumble","Blast"} },
    { id="CRWD",  name="Crowd",         subs={"Chatter","Applause","Crowd React","Protest","Sports","Children","Market","Party"} },
    { id="DSGN",  name="Design",        subs={"Abstract","Creature","Energy","Impact","Movement","Texture","Transition","Weapon"} },
    { id="ELEC",  name="Electricity",   subs={"Buzz","Spark","Hum","Static","Power Up","Power Down","Zap","Arc"} },
    { id="EXPL",  name="Explosion",     subs={"Small","Medium","Large","Distant","Interior","Underwater","Fire","Debris"} },
    { id="FOOT",  name="Footsteps",     subs={"Concrete","Wood","Gravel","Grass","Metal","Carpet","Dirt","Snow","Mud","Tile"} },
    { id="HIT",   name="Hit",           subs={"Soft","Medium","Hard","Flesh","Metal","Wood","Glass","Cloth"} },
    { id="HUMD",  name="Human",         subs={"Breath","Cough","Effort","Laugh","Scream","Whisper","Voice","Cry","Groan"} },
    { id="INTFC", name="Interface",     subs={"Click","Select","Notification","Alert","Confirm","Error","Hover","Open","Close"} },
    { id="LOCK",  name="Lock/Unlock",   subs={"Lock","Unlock","Click","Bolt","Latch","Electronic"} },
    { id="MACH",  name="Machine",       subs={"Engine","Motor","Fan","Pump","Conveyor","Industrial","Generator","Servo"} },
    { id="MISC",  name="Miscellaneous", subs={"Generic","Abstract","Household","Debris","Rattle","Scrape","Thud"} },
    { id="MUSC",  name="Music",         subs={"Stinger","Loop","Sting","Jingle","Ambient","Orchestral","Electronic","Hybrid"} },
    { id="NATR",  name="Nature",        subs={"Wind","Rain","Thunder","Fire","Water","Leaves","Ice","Earthquake"} },
    { id="PROP",  name="Props",         subs={"Cloth","Ceramic","Glass","Plastic","Paper","Rubber","Leather","Stone","Wood"} },
    { id="SCI",   name="Science/Tech",  subs={"Computer","Scanner","Robot","Beep","Laser","Shield","Teleport","System"} },
    { id="SRVO",  name="Servo",         subs={"Small","Medium","Large","Fast","Slow","Loop","Start","Stop"} },
    { id="TRAN",  name="Transport",     subs={"Car","Truck","Train","Plane","Helicopter","Boat","Bicycle","Motorcycle"} },
    { id="WATR",  name="Water",         subs={"Drip","Splash","Stream","Ocean","Rain","Pour","Bubble","Underwater"} },
    { id="WHRP",  name="Whoosh",        subs={"Fast","Slow","Heavy","Light","Debris","Air","Fabric","Designed"} },
    { id="WIND",  name="Wind",          subs={"Light Breeze","Strong Wind","Gust","Howl","Through Leaves","Through Building"} },
    { id="WOOD",  name="Wood",          subs={"Creak","Break","Knock","Scrape","Splinter","Impact","Floor"} },
  }
}

local DEFAULT_PRESET_IDX = 1

-- ─── GUI STATE ──────────────────────────────────────────────
local STATE = {
  gap_ms        = 1000,
  gap_ms_str    = "1000",
  norm_enable   = false,
  norm_mode     = "peak",
  norm_mode_idx = 1,
  norm_level    = -1.0,
  norm_level_str= "-1.0",
  preset_idx    = DEFAULT_PRESET_IDX,
  dd_preset_open = false,
  scroll_preset = 0,
  dd_norm_open  = false,
  validation_issues = {},
  cat_idx       = 1,
  sub_idx       = 1,
  vendor        = "",
  user_data     = "",
  recall_user_data = true,
  microvariant  = "",
  take_num_str  = "",
  auto_take_inc = true,
  free_notes    = "",
  render_use_reaper     = true,
  render_open_dialog    = false,
  render_regions        = false,
  render_root           = "",
  suggest_all_fields    = false,
  confirm_before_run    = true,
  sync_render_preset    = true,
  post_render_import    = false,
  post_render_create_track = true,
  preflight             = nil,
  status_msg    = "",
  status_timer  = 0,
  dd_cat_open   = false,
  dd_sub_open   = false,
  scroll_cat    = 0,
  scroll_sub    = 0,
  scroll_y      = 0,
}

-- ─── PERSISTENCE ─────────────────────────────────────────────
local EXT_SECTION = "UCSAudioTool"
local PRESET_SECTION = "UCSAudioToolPresets"

local BUILTIN_PRESETS = {
  { name = "Clean Slate",     gap_ms_str = "1000", norm_enable = false, norm_mode = "peak", norm_level_str = "-1.0",
    cat_idx = 1, sub_idx = 1, vendor = "", user_data = "", microvariant = "", take_num_str = "",
    auto_take_inc = true, free_notes = "", clear_inputs = true },
  { name = "Variation Stack", gap_ms_str = "1000", norm_enable = true,  norm_mode = "peak", norm_level_str = "-1.0",  auto_take_inc = true  },
  { name = "One-Shot Glue",   gap_ms_str = "500",  norm_enable = true,  norm_mode = "peak", norm_level_str = "-1.0",  auto_take_inc = false },
  { name = "Dialogue / VO",   gap_ms_str = "0",    norm_enable = true,  norm_mode = "lufs", norm_level_str = "-23.0", auto_take_inc = false },
  { name = "SFX Batch",       gap_ms_str = "1000", norm_enable = true,  norm_mode = "lufs", norm_level_str = "-14.0", auto_take_inc = true  },
}

local NORM_MODE_NAMES = { "Peak (dB)", "LUFS-I" }
local NORM_MODE_VALUES = { "peak", "lufs" }
local settings_dirty = false
local input_edits
local frame_char = 0
local frame_codepoint = 0
local RT = {
  pending_action = nil,
  scroll_target_y = 0,
  last_scroll_update = reaper.time_precise(),
  saved_w = 720,
  saved_h = 900,
}

local function mark_dirty()
  settings_dirty = true
end

local function set_status(msg, frames)
  STATE.status_msg   = msg
  STATE.status_timer = frames or 200
end

local function cleanup()
  reaper.SetExtState(EXT_SECTION, "running", "0", false)
  if gfx.quit then gfx.quit() end
end

local function save_settings(win_w, win_h)
  reaper.SetExtState(EXT_SECTION, "gap_ms",       STATE.gap_ms_str,    true)
  reaper.SetExtState(EXT_SECTION, "norm_enable",  STATE.norm_enable and "1" or "0", true)
  reaper.SetExtState(EXT_SECTION, "norm_mode",    STATE.norm_mode, true)
  reaper.SetExtState(EXT_SECTION, "norm_level",   STATE.norm_level_str, true)
  reaper.SetExtState(EXT_SECTION, "preset_idx",   tostring(STATE.preset_idx), true)
  reaper.SetExtState(EXT_SECTION, "scroll_y",     tostring(math.floor(STATE.scroll_y)), true)
  reaper.SetExtState(EXT_SECTION, "cat_idx",      tostring(STATE.cat_idx), true)
  reaper.SetExtState(EXT_SECTION, "sub_idx",      tostring(STATE.sub_idx), true)
  reaper.SetExtState(EXT_SECTION, "vendor",       STATE.vendor,        true)
  reaper.SetExtState(EXT_SECTION, "recall_user_data", STATE.recall_user_data and "1" or "0", true)
  if STATE.recall_user_data then
    reaper.SetExtState(EXT_SECTION, "user_data", STATE.user_data, true)
  end
  reaper.SetExtState(EXT_SECTION, "microvariant", STATE.microvariant,  true)
  reaper.SetExtState(EXT_SECTION, "take_num",     STATE.take_num_str,  true)
  reaper.SetExtState(EXT_SECTION, "auto_take_inc", STATE.auto_take_inc and "1" or "0", true)
  reaper.SetExtState(EXT_SECTION, "free_notes",   STATE.free_notes,    true)
  reaper.SetExtState(EXT_SECTION, "render_reaper", STATE.render_use_reaper and "1" or "0", true)
  reaper.SetExtState(EXT_SECTION, "render_dialog", STATE.render_open_dialog and "1" or "0", true)
  reaper.SetExtState(EXT_SECTION, "render_regions", STATE.render_regions and "1" or "0", true)
  reaper.SetExtState(EXT_SECTION, "render_root",  STATE.render_root,   true)
  reaper.SetExtState(EXT_SECTION, "suggest_all",  STATE.suggest_all_fields and "1" or "0", true)
  reaper.SetExtState(EXT_SECTION, "confirm_run",  STATE.confirm_before_run and "1" or "0", true)
  reaper.SetExtState(EXT_SECTION, "sync_render",  STATE.sync_render_preset and "1" or "0", true)
  reaper.SetExtState(EXT_SECTION, "post_import",  STATE.post_render_import and "1" or "0", true)
  reaper.SetExtState(EXT_SECTION, "post_create",  STATE.post_render_create_track and "1" or "0", true)
  if win_w and win_h then
    reaper.SetExtState(EXT_SECTION, "win_w", tostring(math.floor(win_w)), true)
    reaper.SetExtState(EXT_SECTION, "win_h", tostring(math.floor(win_h)), true)
  end
  local dock = gfx.dock(-1)
  if dock and dock >= 0 then
    reaper.SetExtState(EXT_SECTION, "dock", tostring(dock), true)
  end
  settings_dirty = false
end

local function load_settings()
  local function get(key, default)
    local v = reaper.GetExtState(EXT_SECTION, key)
    return (v ~= "" and v) or default
  end

  STATE.gap_ms_str     = get("gap_ms", "1000")
  STATE.gap_ms         = tonumber(STATE.gap_ms_str) or 1000

  STATE.norm_enable    = get("norm_enable", "0") == "1"
  STATE.norm_mode      = get("norm_mode", "peak")
  STATE.norm_level_str = get("norm_level", "-1.0")
  STATE.norm_level     = tonumber(STATE.norm_level_str) or -1.0
  STATE.norm_mode_idx  = (STATE.norm_mode == "lufs") and 2 or 1
  STATE.preset_idx     = math.max(1, tonumber(get("preset_idx", tostring(DEFAULT_PRESET_IDX))) or DEFAULT_PRESET_IDX)
  if get("preset_order_v2", "0") == "0" then
    local old_idx = STATE.preset_idx
    if old_idx >= 1 and old_idx <= 4 then
      STATE.preset_idx = old_idx + 1
    end
    reaper.SetExtState(EXT_SECTION, "preset_order_v2", "1", true)
  end
  STATE.scroll_y       = math.max(0, tonumber(get("scroll_y", "0")) or 0)

  STATE.cat_idx        = math.max(1, math.min(#UCS.categories, tonumber(get("cat_idx", "1")) or 1))
  STATE.sub_idx        = math.max(1, tonumber(get("sub_idx", "1")) or 1)

  STATE.vendor         = get("vendor", "")
  STATE.recall_user_data = get("recall_user_data", "1") == "1"
  STATE.user_data      = STATE.recall_user_data and get("user_data", "") or ""
  STATE.microvariant   = get("microvariant", "")
  STATE.take_num_str   = get("take_num", "01")
  STATE.auto_take_inc  = get("auto_take_inc", "1") == "1"
  STATE.free_notes     = get("free_notes", "")
  STATE.render_use_reaper     = get("render_reaper", "1") == "1"
  STATE.render_open_dialog    = get("render_dialog", "0") == "1"
  STATE.render_regions        = get("render_regions", "0") == "1"
  STATE.render_root           = get("render_root", "")
  STATE.suggest_all_fields    = get("suggest_all", "0") == "1"
  STATE.confirm_before_run    = get("confirm_run", "1") == "1"
  STATE.sync_render_preset    = get("sync_render", "1") == "1"
  STATE.post_render_import    = get("post_import", "0") == "1"
  STATE.post_render_create_track = get("post_create", "1") == "1"

  local dock = tonumber(get("dock", "0")) or 0

  STATE.init_w = tonumber(get("win_w", "720")) or 720
  STATE.init_h = tonumber(get("win_h", "900")) or 900
  return dock
end

-- ─── HELPERS ────────────────────────────────────────────────
local function get_selected_items_sorted()
  local items = {}
  for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local pos  = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    table.insert(items, { item=item, pos=pos })
  end
  table.sort(items, function(a, b) return a.pos < b.pos end)
  return items
end

local function set_item_name(item, name)
  local tk = reaper.GetActiveTake(item)
  if tk then
    reaper.GetSetMediaItemTakeInfo_String(tk, "P_NAME", name, true)
  end
end

local function increment_take_number(str)
  if not str or str == "" then return "01" end
  local prefix, num = str:match("^(.-)(%d+)$")
  if num then
    local n = tonumber(num) + 1
    return (prefix or "") .. string.format("%0" .. #num .. "d", n)
  end
  if str:match("^%d+$") then
    local n = tonumber(str) + 1
    return string.format("%0" .. #str .. "d", n)
  end
  return str .. "02"
end

local function norm_mode_suffix()
  return STATE.norm_mode == "lufs" and "LUFS" or "dB"
end

local function norm_level_limits()
  if STATE.norm_mode == "lufs" then return -70.0, -5.0, 0.5 end
  return -60.0, 0.0, 0.5
end

local NORM_LEVEL_DEFAULTS = { peak = "-1.0", lufs = "-23.0" }
local norm_level_cache = { peak = "-1.0", lufs = "-23.0" }

local function seed_norm_level_cache()
  norm_level_cache.peak = NORM_LEVEL_DEFAULTS.peak
  norm_level_cache.lufs = NORM_LEVEL_DEFAULTS.lufs
  if STATE.norm_mode == "peak" then
    norm_level_cache.peak = STATE.norm_level_str
  elseif STATE.norm_mode == "lufs" then
    norm_level_cache.lufs = STATE.norm_level_str
  end
end

local function cache_current_norm_level()
  if STATE.norm_mode == "peak" or STATE.norm_mode == "lufs" then
    norm_level_cache[STATE.norm_mode] = STATE.norm_level_str
  end
end

local function sync_norm_mode_idx()
  for i, v in ipairs(NORM_MODE_VALUES) do
    if v == STATE.norm_mode then STATE.norm_mode_idx = i; return end
  end
  STATE.norm_mode_idx = 1
  STATE.norm_mode = "peak"
end

local function switch_norm_mode(new_mode)
  if STATE.norm_mode == new_mode then return end
  cache_current_norm_level()
  STATE.norm_mode = new_mode
  sync_norm_mode_idx()
  local level_str = norm_level_cache[new_mode] or NORM_LEVEL_DEFAULTS[new_mode] or "-1.0"
  STATE.norm_level_str = level_str
  STATE.norm_level = tonumber(level_str) or -1.0
  mark_dirty()
end

-- ─── PRESET WORKFLOWS ────────────────────────────────────────
local function get_user_preset_count()
  return math.max(0, tonumber(reaper.GetExtState(PRESET_SECTION, "count")) or 0)
end

local function get_preset_names()
  local names = {}
  for _, p in ipairs(BUILTIN_PRESETS) do table.insert(names, p.name) end
  local count = get_user_preset_count()
  for i = 1, count do
    local n = reaper.GetExtState(PRESET_SECTION, "name_" .. i)
    if n ~= "" then table.insert(names, n) end
  end
  return names
end

local function capture_render_preset_blob()
  local fmt = select(2, reaper.GetSetProjectInfo_String(0, "RENDER_FORMAT", "", false)) or ""
  local fmt2 = select(2, reaper.GetSetProjectInfo_String(0, "RENDER_FORMAT2", "", false)) or ""
  return table.concat({
    tostring(reaper.GetSetProjectInfo(0, "RENDER_SRATE", 0, false)),
    tostring(reaper.GetSetProjectInfo(0, "RENDER_CHANNELS", 0, false)),
    fmt:gsub("\31", "\29"),
    fmt2:gsub("\31", "\29"),
  }, "\31")
end

local function apply_render_preset_blob(blob)
  if not blob or blob == "" then return end
  local p = {}
  for part in blob:gmatch("[^\31]+") do table.insert(p, part) end
  if #p < 4 then return end
  reaper.GetSetProjectInfo(0, "RENDER_SRATE", tonumber(p[1]) or 0, true)
  reaper.GetSetProjectInfo(0, "RENDER_CHANNELS", tonumber(p[2]) or 2, true)
  reaper.GetSetProjectInfo_String(0, "RENDER_FORMAT", p[3]:gsub("\29", "\31"), true)
  reaper.GetSetProjectInfo_String(0, "RENDER_FORMAT2", p[4]:gsub("\29", "\31"), true)
end

local function serialize_workflow_state()
  local parts = {
    STATE.gap_ms_str,
    STATE.norm_enable and "1" or "0",
    STATE.norm_mode,
    STATE.norm_level_str,
    tostring(STATE.cat_idx),
    tostring(STATE.sub_idx),
    STATE.vendor,
    STATE.user_data,
    STATE.microvariant,
    STATE.take_num_str,
    STATE.auto_take_inc and "1" or "0",
    STATE.free_notes,
    STATE.sync_render_preset and "1" or "0",
  }
  if STATE.sync_render_preset then
    table.insert(parts, capture_render_preset_blob())
  else
    table.insert(parts, "")
  end
  return table.concat(parts, "\31")
end

local function deserialize_workflow_state(data)
  local p = {}
  for part in data:gmatch("[^\31]+") do table.insert(p, part) end
  if #p < 10 then return false end
  STATE.gap_ms_str     = p[1]
  STATE.gap_ms         = tonumber(p[1]) or 1000
  STATE.norm_enable    = p[2] == "1"
  STATE.norm_mode      = p[3]
  STATE.norm_level_str = p[4]
  STATE.norm_level     = tonumber(p[4]) or -1.0
  STATE.cat_idx        = math.max(1, math.min(#UCS.categories, tonumber(p[5]) or 1))
  STATE.sub_idx        = math.max(1, tonumber(p[6]) or 1)
  STATE.vendor         = p[7]
  STATE.user_data      = p[8]
  STATE.microvariant   = p[9]
  STATE.take_num_str   = p[10]
  STATE.auto_take_inc  = p[11] == "1"
  STATE.free_notes     = p[12] or ""
  if p[13] ~= nil then
    STATE.sync_render_preset = p[13] == "1"
    if STATE.sync_render_preset and p[14] and p[14] ~= "" then
      apply_render_preset_blob(p[14])
    end
  end
  sync_norm_mode_idx()
  seed_norm_level_cache()
  return true
end

local function apply_preset_fields(p)
  if not p then return end
  if p.gap_ms_str      then STATE.gap_ms_str = p.gap_ms_str; STATE.gap_ms = tonumber(p.gap_ms_str) or STATE.gap_ms end
  if p.norm_enable ~= nil then STATE.norm_enable = p.norm_enable end
  if p.norm_mode       then STATE.norm_mode = p.norm_mode end
  if p.norm_level_str  then
    STATE.norm_level_str = p.norm_level_str
    STATE.norm_level = tonumber(p.norm_level_str) or STATE.norm_level
  end
  if p.cat_idx ~= nil then STATE.cat_idx = math.max(1, math.min(#UCS.categories, p.cat_idx)) end
  if p.sub_idx ~= nil then STATE.sub_idx = math.max(1, p.sub_idx) end
  if p.vendor ~= nil then STATE.vendor = p.vendor end
  if p.user_data ~= nil then STATE.user_data = p.user_data end
  if p.microvariant ~= nil then STATE.microvariant = p.microvariant end
  if p.take_num_str ~= nil then STATE.take_num_str = p.take_num_str end
  if p.auto_take_inc ~= nil then STATE.auto_take_inc = p.auto_take_inc end
  if p.free_notes ~= nil then STATE.free_notes = p.free_notes end
  if p.sync_render_preset ~= nil then STATE.sync_render_preset = p.sync_render_preset end
  if p.render_blob then apply_render_preset_blob(p.render_blob) end
  sync_norm_mode_idx()
  seed_norm_level_cache()
  if p.clear_inputs then
    input_edits["userdat"] = nil
    input_edits["vendor"] = nil
    input_edits["mvar"] = nil
    input_edits["takenum"] = nil
    input_edits["fnotes"] = nil
  end
end

local function apply_preset_idx(idx)
  local names = get_preset_names()
  if idx < 1 or idx > #names then return end
  STATE.preset_idx = idx
  if idx <= #BUILTIN_PRESETS then
    apply_preset_fields(BUILTIN_PRESETS[idx])
    set_status("Loaded preset: " .. names[idx])
    mark_dirty()
    return
  end
  local user_i = idx - #BUILTIN_PRESETS
  local data = reaper.GetExtState(PRESET_SECTION, "data_" .. user_i)
  if data ~= "" and deserialize_workflow_state(data) then
    set_status("Loaded preset: " .. names[idx])
    mark_dirty()
  end
end

local function save_current_preset()
  local ok, name = reaper.GetUserInputs("Save Workflow Preset", 1, "Preset name:", "My Preset")
  if not ok or name == "" then return end
  name = name:gsub("%s+", " "):match("^%s*(.-)%s*$") or name
  local count = get_user_preset_count()
  for i = 1, count do
    if reaper.GetExtState(PRESET_SECTION, "name_" .. i) == name then
      reaper.SetExtState(PRESET_SECTION, "data_" .. i, serialize_workflow_state(), true)
      STATE.preset_idx = #BUILTIN_PRESETS + i
      set_status("Updated preset: " .. name)
      mark_dirty()
      return
    end
  end
  local new_i = count + 1
  reaper.SetExtState(PRESET_SECTION, "count", tostring(new_i), true)
  reaper.SetExtState(PRESET_SECTION, "name_" .. new_i, name, true)
  reaper.SetExtState(PRESET_SECTION, "data_" .. new_i, serialize_workflow_state(), true)
  STATE.preset_idx = #BUILTIN_PRESETS + new_i
  set_status("Saved preset: " .. name)
  mark_dirty()
end

local function delete_current_user_preset()
  local idx = STATE.preset_idx
  if idx <= #BUILTIN_PRESETS then
    set_status("Built-in presets cannot be deleted.")
    return
  end
  local user_i = idx - #BUILTIN_PRESETS
  local count = get_user_preset_count()
  if user_i < 1 or user_i > count then return end
  for i = user_i, count - 1 do
    reaper.SetExtState(PRESET_SECTION, "name_" .. i, reaper.GetExtState(PRESET_SECTION, "name_" .. (i + 1)), true)
    reaper.SetExtState(PRESET_SECTION, "data_" .. i, reaper.GetExtState(PRESET_SECTION, "data_" .. (i + 1)), true)
  end
  reaper.DeleteExtState(PRESET_SECTION, "name_" .. count, true)
  reaper.DeleteExtState(PRESET_SECTION, "data_" .. count, true)
  reaper.SetExtState(PRESET_SECTION, "count", tostring(count - 1), true)
  STATE.preset_idx = DEFAULT_PRESET_IDX
  set_status("Preset deleted.")
  mark_dirty()
end

-- ─── SMART FIELD SUGGESTIONS ─────────────────────────────────
local action_suggest_from_selection
;(function()
local function normalize_token(s)
  return (s or ""):upper():gsub("[/%-]", "_"):gsub("%s+", "_"):gsub("_+", "_")
end

local function find_cat_by_id(id)
  local key = normalize_token(id)
  for i, c in ipairs(UCS.categories) do
    if normalize_token(c.id) == key then return i end
  end
end

local function find_cat_by_name(name)
  local key = normalize_token(name)
  for i, c in ipairs(UCS.categories) do
    if normalize_token(c.name) == key then return i end
  end
end

local function token_matches_cat_name(cat, token)
  return normalize_token(cat.name) == normalize_token(token)
end

local function find_sub_idx(cat, sub_str)
  if not cat or not cat.subs then return nil end
  local key = normalize_token(sub_str)
  for i, s in ipairs(cat.subs) do
    if normalize_token(s) == key then return i end
  end
  for i, s in ipairs(cat.subs) do
    local sk = normalize_token(s)
    if #key >= 3 and (sk:find(key, 1, true) or key:find(sk, 1, true)) then
      return i
    end
  end
end

local function stem_token(tok)
  if #tok > 5 and tok:sub(-3) == "ing" then return tok:sub(1, -4) end
  if #tok > 4 and tok:sub(-2) == "es" then return tok:sub(1, -3) end
  if #tok > 3 and tok:sub(-1) == "s" then return tok:sub(1, -2) end
  if #tok > 4 and tok:sub(-2) == "ed" then return tok:sub(1, -3) end
  return tok
end

local function words_from_label(label)
  local words = {}
  local seen = {}
  local norm = (label or ""):lower():gsub("[/%-]", " ")
  for w in norm:gmatch("[%w]+") do
    if #w >= 2 and not seen[w] then
      seen[w] = true
      table.insert(words, w)
    end
  end
  return words
end

local function tokenize_name(name)
  name = (name or ""):gsub("%.[%w]+$", "")
  name = name:gsub("(%l)(%u)", "%1 %2")
  name = name:gsub("(%u)(%u)(%l)", "%1%2 %3")
  name = name:lower()
  local tokens, seen = {}, {}
  for part in name:gmatch("[%w]+") do
    if #part >= 2 and not seen[part] then
      seen[part] = true
      table.insert(tokens, part)
      local stem = stem_token(part)
      if stem ~= part and #stem >= 2 and not seen[stem] then
        seen[stem] = true
        table.insert(tokens, stem)
      end
    end
  end
  return tokens, name
end

local function token_pair_score(tok, term)
  if tok == term then return 15 end
  if stem_token(tok) == term or tok == stem_token(term) then return 12 end
  if #term >= 3 and #tok >= 3 then
    if tok:find(term, 1, true) then return 8 end
    if term:find(tok, 1, true) then return 6 end
  end
  return 0
end

local function score_words_against_tokens(words, tokens, name_lower, weight)
  local score = 0
  for _, word in ipairs(words) do
    for _, tok in ipairs(tokens) do
      score = score + token_pair_score(tok, word) * weight
    end
    if #word >= 3 and name_lower:find(word, 1, true) then
      score = score + 4 * weight
    end
  end
  return score
end

-- Common sound-design terms that may not appear verbatim in UCS labels
local KEYWORD_HINTS = {
  footstep = { cat = "FOOT", weight = 22 },
  footsteps = { cat = "FOOT", weight = 22 },
  footfall = { cat = "FOOT", weight = 20 },
  walk = { cat = "FOOT", weight = 16 },
  walking = { cat = "FOOT", weight = 18 },
  run = { cat = "FOOT", weight = 14 },
  running = { cat = "FOOT", weight = 16 },
  stomp = { cat = "FOOT", weight = 16 },
  whoosh = { cat = "WHRP", weight = 24 },
  swoosh = { cat = "WHRP", weight = 24 },
  swish = { cat = "WHRP", weight = 20 },
  whoop = { cat = "WHRP", weight = 14 },
  wind = { cat = "WIND", weight = 18 },
  breeze = { cat = "WIND", sub = "Light Breeze", weight = 20 },
  gust = { cat = "WIND", sub = "Gust", weight = 20 },
  rain = { cat = "NATR", sub = "Rain", weight = 20 },
  thunder = { cat = "NATR", sub = "Thunder", weight = 22 },
  explosion = { cat = "EXPL", weight = 22 },
  explode = { cat = "EXPL", weight = 20 },
  blast = { cat = "BOOM", sub = "Blast", weight = 20 },
  boom = { cat = "BOOM", weight = 24 },
  impact = { cat = "HIT", sub = "Hard", weight = 14 },
  hit = { cat = "HIT", weight = 18 },
  punch = { cat = "HIT", sub = "Hard", weight = 16 },
  slap = { cat = "HIT", sub = "Soft", weight = 16 },
  glass = { cat = "PROP", sub = "Glass", weight = 22 },
  ceramic = { cat = "PROP", sub = "Ceramic", weight = 20 },
  plastic = { cat = "PROP", sub = "Plastic", weight = 20 },
  paper = { cat = "PROP", sub = "Paper", weight = 18 },
  rubber = { cat = "PROP", sub = "Rubber", weight = 18 },
  leather = { cat = "PROP", sub = "Leather", weight = 18 },
  stone = { cat = "PROP", sub = "Stone", weight = 18 },
  wood = { cat = "WOOD", weight = 16 },
  wooden = { cat = "WOOD", weight = 16 },
  creak = { cat = "WOOD", sub = "Creak", weight = 22 },
  splinter = { cat = "WOOD", sub = "Splinter", weight = 20 },
  metal = { cat = "HIT", sub = "Metal", weight = 14 },
  metallic = { cat = "HIT", sub = "Metal", weight = 14 },
  steel = { cat = "HIT", sub = "Metal", weight = 16 },
  cloth = { cat = "PROP", sub = "Cloth", weight = 18 },
  fabric = { cat = "WHRP", sub = "Fabric", weight = 16 },
  ui = { cat = "INTFC", weight = 18 },
  click = { cat = "INTFC", sub = "Click", weight = 18 },
  button = { cat = "INTFC", sub = "Click", weight = 16 },
  beep = { cat = "SCI", sub = "Beep", weight = 20 },
  computer = { cat = "SCI", sub = "Computer", weight = 18 },
  robot = { cat = "SCI", sub = "Robot", weight = 18 },
  laser = { cat = "SCI", sub = "Laser", weight = 20 },
  servo = { cat = "SRVO", weight = 22 },
  motor = { cat = "MACH", sub = "Motor", weight = 18 },
  engine = { cat = "MACH", sub = "Engine", weight = 20 },
  machine = { cat = "MACH", weight = 16 },
  crowd = { cat = "CRWD", weight = 20 },
  applause = { cat = "CRWD", sub = "Applause", weight = 22 },
  chatter = { cat = "CRWD", sub = "Chatter", weight = 20 },
  dog = { cat = "ANML", sub = "Domestic", weight = 18 },
  cat = { cat = "ANML", sub = "Domestic", weight = 14 },
  bird = { cat = "ANML", sub = "Birds", weight = 20 },
  insect = { cat = "ANML", sub = "Insects", weight = 20 },
  animal = { cat = "ANML", weight = 18 },
  water = { cat = "WATR", weight = 18 },
  splash = { cat = "WATR", sub = "Splash", weight = 22 },
  drip = { cat = "WATR", sub = "Drip", weight = 22 },
  pour = { cat = "WATR", sub = "Pour", weight = 18 },
  ocean = { cat = "WATR", sub = "Ocean", weight = 20 },
  stream = { cat = "WATR", sub = "Stream", weight = 18 },
  fire = { cat = "NATR", sub = "Fire", weight = 20 },
  flame = { cat = "NATR", sub = "Fire", weight = 18 },
  breath = { cat = "HUMD", sub = "Breath", weight = 20 },
  cough = { cat = "HUMD", sub = "Cough", weight = 20 },
  scream = { cat = "HUMD", sub = "Scream", weight = 22 },
  whisper = { cat = "HUMD", sub = "Whisper", weight = 20 },
  voice = { cat = "HUMD", sub = "Voice", weight = 18 },
  laugh = { cat = "HUMD", sub = "Laugh", weight = 20 },
  car = { cat = "TRAN", sub = "Car", weight = 20 },
  truck = { cat = "TRAN", sub = "Truck", weight = 20 },
  train = { cat = "TRAN", sub = "Train", weight = 20 },
  plane = { cat = "TRAN", sub = "Plane", weight = 20 },
  helicopter = { cat = "TRAN", sub = "Helicopter", weight = 22 },
  ambience = { cat = "AMB", weight = 18 },
  ambient = { cat = "AMB", weight = 16 },
  lock = { cat = "LOCK", sub = "Lock", weight = 20 },
  unlock = { cat = "LOCK", sub = "Unlock", weight = 20 },
  latch = { cat = "LOCK", sub = "Latch", weight = 18 },
  electricity = { cat = "ELEC", weight = 18 },
  electric = { cat = "ELEC", weight = 16 },
  spark = { cat = "ELEC", sub = "Spark", weight = 20 },
  buzz = { cat = "ELEC", sub = "Buzz", weight = 18 },
  hum = { cat = "ELEC", sub = "Hum", weight = 16 },
  zap = { cat = "ELEC", sub = "Zap", weight = 18 },
  scrape = { cat = "MISC", sub = "Scrape", weight = 16 },
  rattle = { cat = "MISC", sub = "Rattle", weight = 16 },
  thud = { cat = "MISC", sub = "Thud", weight = 16 },
  debris = { cat = "MISC", sub = "Debris", weight = 14 },
  concrete = { cat = "FOOT", sub = "Concrete", weight = 22 },
  gravel = { cat = "FOOT", sub = "Gravel", weight = 22 },
  grass = { cat = "FOOT", sub = "Grass", weight = 22 },
  carpet = { cat = "FOOT", sub = "Carpet", weight = 22 },
  dirt = { cat = "FOOT", sub = "Dirt", weight = 20 },
  snow = { cat = "FOOT", sub = "Snow", weight = 20 },
  mud = { cat = "FOOT", sub = "Mud", weight = 20 },
  tile = { cat = "FOOT", sub = "Tile", weight = 20 },
  ["break"] = { cat = "HIT", sub = "Hard", weight = 12 },
  smash = { cat = "HIT", sub = "Hard", weight = 16 },
  crack = { cat = "HIT", sub = "Hard", weight = 12 },
  soft = { cat = "HIT", sub = "Soft", weight = 14 },
  hard = { cat = "HIT", sub = "Hard", weight = 14 },
  designed = { cat = "DSGN", weight = 14 },
  abstract = { cat = "DSGN", sub = "Abstract", weight = 16 },
  weapon = { cat = "DSGN", sub = "Weapon", weight = 18 },
  music = { cat = "MUSC", weight = 18 },
  stinger = { cat = "MUSC", sub = "Stinger", weight = 20 },
}

local function boost_score(scores, cat_id, sub_name, amount)
  local ci = find_cat_by_id(cat_id)
  if not ci then return end
  local si = sub_name and find_sub_idx(UCS.categories[ci], sub_name) or 1
  if not si then return end
  local key = ci .. ":" .. si
  scores[key] = (scores[key] or 0) + amount
end

local function apply_keyword_hints(tokens, scores)
  for _, tok in ipairs(tokens) do
    local hint = KEYWORD_HINTS[tok]
    if hint then
      local ci = hint.cat and find_cat_by_id(hint.cat)
      if ci then
        if hint.sub then
          local si = find_sub_idx(UCS.categories[ci], hint.sub)
          if si then
            local key = ci .. ":" .. si
            scores[key] = (scores[key] or 0) + hint.weight
          end
        else
          for si = 1, #UCS.categories[ci].subs do
            local key = ci .. ":" .. si
            scores[key] = (scores[key] or 0) + hint.weight * 0.6
          end
        end
      end
    end
  end
end

local function apply_compound_hints(tokens, scores)
  local set = {}
  for _, tok in ipairs(tokens) do set[tok] = true end

  if set.glass and (set["break"] or set.smash or set.shatter or set.crack) then
    boost_score(scores, "HIT", "Glass", 28)
  end
  if (set.metal or set.steel) and (set.impact or set.hit or set.clang or set.clank) then
    boost_score(scores, "HIT", "Metal", 26)
  end
  if (set.wood or set.wooden) and (set.impact or set.hit or set.knock) then
    boost_score(scores, "HIT", "Wood", 24)
  end
  if set.footstep or set.footsteps or set.walk or set.walking or set.run or set.stomp then
    for _, surface in ipairs({ "concrete", "wood", "gravel", "grass", "metal", "carpet", "dirt", "snow", "mud", "tile" }) do
      if set[surface] then
        boost_score(scores, "FOOT", surface:sub(1, 1):upper() .. surface:sub(2), 30)
      end
    end
  end
end

local function try_parse_ucs_format(name)
  name = name:gsub("%.[%w]+$", "")
  local parts = {}
  for p in name:gmatch("[^_]+") do table.insert(parts, p) end
  if #parts == 0 then return nil, nil, 0 end

  local cat_idx, sub_idx = nil, nil
  local i = 1

  local ci = find_cat_by_id(parts[1])
  if ci then
    cat_idx = ci
    i = 2
    if parts[i] and token_matches_cat_name(UCS.categories[ci], parts[i]) then
      i = i + 1
    end
  else
    ci = find_cat_by_name(parts[1])
    if ci then
      cat_idx = ci
      i = 2
    end
  end

  if cat_idx and parts[i] then
    local si = find_sub_idx(UCS.categories[cat_idx], parts[i])
    if si then
      sub_idx = si
      i = i + 1
    end
  end

  if cat_idx and not sub_idx then
    for j = i, #parts do
      local si = find_sub_idx(UCS.categories[cat_idx], parts[j])
      if si then
        sub_idx = si
        break
      end
    end
  end

  if not cat_idx then return nil, nil, 0 end
  local confidence = 80
  if sub_idx then confidence = 120 else confidence = 60 end
  return cat_idx, sub_idx, confidence
end

local function score_all_matches(tokens, name_lower)
  local scores = {}
  local best_score = 0

  for ci, cat in ipairs(UCS.categories) do
    local cat_words = words_from_label(cat.name)
    table.insert(cat_words, 1, cat.id:lower())
    local cat_score = score_words_against_tokens(cat_words, tokens, name_lower, 1.0)

    for si, sub in ipairs(cat.subs) do
      local sub_words = words_from_label(sub)
      local score = cat_score + score_words_against_tokens(sub_words, tokens, name_lower, 1.4)
      local key = ci .. ":" .. si
      scores[key] = score
      if score > best_score then best_score = score end
    end
  end

  apply_keyword_hints(tokens, scores)
  apply_compound_hints(tokens, scores)

  local best_key, best_total = nil, 0
  for key, score in pairs(scores) do
    if score > best_total then
      best_total = score
      best_key = key
    end
  end

  if not best_key or best_total < 8 then
    return nil, nil, 0, "low confidence"
  end

  local ci, si = best_key:match("^(%d+):(%d+)$")
  return tonumber(ci), tonumber(si), best_total, "keyword match"
end

local function get_first_selected_take_name()
  if reaper.CountSelectedMediaItems(0) < 1 then return nil end
  local item = reaper.GetSelectedMediaItem(0, 0)
  local tk = reaper.GetActiveTake(item)
  if not tk then return nil end
  local ok, name = reaper.GetSetMediaItemTakeInfo_String(tk, "P_NAME", "", false)
  if ok and name ~= "" then return name end
  local src = reaper.GetMediaItemTake_Source(tk)
  if src then
    local fn = reaper.GetMediaSourceFileName(src, "")
    if fn and fn ~= "" then
      return fn:match("([^/\\]+)$") or fn
    end
  end
  return nil
end

local function ucs_label_part_count(label)
  local norm = normalize_token(label)
  local n = 0
  for _ in norm:gmatch("[^_]+") do n = n + 1 end
  return math.max(1, n)
end

local function ucs_parts_match_label(label, parts, start_i, num_parts)
  if start_i + num_parts - 1 > #parts then return false end
  local combined = table.concat(parts, "_", start_i, start_i + num_parts - 1)
  return normalize_token(combined) == normalize_token(label)
end

local function advance_ucs_name_prefix(parts, cat, sub_idx)
  local i = 2

  local cat_parts = ucs_label_part_count(cat.name)
  if ucs_parts_match_label(cat.name, parts, i, cat_parts) then
    i = i + cat_parts
  elseif parts[i] and token_matches_cat_name(cat, parts[i]) then
    i = i + 1
  end

  if cat.subs and sub_idx and cat.subs[sub_idx] then
    local sub = cat.subs[sub_idx]
    local sub_parts = ucs_label_part_count(sub)
    if ucs_parts_match_label(sub, parts, i, sub_parts) then
      i = i + sub_parts
    elseif parts[i] and find_sub_idx(cat, parts[i]) == sub_idx then
      i = i + 1
    end
  end

  return i
end

local KNOWN_VENDOR_HINTS = {
  soundideas = true, soundminer = true, sonniss = true, boomlibrary = true,
  sonormedia = true, blastwave = true, prosoundeffects = true, soundmorph = true,
  audiomicro = true, sounddogs = true, hollywoodedge = true, soundstorm = true,
  soundbits = true, ["344audio"] = true, asoundeffect = true, unito = true,
}

local function vendor_hint_key(s)
  return (s or ""):lower():gsub("[%s_%.]+", "")
end

local function looks_like_vendor_token(s)
  if not s or s == "" then return false end
  if KNOWN_VENDOR_HINTS[vendor_hint_key(s)] then return true end
  if s:match("^%u[%a%d]+$") and #s >= 4 then return true end
  if s:match("^%u%u[%a%d]*$") and #s >= 3 then return true end
  return false
end

local function looks_like_micro_token(s)
  if not s or s == "" or s:match("^%d+$") then return false end
  local lower = s:lower()
  if lower:match("^v%d") or lower:match("^var%d") then return true end
  if lower:find("hard", 1, true) or lower:find("soft", 1, true) or lower:find("med", 1, true) then
    return true
  end
  if #s <= 10 and s:match("[%d]") and not looks_like_vendor_token(s) then return true end
  return false
end

local function parse_ucs_tail_fields(parts, start_i)
  local tail = {}
  for j = start_i, #parts do tail[#tail + 1] = parts[j] end
  local n = #tail
  if n == 0 then return end

  STATE.user_data = ""
  STATE.vendor = ""
  STATE.microvariant = ""
  STATE.take_num_str = ""
  STATE.free_notes = ""

  if tail[n] and tail[n]:match("^%d+$") then
    STATE.take_num_str = table.remove(tail)
    n = #tail
  end

  if n >= 3 and looks_like_micro_token(tail[n]) and looks_like_vendor_token(tail[n - 1]) then
    STATE.microvariant = table.remove(tail):upper()
    n = #tail
  end

  if n >= 2 and looks_like_vendor_token(tail[n]) then
    STATE.vendor = table.remove(tail):upper()
    n = #tail
  elseif n >= 1 and looks_like_micro_token(tail[n]) then
    STATE.microvariant = table.remove(tail):upper()
    n = #tail
  elseif n >= 2 then
    STATE.user_data = table.concat(tail, "_")
    return
  elseif n == 1 and looks_like_vendor_token(tail[1]) then
    STATE.vendor = table.remove(tail):upper()
    n = #tail
  end

  if n >= 1 then
    STATE.user_data = table.concat(tail, "_")
  end
end

local function suggest_extra_fields_from_name(name, tokens, cat_idx, sub_idx)
  name = name:gsub("%.[%w]+$", "")
  local parts = {}
  for p in name:gmatch("[^_]+") do table.insert(parts, p) end
  if #parts == 0 then return end

  local file_cat_idx = find_cat_by_id(parts[1])
  if file_cat_idx then
    local file_cat, file_sub = try_parse_ucs_format(name)
    local cat = UCS.categories[file_cat_idx]
    local i = advance_ucs_name_prefix(parts, cat, file_sub or sub_idx)
    parse_ucs_tail_fields(parts, i)
    return
  end

  local used = {}
  local cat = UCS.categories[cat_idx]
  if cat then
    used[cat.id:lower()] = true
    used[normalize_token(cat.name):lower()] = true
    if cat.subs[sub_idx] then
      for w in cat.subs[sub_idx]:lower():gmatch("[%w]+") do used[w] = true end
    end
  end

  local remaining = {}
  for _, tok in ipairs(tokens) do
    if not used[tok] and not used[stem_token(tok)] and not tok:match("^%d+$") then
      table.insert(remaining, tok)
    end
  end

  if #remaining > 0 then
    STATE.user_data = table.concat(remaining, "_")
  elseif name ~= "" then
    STATE.user_data = name:gsub("_", " ")
  end

  for j = #parts, 1, -1 do
    if parts[j]:match("^%d+$") then
      STATE.take_num_str = parts[j]
      break
    end
  end
end

local function suggest_from_name(name)
  if not name or name == "" then return false end

  local tokens, name_lower = tokenize_name(name)
  if #tokens == 0 then return false end

  local cat_idx, sub_idx, confidence, reason = nil, nil, 0, nil

  local ucs_cat, ucs_sub, ucs_conf = try_parse_ucs_format(name)
  local kw_cat, kw_sub, kw_conf, kw_reason = score_all_matches(tokens, name_lower)

  if ucs_cat and ucs_conf >= (kw_conf or 0) then
    cat_idx, sub_idx, confidence, reason = ucs_cat, ucs_sub, ucs_conf, "UCS format"
    if cat_idx and not sub_idx and kw_cat == cat_idx and kw_sub then
      sub_idx = kw_sub
      reason = "UCS format + keyword sub"
    end
  elseif kw_cat then
    cat_idx, sub_idx, confidence, reason = kw_cat, kw_sub, kw_conf, kw_reason
  end

  if not cat_idx then return false end
  if not sub_idx then
    local scores = {}
    local cat = UCS.categories[cat_idx]
    local cat_words = words_from_label(cat.name)
    table.insert(cat_words, 1, cat.id:lower())
    local cat_score = score_words_against_tokens(cat_words, tokens, name_lower, 1.0)
    for si, sub in ipairs(cat.subs) do
      local sub_words = words_from_label(sub)
      scores[cat_idx .. ":" .. si] = cat_score + score_words_against_tokens(sub_words, tokens, name_lower, 1.4)
    end
    apply_keyword_hints(tokens, scores)
    apply_compound_hints(tokens, scores)
    local best_si, best_s = nil, 0
    for si = 1, #cat.subs do
      local s = scores[cat_idx .. ":" .. si] or 0
      if s > best_s then best_s, best_si = s, si end
    end
    sub_idx = (best_si and best_s >= 6) and best_si or 1
  end

  STATE.cat_idx = cat_idx
  STATE.sub_idx = sub_idx

  if STATE.suggest_all_fields then
    suggest_extra_fields_from_name(name, tokens, cat_idx, sub_idx)
  end

  mark_dirty()
  return true, cat_idx, sub_idx, reason, confidence
end

action_suggest_from_selection = function()
  local name = get_first_selected_take_name()
  if not name then
    set_status("Select an item to suggest fields from its name.")
    return
  end
  local ok, cat_idx, sub_idx, reason = suggest_from_name(name)
  if ok then
    local cat = UCS.categories[cat_idx]
    local sub = cat.subs[sub_idx]
    set_status(string.format(
      "Suggested from \"%s\": %s / %s → %s (%s)",
      name:gsub("%.[%w]+$", ""),
      cat.id,
      cat.name,
      sub,
      reason or "match"
    ))
  else
    set_status("Could not infer UCS category from: " .. name)
  end
end
end)()

-- ─── NAME VALIDATION ─────────────────────────────────────────
local function validate_ucs_name(name)
  local issues = {}
  if not name or name == "" then
    table.insert(issues, "Name is empty")
    return issues
  end
  if name:find("%s") then table.insert(issues, "Contains spaces") end
  if name:find("__") then table.insert(issues, "Double underscores") end
  if name:find("[^%w_%-]") then table.insert(issues, "Invalid characters (use A-Z, 0-9, _)") end
  if #name > 128 then table.insert(issues, "Name too long (max 128)") end
  local cat = UCS.categories[STATE.cat_idx]
  if cat and not name:find("^" .. cat.id .. "_", 1, false) then
    table.insert(issues, "Should start with category ID (" .. cat.id .. "_)")
  end
  if name:match("_$") then table.insert(issues, "Trailing underscore") end
  return issues
end

-- ─── SCROLL ──────────────────────────────────────────────────
local ui_scroll_y = 0

local function vmy()
  return gfx.mouse_y + ui_scroll_y
end

local function screen_y(virtual_y)
  return virtual_y - ui_scroll_y
end

local function is_visible_y(virtual_y, h, view_top, view_bottom)
  local sy = screen_y(virtual_y)
  return (sy + h) > view_top and sy < view_bottom
end

-- ─── CLICK GUARD ─────────────────────────────────────────────
local click_guard = 0

local function arm_click_guard()
  click_guard = 4
end

local function any_dropdown_open()
  return STATE.dd_preset_open or STATE.dd_cat_open
      or STATE.dd_sub_open or STATE.dd_norm_open
end

-- ─── CURSOR / APPLE INSPIRED PALETTE ─────────────────────────
local C = {
  bg          = 0x1A1A1CFF,    -- Cursor-like base
  panel       = 0x2C2C2EFF,    -- Apple elevated surface
  panel_alt   = 0x363638FF,    -- tertiary surface
  border      = 0x48484AFF,    -- subtle separator
  border_focus= 0x0A84FFFF,    -- Apple system blue
  accent      = 0x0A84FFFF,    -- primary action blue
  accent_hover= 0x409BFFFF,
  accent2     = 0xFF9F0AFF,    -- Apple orange
  accent3     = 0xBF5AF2FF,    -- Apple purple
  text        = 0xF5F5F7FF,    -- primary label
  text_sec    = 0xAEAEB2FF,    -- secondary label
  text_dim    = 0x636366FF,    -- placeholder
  btn_bg      = 0x3A3A3CFF,
  btn_hover   = 0x48484AFF,
  btn_active  = 0x545456FF,
  input_bg    = 0x1C1C1EFF,
  input_focus = 0x252527FF,
  success     = 0x30D158FF,    -- Apple green
  warning     = 0xFF9F0AFF,
  error       = 0xFF453AFF,
  shadow      = 0x00000055,
  sel_bg      = 0x1E3A5AFF,    -- selection tint
  preview_bg  = 0x1C2838FF,
  preview_bd  = 0x0A84FF55,
}

local RADIUS = {
  card   = 12,
  input  = 8,
  button = 8,
  small  = 6,
  badge  = 10,
}

local function hex(c)
  return ((c >> 24) & 0xFF) / 255,
         ((c >> 16) & 0xFF) / 255,
         ((c >>  8) & 0xFF) / 255,
         ( c        & 0xFF) / 255
end
local function setcol(c) gfx.set(hex(c)) end

local function fill_rounded_rect(x, y, w, h, col, r)
  r = r or RADIUS.input
  r = math.min(r, math.floor(w / 2), math.floor(h / 2))
  if r < 1 then setcol(col); gfx.rect(x, y, w, h, 1); return end
  setcol(col)
  local aa = 1
  if h >= 2 * r then
    gfx.circle(x + r,     y + r,     r, 1, aa)
    gfx.circle(x + w - r, y + r,     r, 1, aa)
    gfx.circle(x + w - r, y + h - r, r, 1, aa)
    gfx.circle(x + r,     y + h - r, r, 1, aa)
    gfx.rect(x,           y + r,     r,     h - r * 2)
    gfx.rect(x + w - r,   y + r,     r + 1, h - r * 2)
    gfx.rect(x + r,       y,         w - r * 2, h + 1)
  else
    gfx.circle(x + r,     y + h - r, r, 1, aa)
    gfx.circle(x + w - r, y + h - r, r, 1, aa)
    gfx.rect(x + r, y + h - r, w - r * 2, r + 1)
  end
end

local function fill_rect(x, y, w, h, col)
  setcol(col); gfx.rect(x, y, w, h, 1)
end

local function stroke_rounded_rect(x, y, w, h, col, r, t)
  r = r or RADIUS.input
  t = t or 1
  r = math.min(r, math.floor(w / 2), math.floor(h / 2))
  setcol(col)
  if r < 1 then
    for i = 0, t - 1 do gfx.rect(x + i, y + i, w - i * 2, h - i * 2, 0) end
    return
  end
  for i = 0, t - 1 do
    local ri = math.max(1, r - i)
    gfx.roundrect(x + i, y + i, w - i * 2, h - i * 2, ri, 1)
  end
end

local function stroke_rect(x, y, w, h, col, t)
  stroke_rounded_rect(x, y, w, h, col, 0, t)
end

local function centered_label(x, y, w, h, txt, col)
  setcol(col or C.text)
  local tw, th = gfx.measurestr(txt)
  gfx.x = x + math.floor((w - tw) / 2)
  gfx.y = y + math.floor((h - th) / 2)
  gfx.drawstr(txt)
end

-- ─── MODERN BUTTON (release-triggered) ───────────────────────
local btn_prev_cap = {}

local function button_modern(id, x, y, w, h, txt, style)
  style = style or "default"
  local sy = screen_y(y)
  local mx, my = gfx.mouse_x, gfx.mouse_y
  local hov  = (mx >= x and mx <= x+w and my >= sy and my <= sy+h)
  local down = (gfx.mouse_cap & 1) == 1

  local bg_col, txt_col, border_col
  if style == "primary" then
    bg_col = hov and C.accent_hover or C.accent
    txt_col = 0xFFFFFFFF
    border_col = C.accent
  elseif style == "secondary" then
    bg_col = hov and C.btn_hover or C.btn_bg
    txt_col = C.accent2
    border_col = C.accent2
  elseif style == "tertiary" then
    bg_col = hov and 0x3D2E48FF or 0x32263AFF
    txt_col = C.accent3
    border_col = C.accent3
  else
    bg_col = hov and C.btn_hover or C.btn_bg
    txt_col = C.text
    border_col = hov and C.text_sec or C.border
  end

  if down and hov then bg_col = C.btn_active end

  fill_rounded_rect(x, sy, w, h, bg_col, RADIUS.button)
  stroke_rounded_rect(x, sy, w, h, border_col, RADIUS.button)
  centered_label(x, sy, w, h, txt, txt_col)

  local prev       = btn_prev_cap[id] or false
  btn_prev_cap[id] = (down and hov)
  if click_guard > 0 or any_dropdown_open() then return false end
  if STATE.preflight and not (id and id:match("^pf_")) then return false end
  return (prev and not down and hov)
end

-- ─── TEXT INPUT (EDITABLE) ───────────────────────────────────
local focused_field = nil
local input_flash   = 0
local input_fields  = {}
input_edits   = {}
local input_prev_down = false
local input_active_drag = nil
local input_last_click = { id = nil, t = 0 }

local KEY_DELETE = 6579564
local KEY_LEFT   = 1818584692
local KEY_RIGHT  = 1919379572
local KEY_HOME   = 1752132965
local KEY_END    = 6647396
local INPUT_TEXT_IMG = 1

local function register_input_field(id, x, y, w, h)
  input_fields[#input_fields + 1] = { id = id, x = x, y = y, w = w, h = h }
end

local function clear_focus_on_click_outside()
  if not focused_field or (gfx.mouse_cap & 1) ~= 1 then return end

  local mx, my = gfx.mouse_x, gfx.mouse_y
  for _, f in ipairs(input_fields) do
    local sy = screen_y(f.y)
    if mx >= f.x and mx <= f.x + f.w and my >= sy and my <= sy + f.h then
      return
    end
  end
  focused_field = nil
end

local function get_edit_state(id, value_len)
  if not input_edits[id] then
    input_edits[id] = { caret = value_len, anchor = value_len, scroll_x = 0 }
  end
  local edit = input_edits[id]
  edit.caret = math.max(0, math.min(edit.caret, value_len))
  edit.anchor = math.max(0, math.min(edit.anchor, value_len))
  edit.scroll_x = edit.scroll_x or 0
  return edit
end

local function input_visible_width(w, options)
  local pad = 20
  if options and options.suffix then
    pad = pad + gfx.measurestr(options.suffix) + 6
  end
  return math.max(24, w - pad)
end

local function clamp_input_scroll(edit, value, visible_w)
  local text_w = gfx.measurestr(value)
  local max_scroll = math.max(0, text_w - visible_w)
  edit.scroll_x = math.max(0, math.min(edit.scroll_x or 0, max_scroll))
end

local function ensure_caret_visible(edit, value, visible_w)
  local caret_x = gfx.measurestr(value:sub(1, edit.caret))
  if caret_x - edit.scroll_x > visible_w - 6 then
    edit.scroll_x = caret_x - visible_w + 6
  elseif caret_x - edit.scroll_x < 6 then
    edit.scroll_x = math.max(0, caret_x - 6)
  end
  clamp_input_scroll(edit, value, visible_w)
end

local function caret_from_mouse(value, text_x, mouse_x, scroll_x)
  local rel_x = mouse_x - text_x + (scroll_x or 0)
  if rel_x <= 0 then return 0 end
  for i = 0, #value do
    if gfx.measurestr(value:sub(1, i)) >= rel_x then
      return i
    end
  end
  return #value
end

local function selection_range(edit)
  if edit.anchor == edit.caret then return nil end
  return math.min(edit.anchor, edit.caret), math.max(edit.anchor, edit.caret)
end

local function move_caret(edit, caret, extend)
  caret = math.max(0, caret)
  edit.caret = caret
  if not extend then edit.anchor = caret end
end

local function delete_selection(value, edit)
  local s, e = selection_range(edit)
  if not s then return value, false end
  value = value:sub(1, s) .. value:sub(e + 1)
  edit.caret = s
  edit.anchor = s
  return value, true
end

local function insert_text(value, edit, text)
  local s, e = selection_range(edit)
  if s then
    value = value:sub(1, s) .. text .. value:sub(e + 1)
    edit.caret = s + #text
  else
    local c = edit.caret
    value = value:sub(1, c) .. text .. value:sub(c + 1)
    edit.caret = c + #text
  end
  edit.anchor = edit.caret
  return value
end

local function input_char_to_string(ch, codepoint)
  if codepoint and codepoint > 0 then
    if utf8 and utf8.char then
      local ok, result = pcall(utf8.char, codepoint)
      if ok and result and #result > 0 then return result end
    end
  end
  if not ch or ch < 32 or ch >= 127 then return nil end

  local shift = (gfx.mouse_cap & 8) == 8
  if ch >= 97 and ch <= 122 then
    return string.char(shift and (ch - 32) or ch)
  end
  if ch >= 65 and ch <= 90 then
    return string.char(shift and ch or (ch + 32))
  end
  return string.char(ch)
end

local function draw_input_text(value, x, sy, h, w, edit, is_focused, options)
  local text_x = x + 10
  local text_y = sy + math.floor((h - 14) / 2)
  local visible_w = input_visible_width(w, options)
  local scroll_x = edit.scroll_x or 0
  local bg_col = is_focused and C.input_focus or C.input_bg

  if is_focused then
    ensure_caret_visible(edit, value, visible_w)
    scroll_x = edit.scroll_x
  else
    local text_w = gfx.measurestr(value)
    if text_w > visible_w then
      scroll_x = text_w - visible_w
      edit.scroll_x = scroll_x
    else
      scroll_x = 0
      edit.scroll_x = 0
    end
  end

  local sel_s, sel_e
  if is_focused then sel_s, sel_e = selection_range(edit) end

  local clip_x = x + 1
  local clip_y = sy + 1
  local clip_w = w - 2
  local clip_h = h - 2
  local buf_text_x = text_x - clip_x
  local buf_text_y = text_y - clip_y

  gfx.setimgdim(INPUT_TEXT_IMG, -1, -1)
  gfx.setimgdim(INPUT_TEXT_IMG, clip_w, clip_h)
  local prev_dest = gfx.dest
  gfx.dest = INPUT_TEXT_IMG
  setcol(bg_col)
  gfx.rect(0, 0, clip_w, clip_h, 1)

  if sel_s then
    local sel_start_px = gfx.measurestr(value:sub(1, sel_s)) - scroll_x
    local sel_end_px = gfx.measurestr(value:sub(1, sel_e)) - scroll_x
    sel_start_px = math.max(0, sel_start_px)
    sel_end_px = math.min(visible_w, sel_end_px)
    if sel_end_px > sel_start_px then
      fill_rect(buf_text_x + sel_start_px, buf_text_y - 1, sel_end_px - sel_start_px, 14, C.sel_bg)
    end
  end

  setcol(C.text)
  gfx.x = buf_text_x - scroll_x
  gfx.y = buf_text_y
  gfx.drawstr(value)

  if scroll_x > 0 then
    fill_rect(0, buf_text_y - 1, 14, 16, bg_col)
    setcol(C.text_dim)
    gfx.x = 3
    gfx.y = buf_text_y
    gfx.drawstr("‹")
  end

  if gfx.measurestr(value) - scroll_x > visible_w then
    local fade_x = clip_w - 14
    fill_rect(fade_x, buf_text_y - 1, 14, 16, bg_col)
    setcol(C.text_dim)
    gfx.x = fade_x + 2
    gfx.y = buf_text_y
    gfx.drawstr("›")
  end

  if is_focused then
    input_flash = (input_flash + 1) % 60
    if input_flash < 30 then
      local caret_x = buf_text_x + gfx.measurestr(value:sub(1, edit.caret)) - scroll_x
      if caret_x >= buf_text_x - 1 and caret_x <= buf_text_x + visible_w then
        setcol(C.text)
        gfx.rect(caret_x, buf_text_y - 1, 1, 14, 1)
      end
    end
  end

  gfx.dest = prev_dest
  gfx.blit(INPUT_TEXT_IMG, 1, 0, 0, 0, clip_w, clip_h, clip_x, clip_y, clip_w, clip_h)
end

local function draw_clipped_text(text, clip_x, clip_y, clip_w, clip_h, text_x, text_y, bg_col, text_col, scroll_x)
  text = text or ""
  local buf_text_x = text_x - clip_x
  local buf_text_y = text_y - clip_y
  local visible_w = clip_w - buf_text_x - 4
  if visible_w < 8 then return end

  local text_w = gfx.measurestr(text)
  if scroll_x == nil then
    scroll_x = 0
  else
    local max_scroll = math.max(0, text_w - visible_w)
    scroll_x = math.max(0, math.min(scroll_x, max_scroll))
  end

  gfx.setimgdim(INPUT_TEXT_IMG, -1, -1)
  gfx.setimgdim(INPUT_TEXT_IMG, clip_w, clip_h)
  local prev_dest = gfx.dest
  gfx.dest = INPUT_TEXT_IMG
  setcol(bg_col)
  gfx.rect(0, 0, clip_w, clip_h, 1)
  setcol(text_col)
  gfx.x = buf_text_x - scroll_x
  gfx.y = buf_text_y
  gfx.drawstr(text)

  if scroll_x > 0 then
    fill_rect(0, buf_text_y - 1, 12, 16, bg_col)
    setcol(C.text_dim)
    gfx.x = 2
    gfx.y = buf_text_y
    gfx.drawstr("‹")
  end
  if text_w - scroll_x > visible_w then
    local fade_x = clip_w - 12
    fill_rect(fade_x, buf_text_y - 1, 12, 16, bg_col)
    setcol(C.text_dim)
    gfx.x = fade_x + 1
    gfx.y = buf_text_y
    gfx.drawstr("›")
  end

  gfx.dest = prev_dest
  gfx.blit(INPUT_TEXT_IMG, 1, 0, 0, 0, clip_w, clip_h, clip_x, clip_y, clip_w, clip_h)
end

local function text_input(id, x, y, w, h, value, placeholder, options)
  options = options or {}
  register_input_field(id, x, y, w, h)
  local sy = screen_y(y)
  local mx, my = gfx.mouse_x, gfx.mouse_y
  local hov  = (mx >= x and mx <= x+w and my >= sy and my <= sy+h)
  local down = (gfx.mouse_cap & 1) == 1
  local text_x = x + 10

  if hov and down then focused_field = id end
  local is_focused = (focused_field == id)
  local edit = get_edit_state(id, #value)
  local visible_w = input_visible_width(w, options)

  if is_focused then
    if hov and down then
      if not input_prev_down then
        local now = reaper.time_precise()
        if input_last_click.id == id and (now - input_last_click.t) < 0.35 then
          edit.anchor = 0
          edit.caret = #value
        else
          local c = caret_from_mouse(value, text_x, mx, edit.scroll_x)
          edit.anchor = c
          edit.caret = c
        end
        input_last_click.id = id
        input_last_click.t = now
        input_active_drag = id
      elseif input_active_drag == id then
        edit.caret = caret_from_mouse(value, text_x, mx, edit.scroll_x)
      end
      ensure_caret_visible(edit, value, visible_w)
    elseif not down and input_active_drag == id then
      input_active_drag = nil
    end

    local wheel_delta = gfx.mouse_wheel
    if gfx.mouse_hwheel and gfx.mouse_hwheel ~= 0 then
      wheel_delta = gfx.mouse_hwheel
      gfx.mouse_hwheel = 0
    end
    if wheel_delta ~= 0 and gfx.measurestr(value) > visible_w then
      edit.scroll_x = (edit.scroll_x or 0) - wheel_delta * 14
      clamp_input_scroll(edit, value, visible_w)
      gfx.mouse_wheel = 0
      mark_dirty()
    end
  end

  local bg_col = is_focused and C.input_focus or C.input_bg
  fill_rounded_rect(x, sy, w, h, bg_col, RADIUS.input)

  if value == "" and not is_focused then
    local ph_y = sy + math.floor((h - 14) / 2)
    local clip_x = x + 1
    local clip_y = sy + 1
    local clip_w = w - 2
    local clip_h = h - 2
    gfx.setimgdim(INPUT_TEXT_IMG, -1, -1)
    gfx.setimgdim(INPUT_TEXT_IMG, clip_w, clip_h)
    local prev_dest = gfx.dest
    gfx.dest = INPUT_TEXT_IMG
    setcol(bg_col)
    gfx.rect(0, 0, clip_w, clip_h, 1)
    setcol(C.text_dim)
    gfx.x = text_x - clip_x
    gfx.y = ph_y - clip_y
    gfx.drawstr(placeholder or "")
    gfx.dest = prev_dest
    gfx.blit(INPUT_TEXT_IMG, 1, 0, 0, 0, clip_w, clip_h, clip_x, clip_y, clip_w, clip_h)
  else
    draw_input_text(value or "", x, sy, h, w, edit, is_focused, options)
  end

  if options.suffix then
    setcol(C.text_dim)
    gfx.x = x + w - gfx.measurestr(options.suffix) - 10
    gfx.y = sy + math.floor((h-14)/2)
    gfx.drawstr(options.suffix)
  end

  stroke_rounded_rect(x, sy, w, h, is_focused and C.border_focus or C.border, RADIUS.input)

  if is_focused and frame_char ~= 0 then
    local ch = frame_char
    local prev = value
    local shift = (gfx.mouse_cap & 8) == 8
    local ctrl = (gfx.mouse_cap & 4) == 4

    if ctrl and (ch == 1 or ch == 97 or ch == 65) then
      edit.anchor = 0
      edit.caret = #value
    elseif ch == KEY_LEFT then
      move_caret(edit, edit.caret - 1, shift)
    elseif ch == KEY_RIGHT then
      move_caret(edit, edit.caret + 1, shift)
    elseif ch == KEY_HOME then
      move_caret(edit, 0, shift)
    elseif ch == KEY_END then
      move_caret(edit, #value, shift)
    elseif ch == 8 then
      if selection_range(edit) then
        value = delete_selection(value, edit)
      elseif edit.caret > 0 then
        value = value:sub(1, edit.caret - 1) .. value:sub(edit.caret + 1)
        edit.caret = edit.caret - 1
        edit.anchor = edit.caret
      end
    elseif ch == KEY_DELETE or ch == 127 then
      if selection_range(edit) then
        value = delete_selection(value, edit)
      elseif edit.caret < #value then
        value = value:sub(1, edit.caret) .. value:sub(edit.caret + 2)
      end
    elseif ch == 13 or ch == 27 then
      focused_field = nil
    else
      local char = input_char_to_string(ch, frame_codepoint)
      if char then
        if options.numeric then
          if char:match("[%d%.%-]") then
            value = insert_text(value, edit, char)
          end
        elseif options.uppercase then
          value = insert_text(value, edit, char:upper())
        else
          value = insert_text(value, edit, char)
        end
      end
    end
    if value ~= prev then mark_dirty() end
    edit.caret = math.max(0, math.min(edit.caret, #value))
    edit.anchor = math.max(0, math.min(edit.anchor, #value))
    ensure_caret_visible(edit, value, visible_w)
  end

  return value
end

-- ─── NUMERIC INPUT (with +/- buttons) ────────────────────────
local function numeric_input(id, x, y, w, h, str_value, min_v, max_v, step, suffix)
  step = step or 1
  suffix = suffix or ""

  local btn_w = 28
  local input_w = w - btn_w * 2 - 4

  local cm = button_modern(id.."_m", x, y, btn_w, h, "−", "default")

  local new_str = text_input(id.."_input", x + btn_w + 2, y, input_w, h,
                             str_value, "", { numeric = true, suffix = suffix })

  local cp = button_modern(id.."_p", x + w - btn_w, y, btn_w, h, "+", "default")

  local num_val = tonumber(new_str) or 0

  if cm then
    num_val = math.max(min_v, num_val - step)
    new_str = step < 1 and string.format("%.1f", num_val) or tostring(num_val)
    mark_dirty()
  end
  if cp then
    num_val = math.min(max_v, num_val + step)
    new_str = step < 1 and string.format("%.1f", num_val) or tostring(num_val)
    mark_dirty()
  end

  return new_str, num_val
end

-- ─── MODERN CHECKBOX ─────────────────────────────────────────
local chk_prev = {}

local function checkbox_modern(id, x, y, checked, lbl)
  local size = 18
  local sy = screen_y(y)
  local mx, my = gfx.mouse_x, gfx.mouse_y
  local hov  = (mx >= x and mx <= x+size and my >= sy and my <= sy+size)
  local down = (gfx.mouse_cap & 1) == 1

  fill_rounded_rect(x, sy, size, size, checked and C.accent or C.input_bg, RADIUS.small)
  stroke_rounded_rect(x, sy, size, size, hov and C.accent or C.border, RADIUS.small)

  if checked then
    setcol(0xFFFFFFFF)
    gfx.x = x + 4; gfx.y = sy + 2
    gfx.drawstr("✓")
  end

  setcol(C.text)
  gfx.x = x + size + 10; gfx.y = sy + 2
  gfx.drawstr(lbl or "")

  local prev   = chk_prev[id] or false
  chk_prev[id] = (down and hov)
  if STATE.preflight then return checked, false end
  if prev and not down and hov then
    mark_dirty()
    return not checked, true
  end
  return checked, false
end

-- ─── DROPDOWN ────────────────────────────────────────────────
local dd_just_closed = {}

local function dropdown_header(id, x, y, w, h, items, idx, is_open)
  local sy = screen_y(y)
  local mx, my = gfx.mouse_x, gfx.mouse_y
  local hov  = (mx >= x and mx <= x+w and my >= sy and my <= sy+h)
  local down = (gfx.mouse_cap & 1) == 1

  fill_rounded_rect(x, sy, w, h, C.input_bg, RADIUS.input)
  stroke_rounded_rect(x, sy, w, h, is_open and C.border_focus or (hov and C.text_sec or C.border), RADIUS.input)

  local display = (items and items[idx]) and items[idx] or "(none)"
  setcol(C.text); gfx.x = x+12; gfx.y = sy + math.floor((h-14)/2); gfx.drawstr(display)

  setcol(is_open and C.accent or C.text_sec)
  gfx.x = x+w-22; gfx.y = sy + math.floor((h-14)/2)
  gfx.drawstr(is_open and "▼" or "▶")

  local prev              = btn_prev_cap[id.."_dd"] or false
  btn_prev_cap[id.."_dd"] = (down and hov)
  local toggled = (prev and not down and hov and not dd_just_closed[id])
  dd_just_closed[id] = false
  if toggled then return idx, not is_open end
  return idx, is_open
end

local function dropdown_list(id, x, y, w, items, idx, scroll, item_h, max_vis)
  item_h  = item_h  or 28
  max_vis = max_vis or 8
  local sy = screen_y(y)
  local vis   = math.min(#items, max_vis)
  local h     = vis * item_h
  local total = #items
  scroll = math.max(0, math.min(scroll or 0, total - vis))

  fill_rect(x+2, sy+2, w, h, C.shadow)
  fill_rounded_rect(x, sy, w, h, C.panel, RADIUS.card)
  stroke_rounded_rect(x, sy, w, h, C.border_focus, RADIUS.card)

  local mx, my = gfx.mouse_x, gfx.mouse_y
  local down   = (gfx.mouse_cap & 1) == 1
  local new_idx = idx
  local close   = false

  for i = 0, vis-1 do
    local di = i + 1 + scroll
    if di <= total then
      local iy    = sy + i * item_h
      local hov_i = (mx >= x and mx <= x+w and my >= iy and my <= iy+item_h)
      local sel   = (di == idx)

      if sel then
        fill_rounded_rect(x + 4, iy + 2, w - 8, item_h - 4, C.sel_bg, RADIUS.small)
      elseif hov_i then
        fill_rect(x+2, iy+1, w-4, item_h-2, C.btn_hover)
      end

      setcol(sel and C.accent or (hov_i and C.text or C.text_sec))
      gfx.x = x+14; gfx.y = iy + math.floor((item_h-14)/2)
      gfx.drawstr(items[di])

      local key  = id.."_li"..di
      local prev = btn_prev_cap[key] or false
      btn_prev_cap[key] = (down and hov_i)
      if prev and not down and hov_i then
        new_idx = di
        close   = true
        dd_just_closed[id] = true
        arm_click_guard()
        mark_dirty()
      end
    end
  end

  if total > vis then
    local sb_x    = x + w - 6
    fill_rect(sb_x, sy+4, 4, h-8, 0x1A1D24FF)
    local thumb_h = math.max(16, math.floor((h-8) * vis / total))
    local thumb_y = sy + 4 + math.floor(((h-8) - thumb_h) * scroll / math.max(1, total - vis))
    fill_rounded_rect(sb_x, thumb_y, 4, thumb_h, C.text_dim, RADIUS.small)
  end

  if gfx.mouse_wheel ~= 0 and total > vis then
    scroll = scroll + (gfx.mouse_wheel < 0 and 1 or -1)
    scroll = math.max(0, math.min(scroll, total - vis))
    gfx.mouse_wheel = 0
    mark_dirty()
  end
  return new_idx, close, scroll
end

-- ─── NAME BUILDER ────────────────────────────────────────────
local function ucs_name_part(s)
  if not s or s == "" then return nil end
  return (s:gsub("[/%-]", "_"):gsub("%s+", "_"):gsub("_+", "_"))
end

local function build_ucs_name()
  local cat   = UCS.categories[STATE.cat_idx]
  local parts = {}
  local function add(s)
    s = ucs_name_part(s)
    if s then table.insert(parts, s) end
  end
  if cat then
    add(cat.id)
    add(cat.name)
    local subs = cat.subs or {}
    if STATE.sub_idx >= 1 and STATE.sub_idx <= #subs then
      add(subs[STATE.sub_idx])
    end
  end
  add(STATE.user_data); add(STATE.vendor)
  add(STATE.microvariant); add(STATE.take_num_str); add(STATE.free_notes)
  return table.concat(parts, "_")
end

local function build_ucs_name_with_take(take_str)
  local prev = STATE.take_num_str
  STATE.take_num_str = take_str or prev
  local name = build_ucs_name()
  STATE.take_num_str = prev
  return name
end

-- ─── UCS RENDER / EXPORT ─────────────────────────────────────
local function render_has_flag(settings, flag)
  return math.floor(settings / flag) % 2 == 1
end

local function render_add_flag(settings, flag)
  if render_has_flag(settings, flag) then return settings end
  return settings + flag
end

local function render_remove_flag(settings, flag)
  if render_has_flag(settings, flag) then return settings - flag end
  return settings
end

local function path_join(...)
  local parts = {}
  for i = 1, select("#", ...) do
    local p = select(i, ...)
    if p and p ~= "" then
      p = tostring(p):gsub("\\", "/"):gsub("/+$", "")
      table.insert(parts, p)
    end
  end
  return table.concat(parts, "/")
end

local function sanitize_fs_name(name)
  name = (name or ""):gsub("\\", "_"):gsub("/", "_")
  name = name:gsub('[:%*%?"<>|]', "_")
  name = name:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  if name == "" then name = "Untitled" end
  return name
end

local function get_default_render_root()
  local proj_path = reaper.GetProjectPath("")
  if proj_path == "" then
    return path_join(reaper.GetResourcePath(), "UCS Export")
  end
  return path_join(proj_path, "UCS Export")
end

local function normalize_folder_path(path)
  path = (path or ""):gsub("\\", "/"):gsub("/+$", "")
  return path
end

local function resolve_absolute_path(path)
  path = normalize_folder_path(path)
  if path == "" then return normalize_folder_path(get_default_render_root()) end

  if reaper.resolve_fn then
    local resolved = reaper.resolve_fn(path, "")
    if resolved and resolved ~= "" then
      path = normalize_folder_path(resolved)
    end
  end

  if not path:match("^/") and not path:match("^%a:[/\\]") then
    local proj = reaper.GetProjectPath("")
    if proj ~= "" then
      path = path_join(proj, path)
    end
  end

  return path
end

local RENDER_NAME_PATTERN = "$item"
local RENDER_REGION_PATTERN = "$region"

local function apply_reaper_render_target(out_dir, pattern)
  out_dir = resolve_absolute_path(out_dir)
  pattern = pattern or RENDER_NAME_PATTERN
  reaper.RecursiveCreateDirectory(out_dir, 0)
  reaper.GetSetProjectInfo_String(0, "RENDER_FILE", out_dir, true)
  reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", pattern, true)
  return out_dir
end

local function wait_for_render_finish(max_secs)
  max_secs = max_secs or 600
  local deadline = reaper.time_precise() + max_secs
  while (reaper.GetPlayState() & 1) == 1 do
    if reaper.time_precise() > deadline then return false end
    local t0 = reaper.time_precise()
    while reaper.time_precise() - t0 < 0.05 do end
  end
  return true
end

local function browse_for_render_root()
  local initial = STATE.render_root
  if initial == "" then initial = get_default_render_root() end

  local retval, folder
  if reaper.APIExists("JS_Dialog_BrowseForFolder") then
    retval, folder = reaper.JS_Dialog_BrowseForFolder("Select UCS export root folder", initial)
  else
    retval, folder = reaper.GetUserInputs(
      "UCS Export Root", 1, "Folder path (install JS_ReaScriptAPI via ReaPack to browse):,extrawidth=500",
      initial
    )
    if retval then retval = 1 end
  end

  if retval == 1 and folder and folder ~= "" then
    STATE.render_root = normalize_folder_path(folder)
    reaper.GetSetProjectInfo_String(0, "RENDER_FILE", resolve_absolute_path(STATE.render_root), true)
    reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", RENDER_NAME_PATTERN, true)
    mark_dirty()
    set_status("Export root: " .. STATE.render_root)
    return true
  end
  return false
end

local function get_render_root()
  return resolve_absolute_path(
    (STATE.render_root ~= "") and STATE.render_root or get_default_render_root()
  )
end

local function get_ucs_render_paths()
  local cat = UCS.categories[STATE.cat_idx]
  local sub = ""
  if cat and cat.subs and STATE.sub_idx >= 1 and STATE.sub_idx <= #cat.subs then
    sub = cat.subs[STATE.sub_idx]
  end
  local root = get_render_root()
  local dir_parts = {
    root,
    sanitize_fs_name(cat and cat.name or "Uncategorized"),
    sanitize_fs_name(sub),
  }
  if STATE.vendor ~= "" then
    table.insert(dir_parts, sanitize_fs_name(STATE.vendor))
  end
  return path_join(dir_parts[1], dir_parts[2], dir_parts[3], dir_parts[4]), sanitize_fs_name(build_ucs_name())
end

local function get_take_output_basename(take)
  if not take then return sanitize_fs_name(build_ucs_name()) end
  local ok, name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
  if ok and name ~= "" then return sanitize_fs_name(name) end
  return sanitize_fs_name(build_ucs_name())
end

local function copy_file(src, dest)
  local in_f = io.open(src, "rb")
  if not in_f then return false end
  local data = in_f:read("*all")
  in_f:close()
  local out_f = io.open(dest, "wb")
  if not out_f then return false end
  out_f:write(data)
  out_f:close()
  return true
end

local function export_take_direct(take, out_dir, base_name)
  local src = reaper.GetMediaItemTake_Source(take)
  if not src then return false, "No take source" end
  local src_fn = reaper.GetMediaSourceFileName(src, "")
  if not src_fn or src_fn == "" then return false, "No source file" end

  local ext = src_fn:match("%.([^%.\\/]+)$") or "wav"
  local dest = path_join(out_dir, base_name .. "." .. ext:lower())

  reaper.RecursiveCreateDirectory(out_dir, 0)

  local item = reaper.GetMediaItemTake_Item(take)
  local startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local src_len = reaper.GetMediaSourceLength(src)
  if src_len <= 0 then src_len = item_len end

  local start_pct = 0
  local end_pct = 1
  if src_len > 0 then
    start_pct = math.max(0, startoffs / src_len)
    end_pct = math.min(1, (startoffs + item_len * math.abs(playrate)) / src_len)
    if end_pct <= start_pct then end_pct = 1 end
  end

  if reaper.RenderFileSection then
    local ok = reaper.RenderFileSection(src_fn, dest, start_pct, end_pct, playrate)
    if ok then return true, dest end
  end

  if start_pct < 0.001 and end_pct > 0.999 and math.abs(playrate - 1) < 0.001 then
    if copy_file(src_fn, dest) then return true, dest end
  end

  return false, "Direct export failed"
end

local function capture_render_state()
  return {
    file = select(2, reaper.GetSetProjectInfo_String(0, "RENDER_FILE", "", false)),
    pattern = select(2, reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "", false)),
    bounds = reaper.GetSetProjectInfo(0, "RENDER_BOUNDSFLAG", 0, false),
    startpos = reaper.GetSetProjectInfo(0, "RENDER_STARTPOS", 0, false),
    endpos = reaper.GetSetProjectInfo(0, "RENDER_ENDPOS", 0, false),
    settings = reaper.GetSetProjectInfo(0, "RENDER_SETTINGS", 0, false),
  }
end

local function restore_render_state(saved)
  if not saved then return end
  reaper.GetSetProjectInfo_String(0, "RENDER_FILE", saved.file or "", true)
  reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", saved.pattern or "", true)
  reaper.GetSetProjectInfo(0, "RENDER_BOUNDSFLAG", saved.bounds or 1, true)
  reaper.GetSetProjectInfo(0, "RENDER_STARTPOS", saved.startpos or 0, true)
  reaper.GetSetProjectInfo(0, "RENDER_ENDPOS", saved.endpos or 0, true)
  reaper.GetSetProjectInfo(0, "RENDER_SETTINGS", saved.settings or 0, true)
end

local function save_item_selection()
  local items = {}
  for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
    items[#items + 1] = reaper.GetSelectedMediaItem(0, i)
  end
  return items
end

local function restore_item_selection(items)
  reaper.SelectAllMediaItems(0, false)
  for _, item in ipairs(items) do
    if reaper.ValidatePtr(item, "MediaItem*") then
      reaper.SetMediaItemSelected(item, true)
    end
  end
end

local function item_overlaps_region(item, rgnpos, rgnend)
  local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  return (pos + len) > rgnpos and pos < rgnend
end

local function collect_region_guids_for_items(items)
  local guids, seen = {}, {}
  local i = 0
  while true do
    local retval, isrgn, rgnpos, rgnend = reaper.EnumProjectMarkers3(0, i)
    if retval < 1 then break end
    if isrgn then
      for _, item in ipairs(items) do
        if item_overlaps_region(item, rgnpos, rgnend) then
          local guid = reaper.GetRegionOrMarker(0, i, "")
          if guid and not seen[guid] then
            seen[guid] = true
            guids[#guids + 1] = guid
          end
          break
        end
      end
    end
    i = i + 1
  end
  return guids
end

local function append_region_guid(guids, seen, guid)
  if guid and not seen[guid] then
    seen[guid] = true
    guids[#guids + 1] = guid
  end
end

local function collect_ui_selected_region_guids()
  local guids, seen = {}, {}
  local i = 0
  while true do
    local retval, isrgn = reaper.EnumProjectMarkers3(0, i)
    if retval < 1 then break end
    if isrgn then
      local guid = reaper.GetRegionOrMarker(0, i, "")
      if guid and reaper.GetRegionOrMarkerInfo_Value(0, guid, "B_UISEL") == 1 then
        append_region_guid(guids, seen, guid)
      end
    end
    i = i + 1
  end
  return guids
end

local function resolve_render_region_guids(items)
  local guids, seen = {}, {}
  items = items or {}

  for _, guid in ipairs(collect_ui_selected_region_guids()) do
    append_region_guid(guids, seen, guid)
  end
  if #guids > 0 then return guids end

  local ts_start, ts_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if ts_end > ts_start then
    local i = 0
    while true do
      local retval, isrgn, rgnpos, rgnend = reaper.EnumProjectMarkers3(0, i)
      if retval < 1 then break end
      if isrgn and rgnend > ts_start and rgnpos < ts_end then
        append_region_guid(guids, seen, reaper.GetRegionOrMarker(0, i, ""))
      end
      i = i + 1
    end
    if #guids > 0 then return guids end
  end

  local _, region_index = reaper.GetLastMarkerAndCurRegion(0, reaper.GetCursorPosition())
  if region_index and region_index >= 0 then
    local retval, isrgn = reaper.EnumProjectMarkers3(0, region_index)
    if retval >= 1 and isrgn then
      append_region_guid(guids, seen, reaper.GetRegionOrMarker(0, region_index, ""))
      if #guids > 0 then return guids end
    end
  end

  if #items > 0 then return collect_region_guids_for_items(items) end
  return guids
end

local function collect_resolved_regions(items)
  local guids = resolve_render_region_guids(items or {})
  local guid_set = {}
  for _, guid in ipairs(guids) do guid_set[guid] = true end

  local regions = {}
  local i = 0
  while true do
    local retval, isrgn, rgnpos, rgnend, name = reaper.EnumProjectMarkers3(0, i)
    if retval < 1 then break end
    if isrgn then
      local guid = reaper.GetRegionOrMarker(0, i, "")
      if guid and guid_set[guid] then
        regions[#regions + 1] = {
          guid = guid,
          name = name or "",
          pos = rgnpos,
          rgnend = rgnend,
        }
      end
    end
    i = i + 1
  end
  return regions
end

local function can_render()
  if reaper.CountSelectedMediaItems(0) > 0 then return true end
  if STATE.render_use_reaper and STATE.render_regions and #resolve_render_region_guids({}) > 0 then
    return true
  end
  return false
end

local function render_target_error()
  if STATE.render_use_reaper and STATE.render_regions then
    return "Click a region, set a time selection, or select items to render."
  end
  return "No items selected to render."
end

local function gather_selected_items()
  local items = {}
  for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
    items[#items + 1] = reaper.GetSelectedMediaItem(0, i)
  end
  return items
end

local function capture_region_selection()
  local saved = {}
  local i = 0
  while true do
    local retval, isrgn = reaper.EnumProjectMarkers3(0, i)
    if retval < 1 then break end
    if isrgn then
      local guid = reaper.GetRegionOrMarker(0, i, "")
      if guid then
        saved[#saved + 1] = {
          guid = guid,
          selected = reaper.GetRegionOrMarkerInfo_Value(0, guid, "B_UISEL") == 1,
        }
      end
    end
    i = i + 1
  end
  return saved
end

local function restore_region_selection(saved)
  if not saved then return end
  for _, entry in ipairs(saved) do
    reaper.SetRegionOrMarkerInfo_Value(0, entry.guid, "B_UISEL", entry.selected and 1 or 0)
  end
end

local function set_region_selection(region_guids)
  local selected = {}
  for _, guid in ipairs(region_guids) do selected[guid] = true end
  local i = 0
  while true do
    local retval, isrgn = reaper.EnumProjectMarkers3(0, i)
    if retval < 1 then break end
    if isrgn then
      local guid = reaper.GetRegionOrMarker(0, i, "")
      if guid then
        reaper.SetRegionOrMarkerInfo_Value(0, guid, "B_UISEL", selected[guid] and 1 or 0)
      end
    end
    i = i + 1
  end
end

local function get_item_region_basename(item)
  local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local mid = pos + len * 0.5
  local i = 0
  while true do
    local retval, isrgn, rgnpos, rgnend, name = reaper.EnumProjectMarkers3(0, i)
    if retval < 1 then break end
    if isrgn and mid >= rgnpos and mid <= rgnend and name and name ~= "" then
      return sanitize_fs_name(name)
    end
    i = i + 1
  end
end

local function render_items_via_reaper(items, open_dialog, use_regions)
  items = items or {}

  local saved_render = capture_render_state()
  local saved_items = save_item_selection()
  local saved_regions = nil
  local region_count = 0
  local pattern = RENDER_NAME_PATTERN

  if use_regions then
    local had_ui_selection = #collect_ui_selected_region_guids() > 0
    local region_guids = resolve_render_region_guids(items)
    if #region_guids < 1 then
      return false, "Select a region, set a time selection, or select items inside regions", 0
    end
    saved_regions = capture_region_selection()
    if not had_ui_selection then set_region_selection(region_guids) end
    region_count = #region_guids
    pattern = RENDER_REGION_PATTERN
    reaper.GetSetProjectInfo(0, "RENDER_BOUNDSFLAG", 5, true)
    local settings = reaper.GetSetProjectInfo(0, "RENDER_SETTINGS", 0, false)
    settings = render_remove_flag(settings, 32)
    settings = render_remove_flag(settings, 64)
    reaper.GetSetProjectInfo(0, "RENDER_SETTINGS", settings, true)
  else
    reaper.SelectAllMediaItems(0, false)
    for _, item in ipairs(items) do
      reaper.SetMediaItemSelected(item, true)
    end
    reaper.GetSetProjectInfo(0, "RENDER_BOUNDSFLAG", 4, true)
    local settings = reaper.GetSetProjectInfo(0, "RENDER_SETTINGS", 0, false)
    reaper.GetSetProjectInfo(0, "RENDER_SETTINGS", render_add_flag(settings, 32), true)
    if #items < 1 then return false, "No items selected to render", 0 end
  end

  local out_dir_abs = apply_reaper_render_target(get_render_root(), pattern)

  if open_dialog then
    reaper.Main_OnCommand(40015, 0)
    restore_item_selection(saved_items)
    if saved_regions then restore_region_selection(saved_regions) end
    return true, out_dir_abs, use_regions and region_count or #items
  end

  reaper.Main_OnCommand(42230, 0)
  wait_for_render_finish()
  restore_item_selection(saved_items)
  if saved_regions then restore_region_selection(saved_regions) end
  restore_render_state(saved_render)
  return true, out_dir_abs, use_regions and region_count or #items
end

local function list_dir_files(dir)
  local files = {}
  if not reaper.EnumerateFiles then return files end
  local i = 0
  while true do
    local fn = reaper.EnumerateFiles(dir, i)
    if not fn or fn == "" then break end
    table.insert(files, fn)
    i = i + 1
  end
  return files
end

local function find_rendered_file(dir, basename)
  if not dir or dir == "" then return nil end
  local base_lower = basename:lower()
  for _, fn in ipairs(list_dir_files(dir)) do
    local stem = fn:match("^(.+)%.[^%.]+$") or fn
    if stem:lower() == base_lower then
      return path_join(dir, fn)
    end
  end
  for _, fn in ipairs(list_dir_files(dir)) do
    if fn:lower():find(base_lower, 1, true) == 1 then
      return path_join(dir, fn)
    end
  end
  return nil
end

local function get_track_below(source_track)
  local num = reaper.GetMediaTrackInfo_Value(source_track, "IP_TRACKNUMBER")
  local below_idx = num
  if below_idx < reaper.CountTracks(0) then
    return reaper.GetTrack(0, below_idx)
  end
  return nil
end

local function get_or_create_track_below(source_track)
  local existing = get_track_below(source_track)
  if existing then return existing end
  if not STATE.post_render_create_track then return nil end

  local below_idx = reaper.GetMediaTrackInfo_Value(source_track, "IP_TRACKNUMBER")
  reaper.InsertTrackAtIndex(below_idx, true)
  reaper.TrackList_AdjustWindows(false)
  return reaper.GetTrack(0, below_idx)
end

local function import_file_on_track_below(source_item, file_path)
  if not file_path or not reaper.file_exists(file_path) then return false end
  if not reaper.ValidatePtr(source_item, "MediaItem*") then return false end

  local source_track = reaper.GetMediaItem_Track(source_item)
  if not source_track then return false end

  local dest_track = get_or_create_track_below(source_track)
  if not dest_track then return false end
  local pos = reaper.GetMediaItemInfo_Value(source_item, "D_POSITION")

  local item = reaper.AddMediaItemToTrack(dest_track, false)
  if not item then return false end
  local take = reaper.AddTakeToMediaItem(item)
  if not take then return false end

  local src = reaper.PCM_Source_CreateFromFile(file_path)
  if not src then return false end
  reaper.SetMediaItemTake_Source(take, src)

  local ok, name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
  local display = (ok and name ~= "") and name or file_path:match("([^/\\]+)$") or file_path
  reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", display, true)

  reaper.SetMediaItemInfo_Value(item, "D_POSITION", pos)
  local len = reaper.GetMediaSourceLength(src)
  if len > 0 then
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", len)
  end
  reaper.UpdateArrange()
  return true
end

local function collect_render_import_plan(items, use_regions)
  local plan = {}
  for _, item in ipairs(items) do
    local tk = reaper.GetActiveTake(item)
    local basename = get_take_output_basename(tk)
    if use_regions then
      basename = get_item_region_basename(item) or basename
    end
    plan[#plan + 1] = {
      item = item,
      basename = basename,
      path = nil,
    }
  end
  return plan
end

local function import_rendered_files_to_items(plan, out_dir)
  local imported = 0
  for _, entry in ipairs(plan) do
    local file_path = entry.path or find_rendered_file(out_dir, entry.basename)
    if import_file_on_track_below(entry.item, file_path) then
      imported = imported + 1
    end
  end
  return imported
end

local function action_render_to_ucs_folder()
  if not can_render() then
    set_status(render_target_error())
    return false
  end

  local out_dir = get_ucs_render_paths()
  local items = gather_selected_items()
  local use_regions = STATE.render_use_reaper and STATE.render_regions
  local import_plan = (#items > 0 and STATE.post_render_import)
    and collect_render_import_plan(items, use_regions) or nil

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  local rendered = 0
  local last_path = out_dir
  local render_err = nil

  if STATE.render_use_reaper then
    local ok, path_or_err, render_count = render_items_via_reaper(
      items, STATE.render_open_dialog, use_regions)
    if ok then
      rendered = render_count or #items
      last_path = path_or_err or get_render_root()
    else
      render_err = path_or_err
    end
  else
    if #items < 1 then
      set_status(render_target_error())
      reaper.PreventUIRefresh(-1)
      reaper.Undo_EndBlock("UCS Tool: Render to UCS folder", -1)
      return false
    end
    for i, item in ipairs(items) do
      local tk = reaper.GetActiveTake(item)
      local bn = get_take_output_basename(tk)
      local ok, path = export_take_direct(tk, out_dir, bn)
      if ok then
        rendered = rendered + 1
        last_path = path
        if import_plan and import_plan[i] then
          import_plan[i].path = path
        end
      end
    end
  end

  local imported = 0
  if rendered > 0 and import_plan then
    imported = import_rendered_files_to_items(import_plan, get_render_root())
  end

  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock("UCS Tool: Render to UCS folder", -1)

  if rendered < 1 then
    set_status(render_err or "Render failed — check item source and output path.")
    return false
  end

  local mode = "direct export"
  if STATE.render_use_reaper then
    mode = use_regions and "REAPER render ($region)" or "REAPER render ($item)"
  end
  local msg = string.format("Rendered %d file(s) via %s → %s", rendered, mode, last_path)
  if imported > 0 then
    msg = msg .. string.format(" · imported %d below source item(s)", imported)
  elseif import_plan and #import_plan > 0 then
    msg = msg .. " · post-import skipped (enable create track or add a track below)"
  end
  set_status(msg)
  save_settings(gfx.w, gfx.h)
  return true
end

local function build_preflight_data(action)
  local sorted = get_selected_items_sorted()
  local previews = {}
  local take_cursor = STATE.take_num_str

  if action == "pipeline" then
    local current = ""
    if #sorted == 1 then
      local tk = reaper.GetActiveTake(sorted[1].item)
      if tk then
        local ok, name = reaper.GetSetMediaItemTakeInfo_String(tk, "P_NAME", "", false)
        if ok and name ~= "" then current = name end
      end
    else
      current = string.format("%d items (glued into one)", #sorted)
    end
    previews[#previews + 1] = {
      current = current ~= "" and current or "(unnamed)",
      proposed = build_ucs_name_with_take(take_cursor),
    }
  elseif #sorted > 0 then
    for idx, entry in ipairs(sorted) do
      local tk = reaper.GetActiveTake(entry.item)
      local current = ""
      if tk then
        local ok, name = reaper.GetSetMediaItemTakeInfo_String(tk, "P_NAME", "", false)
        if ok and name ~= "" then current = name end
      end
      previews[#previews + 1] = {
        current = current ~= "" and current or "(unnamed)",
        proposed = build_ucs_name_with_take(take_cursor),
      }
      if STATE.auto_take_inc and idx < #sorted then
        take_cursor = increment_take_number(take_cursor)
      end
    end
  elseif action == "render" and STATE.render_regions then
    for _, region in ipairs(collect_resolved_regions()) do
      local current = region.name ~= "" and region.name or "(unnamed region)"
      previews[#previews + 1] = {
        current = current,
        proposed = sanitize_fs_name(region.name ~= "" and region.name or current),
      }
    end
  end

  local rename_count = (action == "pipeline") and 1 or #sorted
  if action == "render" and rename_count < 1 and STATE.render_regions then
    rename_count = #previews
  end
  local next_take = nil
  if STATE.auto_take_inc then
    local t = STATE.take_num_str
    for _ = 1, rename_count do
      t = increment_take_number(t)
    end
    next_take = t
  end

  local target_count = #sorted
  if action == "render" and target_count < 1 and STATE.render_regions then
    target_count = #previews
  end

  return {
    action = action,
    count = target_count,
    previews = previews,
    will_render = action == "render",
    next_take = next_take,
  }
end

local function open_preflight(action)
  STATE.preflight = build_preflight_data(action)
end

local function request_render()
  if not can_render() then
    set_status(render_target_error())
    return
  end
  if STATE.confirm_before_run then
    open_preflight("render")
  else
    RT.pending_action = "render"
  end
end

local function request_pipeline()
  if reaper.CountSelectedMediaItems(0) < 1 then
    set_status("No items selected.")
    return
  end
  if STATE.confirm_before_run then
    open_preflight("pipeline")
  else
    RT.pending_action = "pipeline"
  end
end

-- ─── ACTIONS ─────────────────────────────────────────────────
local function action_space_items()
  local sorted = get_selected_items_sorted()
  if #sorted < 2 then set_status("Select 2+ items to space."); return end
  reaper.Undo_BeginBlock()
  local gap_s  = STATE.gap_ms / 1000.0
  local cursor = reaper.GetMediaItemInfo_Value(sorted[1].item, "D_POSITION")
              + reaper.GetMediaItemInfo_Value(sorted[1].item, "D_LENGTH")
  for i = 2, #sorted do
    local item = sorted[i].item
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", cursor + gap_s)
    cursor = cursor + gap_s + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  end
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("UCS Tool: Space Items", -1)
  set_status("Items spaced (" .. STATE.gap_ms .. " ms gap).")
  save_settings(gfx.w, gfx.h)
end

local function action_glue_items()
  if reaper.CountSelectedMediaItems(0) < 1 then set_status("No items selected."); return end
  reaper.Undo_BeginBlock()
  reaper.Main_OnCommand(41588, 0)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("UCS Tool: Glue Items", -1)
  set_status("Items glued into one.")
  save_settings(gfx.w, gfx.h)
end

local function action_normalize()
  local count = reaper.CountSelectedMediaItems(0)
  if count < 1 then set_status("No items selected."); return end
  reaper.Undo_BeginBlock()
  local target = STATE.norm_level
  local mode = (STATE.norm_mode == "lufs") and 0 or 2
  local mode_label = (STATE.norm_mode == "lufs") and "LUFS-I" or "peak"
  for i = 0, count-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local tk   = reaper.GetActiveTake(item)
    if tk then
      local src     = reaper.GetMediaItemTake_Source(tk)
      local gain_db = reaper.CalculateNormalization(src, mode, target, 0, 0)
      local lin_gain = 10 ^ (gain_db / 20.0)
      reaper.SetMediaItemTakeInfo_Value(tk, "D_VOL", lin_gain)
    end
  end
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("UCS Tool: Normalize", -1)
  set_status(string.format("Normalized to %.1f %s (%s).", target, norm_mode_suffix(), mode_label))
  save_settings(gfx.w, gfx.h)
end

local function action_apply_ucs_name()
  local count = reaper.CountSelectedMediaItems(0)
  if count < 1 then set_status("No items selected."); return end

  local first_name = build_ucs_name()
  STATE.validation_issues = validate_ucs_name(first_name)
  if #STATE.validation_issues > 0 then
    set_status("Name issue: " .. STATE.validation_issues[1])
    return
  end
  if first_name == "" then set_status("Fill in UCS fields first."); return end

  reaper.Undo_BeginBlock()
  local last_name = first_name
  for i = 0, count - 1 do
    local name = build_ucs_name()
    set_item_name(reaper.GetSelectedMediaItem(0, i), name)
    last_name = name
    if STATE.auto_take_inc then
      STATE.take_num_str = increment_take_number(STATE.take_num_str)
      input_edits["takenum"] = nil
      mark_dirty()
    end
  end
  reaper.Undo_EndBlock("UCS Tool: Rename", -1)

  if STATE.auto_take_inc then
    set_status("Renamed → " .. last_name .. "  (take → " .. STATE.take_num_str .. ")")
  else
    set_status("Renamed → " .. last_name)
  end
  save_settings(gfx.w, gfx.h)
end

local function action_run_pipeline()
  if reaper.CountSelectedMediaItems(0) < 1 then
    set_status("No items selected.")
    return
  end

  if #get_selected_items_sorted() >= 2 then
    action_space_items()
  end
  action_glue_items()
  if STATE.norm_enable then action_normalize() end
  action_apply_ucs_name()
end

local function flush_pending_action()
  if not RT.pending_action then return end
  local action = RT.pending_action
  RT.pending_action = nil
  focused_field = nil
  if action == "pipeline" then
    action_run_pipeline()
  elseif action == "render" then
    action_render_to_ucs_folder()
  elseif action == "apply_name" then
    action_apply_ucs_name()
  end
end

-- ─── LAYOUT CONSTANTS ────────────────────────────────────────
local LY = {
  ROW_GAP = 12,
  SECTION_GAP = 20,
  STATUS_H = 32,
  HEADER_H = 52,
  LABEL_H = 14,
  INPUT_H = 30,
  BTN_H = 32,
  INNER_PAD = 16,
  TITLE_Y_OFFSET = 16,
  HEADER_DIVIDER_GAP = 14,
  CONTENT_TOP_PAD = 18,
  SCROLL_WHEEL_STEP = 40,
  SCROLL_SMOOTH_RATE = 14,
}
LY.CARD_HEADER = LY.TITLE_Y_OFFSET + LY.LABEL_H + LY.HEADER_DIVIDER_GAP + 1
LY.CONTENT_START = LY.CARD_HEADER + LY.CONTENT_TOP_PAD

-- ─── FONT HELPERS ────────────────────────────────────────────
local UI_FONT = "Helvetica Neue"
local function font_title() gfx.setfont(1, UI_FONT, 15, string.byte("b")) end
local function font_body()  gfx.setfont(1, UI_FONT, 13) end
local function font_label() gfx.setfont(1, UI_FONT, 11) end
local function font_small() gfx.setfont(1, UI_FONT, 10) end

-- ─── BRANDING ────────────────────────────────────────────────
local TOOL_TITLE = "UCS Multi Toolkit"
local TOOL_VERSION = "1.0.1"
local LOGO_IMG = 2
local LOGO_FILE = "Haptik_Audio_logo.png"
local logo_loaded = false
local logo_w, logo_h = 0, 0

local function logo_path()
  local _, script_fn = reaper.get_action_context()
  if not script_fn or script_fn == "" then return nil end
  local dir = script_fn:match("^(.*[/\\])")
  if not dir then return nil end
  return dir .. LOGO_FILE
end

local function load_logo()
  local path = logo_path()
  if not path or not gfx.loadimg(LOGO_IMG, path) then return false end
  logo_w, logo_h = gfx.getimgdim(LOGO_IMG)
  logo_loaded = (logo_w or 0) > 0 and (logo_h or 0) > 0
  return logo_loaded
end

local function draw_header_logo(x, y, size)
  if not logo_loaded then return 0 end
  gfx.blit(LOGO_IMG, 1, 0, 0, 0, logo_w, logo_h, x, y, size, size)
  return size
end

-- ─── SECTION CARD ────────────────────────────────────────────
local function draw_section_card(x, y, w, h, title, _accent, num)
  local sy = screen_y(y)
  fill_rounded_rect(x + 1, sy + 2, w, h, C.shadow, RADIUS.card)
  fill_rounded_rect(x, sy, w, h, C.panel, RADIUS.card)
  stroke_rounded_rect(x, sy, w, h, C.border, RADIUS.card)

  local title_x = 16
  if num then
    font_small()
    setcol(C.text_dim)
    gfx.x = x + 16
    gfx.y = sy + LY.TITLE_Y_OFFSET + 3
    gfx.drawstr(string.format("%02d", num))

    setcol(C.border)
    gfx.rect(x + 38, sy + LY.TITLE_Y_OFFSET + 5, 1, 12, 1)

    title_x = 48
  end

  font_label()
  setcol(C.text_sec)
  gfx.x = x + title_x
  gfx.y = sy + LY.TITLE_Y_OFFSET + 1
  gfx.drawstr(title)

  local divider_y = sy + LY.TITLE_Y_OFFSET + LY.LABEL_H + LY.HEADER_DIVIDER_GAP
  setcol(C.border)
  gfx.line(x + 16, divider_y, x + w - 16, divider_y)

  return y + LY.CONTENT_START
end

-- ─── LAYOUT HELPERS ──────────────────────────────────────────
local function compute_layout()
  local win_w = math.max(520, gfx.w)
  local win_h = math.max(400, gfx.h)
  local pad   = 16
  local card_w = win_w - pad * 2
  local col_gap = 12
  local inner_w = card_w - LY.INNER_PAD * 2
  local half_w  = math.floor((inner_w - col_gap) / 2)
  local col1_x  = pad + LY.INNER_PAD
  local col2_x  = col1_x + half_w + col_gap
  local stack_cols = win_w < 600

  return {
    win_w = win_w,
    win_h = win_h,
    pad = pad,
    card_w = card_w,
    col1_x = col1_x,
    col2_x = stack_cols and col1_x or col2_x,
    half_w = stack_cols and inner_w or half_w,
    full_w = inner_w,
    stack_cols = stack_cols,
  }
end

local function workflow_section_height()
  return LY.CONTENT_START + LY.LABEL_H + 4 + LY.INPUT_H + 8 + 28 * 3 + 10 + LY.BTN_H + LY.INNER_PAD
end

local function spacing_section_height()
  return LY.CONTENT_START + LY.LABEL_H + 4 + LY.INPUT_H + 12 + LY.BTN_H + LY.INNER_PAD
end

local function normalize_section_height()
  if STATE.norm_enable then
    return LY.CONTENT_START + 22 + (LY.LABEL_H + 4 + LY.INPUT_H + 8) + LY.LABEL_H + 4 + LY.INPUT_H + LY.INNER_PAD
  end
  return LY.CONTENT_START + 22 + LY.LABEL_H + 8 + LY.INNER_PAD
end

local function rename_section_height(L)
  local h = LY.CONTENT_START
  local standard_row = LY.LABEL_H + 4 + LY.INPUT_H + LY.ROW_GAP
  local checkbox_row = 28 + LY.ROW_GAP

  h = h + standard_row
  if L.stack_cols then h = h + standard_row end

  h = h + LY.LABEL_H + 4 + LY.INPUT_H + 28 + LY.ROW_GAP
  if L.stack_cols then h = h + standard_row end

  h = h + standard_row
  if L.stack_cols then
    h = h + LY.LABEL_H + 4 + LY.INPUT_H + 28 + LY.ROW_GAP
  else
    h = h + 22
  end

  h = h + standard_row
  h = h + checkbox_row
  if STATE.render_use_reaper then h = h + checkbox_row + checkbox_row end
  h = h + checkbox_row
  h = h + checkbox_row

  h = h + LY.LABEL_H + 4 + LY.INPUT_H + LY.ROW_GAP
  h = h + LY.INPUT_H + 8
  if #STATE.validation_issues > 0 then h = h + 16 end

  h = h + LY.ROW_GAP + (LY.BTN_H + 2) + 8 + (LY.BTN_H + 2)
  return h + LY.INNER_PAD
end

local function compute_content_height(L)
  STATE.validation_issues = validate_ucs_name(build_ucs_name())
  return 12
       + workflow_section_height() + LY.SECTION_GAP
       + spacing_section_height() + LY.SECTION_GAP
       + normalize_section_height() + LY.SECTION_GAP
       + rename_section_height(L) + 24
end

local function draw_scrollbar(win_w, view_top, view_h, content_h, scroll_max)
  if scroll_max <= 0 then return end
  local track_x = win_w - 10
  local track_y = view_top + 4
  local track_h = view_h - 8
  fill_rounded_rect(track_x, track_y, 4, track_h, C.input_bg, 2)
  local thumb_h = math.max(24, math.floor(track_h * view_h / content_h))
  local thumb_y = track_y + math.floor((track_h - thumb_h) * STATE.scroll_y / scroll_max)
  fill_rounded_rect(track_x, thumb_y, 4, thumb_h, C.text_dim, 2)
end

local function sy(vy)
  return screen_y(vy)
end

local function update_smooth_scroll(scroll_max)
  RT.scroll_target_y = math.max(0, math.min(RT.scroll_target_y, scroll_max))

  local now = reaper.time_precise()
  local dt = math.min(0.05, math.max(0.001, now - RT.last_scroll_update))
  RT.last_scroll_update = now

  local diff = RT.scroll_target_y - STATE.scroll_y
  if math.abs(diff) < 0.5 then
    if math.abs(STATE.scroll_y - RT.scroll_target_y) > 0.01 then
      STATE.scroll_y = RT.scroll_target_y
      mark_dirty()
    end
    return
  end

  local factor = 1 - math.exp(-LY.SCROLL_SMOOTH_RATE * dt)
  STATE.scroll_y = STATE.scroll_y + diff * factor
  mark_dirty()
end

-- ─── CATEGORY NAME LIST ──────────────────────────────────────
local cat_names = {}
for _, c in ipairs(UCS.categories) do
  table.insert(cat_names, c.id .. "  " .. c.name)
end

local function get_sub_names()
  local cat = UCS.categories[STATE.cat_idx]
  if cat and cat.subs then return cat.subs end
  return {}
end

local function draw_preflight_modal(L)
  local pf = STATE.preflight
  if not pf then return end

  local saved_scroll = ui_scroll_y
  ui_scroll_y = 0

  local win_w, win_h = L.win_w, L.win_h
  local pad = 12
  local line_h = 14
  local footer_h = LY.BTN_H + 20
  local max_modal_h = 280
  local max_modal_w = 420
  local max_preview_lines = 5

  fill_rect(0, 0, win_w, win_h, 0x00000099)

  local modal_w = math.min(max_modal_w, math.max(240, win_w - pad * 2))
  local modal_h = math.min(max_modal_h, math.max(footer_h + 96, win_h - pad * 2))
  local mx = math.max(pad, math.floor((win_w - modal_w) / 2))
  local my = math.max(pad, math.floor((win_h - modal_h) / 2))
  local btn_y = my + modal_h - pad - LY.BTN_H
  local list_bottom = btn_y - 8

  fill_rounded_rect(mx + 2, my + 3, modal_w, modal_h, C.shadow, RADIUS.card)
  fill_rounded_rect(mx, my, modal_w, modal_h, C.panel, RADIUS.card)
  stroke_rounded_rect(mx, my, modal_w, modal_h, C.border_focus, RADIUS.card)

  font_title(); setcol(C.text)
  gfx.x = mx + 16; gfx.y = my + 12
  gfx.drawstr(pf.action == "pipeline" and "Pre-flight: Pipeline" or "Pre-flight: Render")

  font_label(); setcol(C.text_sec)
  gfx.x = mx + 16; gfx.y = my + 32
  gfx.drawstr(string.format("%d item(s) selected", pf.count))

  local detail_y = my + 50
  if pf.action == "pipeline" then
    local steps = { "Space", "Glue" }
    if STATE.norm_enable then table.insert(steps, "Normalize") end
    table.insert(steps, "Rename")
    if pf.will_render then table.insert(steps, "Render") end
    gfx.x = mx + 16; gfx.y = detail_y
    gfx.drawstr("Steps: " .. table.concat(steps, " → "))
    detail_y = detail_y + 16
  elseif pf.will_render then
    gfx.x = mx + 16; gfx.y = detail_y
    local out_line = "Output: " .. get_render_root()
    if gfx.measurestr(out_line) > modal_w - 32 then
      while #out_line > 3 and gfx.measurestr(out_line .. "...") > modal_w - 32 do
        out_line = out_line:sub(1, -2)
      end
      out_line = out_line .. "..."
    end
    gfx.drawstr(out_line)
    detail_y = detail_y + 16
  end

  font_small(); setcol(C.text_dim)
  gfx.x = mx + 16; gfx.y = detail_y
  gfx.drawstr(pf.action == "render" and "Output names:" or "Target UCS names:")
  detail_y = detail_y + 16

  if pf.next_take and pf.next_take ~= STATE.take_num_str then
    list_bottom = list_bottom - 14
    font_small(); setcol(C.text_dim)
    gfx.x = mx + 16; gfx.y = list_bottom + 1
    gfx.drawstr("Take after run → " .. pf.next_take)
  end

  local max_lines = math.min(max_preview_lines,
    math.max(1, math.floor((list_bottom - detail_y) / line_h)))
  local shown = math.min(#pf.previews, max_lines)
  for i = 1, shown do
    if detail_y + line_h > list_bottom then break end
    local p = pf.previews[i]
    setcol(C.text_sec)
    gfx.x = mx + 20; gfx.y = detail_y
    local line = string.format("%d. %s", i, p.proposed or p.current)
    if gfx.measurestr(line) > modal_w - 40 then
      while #line > 3 and gfx.measurestr(line .. "...") > modal_w - 40 do
        line = line:sub(1, -2)
      end
      line = line .. "..."
    end
    gfx.drawstr(line)
    detail_y = detail_y + line_h
  end
  if #pf.previews > shown then
    if detail_y + line_h <= list_bottom then
      setcol(C.text_dim)
      gfx.x = mx + 20; gfx.y = detail_y
      gfx.drawstr(string.format("... and %d more", #pf.previews - shown))
    end
  end

  setcol(C.border)
  gfx.line(mx + 12, btn_y - 8, mx + modal_w - 12, btn_y - 8)

  local btn_w = math.floor((modal_w - 44) / 2)
  if button_modern("pf_cancel", mx + 16, btn_y, btn_w, LY.BTN_H, "CANCEL", "default") then
    STATE.preflight = nil
  end
  if button_modern("pf_confirm", mx + 16 + btn_w + 12, btn_y, btn_w, LY.BTN_H, "RUN", "primary") then
    RT.pending_action = pf.action
    STATE.preflight = nil
  end

  ui_scroll_y = saved_scroll
end

local function handle_keyboard_shortcuts(char)
  if not char or char < 0 then return end

  if STATE.preflight then
    if char == 27 then
      STATE.preflight = nil
    elseif char == 13 or char == 271 then
      RT.pending_action = STATE.preflight.action
      STATE.preflight = nil
    end
    return
  end

  if focused_field or any_dropdown_open() then return end

  if char == 115 or char == 83 then
    action_suggest_from_selection()
  elseif char == 114 or char == 82 then
    request_render()
  elseif char == 112 or char == 80 then
    request_pipeline()
  end
end

-- ─── MAIN DRAW ───────────────────────────────────────────────
local DD = {
  cat_list_y = 0, sub_list_y = 0,
  list_x_cat = 0, list_x_sub = 0,
  list_w_cat = 0, list_w_sub = 0,
  preset_list_y = 0, preset_list_x = 0, preset_list_w = 0,
  norm_list_y = 0, norm_list_x = 0, norm_list_w = 0,
}

local function draw()
  if click_guard > 0 then click_guard = click_guard - 1 end
  input_fields = {}
  local frame_mouse_down = (gfx.mouse_cap & 1) == 1

  local new_preset_open = STATE.dd_preset_open
  local new_norm_open = STATE.dd_norm_open
  local new_cat_open = STATE.dd_cat_open
  local new_sub_open = STATE.dd_sub_open

  local L = compute_layout()
  local win_w, win_h = L.win_w, L.win_h
  local pad, card_w = L.pad, L.card_w
  local col1_x, col2_x = L.col1_x, L.col2_x
  local half_w, full_w = L.half_w, L.full_w

  fill_rect(0, 0, win_w, win_h, C.bg)

  local view_top = LY.HEADER_H
  local view_bottom = win_h - LY.STATUS_H
  local view_h = view_bottom - view_top
  local content_h = compute_content_height(L)
  local scroll_max = math.max(0, content_h - view_h)
  update_smooth_scroll(scroll_max)
  ui_scroll_y = STATE.scroll_y

  fill_rect(0, view_top, win_w, view_h, C.bg)

  local cy = LY.HEADER_H + 12

  -- ── SECTION 1: WORKFLOW PRESETS ──────────────────────────────
  local preset_names = get_preset_names()
  if STATE.preset_idx > #preset_names then STATE.preset_idx = DEFAULT_PRESET_IDX end

  local s0_h = workflow_section_height()
  content_y = draw_section_card(pad, cy, card_w, s0_h, "WORKFLOW PRESETS", C.accent, 1)

  font_label(); setcol(C.text_sec)
  gfx.x = col1_x; gfx.y = sy(content_y); gfx.drawstr("Preset")

  font_body()
  DD.preset_list_y = content_y + LY.LABEL_H + 4 + LY.INPUT_H
  DD.preset_list_x = col1_x
  DD.preset_list_w = math.min(full_w, 280)
  _, new_preset_open = dropdown_header("preset", col1_x, content_y + LY.LABEL_H + 4,
                            DD.preset_list_w, LY.INPUT_H, preset_names, STATE.preset_idx, STATE.dd_preset_open)

  local chk_row_y = content_y + LY.LABEL_H + 4 + LY.INPUT_H + 8
  STATE.suggest_all_fields, _ = checkbox_modern(
    "suggest_all", col1_x, chk_row_y, STATE.suggest_all_fields, "Suggest all fields"
  )
  if not L.stack_cols then
    STATE.sync_render_preset, _ = checkbox_modern(
      "sync_render", col2_x, chk_row_y, STATE.sync_render_preset, "Sync render preset"
    )
  else
    chk_row_y = chk_row_y + 28
    STATE.sync_render_preset, _ = checkbox_modern(
      "sync_render", col1_x, chk_row_y, STATE.sync_render_preset, "Sync render preset"
    )
  end
  chk_row_y = chk_row_y + 28
  STATE.confirm_before_run, _ = checkbox_modern(
    "confirm_run", col1_x, chk_row_y, STATE.confirm_before_run, "Confirm before pipeline/render"
  )

  local wf_btn_y = chk_row_y + 28 + 10
  local wf_btn_w = math.floor((full_w - 20) / 3)
  if button_modern("save_preset", col1_x, wf_btn_y, wf_btn_w, LY.BTN_H, "SAVE PRESET", "default") then
    save_current_preset()
  end
  if button_modern("suggest_btn", col1_x + wf_btn_w + 10, wf_btn_y, wf_btn_w, LY.BTN_H,
                   "SUGGEST FIELDS", "secondary") then
    action_suggest_from_selection()
  end
  if button_modern("del_preset", col1_x + (wf_btn_w + 10) * 2, wf_btn_y, wf_btn_w, LY.BTN_H,
                   "DELETE", "default") then
    delete_current_user_preset()
  end

  cy = cy + s0_h + LY.SECTION_GAP

  -- ── SECTION 2: SPACING ───────────────────────────────────────
  local s1_h = spacing_section_height()
  content_y = draw_section_card(pad, cy, card_w, s1_h, "SPACING", C.accent, 2)

  font_label(); setcol(C.text_sec)
  gfx.x = col1_x; gfx.y = sy(content_y); gfx.drawstr("Gap between items")

  font_body()
  local prev_gap = STATE.gap_ms_str
  STATE.gap_ms_str, STATE.gap_ms = numeric_input(
    "gap", col1_x, content_y + LY.LABEL_H + 4, math.min(220, half_w), LY.INPUT_H,
    STATE.gap_ms_str, 0, 60000, 50, "ms"
  )
  if STATE.gap_ms_str ~= prev_gap then mark_dirty() end

  font_small(); setcol(C.text_dim)
  gfx.x = col1_x + math.min(220, half_w) + 10
  gfx.y = sy(content_y + LY.LABEL_H + 10)
  gfx.drawstr("milliseconds")

  local btn_y = content_y + LY.LABEL_H + 4 + LY.INPUT_H + 12
  local btn_w = math.floor((full_w - 10) / 2)
  if button_modern("space_btn", col1_x, btn_y, btn_w, LY.BTN_H, "APPLY SPACING", "primary") then
    action_space_items()
  end
  if button_modern("glue_btn", col1_x + btn_w + 10, btn_y, btn_w, LY.BTN_H, "GLUE SELECTED", "secondary") then
    action_glue_items()
  end

  cy = cy + s1_h + LY.SECTION_GAP

  -- ── SECTION 3: NORMALIZE ─────────────────────────────────────
  local s2_h = normalize_section_height()
  content_y = draw_section_card(pad, cy, card_w, s2_h, "NORMALIZE", C.accent2, 3)

  font_body()
  STATE.norm_enable, _ = checkbox_modern("norm_chk", col1_x, content_y, STATE.norm_enable,
                                         "Enable normalization")

  if STATE.norm_enable then
    local mode_y = content_y + 28
    font_label(); setcol(C.text_sec)
    gfx.x = col1_x; gfx.y = sy(mode_y); gfx.drawstr("Mode")

    font_body()
    local mode_w = math.min(160, math.floor(full_w * 0.35))
    DD.norm_list_y = mode_y + LY.LABEL_H + 4 + LY.INPUT_H
    DD.norm_list_x = col1_x
    DD.norm_list_w = mode_w
    local prev_mode_idx = STATE.norm_mode_idx
    _, new_norm_open = dropdown_header("norm_mode", col1_x, mode_y + LY.LABEL_H + 4,
                              mode_w, LY.INPUT_H, NORM_MODE_NAMES, STATE.norm_mode_idx, STATE.dd_norm_open)
    if STATE.norm_mode_idx ~= prev_mode_idx then
      switch_norm_mode(NORM_MODE_VALUES[STATE.norm_mode_idx] or "peak")
    end

    local target_y = mode_y + LY.LABEL_H + 4 + LY.INPUT_H + 8
    font_label(); setcol(C.text_sec)
    gfx.x = col1_x; gfx.y = sy(target_y); gfx.drawstr("Target level")

    font_body()
    local norm_min, norm_max, norm_step = norm_level_limits()
    local norm_input_w = math.min(200, math.floor(full_w * 0.45))
    local prev_norm_str = STATE.norm_level_str
    STATE.norm_level_str, STATE.norm_level = numeric_input(
      "norm_lvl", col1_x, target_y + LY.LABEL_H + 4, norm_input_w, LY.INPUT_H,
      STATE.norm_level_str, norm_min, norm_max, norm_step, norm_mode_suffix()
    )
    if STATE.norm_level_str ~= prev_norm_str then
      cache_current_norm_level()
    end

    local norm_btn_x = col1_x + norm_input_w + 10
    local norm_btn_w = full_w - norm_input_w - 10
    if button_modern("norm_btn", norm_btn_x, target_y + LY.LABEL_H + 4,
                     norm_btn_w, LY.INPUT_H, "NORMALIZE", "primary") then
      action_normalize()
    end
  else
    font_label(); setcol(C.text_dim)
    gfx.x = col1_x; gfx.y = sy(content_y + 28)
    gfx.drawstr("Enable checkbox to set normalization level")
  end

  cy = cy + s2_h + LY.SECTION_GAP

  -- ── SECTION 4: UCS RENAME ────────────────────────────────────
  STATE.validation_issues = validate_ucs_name(build_ucs_name())
  local s3_h = rename_section_height(L)
  content_y = draw_section_card(pad, cy, card_w, s3_h, "UCS RENAME", C.accent3, 4)

  local row_y = content_y

  -- Row 1: Category dropdowns
  font_label(); setcol(C.text_sec)
  gfx.x = col1_x; gfx.y = sy(row_y); gfx.drawstr("CATEGORY")
  if not L.stack_cols then
    gfx.x = col2_x; gfx.y = sy(row_y); gfx.drawstr("SUB CATEGORY")
  end

  font_body()
  DD.cat_list_y = row_y + LY.LABEL_H + 4 + LY.INPUT_H
  DD.list_x_cat = col1_x
  DD.list_w_cat = half_w

  _, new_cat_open = dropdown_header("cat", col1_x, row_y + LY.LABEL_H + 4, half_w, LY.INPUT_H,
                            cat_names, STATE.cat_idx, STATE.dd_cat_open)

  local sub_names = get_sub_names()
  if STATE.sub_idx > #sub_names then STATE.sub_idx = 1 end

  if L.stack_cols then
    row_y = row_y + LY.LABEL_H + 4 + LY.INPUT_H + LY.ROW_GAP
    font_label(); setcol(C.text_sec)
    gfx.x = col1_x; gfx.y = sy(row_y); gfx.drawstr("SUB CATEGORY")
    font_body()
    DD.sub_list_y = row_y + LY.LABEL_H + 4 + LY.INPUT_H
    DD.list_x_sub = col1_x
    DD.list_w_sub = half_w
    _, new_sub_open = dropdown_header("sub", col1_x, row_y + LY.LABEL_H + 4, half_w, LY.INPUT_H,
                          sub_names, STATE.sub_idx, STATE.dd_sub_open)
    row_y = row_y + LY.LABEL_H + 4 + LY.INPUT_H + LY.ROW_GAP
  else
    DD.sub_list_y = DD.cat_list_y
    DD.list_x_sub = col2_x
    DD.list_w_sub = half_w
    _, new_sub_open = dropdown_header("sub", col2_x, row_y + LY.LABEL_H + 4, half_w, LY.INPUT_H,
                          sub_names, STATE.sub_idx, STATE.dd_sub_open)
    row_y = row_y + LY.LABEL_H + 4 + LY.INPUT_H + LY.ROW_GAP
  end

  -- Row 2: User Data / Vendor
  font_label(); setcol(C.text_sec)
  gfx.x = col1_x; gfx.y = sy(row_y); gfx.drawstr("USER DATA / ASSET NAME")
  if not L.stack_cols then
    gfx.x = col2_x; gfx.y = sy(row_y); gfx.drawstr("VENDOR / LIBRARY")
  end

  font_body()
  STATE.user_data = text_input("userdat", col1_x, row_y + LY.LABEL_H + 4, half_w, LY.INPUT_H,
                               STATE.user_data, "e.g. GlassBreak")
  STATE.recall_user_data, _ = checkbox_modern(
    "recall_ud", col1_x, row_y + LY.LABEL_H + 4 + LY.INPUT_H + 6,
    STATE.recall_user_data, "Recall user data"
  )
  if L.stack_cols then
    row_y = row_y + LY.LABEL_H + 4 + LY.INPUT_H + 28 + LY.ROW_GAP
    font_label(); setcol(C.text_sec)
    gfx.x = col1_x; gfx.y = sy(row_y); gfx.drawstr("VENDOR / LIBRARY")
    font_body()
    STATE.vendor = text_input("vendor", col1_x, row_y + LY.LABEL_H + 4, half_w, LY.INPUT_H,
                              STATE.vendor, "e.g. SoundDesigner", { uppercase = true })
    row_y = row_y + LY.LABEL_H + 4 + LY.INPUT_H + LY.ROW_GAP
  else
    STATE.vendor = text_input("vendor", col2_x, row_y + LY.LABEL_H + 4, half_w, LY.INPUT_H,
                             STATE.vendor, "e.g. SoundDesigner", { uppercase = true })
    row_y = row_y + LY.LABEL_H + 4 + LY.INPUT_H + 28 + LY.ROW_GAP
  end

  -- Row 3: Micro variant / Take
  font_label(); setcol(C.text_sec)
  gfx.x = col1_x; gfx.y = sy(row_y); gfx.drawstr("MICRO VARIANT")
  if not L.stack_cols then
    gfx.x = col2_x; gfx.y = sy(row_y); gfx.drawstr("TAKE NUMBER")
  end

  font_body()
  STATE.microvariant = text_input("mvar", col1_x, row_y + LY.LABEL_H + 4, half_w, LY.INPUT_H,
                                  STATE.microvariant, "e.g. HardV1", { uppercase = true })
  if L.stack_cols then
    row_y = row_y + LY.LABEL_H + 4 + LY.INPUT_H + LY.ROW_GAP
    font_label(); setcol(C.text_sec)
    gfx.x = col1_x; gfx.y = sy(row_y); gfx.drawstr("TAKE NUMBER")
    font_body()
    STATE.take_num_str = text_input("takenum", col1_x, row_y + LY.LABEL_H + 4, half_w, LY.INPUT_H,
                                    STATE.take_num_str, "e.g. 01")
    STATE.auto_take_inc, _ = checkbox_modern("auto_take", col1_x, row_y + LY.LABEL_H + 4 + LY.INPUT_H + 6,
                                             STATE.auto_take_inc, "Auto-increment after rename")
    row_y = row_y + LY.LABEL_H + 4 + LY.INPUT_H + 28 + LY.ROW_GAP
  else
    STATE.take_num_str = text_input("takenum", col2_x, row_y + LY.LABEL_H + 4, half_w, LY.INPUT_H,
                                    STATE.take_num_str, "e.g. 01")
    STATE.auto_take_inc, _ = checkbox_modern("auto_take", col2_x, row_y + LY.LABEL_H + 4 + LY.INPUT_H + 6,
                                             STATE.auto_take_inc, "Auto-increment")
    row_y = row_y + LY.LABEL_H + 4 + LY.INPUT_H + LY.ROW_GAP
  end

  -- Row 4: Free notes
  font_label(); setcol(C.text_sec)
  gfx.x = col1_x; gfx.y = sy(row_y); gfx.drawstr("FREE NOTES")

  font_body()
  STATE.free_notes = text_input("fnotes", col1_x, row_y + LY.LABEL_H + 4, full_w, LY.INPUT_H,
                                STATE.free_notes, "Optional extra info", { uppercase = true })
  row_y = row_y + LY.LABEL_H + 4 + LY.INPUT_H + LY.ROW_GAP

  -- Render options
  STATE.render_use_reaper, _ = checkbox_modern(
    "render_reaper", col1_x, row_y, STATE.render_use_reaper,
    "Use REAPER render"
  )
  row_y = row_y + 28 + LY.ROW_GAP

  if STATE.render_use_reaper then
    STATE.render_open_dialog, _ = checkbox_modern(
      "render_dialog", col1_x, row_y, STATE.render_open_dialog,
      "Open REAPER render dialog"
    )
    row_y = row_y + 28 + LY.ROW_GAP

    STATE.render_regions, _ = checkbox_modern(
      "render_regions", col1_x, row_y, STATE.render_regions,
      "Render regions (click region, time sel, or items)"
    )
    row_y = row_y + 28 + LY.ROW_GAP
  end

  STATE.post_render_import, _ = checkbox_modern(
    "post_import", col1_x, row_y, STATE.post_render_import,
    "Post-render: place file on track below item"
  )
  row_y = row_y + 28 + LY.ROW_GAP

  STATE.post_render_create_track, _ = checkbox_modern(
    "post_create", col1_x, row_y, STATE.post_render_create_track,
    "Create track below if none exists"
  )
  row_y = row_y + 28 + LY.ROW_GAP

  font_label(); setcol(C.text_sec)
  gfx.x = col1_x; gfx.y = sy(row_y); gfx.drawstr("UCS EXPORT ROOT FOLDER")

  font_body()
  local default_root = get_default_render_root()
  local browse_w = 76
  local root_input_w = full_w - browse_w - 8
  STATE.render_root = text_input(
    "render_root", col1_x, row_y + LY.LABEL_H + 4, root_input_w, LY.INPUT_H,
    STATE.render_root, default_root
  )
  if button_modern("render_root_browse", col1_x + root_input_w + 8, row_y + LY.LABEL_H + 4,
                   browse_w, LY.INPUT_H, "BROWSE", "default") then
    browse_for_render_root()
  end
  row_y = row_y + LY.LABEL_H + 4 + LY.INPUT_H + LY.ROW_GAP

  -- Preview bar
  local preview = build_ucs_name()
  local preview_valid = #STATE.validation_issues == 0
  local preview_h = LY.INPUT_H + 2
  local preview_sy = sy(row_y)
  fill_rounded_rect(col1_x, preview_sy, full_w, preview_h, C.preview_bg, RADIUS.input)

  font_label(); setcol(C.text_dim)
  gfx.x = col1_x + 10; gfx.y = preview_sy + 9; gfx.drawstr("Preview:")

  font_body()
  local preview_text = preview ~= "" and preview or "(fill in fields above)"
  draw_clipped_text(
    preview_text,
    col1_x + 62, preview_sy + 1, full_w - 66, preview_h - 2,
    col1_x + 64, preview_sy + 9,
    C.preview_bg, preview_valid and C.accent or C.error
  )

  stroke_rounded_rect(col1_x, preview_sy, full_w, preview_h,
                      preview_valid and C.preview_bd or C.error, RADIUS.input)
  row_y = row_y + preview_h + 6

  if not preview_valid then
    font_small(); setcol(C.error)
    gfx.x = col1_x; gfx.y = sy(row_y)
    gfx.drawstr("⚠ " .. table.concat(STATE.validation_issues, " • "))
    row_y = row_y + 16
  end
  row_y = row_y + LY.ROW_GAP - 6

  -- Action buttons
  local btn_gap = 10
  local half_btn = math.floor((full_w - btn_gap) / 2)
  if button_modern("rename_btn", col1_x, row_y, half_btn, LY.BTN_H + 2,
                   "APPLY UCS NAME", "tertiary") then
    RT.pending_action = "apply_name"
  end
  if button_modern("render_btn", col1_x + half_btn + btn_gap, row_y, half_btn, LY.BTN_H + 2,
                   "RENDER", "primary") then
    request_render()
  end
  row_y = row_y + LY.BTN_H + 2 + 8
  if button_modern("pipeline_btn", col1_x, row_y, full_w, LY.BTN_H + 2,
                   "SPACE + GLUE + NORM + RENAME", "secondary") then
    request_pipeline()
  end

  draw_scrollbar(win_w, view_top, view_h, content_h, scroll_max)

  -- ── STATUS BAR (pinned to bottom) ────────────────────────────
  local sb_y = win_h - LY.STATUS_H
  fill_rect(0, sb_y, win_w, LY.STATUS_H, C.panel)
  setcol(C.border); gfx.line(0, sb_y, win_w - 1, sb_y)

  font_body()
  if STATE.status_timer > 0 then
    local alpha = math.min(1.0, STATE.status_timer / 40.0)
    gfx.set(0.19, 0.82, 0.35, alpha)
    gfx.x = 20; gfx.y = sb_y + 9
    gfx.drawstr("✓ " .. STATE.status_msg)
    STATE.status_timer = STATE.status_timer - 1
  else
    setcol(C.text_dim)
    gfx.x = 20; gfx.y = sb_y + 9
    local hint = "S suggest · R render · P pipeline"
    if scroll_max > 0 then hint = hint .. " · scroll for more" end
    gfx.drawstr(hint)
  end

  font_small(); setcol(C.text_dim)
  local credit = "By Haptik Audio"
  local version = "v" .. TOOL_VERSION
  gfx.x = win_w - gfx.measurestr(credit) - 16
  gfx.y = sb_y + 10
  gfx.drawstr(credit)
  gfx.x = win_w - gfx.measurestr(credit) - gfx.measurestr(version) - 28
  gfx.y = sb_y + 10
  gfx.drawstr(version)

  -- ── HEADER (fixed on top) ────────────────────────────────────
  fill_rect(0, 0, win_w, LY.HEADER_H, C.panel)
  setcol(C.border); gfx.line(0, LY.HEADER_H - 1, win_w, LY.HEADER_H - 1)

  local logo_size = 32
  local logo_x = 12
  local logo_y = math.floor((LY.HEADER_H - logo_size) / 2)
  local logo_w_used = draw_header_logo(logo_x, logo_y, logo_size)

  font_title()
  setcol(C.text)
  gfx.x = logo_w_used > 0 and (logo_x + logo_w_used + 10) or 20
  gfx.y = 18
  gfx.drawstr(TOOL_TITLE)

  font_small(); setcol(C.text_dim)
  local subtitle = "Space • Glue • Normalize • Rename"
  gfx.x = math.max(220, win_w - gfx.measurestr(subtitle) - 68)
  gfx.y = 20; gfx.drawstr(subtitle)

  ui_scroll_y = 0
  local dock_btn_w = 52
  if button_modern("dock_btn", win_w - dock_btn_w - 12, 12, dock_btn_w, 28,
                   gfx.dock(-1) > 0 and "UNDOCK" or "DOCK", "default") then
    if gfx.dock(-1) > 0 then gfx.dock(0) else gfx.dock(1) end
    mark_dirty()
  end
  ui_scroll_y = STATE.scroll_y

  -- Sync open state before wheel handling so dropdowns get scroll priority
  STATE.dd_preset_open = new_preset_open
  STATE.dd_norm_open = new_norm_open
  STATE.dd_cat_open = new_cat_open
  STATE.dd_sub_open = new_sub_open

  if gfx.mouse_wheel ~= 0 and not any_dropdown_open() and not STATE.preflight and not focused_field then
    local mx, my = gfx.mouse_x, gfx.mouse_y
    if my >= view_top and my < view_bottom and scroll_max > 0 then
      RT.scroll_target_y = math.max(0, math.min(scroll_max,
        RT.scroll_target_y - gfx.mouse_wheel * LY.SCROLL_WHEEL_STEP))
      gfx.mouse_wheel = 0
      mark_dirty()
    end
  end

  -- ── DROPDOWN OVERLAYS ────────────────────────────────────────
  font_body()

  if STATE.dd_preset_open then
    local new_idx, closed, new_scroll =
      dropdown_list("preset", DD.preset_list_x, DD.preset_list_y, DD.preset_list_w,
                    preset_names, STATE.preset_idx, STATE.scroll_preset, 28, 8)
    if new_idx ~= STATE.preset_idx then apply_preset_idx(new_idx) end
    STATE.scroll_preset = new_scroll
    if closed then STATE.dd_preset_open = false end
  end

  if STATE.dd_norm_open then
    local new_idx, closed, _ =
      dropdown_list("norm_mode", DD.norm_list_x, DD.norm_list_y, DD.norm_list_w,
                    NORM_MODE_NAMES, STATE.norm_mode_idx, 0, 28, 4)
    if new_idx ~= STATE.norm_mode_idx then
      STATE.norm_mode_idx = new_idx
      switch_norm_mode(NORM_MODE_VALUES[new_idx] or "peak")
    end
    if closed then STATE.dd_norm_open = false end
  end

  if STATE.dd_cat_open then
    local new_idx, closed, new_scroll =
      dropdown_list("cat", DD.list_x_cat, DD.cat_list_y, DD.list_w_cat,
                    cat_names, STATE.cat_idx, STATE.scroll_cat, 28, 10)
    if new_idx ~= STATE.cat_idx then
      STATE.cat_idx = new_idx
      STATE.sub_idx = 1
    end
    STATE.scroll_cat  = new_scroll
    if closed then STATE.dd_cat_open = false end
  end

  if STATE.dd_sub_open then
    local sub_n = get_sub_names()
    local new_idx, closed, new_scroll =
      dropdown_list("sub", DD.list_x_sub, DD.sub_list_y, DD.list_w_sub,
                    sub_n, STATE.sub_idx, STATE.scroll_sub, 28, 10)
    STATE.sub_idx    = new_idx
    STATE.scroll_sub = new_scroll
    if closed then STATE.dd_sub_open = false end
  end

  -- Close dropdowns on outside click
  if (gfx.mouse_cap & 1) == 1 then
    local mx = gfx.mouse_x
    local my = gfx.mouse_y
    if STATE.dd_preset_open then
      local in_header = (mx >= DD.preset_list_x and mx <= DD.preset_list_x + DD.preset_list_w
                         and vmy() >= DD.preset_list_y - LY.INPUT_H and vmy() < DD.preset_list_y)
      local in_list   = (mx >= DD.preset_list_x and mx <= DD.preset_list_x + DD.preset_list_w
                         and vmy() >= DD.preset_list_y)
      if not in_header and not in_list then STATE.dd_preset_open = false end
    end
    if STATE.dd_norm_open then
      local in_header = (mx >= DD.norm_list_x and mx <= DD.norm_list_x + DD.norm_list_w
                         and vmy() >= DD.norm_list_y - LY.INPUT_H and vmy() < DD.norm_list_y)
      local in_list   = (mx >= DD.norm_list_x and mx <= DD.norm_list_x + DD.norm_list_w
                         and vmy() >= DD.norm_list_y)
      if not in_header and not in_list then STATE.dd_norm_open = false end
    end
    if STATE.dd_cat_open then
      local in_header = (mx >= DD.list_x_cat and mx <= DD.list_x_cat+DD.list_w_cat
                         and vmy() >= DD.cat_list_y-LY.INPUT_H and vmy() < DD.cat_list_y)
      local in_list   = (mx >= DD.list_x_cat and mx <= DD.list_x_cat+DD.list_w_cat
                         and vmy() >= DD.cat_list_y)
      if not in_header and not in_list then
        STATE.dd_cat_open = false
      end
    end
    if STATE.dd_sub_open then
      local in_header = (mx >= DD.list_x_sub and mx <= DD.list_x_sub+DD.list_w_sub
                         and vmy() >= DD.sub_list_y-LY.INPUT_H and vmy() < DD.sub_list_y)
      local in_list   = (mx >= DD.list_x_sub and mx <= DD.list_x_sub+DD.list_w_sub
                         and vmy() >= DD.sub_list_y)
      if not in_header and not in_list then
        STATE.dd_sub_open = false end
    end
  end

  clear_focus_on_click_outside()
  input_prev_down = frame_mouse_down

  if STATE.preflight then
    draw_preflight_modal(L)
  end
end

-- ─── INIT & LOOP ─────────────────────────────────────────────
reaper.atexit(cleanup)

-- Release a stale gfx context if the previous run didn't shut down cleanly
if reaper.GetExtState(EXT_SECTION, "running") == "1" then
  pcall(gfx.quit)
end
reaper.SetExtState(EXT_SECTION, "running", "1", false)

local init_dock = load_settings()
seed_norm_level_cache()
RT.scroll_target_y = STATE.scroll_y
gfx.init(TOOL_TITLE, STATE.init_w, STATE.init_h, init_dock)
gfx.setfont(1, UI_FONT, 13)
load_logo()
RT.saved_w = gfx.w
RT.saved_h = gfx.h

local function loop()
  frame_char, frame_codepoint = gfx.getchar()
  handle_keyboard_shortcuts(frame_char)
  if frame_char == -1 then
    save_settings(gfx.w, gfx.h)
    cleanup()
    return
  end

  draw()
  gfx.update()
  flush_pending_action()

  local cur_w, cur_h = gfx.w, gfx.h
  if math.floor(cur_w) ~= math.floor(RT.saved_w)
     or math.floor(cur_h) ~= math.floor(RT.saved_h) then
    RT.saved_w, RT.saved_h = cur_w, cur_h
    mark_dirty()
  end

  if settings_dirty then
    save_settings(cur_w, cur_h)
  end

  reaper.defer(loop)
end

reaper.defer(loop)
