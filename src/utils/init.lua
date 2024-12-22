--- SPDX-License-Identifier: 0BSD

--------------------------------------------------------------------------------

local require      = require
local getmetatable = getmetatable
local setmetatable = setmetatable
local error        = error
local assert       = assert
local select       = select
local string       = string
local table        = table

local format = string.format

--------------------------------------------------------------------------------

---@class lgi-async-await.utils : lgi-async-await.utils.Module
local _M = {
	__name    = "lgi-async-await.utils",
	__package = (... or "__main__"),
}

--------------------------------------------------------------------------------

_M.module_namespace_prefix = "lgi-async-await"

---@param message_format string
---@param ...            any
---@return lgi-async-await.Error
function _M.error(message_format, ...)
	local level = 2

	return error(format("\x1b[1;41m Error \x1b[0m " .. message_format, ...), level)
end

---@generic T
---@param value T
---@param message_format string
---@param ...            any
---@return lgi-async-await.MaybeError<T>
function _M.assert(value, message_format, ...)
	if value then
		return value
	end

	return _M.error(message_format, ...)
end

--- A helper function to check whether the type of a given parameter is correct,
--- generating an error message if it is not.
---@generic T
---@param function_name   string
---@param expected_type   `T` | type
---@param parameter_name  string
---@param parameter_index integer
---@param parameter_value T | any
---@return boolean      parameter_type_is_valid
---@return nil | string error_message
function _M.check_parameter_type(function_name, expected_type, parameter_name, parameter_index, parameter_value)
	local parameter_type = type(parameter_value)

	if parameter_type == expected_type then
		return true, nil
	end

	return false, ("Wrong type of parameter #%d '%s' to function '%s()'! (expected %s but got %s)"):format(
		parameter_index,
		parameter_name,
		function_name,
		expected_type,
		parameter_type
	)
end

--- A helper function that converts a readable key name (like `"foo"`) into a
--- private key name (like `"__PRIVATE_MyClass::foo__"`).
--- 
--- The table `tb` **must** have a metatable with a `__name` string field.
---@generic K : string
---@generic V
---@param tb  table<K, V>
---@param key string
---@return K | nil      private_key
---@return nil | string error_message
local function private_key_helper(tb, key)
	---@type metatable | nil
	local mt = getmetatable(tb)

	if type(mt) ~= "table" then
		return nil, "The given table has no metatable!"
	end

	---@type string | nil
	local name = rawget(mt, "__name")

	if type(name) ~= "string" then
		return nil, "The given table has no '__name' metatable field!"
	end

	local private_key = ("__PRIVATE__%s::%s__"):format(name, key)

	return private_key, nil
end

--- Get the value of a private field `key` of a table `tb`.
--- 
--- The table `tb` **must** have a metatable with a `__name` string field.
---@generic K : string
---@generic V
---@param tb  table<K, V>
---@param key string
---@return V value
function _M.get_private(tb, key)
	assert(_M.check_parameter_type("get", "table",  "tb",  1, tb))
	assert(_M.check_parameter_type("get", "string", "key", 2, key))

	local private_key = assert(private_key_helper(tb, key))

	local value = tb[private_key]

	return value
end

--- Set a private field `key` of a table `tb` to `value`.
--- 
--- The table `tb` **must** have a metatable with a `__name` string field.
---@generic K : string
---@generic V
---@param tb    table<K, V>
---@param key   string
---@param value V
---@return nil
function _M.set_private(tb, key, value)
	assert(_M.check_parameter_type("set", "table",  "tb",  1, tb))
	assert(_M.check_parameter_type("set", "string", "key", 2, key))

	local private_key = assert(private_key_helper(tb, key))

	tb[private_key] = value

	return nil
end

