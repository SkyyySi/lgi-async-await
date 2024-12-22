--- SPDX-License-Identifier: 0BSD

--------------------------------------------------------------------------------

---@class lgi-async-await.Module
---@field __name    string
---@field __package string | "__main__"
---@field main      nil | (fun(args: string[]): exit_status_code: boolean | integer | nil)
---@field new       nil | (fun(...: unknown): unknown)
