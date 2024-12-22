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
---| (fun(fulfill: fun(result?: T), reject: fun(reason?: string) ))

_M.Promise = utils.create_class("lgi-async-await.promise.Promise", function(class)
	---@generic T
	---@class lgi-async-await.promise.Promise : lgi-async-await.utils.Class
	---@field private status "pending" | "fulfilled" | "rejected"
	---@field private result_or_reason unknown | string -- <T>
	---@field private on_fulfilled_callback (fun(result?: unknown): any) -- <T>
	---@field private on_rejected_callback  (fun(reason?: string):  any)
	---@field __name  "lgi-async-await.promise.Promise"
	---@field __class lgi-async-await.promise.Promise
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
	---@return lgi-async-await.promise.Promise -- <nil>
	function class.new_rejected(cls, reason)
		return cls():reject(reason)
	end

	---@generic T
	---@param self lgi-async-await.promise.Promise -- <T>
	---@param value T
	---@return lgi-async-await.promise.Promise self -- <T>
	function class:fulfill(value)
		utils.assert(self.status == "pending",  "Cannot fulfill a promise that has already been %s!", self.status)

		self.status           = "fulfilled"
		self.result_or_reason = value

		if self.on_fulfilled_callback ~= nil then
			xpcall(function()
				self.on_fulfilled_callback(value)
			end, function(err)
				self:reject(err)
			end)
		end

		return self
	end

	---@generic T
	---@param self lgi-async-await.promise.Promise -- <T>
	---@param reason string
	---@return lgi-async-await.promise.Promise self -- <T>
	function class:reject(reason)
		print(("Rejected promise at %p: %q"):format(self, reason))

		self.status           = "rejected"
		self.result_or_reason = reason

		if self.on_rejected_callback ~= nil then
			xpcall(function()
				self.on_rejected_callback(reason)
			end, function(err)
				print(debug.traceback("Unhanlded error: " .. tostring(err)))
			end)
		end

		return self
	end

	--[=[
	---@generic T
	---@param self lgi-async-await.promise.Promise -- <T>
	---@return lgi-async-await.promise.Promise copy_of_self -- <T>
	function class:create_copy()
		local copy = self.__class()

		--[[
		for k, v in pairs(self) do
			copy[k] = v
		end
		--]]

		copy.status           = self.status
		copy.result_or_reason = self.result_or_reason

		return copy
	end
	--]=]

	local return_args_func = function(...)
		return ...
	end

	---@generic T
	---@generic U
	---@param promise   lgi-async-await.promise.Promise -- <T>
	---@param fulfiller (fun(result?: T): U?)?
	---@return (fun(result?: T): U?)
	local function try_fulfill(promise, fulfiller)
		fulfiller = fulfiller or return_args_func

		return function(result)
			return select(2, xpcall(function()
				local wrapped_result = fulfiller(result)

				promise:fulfill(wrapped_result)

				return wrapped_result
			end, function(err)
				--print(debug.traceback("Caught an error while fulfilling: " .. tostring(err)))

				promise:reject(err)

				return nil
			end))
		end
	end

	---@generic T
	---@generic U
	---@param promise  lgi-async-await.promise.Promise -- <T>
	---@param rejector (fun(reason?: string): U?)?
	---@return (fun(reason?: string): U?)
	local function try_reject(promise, rejector)
		rejector = rejector or return_args_func

		return function(reason)
			return select(2, xpcall(function()
				local wrapped_reason = rejector(reason)

				promise:reject(wrapped_reason)

				return wrapped_reason
			end, function(err)
				print(debug.traceback("Caught an error while rejecting: " .. tostring(err)))

				promise:reject(err)

				return err
			end))
		end
	end

	---@generic T
	---@generic U
	---@param self lgi-async-await.promise.Promise -- <T>
	---@param callback (fun(result?: T): U?)
	---@return lgi-async-await.promise.Promise new_promise -- <T>
	function class:on_fulfilled(callback)
		local new_promise = self.__class()

		self.on_fulfilled_callback = try_fulfill(new_promise, callback)
		self.on_rejected_callback  = try_reject(new_promise)

		if self.status == "fulfilled" then
			self.on_fulfilled_callback(self.result_or_reason)
		end

		return new_promise
	end

	---@generic T
	---@generic U
	---@param self lgi-async-await.promise.Promise -- <T>
	---@param callback (fun(reason?: string): U?)
	---@return lgi-async-await.promise.Promise new_promise -- <T>
	function class:on_rejected(callback)
		local new_promise = self.__class()

		self.on_fulfilled_callback = try_fulfill(new_promise)
		self.on_rejected_callback  = try_reject(new_promise, callback)

		if self.status == "rejected" then
			self.on_rejected_callback(self.result_or_reason)
		end

		return new_promise
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
			end):on_rejected(function(reason)
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
	local Promise = _M.Promise

	print(("Promise = %s"):format(Promise))
	print(("Promise() = %s"):format(Promise()))

	--[===[
	local GLib = require("lgi").GLib
	local main_loop = GLib.MainLoop()

	GLib.timeout_add(0, 1000, function()
		print("Terminating GLib main loop.")
		main_loop:quit()
	end)

	main_loop:run()
	--]===]

	return 0
end

--------------------------------------------------------------------------------

return _M:finalize()
