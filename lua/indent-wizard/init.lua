#!/usr/bin/env -S nvim -l

require("indent-wizard.guesswork")
require("indent-wizard.utils")

local default_line_count = 25

---@class ScanSettings
---@field line_count uinteger?
---@field offset (number|string)?

---@class Settings
---@field tabstop uinteger?
---@field softtabstop uinteger?
---@field shiftwidth uinteger?
---@field expandtab boolean?
---@field smartindent boolean?
---@field spaces uinteger? Shorthand for setting `shiftwidth`, `tabstop`, and `softtabstop` at the same time as fallback

---@module "indent-wizard"
local M = {
  ---@type table<string, Settings>
  ft_defaults = {},
  ---@type ScanSettings|nil
  scan_settings = nil,
}

--- Setup function
---
---@param opts {
---  auto_guess:boolean?,
---  defaults:{
---    ft:(string|string[])?,
---    options:Settings,
---  }[]?,
---  scan:ScanSettings?,
---}? Configuration opts
function M.setup(opts)
  local function indent_info()
    local result = M.indent_info(opts and opts.scan)
    vim.print(
      string.format(
        "spaces=%s, %stab, mixed?=%s",
        result.spaces == nil and "?" or tostring(result.spaces),
        result.expandtab == nil and "unknown" or result.expandtab and "expand" or "noexpand",
        tostring(result.mixed)
      )
    )
    return result
  end

  vim.api.nvim_create_user_command(
    "IndentInfo",
    indent_info,
    {
      desc = "indent-wizard.nvim: Get indentation info of current buffer",
    }
  )

  vim.api.nvim_create_user_command(
    "GuessIndent",
    function ()
      M.apply_guess {
        scan = M.scan_settings,
        fallback = M.default_indent(),
      }
    end,
    {
      desc = "indent-wizard.nvim: Guess indentation for current buffer",
    }
  )

  if not opts then
    return
  end

  -- Save the settings for later use
  M.scan_settings = opts.scan

  if opts.defaults then
    for _, item in ipairs(opts.defaults) do
      if not item.ft then
        -- Apply global settings immediately
        if item.options then
          M.set_indent {
            global = true,
            options = item.options,
          }
        end
      else
        -- Save local settings
        local fts = (type(item.ft) == "table" and item.ft or { item.ft }) --[=[@as (string|nil)[]]=]

        for _, ft in ipairs(fts) do
          if type(ft) == "string" then
            M.ft_defaults[ft] = item.options
          end
        end
      end
    end
  end

  local function ft_set_indent()
    local defaults = M.default_indent()
    if defaults then
      M.set_indent {
        global = false,
        options = defaults,
      }
    end
  end

  local group = vim.api.nvim_create_augroup("indent-wizard", { clear = true })
  if opts.auto_guess == nil or opts.auto_guess then
    vim.api.nvim_create_autocmd("BufReadPost", {
      group = group,
      desc = "indent-wizard.nvim: Auto guess indentation while entering a new buffer",
      callback = function ()
        M.apply_guess {
          scan = opts.scan,
          fallback = M.default_indent(),
        }
      end,
    })
  else
    vim.api.nvim_create_autocmd("BufReadPost", {
      group = group,
      desc = "indent-wizard.nvim: Set indentation for buffers by filetypes",
      callback = ft_set_indent,
    })
  end

  vim.api.nvim_create_autocmd("BufNewFile", {
    group = group,
    desc = "indent-wizard.nvim: Set indentation for new file buffers",
    callback = ft_set_indent,
  })
end

--- Get default indentation
---
---@param ft string|nil File type (use file type from current buffer if empty)
---@return Settings|nil 
function M.default_indent(ft)
  return M.ft_defaults[ft or vim.bo.filetype]
end

--- Check indentation in current buffer
---
---@param opts ScanSettings|nil Indentation opts
---@return IndentResult 
function M.indent_info(opts)
  opts = opts or {}

  local line_count = type(opts.line_count) == "number" and math.max(math.floor(opts.line_count), 1) or default_line_count
  local offset = 0
  if type(opts.offset) == "number" then
    if opts.offset < 1 then
      offset = opts.offset --[[@as number]]
    else
      offset = math.floor(
        opts.offset  --[[@as number]]
      )
    end
  elseif type(opts.offset) == "string" and string.match(opts.offset, "^%d+%%$") then
    offset = tonumber(string.gsub(opts.offset, "%%", ""))
  end

  return GuessIndent(line_count, offset)
end

--- Set indentation for current buffer
---
---@param opts {global:boolean|nil, options:Settings}
function M.set_indent(opts)
  local vim_opt = opts.global and vim.opt or vim.bo

  local expandtab = opts.options.expandtab
  local smartindent = opts.options.smartindent
  local tabstop = opts.options.tabstop or opts.options.spaces
  local softtabstop = opts.options.softtabstop or opts.options.spaces
  local shiftwidth = opts.options.shiftwidth or opts.options.spaces

  if expandtab ~= nil then
    vim_opt.expandtab = expandtab
  end

  if smartindent ~= nil then
    vim_opt.smartindent = smartindent
  end

  if tabstop ~= nil then
    vim_opt.tabstop = tabstop
  end

  if softtabstop ~= nil then
    vim_opt.softtabstop = softtabstop
  end

  if shiftwidth ~= nil then
    vim_opt.shiftwidth = shiftwidth
  end
end

--- Guess and apply the result
---
---@param opts {scan:ScanSettings|nil, fallback:Settings|nil}
function M.apply_guess(opts)
  local fallback = opts and opts.fallback or nil
  local result = M.indent_info(opts.scan)

  local gen_settings = {
    spaces = result.spaces,
    smartindent = true,
    expandtab = result.expandtab,
  }

  M.set_indent {
    global = false,
    options = fallback and MergeSettings(gen_settings, fallback) or gen_settings,
  }
end

return M
