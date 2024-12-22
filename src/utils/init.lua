--- SPDX-License-Identifier: 0BSD

--------------------------------------------------------------------------------

local getmetatable = getmetatable
local setmetatable = setmetatable
local string = string

local format = string.format

--------------------------------------------------------------------------------

---@class lgi-async-await.utils : lgi-async-await.Module
local _M = {
	__name    = "lgi-async-await.utils",
	__package = (... or "__main__"),
}

--------------------------------------------------------------------------------

---@generic T : lgi-async-await.Module
---@param name    string
---@param package string | nil
---@return T module
function _M.create_module(name, package)
	local module = {
		__name    = name,
		__package = (package or "__main__"),
	}

	-- ...

	return module
end

---@generic T : lgi-async-await.utils.ClassBody
---@param name           string -- Note that this gets automatically prefixed with `"lgi-async-await."` internally
---@param make_body_func (fun(body: lgi-async-await.utils.ClassBody): T)
---@return T class
function _M.create_class(name, make_body_func)
	---@class lgi-async-await.utils.ClassBody
	local body = {
		__name = ("lgi-async-await." .. name),
	}

	body.__class = body

	---@param cls lgi-async-await.utils.ClassBody
	function body.__new(cls, ...)
		return setmetatable({}, cls)
	end

	function body:__init(...) end

	---@generic K
	---@generic V
	---@param self { [K]: V }
	---@param key  K
	---@return V value
	function body:__index(key)
		return getmetatable(self)[key]
	end

	---@return string
	function body:__tostring()
		return format("<instance of class %s at %p>", self.__class.__name, self)
	end

	---@class lgi-async-await.utils.ClassMeta
	local meta = {}

	body.__meta = meta

	---@param cls lgi-async-await.utils.ClassBody
	function meta.__call(cls, ...)
		local self cls.new(cls, ...)
		cls.__init(self, ...)
		return self
	end

	---@generic K
	---@generic V
	---@param self { [K]: V } | lgi-async-await.utils.ClassBody
	---@param key  K
	---@return V value
	function meta.__index(cls, key)
		return getmetatable(cls)[key]
	end

	---@param cls lgi-async-await.utils.ClassBody
	---@return string
	function meta.__tostring(cls)
		return format("<class %s>", cls.__name)
	end

	setmetatable(class, meta)

	make_body_func(body)

	return class
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
