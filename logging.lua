if type(logging) == "table" and type(logging.disable) == "function" then
  logging.disable()
end

logging = {}
logging.signals = {}

function logging.enable()
  for _, reg in ipairs(logging.signals) do
    if signal.defined(reg.event, reg.callback_name) then
      signal.remove(reg.event, reg.callback_name)
    end
    return signal.connect(reg.event, reg.callback_name)
  end
end

function logging.disable()
  for _, reg in ipairs(logging.signals) do
    if signal.defined(reg.event, reg.callback_name) then
      signal.remove(reg.event, reg.callback_name)
    end
  end
end

function logging.register_signal(event, callback_name)
  table.insert(logging.signals, {
    event = event,
    callback_name = callback_name
  })
end

function logging.log_and_store_event(event)
  logging.log_event(event)
  logging.store_event(event)
end

function logging.log_event(event)
  log.normal(json.encode(event))
end

function logging.store_event(event)
  local events = logging.events_get()
  local turn = game.current_turn()
  if logging.turn and turn > logging.turn then
    logging.events_clear()
  end
  event.timestamp = os.time()
  table.insert(events, event)
  logging.events_save()
end

function logging.player_tag(player)
  return {
    id = player.id,
    name = player.name,
    nation = player.nation:rule_name()
  }
end

function logging.tile_tag(tile)
  return { x = tile.x, y = tile.y, nat_x = tile.nat_x, nat_y = tile.nat_y }
end

function logging.unit_tag(unit)
  if not unit or not unit:exists() then return nil end
  return {
    owner = logging.player_tag(unit.owner),
    utype = unit.utype:rule_name(),
    id = unit.id,
    tile = logging.tile_tag(unit.tile)
  }
end

function logging.city_tag(city)
  if not city or not city:exists() then return nil end
  return {
    owner = logging.player_tag(city.owner),
    id = city.id,
    name = city.name,
    size = city.size,
    tile = logging.tile_tag(city.tile)
  }
end

function logging_turn_begin(turn, year)
  logging.log_event {
    event = "turn_begin",
    turn = turn,
    year = game.current_year()
  }
end
logging.register_signal("turn_begin", "logging_turn_begin")

function logging.events_clear()
  logging.turn = game.current_turn()
  logging.events = {}
  logging.events_save()
end

function logging.events_get()
  if logging.events then return logging.events end
  if _G["events"] then
    logging.events = json.decode(_G["events"])
  else
    logging.events = {}
    logging.events_save()
  end
  return events
end

function logging.events_save()
  _G["events"] = json.encode(logging.events)
end

function logging_unit_moved(unit, tile_from, tile_to)
  logging.store_event {
    event = "unit_moved",
    unit = logging.unit_tag(unit),
    tile_from = logging.tile_tag(tile_from),
    tile_to = logging.tile_tag(tile_to)
  }
end
logging.register_signal("unit_moved", "logging_unit_moved")

function logging_city_built(city)
  logging.log_and_store_event {
    event = "city_built",
    city = logging.city_tag(city)
  }
end
logging.register_signal("city_built", "logging_city_built")

function logging_city_size_change(city, change, reason)
  logging.log_and_store_event {
    event = "city_size_change",
    change = change,
    city = logging.city_tag(city),
    reason = reason
  }
end
logging.register_signal("city_size_change", "logging_city_size_change")

function logging_unit_built(unit, city)
  logging.log_and_store_event {
    event = "unit_built",
    city = logging.city_tag(city),
    unit = logging.unit_tag(unit)
  }
end
logging.register_signal("unit_built", "logging_unit_built")

function logging_building_built(building, city)
  logging.log_and_store_event {
    event = "building_built",
    city = logging.city_tag(city),
    building = building:rule_name()
  }
end
logging.register_signal("building_built", "logging_building_built")

function logging_building_lost(city, building, reason, destroyer)
  logging.log_and_store_event {
    event = "building_lost",
    city = logging.city_tag(city),
    building = building:rule_name(),
    reason = reason,
    unit = logging.unit_tag(destroyer)
  }
