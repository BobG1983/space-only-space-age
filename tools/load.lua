#!/usr/bin/env lua5.2
-- Runs the Factorio 2.1 prototype (settings + data) stage outside the game against a
-- checkout of wube/factorio-data, optionally with one mod on top. See tools/README.md.
--
-- Exit codes: 0 loaded (and, with --check, no problems); 1 --check found problems;
-- 2 a stage file raised an error; 3 bad command line.

local TOOLS_DIR = (arg and arg[0] and arg[0]:match("^(.*)/[^/]*$")) or "."

local VANILLA_ORDER = {"base", "elevated-rails", "recycler", "quality", "space-age"}
local FEATURE_FLAGS = {"space_travel", "spoiling", "freezing", "segmented_units",
                       "expansion_shaders", "quality", "rail_bridges", "expansion"}

-- ---------------------------------------------------------------------------
-- command line
-- ---------------------------------------------------------------------------
local function usage(msg)
  if msg then io.stderr:write("load.lua: ", msg, "\n") end
  io.stderr:write([[
usage: lua5.2 tools/load.lua --data DIR [--mod DIR] [--dump FILE] [--dump-types a,b]
                             [--check] [--find-string NAME ...] [--verbose]
  --data DIR         factorio-data checkout (holds core/, base/, space-age/ ...)
  --mod DIR          mod directory to load after space-age (needs info.json)
  --dump FILE        write data.raw as JSON (functions skipped, keys sorted)
  --dump-types a,b   limit --dump to these data.raw categories
  --check            run tools/check.lua; one line per problem, exit 1 on any
  --find-string N..  print every data.raw path whose string equals N or holds N as a word
  --verbose          print every log() call and every stub as it fires
]])
  os.exit(3)
end

