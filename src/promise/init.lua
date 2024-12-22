--- SPDX-License-Identifier: 0BSD

--------------------------------------------------------------------------------

local setmetatable = setmetatable

--------------------------------------------------------------------------------

---@class lgi-async-await.promise : lgi-async-await.Module
local _M = {
	__name    = "lgi-async-await.promise",
	__package = (... or "__main__"),
}

--------------------------------------------------------------------------------

---@class lgi-async-await.promise.Promise
_M.Promise = {}

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