end
logging.register_signal("building_lost", "logging_building_lost")

function logging_tech_researched(tech, player, source)
  logging.log_and_store_event {
    event = "tech_researched",
    player = logging.player_tag(player),
    tech = tech:rule_name(),
    source = source
  }
end
logging.register_signal("tech_researched", "logging_tech_researched")

function logging_city_destroyed(city, owner, enemy)
  logging.log_and_store_event {
    event = "city_destroyed",
    city = logging.city_tag(city),
    enemy = logging.player_tag(enemy),
  }
end
logging.register_signal("city_destroyed", "logging_city_destroyed")

function logging_city_transferred(city, former_owner, new_owner, reason)
  logging.log_and_store_event {
    event = "city_transferred",
    former_owner = logging.player_tag(former_owner),
    new_owner = logging.player_tag(new_owner),
    reason = reason
  }
end
logging.register_signal("city_transferred", "logging_city_transferred")

function logging_hut_enter(unit, extra)
  logging.log_and_store_event {
    event = "hut_enter",
    unit = logging.unit_tag(unit),
    extra = extra
  }
end
logging.register_signal("hut_enter", "logging_hut_enter")

function logging_hut_frighten(unit, extra)
  logging.log_and_store_event {
    event = "hut_frighten",
    unit = logging.unit_tag(unit),
    extra = extra
  }
end
logging.register_signal("hut_frighten", "logging_hut_frighten")

function logging_unit_lost(unit, player, reason)
  logging.log_and_store_event {
    event = "unit_lost",
    unit = logging.unit_tag(unit),
    reason = reason
  }
end
logging.register_signal("unit_lost", "logging_unit_lost")

function logging_disaster_occurred(disaster, city)
  logging.log_and_store_event {
    event = "disaster_occurred",
    disaster = disaster:rule_name(),
    city = logging.city_tag(city)
  }
end
logging.register_signal("disaster_occurred", "logging_disaster_occurred")

function logging_nuke_exploded(tile, player)
  logging.log_and_store_event {
    event = "nuke_exploded",
    tile = logging.tile_tag(tile),
    player = logging.player_tag(player)
  }
end
logging.register_signal("nuke_exploded", "logging_nuke_exploded")

function logging_achievement_gained(achievement, player, first)
  logging.log_and_store_event {
    event = "achievement_gained",
    achievement = achievement:rule_name(),
    player = logging.player_tag(player),
    first = first
  }
end
logging.register_signal("achievement_gained", "logging_achievement_gained")

function logging_action_on_self(action, actor)
  logging.log_and_store_event {
    event = "action_started_unit_self",
    action = action:rule_name(),
    actor = logging.unit_tag(actor)
  }
end
logging.register_signal("action_started_unit_self", "logging_action_on_self")

function logging_action_on_tile(action, actor, target)
  logging.log_and_store_event {
    event = "action_started_unit_tile",
    action = action:rule_name(),
    actor = logging.unit_tag(actor),
    target = logging.tile_tag(target)
  }
end
logging.register_signal("action_started_unit_units", "logging_action_on_units")

function logging_action_on_units(action, actor, target)
  logging.log_and_store_event {
    event = "action_started_unit_units",
    action = action:rule_name(),
    actor = logging.unit_tag(actor),
    target = logging.tile_tag(target)
  }
end
logging.register_signal("action_started_unit_tile", "logging_action_on_tile")

function logging_action_on_city(action, actor, target)
  logging.log_and_store_event {
    event = "action_started_unit_city",
    action = action:rule_name(),
    actor = logging.unit_tag(actor),
    target = logging.city_tag(target)
  }
end
logging.register_signal("action_started_unit_city", "logging_action_on_city")

function logging_action_on_unit(action, actor, target)
  logging.log_and_store_event {
    event = "action_started_unit_unit",
    action = action:rule_name(),
    actor = logging.unit_tag(actor),
    target = logging.unit_tag(target)
  }
end
logging.register_signal("action_started_unit_unit", "logging_action_on_unit")

-------------
-- Modules --
-------------