local opts = {find = {}}
do
  local i = 1
  local function need(flag)
    i = i + 1
    if not arg[i] then usage(flag .. " needs a value") end
    return arg[i]
  end
  while i <= #arg do
    local a = arg[i]
    if a == "--data" then opts.data = need(a)
    elseif a == "--mod" then opts.mod = need(a)
    elseif a == "--dump" then opts.dump = need(a)
    elseif a == "--dump-types" then opts.dump_types = need(a)
    elseif a == "--check" then opts.check = true
    elseif a == "--verbose" then opts.verbose = true
    elseif a == "--find-string" then
      i = i + 1
      while arg[i] and arg[i]:sub(1, 2) ~= "--" do
        opts.find[#opts.find + 1] = arg[i]
        i = i + 1
      end
      if #opts.find == 0 then usage("--find-string needs at least one name") end
      i = i - 1
    elseif a == "--help" or a == "-h" then usage()
    else usage("unknown argument " .. a) end
    i = i + 1
  end
  if not opts.data then usage("--data is required") end
end

-- ---------------------------------------------------------------------------
-- file helpers
-- ---------------------------------------------------------------------------
local function file_exists(p)
  local f = io.open(p, "rb")
  if f then f:close() return true end
  return false
end

local function read_file(p)
  local f, err = io.open(p, "rb")
  if not f then error(err, 0) end
  local s = f:read("*a")
  f:close()
  return s
end

local function dirname(p) return p:match("^(.*)/[^/]*$") or "." end
local function basename(p) return p:match("([^/]*)$") end
local function strip_slash(p) return (p:gsub("/+$", "")) end

local function warn(...) io.stderr:write(table.concat({...}, ""), "\n") end

-- ---------------------------------------------------------------------------
-- minimal JSON decoder, for info.json
-- ---------------------------------------------------------------------------
local json_decode
do
  local function utf8_char(cp)
    if cp < 0x80 then return string.char(cp) end
    if cp < 0x800 then return string.char(0xC0 + math.floor(cp / 0x40), 0x80 + cp % 0x40) end
    return string.char(0xE0 + math.floor(cp / 0x1000), 0x80 + math.floor(cp / 0x40) % 0x40, 0x80 + cp % 0x40)
  end
  local escapes = {['"'] = '"', ['\\'] = '\\', ['/'] = '/', b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'}
  local function skip(s, i) return s:find("%S", i) or #s + 1 end
  local function parse_string(s, i)
    local buf, j = {}, i + 1
    while true do
      local c = s:sub(j, j)
      if c == "" then error("json: unterminated string", 0) end
      if c == '"' then return table.concat(buf), j + 1 end
      if c == "\\" then
        local e = s:sub(j + 1, j + 1)
        if e == "u" then
          buf[#buf + 1] = utf8_char(tonumber(s:sub(j + 2, j + 5), 16) or 63)
          j = j + 6
        else
          buf[#buf + 1] = escapes[e] or e
          j = j + 2
        end
      else
        buf[#buf + 1] = c
        j = j + 1
      end
    end
  end
  local parse
  parse = function(s, i)
    i = skip(s, i)
    local c = s:sub(i, i)
    if c == "{" then
      local obj = {}
      i = skip(s, i + 1)
      if s:sub(i, i) == "}" then return obj, i + 1 end
      while true do
        i = skip(s, i)
        if s:sub(i, i) ~= '"' then error("json: expected a key at " .. i, 0) end
        local k
        k, i = parse_string(s, i)
        i = skip(s, i)
        if s:sub(i, i) ~= ":" then error("json: expected ':' at " .. i, 0) end
        local v
        v, i = parse(s, i + 1)
        obj[k] = v
        i = skip(s, i)
        local d = s:sub(i, i)
        if d == "," then i = i + 1
        elseif d == "}" then return obj, i + 1
        else error("json: expected ',' or '}' at " .. i, 0) end
      end
    elseif c == "[" then
      local arr = {}
      i = skip(s, i + 1)
      if s:sub(i, i) == "]" then return arr, i + 1 end
      while true do
        local v
        v, i = parse(s, i)
        arr[#arr + 1] = v
        i = skip(s, i)
        local d = s:sub(i, i)
        if d == "," then i = i + 1
        elseif d == "]" then return arr, i + 1
        else error("json: expected ',' or ']' at " .. i, 0) end
      end
    elseif c == '"' then return parse_string(s, i)
    elseif s:sub(i, i + 3) == "true" then return true, i + 4
    elseif s:sub(i, i + 4) == "false" then return false, i + 5
    elseif s:sub(i, i + 3) == "null" then return nil, i + 4
    else
      local num = s:match("^-?%d+%.?%d*[eE]?[-+]?%d*", i)
      if not num or num == "" then error("json: unexpected character at " .. i, 0) end
      return tonumber(num), i + #num
    end
  end
  json_decode = function(s) return (parse(s, 1)) end
end

-- ---------------------------------------------------------------------------
-- serpent: enough of serpent.block / line / dump for dataloader and util
-- ---------------------------------------------------------------------------
local serpent = {}
do
  local function key_order(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return ta < tb end
    if ta == "number" or ta == "string" then return a < b end
    return tostring(a) < tostring(b)
  end
  local function ser(v, o, level, seen)
    local t = type(v)
    if t == "string" then return string.format("%q", v) end
    if t == "number" then
      if v ~= v then return "0/0" end
      if v == math.huge then return "math.huge" end
      if v == -math.huge then return "-math.huge" end
      if v == math.floor(v) and math.abs(v) < 2 ^ 53 then return string.format("%d", v) end
      return string.format("%.17g", v)
    end
    if t == "boolean" or t == "nil" then return tostring(v) end
    if t ~= "table" then return "nil --[[" .. tostring(v) .. "]]" end
    if seen[v] then return "nil --[[ref]]" end
    if o.maxlevel and level >= o.maxlevel then return "{--[[...]]}" end
    seen[v] = true
    local parts = {}
    local n = #v
    for i = 1, n do parts[#parts + 1] = ser(v[i], o, level + 1, seen) end
    local others = {}
    for k in pairs(v) do
      if not (type(k) == "number" and k >= 1 and k <= n and k == math.floor(k)) then others[#others + 1] = k end
    end
    table.sort(others, key_order)
    for _, k in ipairs(others) do
      local ks
      if type(k) == "string" and k:match("^[%a_][%w_]*$") then ks = k else ks = "[" .. ser(k, o, level + 1, seen) .. "]" end
      parts[#parts + 1] = ks .. " = " .. ser(v[k], o, level + 1, seen)
    end
    seen[v] = nil
    if #parts == 0 then return "{}" end
    if o.compact then return "{" .. table.concat(parts, ", ") .. "}" end
    local ind = o.indent or "  "
    local pad = string.rep(ind, level + 1)
    return "{\n" .. pad .. table.concat(parts, ",\n" .. pad) .. "\n" .. string.rep(ind, level) .. "}"
  end
  serpent.block = function(v, o) o = o or {} return ser(v, {maxlevel = o.maxlevel, indent = o.indent}, 0, {}) end
  serpent.line = function(v, o) o = o or {} return ser(v, {maxlevel = o.maxlevel, compact = true}, 0, {}) end
  serpent.dump = function(v, o) return "do local _=" .. serpent.line(v, o) .. ";return _;end" end
end

-- ---------------------------------------------------------------------------
-- defines
-- ---------------------------------------------------------------------------
local function make_defines(hierarchy)
  local defines = {}
  defines.direction = {
    north = 0, northnortheast = 1, northeast = 2, eastnortheast = 3, east = 4, eastsoutheast = 5,
    southeast = 6, southsoutheast = 7, south = 8, southsouthwest = 9, southwest = 10,
    westsouthwest = 11, west = 12, westnorthwest = 13, northwest = 14, northnorthwest = 15,
  }
  -- defines.prototypes[base_type][concrete_type] = 0, exactly what core/lualib/prototype-info.lua asserts.
  defines.prototypes = {}
  local function add(base, name, node)
    if not node._abstract then defines.prototypes[base][name] = 0 end
    for k, v in pairs(node) do if k ~= "_abstract" then add(base, k, v) end end
  end
  for base, node in pairs(hierarchy) do
    defines.prototypes[base] = {}
    add(base, base, node)
  end
  local counter = 1000
  local auto_leaf = {__index = function(t, k)
    counter = counter + 1
    rawset(t, k, counter)
    return counter
  end}
  defines.constant = setmetatable({default_icon_size = 64}, auto_leaf)
  return setmetatable(defines, {__index = function(t, k)
    local sub = setmetatable({}, auto_leaf)
    rawset(t, k, sub)
    return sub
  end})
end

-- ---------------------------------------------------------------------------
-- function values cannot be serialised into prototypes; list where they sit
-- ---------------------------------------------------------------------------
local function scan_functions(raw, functions_out)
  local seen = {}
  local function scan(v, path)
    if type(v) == "function" then functions_out[#functions_out + 1] = path return end
    if type(v) ~= "table" or seen[v] then return end
    seen[v] = true
    for k, x in pairs(v) do
      local kp = type(k) == "number" and ("[" .. k .. "]") or ("." .. tostring(k))
      scan(x, path .. kp)
    end
  end
  scan(raw, "data.raw")
end

-- ---------------------------------------------------------------------------
-- the loader
-- ---------------------------------------------------------------------------
local L = {
  data_dir = strip_slash(opts.data),
  mods = {},          -- ordered list of {name=, root=, version=, is_core=}
  by_name = {},
  mods_table = {},    -- the `mods` global: name -> version
  stub_fires = 0,
  stubs = {},         -- requested name -> {path=, from=, count=}
  stub_order = {},
  log_count = 0,
  functions = {},
  files_run = {},
}

local function add_mod(root, is_core)
  root = strip_slash(root)
  local info_path = root .. "/info.json"
  local name, version
  if file_exists(info_path) then
    local ok, info = pcall(json_decode, read_file(info_path))
    if not ok then usage("cannot parse " .. info_path .. ": " .. tostring(info)) end
    name, version = info.name, info.version
  end
  if not name then
    if is_core then name = "core" else
      name = basename(root)
      if (name == "." or name == "") and os.getenv("PWD") then name = basename(os.getenv("PWD")) end
      warn("warning: ", info_path, " missing; using directory name '", name, "' as the mod name")
    end
  end
  local rec = {name = name, root = root, version = version or "0.0.0", is_core = is_core}
  L.mods[#L.mods + 1] = rec
  L.by_name[name] = rec
  if not is_core then L.mods_table[name] = rec.version end
  return rec
end

if not file_exists(L.data_dir .. "/core/lualib/dataloader.lua") then
  usage(L.data_dir .. " has no core/lualib/dataloader.lua")
end
L.core = add_mod(L.data_dir .. "/core", true)
for _, m in ipairs(VANILLA_ORDER) do
  if not file_exists(L.data_dir .. "/" .. m .. "/info.json") then usage(L.data_dir .. "/" .. m .. "/info.json is missing") end
  add_mod(L.data_dir .. "/" .. m)
end
if opts.mod then L.user_mod = add_mod(opts.mod) end

L.hierarchy = dofile(L.data_dir .. "/core/lualib/prototype-hierarchy.lua")
L.defines = make_defines(L.hierarchy)
L.feature_flags = {}
for _, f in ipairs(FEATURE_FLAGS) do L.feature_flags[f] = true end

function L:display(path)
  for _, m in ipairs(self.mods) do
    if path:sub(1, #m.root + 1) == m.root .. "/" then return "__" .. m.name .. "__/" .. path:sub(#m.root + 2) end
  end
  return path
end

function L:mod_of(path)
  for _, m in ipairs(self.mods) do
    if path:sub(1, #m.root + 1) == m.root .. "/" then return m end
  end
  return nil
end

local function stub_for(name, path)
  local stub = {harness_stub = name}
  if name:find("/sound/", 1, true) then
    -- These sit directly inside a data:extend list in space-age/prototypes/ambient-sounds.lua,
    -- so the stub must be a prototype. The real files are not in the checkout; the name is a guess.
    local base = basename(path):gsub("%.lua$", "")
    local group = basename(dirname(dirname(path)))
    stub.type = "ambient-sound"
    stub.name = (base:sub(1, #group) == group) and base or (group .. "-" .. base)
    stub.track_type = "interlude"
    stub.sound = {filename = name .. ".ogg"}
  elseif name:find("/graphics/", 1, true) then
    -- util.sprite_load(path, t) reads width, height, shift, line_length and frames from the
    -- required table, so a graphics stub carries the fields it indexes.
    stub.width, stub.height, stub.shift, stub.line_length, stub.frames = 1, 1, {0, 0}, 1, 1
  end
  return stub
end

function L:log_message(msg)
  self.log_count = self.log_count + 1
  if opts.verbose then
    if type(msg) == "table" then msg = serpent.line(msg) end
    warn("log: ", tostring(msg))
  end
end

-- One Lua state per stage. Within a stage every mod's files share globals and the require
-- cache: base/data-updates.lua uses `util` and elevated-rails/data.lua uses `kg` without
-- requiring core/lualib/util.lua themselves, which only works because base/data.lua ran
-- `require "util"` earlier in the same state.
function L:new_state()
  local env = {}
  for _, k in ipairs{"assert", "error", "ipairs", "pairs", "next", "pcall", "xpcall", "select",
                     "tonumber", "tostring", "type", "rawequal", "rawget", "rawset", "rawlen",
                     "setmetatable", "getmetatable", "print", "collectgarbage", "_VERSION"} do
    env[k] = _G[k]
  end
  -- Deterministic pairs: a sorted snapshot of the keys. Lua 5.2 seeds its string hash per
  -- process, so native pairs order differs between runs, and recycler/data-updates.lua inserts
  -- into data.raw.recipe while iterating it, which made two barrel-recycling recipes appear or
  -- not depending on the run. The game's order is fixed but not reproducible here either.
  local function key_order(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return ta < tb end
    if ta == "number" or ta == "string" then return a < b end
    return tostring(a) < tostring(b)
  end
  env.pairs = function(t)
    local mt = getmetatable(t)
    if mt and mt.__pairs then return mt.__pairs(t) end
    local keys, n = {}, 0
    for k in next, t do n = n + 1 keys[n] = k end
    if n > 1 then table.sort(keys, key_order) end
    local i = 0
    return function()
      -- a key cleared by the loop body before its turn is skipped, as native pairs does
      while true do
        i = i + 1
        local k = keys[i]
        if k == nil then return nil end
        local v = t[k]
        if v ~= nil then return k, v end
      end
    end, t, nil
  end
  local function copy_lib(lib) local c = {} for k, v in pairs(lib) do c[k] = v end return c end
  env.math = copy_lib(math)
  env.math.pow = env.math.pow or function(a, b) return a ^ b end
  env.string = copy_lib(string)
  env.table = copy_lib(table)
  env.bit32 = copy_lib(bit32)
  env.coroutine = copy_lib(coroutine)
  env.unpack = table.unpack
  env.table_size = function(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end
  env.log = function(msg) self:log_message(msg) end
  env.localised_print = function(msg)
    if type(msg) == "table" then msg = serpent.line(msg) end
    warn("print: ", tostring(msg))
  end
  env.serpent = serpent
  env.defines = self.defines
  env.mods = self.mods_table
  env.feature_flags = self.feature_flags
  env.settings = self.settings
  env._G = env
  env.load = function(chunk, name, mode, e) return load(chunk, name, mode or "bt", e or env) end
  env.loadstring = env.load

  local loaded = {}
  local stack = {{file = self.core.root .. "/data.lua", mod = self.core}}
  local function run_chunk(path)
    local fn, err = load(read_file(path), "@" .. self:display(path), "t", env)
    if not fn then error(err, 0) end
    stack[#stack + 1] = {file = path, mod = self:mod_of(path) or stack[#stack].mod}
    local result = fn()
    stack[#stack] = nil
    return result
  end
  env.require = function(name)
    if type(name) ~= "string" then error("require: module name must be a string", 2) end
    local top = stack[#stack]
    local candidates = {}
    local modname, rest = name:match("^__(.-)__[/%.](.+)$")
    if modname then
      local m = self.by_name[modname]
      if not m then error("require: mod '" .. modname .. "' is not loaded (" .. name .. ")", 2) end
      candidates[1] = m.root .. "/" .. rest:gsub("%.", "/") .. ".lua"
    else
      local rel = name:gsub("%.", "/") .. ".lua"
      candidates[1] = top.mod.root .. "/" .. rel
      candidates[2] = dirname(top.file) .. "/" .. rel
      candidates[3] = self.core.root .. "/lualib/" .. rel
    end
    local path
    for _, c in ipairs(candidates) do
      if file_exists(c) then path = c break end
    end
    if not path then
      path = candidates[1]
      self.stub_fires = self.stub_fires + 1
      local rec = self.stubs[name]
      if not rec then
        rec = {path = path, from = self:display(top.file), count = 0}
        self.stubs[name] = rec
        self.stub_order[#self.stub_order + 1] = name
      end
      rec.count = rec.count + 1
      local norm = name:gsub("%.", "/")
      rec.asset = norm:find("/graphics/", 1, true) or norm:find("/sound/", 1, true)
        or norm:find("menu%-simulations") or norm:find("^graphics/")
      if opts.verbose or (rec.count == 1 and not rec.asset) then
        warn("stub: require(\"", name, "\") -> ", self:display(path), " is not in the checkout; returning a stub (from ", rec.from, ")")
      end
      if loaded[path] == nil then loaded[path] = stub_for(name, path) end
      return loaded[path]
    end
    if loaded[path] == nil then
      local result = run_chunk(path)
      if result == nil then result = true end
      loaded[path] = result
    end
    return loaded[path]
  end
  local state = {env = env, run_chunk = run_chunk}
  self:run_file(state, self.core.root .. "/lualib/dataloader.lua", "dataloader")
  return state
end

-- Runs one file in a state; a raised error ends the harness with exit code 2.
function L:run_file(state, path, stage)
  local ok, err = xpcall(function() state.run_chunk(path) end, debug.traceback)
  if not ok then
    -- drop the harness's own frames so the traceback reads like the game's
    local lines = {}
    for line in tostring(err):gmatch("[^\n]+") do
      if not (line:find("tools/load.lua", 1, true) or line:find("[C]: in function 'xpcall'", 1, true) or line:find("[C]: in ?", 1, true)) then
        lines[#lines + 1] = line
      end
    end
    io.stderr:write("ERROR in ", self:display(path), " (", stage, "):\n", table.concat(lines, "\n"), "\n")
    os.exit(2)
  end
end

function L:run_stage_file(state, modrec, filename, stage)
  local path = modrec.root .. "/" .. filename
  if not file_exists(path) then return false end
  self:run_file(state, path, stage)
  self.files_run[#self.files_run + 1] = self:display(path)
  return true
end

function L:run_phase(state, stage, filename)
  local n = 0
  for _, m in ipairs(self.mods) do
    if not m.is_core then
      if self:run_stage_file(state, m, filename, stage) then n = n + 1 end
    end
  end
  return n
end

-- settings stage ---------------------------------------------------------------
do
  local has_settings = false
  for _, m in ipairs(L.mods) do
    for _, f in ipairs{"settings.lua", "settings-updates.lua", "settings-final-fixes.lua"} do
      if file_exists(m.root .. "/" .. f) then has_settings = true end
    end
  end
  L.raw_settings = {}
  if has_settings then
    local state = L:new_state()
    L:run_phase(state, "settings", "settings.lua")
    L:run_phase(state, "settings-updates", "settings-updates.lua")
    L:run_phase(state, "settings-final-fixes", "settings-final-fixes.lua")
    L.raw_settings = state.env.data.raw
  end
  L.settings = {startup = {}, global = {}, player = {}}
  for _, t in ipairs{"bool-setting", "int-setting", "double-setting", "string-setting", "color-setting"} do
    for name, s in pairs(L.raw_settings[t] or {}) do
      local bucket = ({startup = "startup", ["runtime-global"] = "global", ["runtime-per-user"] = "player"})[s.setting_type]
      if bucket then L.settings[bucket][name] = {value = s.default_value} end
    end
  end
end

-- data stage -------------------------------------------------------------------
local raw
do
  local state = L:new_state()
  L:run_stage_file(state, L.core, "data.lua", "data")
  L:run_phase(state, "data", "data.lua")
  L:run_phase(state, "data-updates", "data-updates.lua")
  L:run_phase(state, "data-final-fixes", "data-final-fixes.lua")
  raw = state.env.data.raw
  L.raw = raw
  scan_functions(raw, L.functions)
end

-- summary ------------------------------------------------------------------------
do
  local types, protos = 0, 0
  for _, cat in pairs(raw) do
    types = types + 1
    for _ in pairs(cat) do protos = protos + 1 end
  end
  local distinct = #L.stub_order
  print(string.format("loaded %d prototypes in %d types from %d stage files; stubs fired %d times for %d missing files; log() called %d times; functions left in data.raw: %d",
    protos, types, #L.files_run, L.stub_fires, distinct, L.log_count, #L.functions))
  -- asset stubs summarised per mod and folder; anything else was already printed in full
  local groups, order = {}, {}
  for _, name in ipairs(L.stub_order) do
    local rec = L.stubs[name]
    if rec.asset then
      local shown = L:display(rec.path)
      local key = shown:match("^(__[^/]+__/[^/]+)/") or shown
      if not groups[key] then groups[key] = 0 order[#order + 1] = key end
      groups[key] = groups[key] + 1
    end
  end
  table.sort(order)
  for _, key in ipairs(order) do
    print(string.format("  stubbed %4d missing files under %s/ (sprite data, sounds or menu simulations the checkout omits)", groups[key], key))
  end
  for _, p in ipairs(L.functions) do warn("warning: function value at ", p) end
end

-- ---------------------------------------------------------------------------
-- --find-string
-- ---------------------------------------------------------------------------
local function walk(t, path, fn, seen)
  seen = seen or {}
  if seen[t] then return end
  seen[t] = true
  for k, v in pairs(t) do
    local kp = type(k) == "number" and ("[" .. k .. "]") or ("." .. tostring(k))
    fn(path .. kp, k, v)
    if type(v) == "table" then walk(v, path .. kp, fn, seen) end
  end
end

if #opts.find > 0 then
  for _, name in ipairs(opts.find) do
    local pat = "%f[%w_]" .. name:gsub("%W", "%%%0") .. "%f[^%w_]"
    local hits = 0
    local function show(path, what, s)
      hits = hits + 1
      if #s > 100 then
        local a = s:find(pat) or s:find(name, 1, true) or 1
        s = "..." .. s:sub(math.max(1, a - 40), a + #name + 40):gsub("\n", " ") .. "..."
      end
      print(string.format("%s %s = %q", path, what, s))
    end
    walk(raw, "", function(path, k, v)
      if type(v) == "string" and (v == name or v:find(pat)) then show(path:sub(2), "value", v) end
      if type(k) == "string" and k ~= name and k:find(pat) then show(path:sub(2), "key", k) end
      if type(k) == "string" and k == name then show(path:sub(2), "key", k) end
    end)
    print(string.format("find-string %q: %d hits", name, hits))
  end
end

-- ---------------------------------------------------------------------------
-- --dump
-- ---------------------------------------------------------------------------
if opts.dump then
  local out = assert(io.open(opts.dump, "wb"))
  local buf, n = {}, 0
  local function emit(s)
    n = n + 1
    buf[n] = s
    if n >= 4096 then out:write(table.concat(buf)) buf, n = {}, 0 end
  end
  local function esc(s)
    return '"' .. s:gsub('[%c"\\]', function(c)
      if c == '"' then return '\\"' elseif c == "\\" then return "\\\\"
      elseif c == "\n" then return "\\n" elseif c == "\r" then return "\\r" elseif c == "\t" then return "\\t"
      else return string.format("\\u%04x", c:byte()) end
    end) .. '"'
  end
  local function num(v)
    if v ~= v or v == math.huge or v == -math.huge then return "null" end
    if v == math.floor(v) and math.abs(v) < 2 ^ 53 then return string.format("%d", v) end
    local s = string.format("%.15g", v)
    if tonumber(s) ~= v then s = string.format("%.17g", v) end
    return s
  end
  local function is_array(t)
    local cnt = 0
    for _ in pairs(t) do cnt = cnt + 1 end
    return cnt == #t
  end
  local active = {}
  local function enc(v)
    local t = type(v)
    if t == "string" then emit(esc(v))
    elseif t == "number" then emit(num(v))
    elseif t == "boolean" then emit(tostring(v))
    elseif t ~= "table" then emit("null")
    elseif active[v] then emit("null")
    else
      active[v] = true
      if is_array(v) then
        emit("[")
        for i = 1, #v do
          if i > 1 then emit(",") end
          if type(v[i]) == "function" then emit("null") else enc(v[i]) end
        end
        emit("]")
      else
        local keys = {}
        for k, x in pairs(v) do if type(x) ~= "function" then keys[#keys + 1] = k end end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        emit("{")
        for i, k in ipairs(keys) do
          if i > 1 then emit(",") end
          emit(esc(tostring(k)))
          emit(":")
          enc(v[k])
        end
        emit("}")
      end
      active[v] = nil
    end
  end
  local subject = raw
  if opts.dump_types then
    subject = {}
    for t in opts.dump_types:gmatch("[^,%s]+") do
      if not raw[t] then warn("warning: --dump-types names '", t, "', which is not a data.raw category") end
      subject[t] = raw[t] or {}
    end
  end
  enc(subject)
  emit("\n")
  out:write(table.concat(buf))
  out:close()
  print("dumped data.raw to " .. opts.dump)
end

-- ---------------------------------------------------------------------------
-- --check
-- ---------------------------------------------------------------------------
if opts.check then
  local check = dofile(TOOLS_DIR .. "/check.lua")
  local ctx = {
    hierarchy = L.hierarchy,
    stubs = L.stubs,
    stub_order = L.stub_order,
    functions = L.functions,
    mod_name = L.user_mod and L.user_mod.name or nil,
  }
  local problems = check.run(raw, ctx)
  for _, p in ipairs(problems) do print(check.format(p)) end
  print(string.format("check: %d problems (%d checks run)", #problems, #check.checks))
  if #problems > 0 then os.exit(1) end
end
