--local file = io.open("logtext.txt","a")--the lua print is closed
local oldPrint = print
local print0 = function(str, ...)
    oldPrint(str, ...)
    --file:write(tostring(str).."\n")
    --file:flush()
end

---@class ELogLevel
local ELogLevel = {
    LOG_REPORT = -100,
    NOLOG = 0,
    ASSERT = 250,
    TIMEPRO = 296,
    PROFILE = 300,
    EXCEPTION = 340,
    CRITICAL = 350,
    KEYLOG = 390,
    ERROR = 400,
    WARNING = 500,
    INFO = 700,
    DEBUG = 800
}

--local _iowrite = _iowrite
local nowtime = {}
local dumpvisited
local dumpfrom = ""

local function indented(level, ...)
    -- if PUBLIC then return end
    --print0(table.concat({ ('  '):rep(level), ...}))
    local s = table.concat({("  "):rep(level), ...})
    table.insert(tsss, s)
end
local function dumpval(level, name, value, limit)
    local index
    if type(name) == "number" then
        index = string.format("[%d] = ", name)
    elseif
        type(name) == "string" and
            (name == "__VARSLEVEL__" or name == "__ENVIRONMENT__" or name == "__GLOBALS__" or name == "__UPVALUES__" or
                name == "__LOCALS__")
     then
        --ignore these, they are debugger generated
        return
    elseif type(name) == "string" and string.find(name, "^[_%a][_.%w]*$") then
        index = name .. " = "
    else
        index = string.format("[%q] = ", tostring(name))
    end
    if type(value) == "table" then
        if dumpvisited[value] then
            indented(level, index, string.format("ref%q,", dumpvisited[value]))
        else
            dumpvisited[value] = tostring(value)
            if (limit or 0) > 0 and level + 1 >= limit then
                indented(level, index, dumpvisited[value])
            else
                indented(level, index, "{  -- ", dumpvisited[value])
                for n, v in pairs(value) do
                    dumpval(level + 1, n, v, limit)
                end
                dumpval(level + 1, ".meta", getmetatable(value), limit)
                indented(level, "},")
            end
        end
    else
        if type(value) == "string" then
            if string.len(value) > 40 then
                indented(level, index, "[[", value, "]];")
            else
                indented(level, index, string.format("%q", value), ",")
            end
        else
            indented(level, index, tostring(value), ",")
        end
    end
end

local function dumpvar(value, limit, name)
    dumpvisited = {}
    dumpval(0, name or tostring(value), value, limit)
    dumpvisited = nil
end

debug.dumpdepth = 5
function dump(v, depth)
    -- if PUBLIC then return end
    local info = debug.getinfo(2)
    dumpfrom = info.source .. "|" .. info.currentline --info.currentline
    _G.tsss = {}
    dumpvar(v, (depth or debug.dumpdepth) + 1, tostring(v))
    local s = debug.getinfo(2)
    local _, _, src = string.find(s.short_src, "([%w%_]+%.lua)")
    s = table.concat {"dump ", src, ":", s.currentline}
    s = s .. table.concat(tsss, "\n")
    print0(s)
end

local doprint = function(head, t)
    local s = {head, " "}
    s[#s + 1] = os.date("%Y-%m-%d %H:%M:%S", os.time()) .. "  "
    local len = table.maxn(t)
    for i = 1, len do
        local v = t[i]
        table.insert(s, tostring(v))
        table.insert(s, " ")
    end
    if len >= 1 then
        table.remove(s)
    end
    print0(table.concat(s))
end

local check_log = function(loglevel)
    local configlevel = Log.loglevel
    if (configlevel >= loglevel) then
        return true
    else
        return false
    end
end
Log = {}
Log.loglevel = ELogLevel.DEBUG
Log.loglevel_table = ELogLevel
Log.sys = function(...)
    if (check_log(ELogLevel.KEYLOG) == false) then
        return
    end
    local s = debug.getinfo(2)
    doprint(table.concat {"sys ", s.short_src, ":", s.currentline}, {...}, true, true)
end

Log.debug = function(...)
    if (check_log(ELogLevel.DEBUG) == false) then
        return
    end
    local s = debug.getinfo(2)
    --if os.info.system ~= 'windows' then return end
    doprint(table.concat {"debug ", s.short_src, ":", s.currentline}, {...}, true, true)
end
Log.notice = function(...)
    if (check_log(ELogLevel.DEBUG) == false) then
        return
    end
    local s = debug.getinfo(2)
    --if os.info.system ~= 'windows' then return end
    doprint(table.concat {"notice ", s.short_src, ":", s.currentline}, {...}, true, true)
end
Log.warn = function(...)
    if (check_log(ELogLevel.WARNING) == false) then
        return
    end
    local s = debug.getinfo(2)
    doprint(table.concat {"warn ", s.short_src, ":", s.currentline}, {...}, true, true)
end
Log.error = function(...)
    if (check_log(ELogLevel.ERROR) == false) then
        return
    end
    local s = debug.getinfo(2)
    doprint(table.concat {"error ", s.short_src, ":", s.currentline}, {...}, true, true)
end
Log.fatal = function(...)
    if (check_log(ELogLevel.CRITICAL) == false) then
        return
    end
    local s = debug.getinfo(2)
    doprint(table.concat {"fatal ", s.short_src, ":", s.currentline}, {...}, true, true)
end
Log.exception = function(...)
    if (check_log(ELogLevel.EXCEPTION) == false) then
        return
    end
    local s = debug.getinfo(2)
    doprint(table.concat {"exception ", s.short_src, ":", s.currentline}, {...}, true, true)
    G_ShowException(table.concat {...})
end
Log.tick = function(...)
    if (check_log(ELogLevel.TIMEPRO) == false) then
        return
    end
    if os.info.system == "windows" then
        return
    end
    local s = debug.getinfo(2)
    doprint(table.concat {"tick ", s.short_src, ":", s.currentline}, {...}, true, true)
end

local programmers = {"ylw", "yqq", "zn", "cj"}

for i, v in pairs(programmers) do
    _G["_" .. v] = function(...)
        if (check_log(ELogLevel.DEBUG) == false) then
            return
        end
        local s = debug.getinfo(2)
        doprint(table.concat {"debug ", s.short_src, ":", s.currentline}, {...}, true, true)
    end
end

---禁掉print
print = function()
    error("print is forbidden")
end
