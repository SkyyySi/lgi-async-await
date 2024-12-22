--- SPDX-License-Identifier: 0BSD

--------------------------------------------------------------------------------

local require = require

local utils = require("utils")

--------------------------------------------------------------------------------

---@class lgi-async-await.promise : lgi-async-await.utils.Module
local _M = utils.create_module("promise", ...)

--------------------------------------------------------------------------------

---@generic T
---@alias lgi-async-await.promise.ResolverFunction<T>
---| (fun(fulfill: fun(result: T), reject: fun(reason: string) ))

_M.Promise = utils.create_class("lgi-async-await.promise.Promise", function(class)
	---@generic T
	---@class lgi-async-await.promise.Promise : lgi-async-await.utils.Class
	---@field private status "pending" | "fulfilled" | "rejected"
	---@field private result_or_reason unknown | string -- <T>
	---@field private on_fulfilled_callback  (fun(result: unknown): lgi-async-await.promise.Promise) -- <T>
	---@field private on_rejecteded_callback (fun(reason: string):  lgi-async-await.promise.Promise) -- <T>
	---@overload fun(): lgi-async-await.promise.Promise -- <T>
	---@overload fun(resolver_function: lgi-async-await.promise.ResolverFunction<unknown>): lgi-async-await.promise.Promise -- <T>
	class = class

	---@generic T
	---@param self lgi-async-await.promise.Promise -- <T>
	---@param resolver_function lgi-async-await.promise.ResolverFunction<T>?
	function class:__init(resolver_function)
		self.status = "pending"

		if resolver_function == nil then
			return
		end

		utils.assert(utils.check_parameter_type(
			"Promise:__init",
			"function",
			"resolver_function",
			1,
			resolver_function
		))

		resolver_function(function(result)
			self:fulfill(result)
		end, function(reason)
			self:reject(reason)
		end)
	end

	---@generic T
	---@param cls lgi-async-await.promise.Promise
	---@param value T
	---@return lgi-async-await.promise.Promise -- <T>
	function class.new_fulfilled(cls, value)
		return cls():fulfill(value)
	end

	---@param cls lgi-async-await.promise.Promise
	---@param reason string
	---@return lgi-async-await.promise.Promise -- <T>
	function class.new_rejected(cls, reason)
		return cls():reject(reason)
	end

	---@generic T
	---@param self lgi-async-await.promise.Promise -- <T>
	---@param value T
	---@return lgi-async-await.promise.Promise self -- <T>
	function class:fulfill(value)
		utils.assert(self.status == "pending",  "Cannot fulfill a promise that has already been %s!", self.status)

		self.status = "fulfilled"
		self.result_or_reason = value

		return self
	end

	---@param self lgi-async-await.promise.Promise -- <T>
	---@param reason string
	---@return lgi-async-await.promise.Promise self -- <T>
	function class:reject(reason)
		utils.assert(self.status ~= "rejected", "Cannot reject a promise that has already been rejected!")

		self.status = "rejected"
		self.result_or_reason = reason

		return self
	end

	---@generic T
	---@param self lgi-async-await.promise.Promise -- <T>
	---@param callback fun(result: T)
	---@return lgi-async-await.promise.Promise self -- <T>
	function class:on_fulfilled(callback)
		self.on_fulfilled_callback = callback

		return self
	end

	---@generic T
	---@param self lgi-async-await.promise.Promise -- <T>
	---@param callback fun(reason: string)
	---@return lgi-async-await.promise.Promise self -- <T>
	function class:on_rejecteded(callback)
		self.on_rejecteded_callback = callback

		return self
	end
end)

---@generic T
---@param promises lgi-async-await.promise.Promise[] -- lgi-async-await.promise.Promise<T>[]
---@return lgi-async-await.promise.Promise -- lgi-async-await.promise.Promise
function _M.all(promises)
	return _M.Promise(function(fulfill, reject)
		local promises_count = #promises
		local fulfillment_counter = 0
		local results = {}
		local has_failed = false

		for i = 1, promises_count do
			promises[i]:on_fulfilled(function(result)
				if has_failed then
					return
				end

				fulfillment_counter = fulfillment_counter + 1

				if fulfillment_counter == promises_count then
					fulfill(results)
					return
				end

				results[i] = result
			end):on_rejecteded(function(reason)
				if has_failed then
					return
				end

				has_failed = true
				reject(reason)
			end)
		end
	end)
end

--------------------------------------------------------------------------------

function _M.new(...)
	return _M.Promise(...)
end

--------------------------------------------------------------------------------

function _M.main(args)
	-- ...

	return 0
end

--------------------------------------------------------------------------------

return _M:finalize()
