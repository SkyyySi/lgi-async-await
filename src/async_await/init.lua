--- SPDX-License-Identifier: 0BSD

--------------------------------------------------------------------------------

local lgi = require("lgi")

local GLib = lgi.GLib

--- See <https://docs.gtk.org/glib/func.idle_add_full.html> for more details
---@type fun(priority: integer, callback: function, notify: unknown)
local g_idle_add = GLib.idle_add

local utils   = require("utils")
local promise = require("promise")

local Promise = promise.Promise

local coroutine = coroutine
local debug     = debug

local co_create  = coroutine.create
local co_yield   = coroutine.yield
local co_resume  = coroutine.resume
local co_status  = coroutine.status
local co_running = coroutine.running

local debug_traceback = debug.traceback

--------------------------------------------------------------------------------

---@class lgi-async-await.async_await : lgi-async-await.utils.Module
local _M = utils.create_module("async_await", ...)

--------------------------------------------------------------------------------

local function add_callback_to_queue(callback)
	---@type integer
	local event_source_id = g_idle_add(0, callback, nil)
end

---@generic T_Params
---@generic T_Return
---@param func (fun(...: T_Params): T_Return)
---@return (fun(...: T_Params): lgi-async-await.promise.Promise) -- lgi-async-await.promise.Promise<T_Return>
function _M.async(func)
	return function(...)
		local argv, argc = utils.pack(...)

		local thread = coroutine.create(function(fulfill, reject)
			xpcall(function()
				local result = func(utils.unpack(argv, 1, argc))
				fulfill(result)
			end, function(reason)
				reject(debug_traceback(reason))
			end)
		end)

		return Promise(function(fulfill, reject)
			co_resume(thread, fulfill, reject)
		end)
	end
end

---@generic T
---@param promise lgi-async-await.promise.Promise -- lgi-async-await.promise.Promise<T_Return>
---@return T
---@async
function _M.await(promise)
	local current_coroutine, is_main = co_running()

	if is_main then
		do return utils.error("Global 'await()' is current not implemented!") end

		local has_resolved = false

		promise:on_fulfilled(function(result)
			has_resolved = true
		end):on_rejecteded(function(result)
			has_resolved = true
		end)
	end

	promise:on_fulfilled(function(result)
		add_callback_to_queue(function()
			co_resume(current_coroutine, result)
		end)
	end):on_rejecteded(function(reason)
		local message = (
			"Error in 'await()'-call: " ..
			tostring(reason) ..
			"\n" ..
			debug_traceback(current_coroutine)
		)

		print(message)

		return error(message)
	end)

	return co_yield()
end

--------------------------------------------------------------------------------

function _M.main(args)
	-- ...

	return 0
end

--------------------------------------------------------------------------------

return _M:finalize()
