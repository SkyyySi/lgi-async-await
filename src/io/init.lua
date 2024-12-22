--- SPDX-License-Identifier: 0BSD

--------------------------------------------------------------------------------

local require = require
local math    = math

local floor = math.floor

local lgi  = require("lgi")
local GLib = lgi.GLib

--- See <https://docs.gtk.org/glib/const.PRIORITY_DEFAULT.html> for more details
---@type integer
local G_PRIORITY_DEFAULT = GLib.PRIORITY_DEFAULT

--- See <https://docs.gtk.org/glib/func.timeout_add_full.html> for more details
---@type fun(priority: integer, timeout_milliseconds: integer, callback: function)
local g_timeout_add = GLib.timeout_add

local utils   = require("utils")
local Promise = require("promise").Promise

--------------------------------------------------------------------------------

---@class lgi-async-await.io : lgi-async-await.utils.Module
local _M = utils.create_module("io", ...)

--------------------------------------------------------------------------------

---@param timeout_seconds number
---@return lgi-async-await.promise.Promise -- <nil>
function _M.sleep(timeout_seconds)
	utils.assert(utils.check_parameter_type(
		"io.sleep",
		"number",
		"timeout_seconds",
		1,
		timeout_seconds
	))

	---@type integer
	local timeout_milliseconds = floor(timeout_seconds * 1000.0)

	return Promise(function(fulfill, reject)
		g_timeout_add(
			G_PRIORITY_DEFAULT,
			timeout_milliseconds,
			function()
				fulfill(timeout_milliseconds)
			end
		)
	end)
end

--------------------------------------------------------------------------------

function _M.main(args)
	local main_loop = GLib.MainLoop()

	---@type integer
	local call_order_tracker = 0
	local function track_call_order(message)
		call_order_tracker = call_order_tracker + 1

		print((">>> #%d: %s"):format(call_order_tracker, message))
	end

	_M.sleep(0.5):on_fulfilled(function(result)
		track_call_order("Initial fulfiller")
		print("Successfully slept for 0.5 seconds")
		return result
	end):on_rejected(function(reason)
		track_call_order("Rejector")
		print(">>> Rejection handler called!")

		print(("reason = %q"):format(reason))
	end):on_fulfilled(function(result)
		track_call_order("Second fulfiller")
		print(("result: %s = %s"):format(type(result), result))

		error("Something happened")

		return "Test"
	end):on_fulfilled(function(result)
		track_call_order("Third fulfiller")
		print(("result: %s = %q"):format(type(result), result))
	end)

	GLib.timeout_add(0, 2000, function()
		print("Terminating GLib main loop.")
		main_loop:quit()
	end)

	main_loop:run()

	return 0
end

--------------------------------------------------------------------------------

return _M:finalize()