_M.require_lazily = require
--- The reason for this weird type annotation is that it makes
--- lua-langauge-server believe that this function is an alias for `require`,
--- which is needed to make it correctly use the imported module as the return-
--- value.
--- 
--- This may be changed if [issue #3003](https://github.com/LuaLS/lua-language-server/issues/3003)
--- gets added / merged into LuaLS.
---@diagnostic disable-next-line: assign-type-mismatch
_M[("require_lazily" --[[@as string]])] = function(package_name) ---@param package_name string
	---@type table
	local cached_import

	local index_after_cache = function(_, key)
		return cached_import[key]
	end

	local module_proxy

	local index_before_cache = function(_, key)
		cached_import = require(package_name)

		setmetatable(module_proxy, { __index = index_after_cache })

		return cached_import[key]
	end

	module_proxy = setmetatable({}, { __index = index_before_cache })

	return module_proxy
end

---@generic T : lgi-async-await.utils.Class
---@param name            `T`
---@param func_make_class (fun(class: T): lgi-async-await.NoReturn)
---@return T | any class
function _M.create_class(name, func_make_class)
	_M.assert(_M.check_parameter_type(
		"utils.create_class",
		"string",
		"name",
		1,
		name
	))

	_M.assert(_M.check_parameter_type(
		"utils.create_class",
		"function",
		"func_make_class",
		2,
		func_make_class
	))

	---@class lgi-async-await.utils.Class : lgi-async-await.utils.ClassMeta
	local class = {
		__name = name,
	}

	class.__class = class

	---@param cls lgi-async-await.utils.Class
	---@param ... unknown
	---@return lgi-async-await.utils.Class self
	function class.__new(cls, ...)
		return setmetatable({}, cls)
	end

	---@param self lgi-async-await.utils.Class
	---@param ... unknown
	---@return nil
	function class:__init(...) end

	---@generic K
	---@generic V
	---@param self { [K]: V } | lgi-async-await.utils.Class
	---@param key  K
	---@return V value
	function class:__index(key)
		return getmetatable(self)[key]
	end

	---@return string
	function class:__tostring()
		return format("<instance of class %s at %p>", self.__class.__name, self)
	end

	---@class lgi-async-await.utils.ClassMeta
	local meta = {}

	class.__meta = meta

	---@param cls lgi-async-await.utils.Class
	function meta.__call(cls, ...)
		local self = cls.__new(cls, ...)

		cls.__init(self, ...)

		return self
	end

	---@generic K
	---@generic V
	---@param cls { [K]: V } | lgi-async-await.utils.Class
	---@param key K
	---@return V value
	function meta.__index(cls, key)
		return getmetatable(cls)[key]
	end

	---@param cls lgi-async-await.utils.Class
	---@return string
	function meta.__tostring(cls)
		return format("<class %s>", cls.__name)
	end

	setmetatable(class, meta)

	func_make_class(class)

	return class
end

---@generic T : lgi-async-await.utils.Module
---@param name    string -- Note that this gets automatically prefixed with `utils.module_namespace_prefix .. "."` internally.
---@param package string | nil
---@return T module
function _M.create_module(name, package)
	---@class lgi-async-await.utils.Module
	---@field private __is_finalized__ boolean
	---@field __name    string
	---@field __package string | "__main__"
	---@field main      nil | (fun(args: string[]): exit_status_code: (boolean | integer | nil))
	---@field new       nil | (fun(...: unknown): unknown)
	local module = {
		__is_finalized__ = false,
		__name    = ((name ~= "") and (_M.module_namespace_prefix .. "." .. name) or _M.module_namespace_prefix),
		__package = (package or "__main__"),
	}

	---@generic T : lgi-async-await.utils.Module
	---@param self T | lgi-async-await.utils.Module
	---@return T
	function module:finalize()
		_M.assert(not self.__is_finalized__, "Module %q is already finalized!", self.__name)

		if self.__package == "__main__" then
			os.exit(self.main(arg or {}))
		end

		self.__is_finalized__ = true

		return self
	end

	return module
end

_M.unpack = unpack or table.unpack

---@generic T
---@param ... T
---@return lgi-async-await.Array<T> packed_varargs
---@return integer packed_args_count
function _M.pack(...)
	---@type lgi-async-await.Array<unknown>
	local result = { ... }

	---@type integer
	local count = select("#", ...)
	result.n = count

	return result, count
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