do
--
-- json.lua
--
-- Copyright (c) 2020 rxi
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

local json = { _version = "0.1.2" }

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local encode

local escape_char_map = {
  [ "\\" ] = "\\",
  [ "\"" ] = "\"",
  [ "\b" ] = "b",
  [ "\f" ] = "f",
  [ "\n" ] = "n",
  [ "\r" ] = "r",
  [ "\t" ] = "t",
}

local escape_char_map_inv = { [ "/" ] = "/" }
for k, v in pairs(escape_char_map) do
  escape_char_map_inv[v] = k
end


local function escape_char(c)
  return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
end


local function encode_nil(val)
  return "null"
end


local function encode_table(val, stack)
  local res = {}
  stack = stack or {}

  -- Circular reference?
  if stack[val] then error("circular reference") end

  stack[val] = true

  if rawget(val, 1) ~= nil or next(val) == nil then
    -- Treat as array -- check keys are valid and it is not sparse
    local n = 0
    for k in pairs(val) do
      if type(k) ~= "number" then
        error("invalid table: mixed or invalid key types")
      end
      n = n + 1
    end
    if n ~= #val then
      error("invalid table: sparse array")
    end
    -- Encode
    for i, v in ipairs(val) do
      table.insert(res, encode(v, stack))
    end
    stack[val] = nil
    return "[" .. table.concat(res, ",") .. "]"

  else
    -- Treat as an object
    for k, v in pairs(val) do
      if type(k) ~= "string" then
        error("invalid table: mixed or invalid key types")
      end
      table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
    end
    stack[val] = nil
    return "{" .. table.concat(res, ",") .. "}"
  end
end


local function encode_string(val)
  return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end


local function encode_number(val)
  -- Check for NaN, -inf and inf
  if val ~= val or val <= -math.huge or val >= math.huge then
    error("unexpected number value '" .. tostring(val) .. "'")
  end
  return string.format("%.14g", val)
end


local type_func_map = {
  [ "nil"     ] = encode_nil,
  [ "table"   ] = encode_table,
  [ "string"  ] = encode_string,
  [ "number"  ] = encode_number,
  [ "boolean" ] = tostring,
}


encode = function(val, stack)
  local t = type(val)
  local f = type_func_map[t]
  if f then
    return f(val, stack)
  end
  error("unexpected type '" .. t .. "'")
end


function json.encode(val)
  return ( encode(val) )
end


-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

local function create_set(...)
  local res = {}
  for i = 1, select("#", ...) do
    res[ select(i, ...) ] = true
  end
  return res
end

local space_chars   = create_set(" ", "\t", "\r", "\n")
local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals      = create_set("true", "false", "null")

local literal_map = {
  [ "true"  ] = true,
  [ "false" ] = false,
  [ "null"  ] = nil,
}


local function next_char(str, idx, set, negate)
  for i = idx, #str do
    if set[str:sub(i, i)] ~= negate then
      return i
    end
  end
  return #str + 1
end


local function decode_error(str, idx, msg)
  local line_count = 1
  local col_count = 1
  for i = 1, idx - 1 do
    col_count = col_count + 1
    if str:sub(i, i) == "\n" then
      line_count = line_count + 1
      col_count = 1
    end
  end
  error( string.format("%s at line %d col %d", msg, line_count, col_count) )
end


local function codepoint_to_utf8(n)
  -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
  local f = math.floor
  if n <= 0x7f then
    return string.char(n)
  elseif n <= 0x7ff then
    return string.char(f(n / 64) + 192, n % 64 + 128)
  elseif n <= 0xffff then
    return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
  elseif n <= 0x10ffff then
    return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
                       f(n % 4096 / 64) + 128, n % 64 + 128)
  end
  error( string.format("invalid unicode codepoint '%x'", n) )
end


local function parse_unicode_escape(s)
  local n1 = tonumber( s:sub(1, 4),  16 )
  local n2 = tonumber( s:sub(7, 10), 16 )
   -- Surrogate pair?
  if n2 then
    return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
  else
    return codepoint_to_utf8(n1)
  end
