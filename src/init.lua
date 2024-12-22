--- SPDX-License-Identifier: 0BSD

--------------------------------------------------------------------------------

local require = require

local utils = require("utils")

--------------------------------------------------------------------------------

---@class lgi-async-await : lgi-async-await.utils.Module
local _M = utils.create_module("", ...)

--------------------------------------------------------------------------------

_M.async_await = require("async_await")
_M.io          = require("io")
_M.promise     = require("promise")
_M.utils       = utils

--------------------------------------------------------------------------------

function _M.main(args)
	-- ...

	return 0
end

--------------------------------------------------------------------------------

return _M
