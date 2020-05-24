require "log_helper"
require "table_helper"
require "object"
require "singleton"

--region 自动require所有lua
-- require "require"
-- requireall()
require "c_base"
require "c_son"
require "c_solo"
--endregion

--region debug
package.cpath =
    package.cpath .. ";c:/Users/Administrator/.vscode/extensions/tangzx.emmylua-0.3.49/debugger/emmy/windows/x64/?.dll"
local dbg = require("emmy_core")
dbg.tcpListen("localhost", 1024)
--endregion

local function main()
    local son = CSon:New()
    local solo = CSolo:New()
    Log.fatal("### son super", son.super._className)
    Log.fatal("### son", son._className)
    Log.fatal("### solo", solo._className)
end

main()