end


local function parse_string(str, i)
  local res = ""
  local j = i + 1
  local k = j

  while j <= #str do
    local x = str:byte(j)

    if x < 32 then
      decode_error(str, j, "control character in string")

    elseif x == 92 then -- `\`: Escape
      res = res .. str:sub(k, j - 1)
      j = j + 1
      local c = str:sub(j, j)
      if c == "u" then
        local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)
                 or str:match("^%x%x%x%x", j + 1)
                 or decode_error(str, j - 1, "invalid unicode escape in string")
        res = res .. parse_unicode_escape(hex)
        j = j + #hex
      else
        if not escape_chars[c] then
          decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
        end
        res = res .. escape_char_map_inv[c]
      end
      k = j + 1

    elseif x == 34 then -- `"`: End of string
      res = res .. str:sub(k, j - 1)
      return res, j + 1
    end

    j = j + 1
  end

  decode_error(str, i, "expected closing quote for string")
end


local function parse_number(str, i)
  local x = next_char(str, i, delim_chars)
  local s = str:sub(i, x - 1)
  local n = tonumber(s)
  if not n then
    decode_error(str, i, "invalid number '" .. s .. "'")
  end
  return n, x
end


local function parse_literal(str, i)
  local x = next_char(str, i, delim_chars)
  local word = str:sub(i, x - 1)
  if not literals[word] then
    decode_error(str, i, "invalid literal '" .. word .. "'")
  end
  return literal_map[word], x
end


local function parse_array(str, i)
  local res = {}
  local n = 1
  i = i + 1
  while 1 do
    local x
    i = next_char(str, i, space_chars, true)
    -- Empty / end of array?
    if str:sub(i, i) == "]" then
      i = i + 1
      break
    end
    -- Read token
    x, i = parse(str, i)
    res[n] = x
    n = n + 1
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "]" then break end
    if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
  end
  return res, i
end


local function parse_object(str, i)
  local res = {}
  i = i + 1
  while 1 do
    local key, val
    i = next_char(str, i, space_chars, true)
    -- Empty / end of object?
    if str:sub(i, i) == "}" then
      i = i + 1
      break
    end
    -- Read key
    if str:sub(i, i) ~= '"' then
      decode_error(str, i, "expected string for key")
    end
    key, i = parse(str, i)
    -- Read ':' delimiter
    i = next_char(str, i, space_chars, true)
    if str:sub(i, i) ~= ":" then
      decode_error(str, i, "expected ':' after key")
    end
    i = next_char(str, i + 1, space_chars, true)
    -- Read value
    val, i = parse(str, i)
    -- Set
    res[key] = val
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "}" then break end
    if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
  end
  return res, i
end


local char_func_map = {
  [ '"' ] = parse_string,
  [ "0" ] = parse_number,
  [ "1" ] = parse_number,
  [ "2" ] = parse_number,
  [ "3" ] = parse_number,
  [ "4" ] = parse_number,
  [ "5" ] = parse_number,
  [ "6" ] = parse_number,
  [ "7" ] = parse_number,
  [ "8" ] = parse_number,
  [ "9" ] = parse_number,
  [ "-" ] = parse_number,
  [ "t" ] = parse_literal,
  [ "f" ] = parse_literal,
  [ "n" ] = parse_literal,
  [ "[" ] = parse_array,
  [ "{" ] = parse_object,
}


parse = function(str, idx)
  local chr = str:sub(idx, idx)
  local f = char_func_map[chr]
  if f then
    return f(str, idx)
  end
  decode_error(str, idx, "unexpected character '" .. chr .. "'")
end


function json.decode(str)
  if type(str) ~= "string" then
    error("expected argument of type string, got " .. type(str))
  end
  local res, idx = parse(str, next_char(str, 1, space_chars, true))
  idx = next_char(str, idx, space_chars, true)
  if idx <= #str then
    decode_error(str, idx, "trailing garbage")
  end
  return res
end


_G["json"] = json
end

--------------------
-- Initialisation --
--------------------

logging.enable()

