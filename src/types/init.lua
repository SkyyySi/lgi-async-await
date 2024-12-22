--- SPDX-License-Identifier: 0BSD

--------------------------------------------------------------------------------

--- When used as a return type: Indicates that a marked function will not
--- return any value. Like `void` in many C-like programming languages.
---@alias lgi-async-await.NoReturn nil

--- When used as a return type: Indicates that a marked function will not
--- return any value, instead throwing an error.
---@class lgi-async-await.Error : nil

--- When used as a return type: Indicates that a marked function may return a
--- value of type `T` or throw an error.
---@alias lgi-async-await.MaybeError<T> T

--- An array table with an explicit length. To iterate over it, do not use
--- the `pairs()` or `ipairs()` functions. Instead, do something like this:
--- 
--- ```lua
--- ---@type lgi-async-await.Array<string>
--- local my_array = { "foo", "bar", "biz", "baz", n = 4 }
--- 
--- for i = 1, my_array.n do
--- 	print(("my_array[%d] = %q"):format(i, my_array[i]))
--- end
--- ```
---@alias lgi-async-await.Array<T>
---| { [integer]: T, n: integer }
