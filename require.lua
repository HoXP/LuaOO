--lua 版require和requireall实现，想脱离unity引擎跑lua代码做测试的话，打开下面这段代码，然后去拿带有lfs的luadll
--这是第一个被运行的lua文件，定义了require和requireall的运行规则
local str_find = string.find
local str_lower = string.lower

local originalPath  = lfs.currentdir()
local luaPath = originalPath .. "/../resources/lua"
print("luaPath = " .. luaPath)
print("path = " .. package.path)
package.path = luaPath .. "/?.lua"
print("path = " .. package.path)
local ignoreDir = {"unit_test", "lua_api"}--文件映射忽视的目录

require "framework/base/lib/table_helper"
require "framework/base/lib/log_helper"
require "framework/base/object"
require "framework/base/containers/algorithm"
require "framework/base/containers/sorted_array"
require "framework/base/containers/sorted_dictionary"
local filePaths = SortedDictionary:New()--保证requireall顺序一致
function SearchforStringInWhichFile (path)
	for file in lfs.dir(path) do
		if file ~= "." and file ~= ".." then
			local f = path..'/'..file
			local attr = lfs.attributes (f)
			assert (type(attr) == "table")
			if attr.mode == "directory" then
				SearchforStringInWhichFile(f)
			elseif attr.mode == "file" then
				local ignored = false
				for _, ignore in pairs(ignoreDir) do
					if str_find(f, ignore) then
                        ignored = true
						break
					end
				end
				if not ignored then
					local _, _, head = str_find(file, "(.*)%.lua$")
					if head then
						local _, _, p = str_find(f, "resources/lua/(.*)%.lua$")
						Log.debug("adding " .. p .. " as " .. head)
						filePaths:Insert(str_lower(head), p)
					end
				end
			end
		end
	end
end
SearchforStringInWhichFile(luaPath)

local oldRequire = require

function require(name)
	local path = filePaths:Find(name)
	if not path then
		return oldRequire(name)
	else
		return oldRequire(path)
	end
end

local excludeFiles = {"require", "start", "launch"}
function requireall(excludeDirs)
	for i = 1, filePaths:Size() do
		local file, path = filePaths:GetPairAt(i)
		local bfind = false

		if excludeDirs then
			for _, exclude in pairs(excludeDirs) do
				if str_find(path, exclude) then
					bfind = true
					break
				end
			end
		end

		if not bfind then
			local b = false;
			for _, v in pairs(excludeFiles) do
				if str_find(file, v) then
					b = true;
					break;
				end
			end
			if not b then
				Log.debug("requireall ", path)
				local ok, err = pcall(oldRequire, path)
				if not ok then
					Log.fatal(err)
				end
			end
		end
	end
end

local oldDofile = dofile
function dofile(name)
	local path = filePaths:Find(name)
	if not path then
		return oldDofile(name)
	else
		local fullPath = luaPath.."/"..path..".lua"
		--Log.debug("fullPath",fullPath)
		return oldDofile(fullPath)
	end
end