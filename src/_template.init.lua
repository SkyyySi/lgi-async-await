--- SPDX-License-Identifier: 0BSD

--------------------------------------------------------------------------------

--- Global variable caches go here

--- Imports / `require()`s go here

--------------------------------------------------------------------------------

---@class lgi-async-await._template : lgi-async-await.Module
local _M = {
	__name    = "lgi-async-await._template",
	__package = (... or "__main__"),
}

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

if _M.__package == "__main__" then
	os.exit(_M.main(arg or {}))
end

--------------------------------------------------------------------------------

return _M
