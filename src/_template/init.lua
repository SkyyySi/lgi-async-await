--- SPDX-License-Identifier: 0BSD

--------------------------------------------------------------------------------

--- Global variable caches go here
local require = require

--- Imports / `require()`s go here
local utils = require("utils")

--------------------------------------------------------------------------------

---@class lgi-async-await._template : lgi-async-await.utils.Module
local _M = utils.create_module("_template", ...)

--------------------------------------------------------------------------------

-- Functions, classes, etc. go here

--------------------------------------------------------------------------------

function _M.new()
	return -- ...
end

--------------------------------------------------------------------------------

function _M.main(args)
	-- ...

	return 0
end

--------------------------------------------------------------------------------

return _M:finalize()
