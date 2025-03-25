#!/usr/bin/env luajit

--- @alias Settings {tabstop:uinteger|nil, softtabstop:uinteger|nil, shiftwidth:uinteger|nil, expandtab: boolean|nil, smartindent: boolean|nil}

--- @module "indent-wizard"
local M = {
  ---@type table<string, Settings>
  ft_defaults = {},
}

--- Setup function
---
---@param opts {auto_guess:boolean|nil, defaults:{ft:string|string[]|nil, options:Settings}[], scan:{line_count:uinteger|nil, offset:uinteger|nil}}|nil: Configuration opts
function M.setup(opts)
  local function indent_info()
    local result = M.indent_info(opts and opts.scan)
    vim.print(
      string.format(
        "Apparently: shiftwidth=%s, expandtab=%s",
        result.shiftwidth == nil and "?" or tostring(result.shiftwidth),
        result.expandtab == nil and "?" or result.expandtab and "yes" or "no"
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
        M.set_indent {
          global = false,
          options = indent_info(),
        }
    end,
    {
      desc = "indent-wizard.nvim: Guess indentation for current buffer",
    }
  )

  if not opts then
    return
  end

  if opts.defaults then
    for _, item in ipairs(opts.defaults) do
      if not item.ft then
        if item.options then
          M.set_indent {
            global = true,
            options = item.options,
          }
        end

      else
        --[=[@as (string|nil)[]]=]
        local fts = type(item.ft) == "table" and item.ft or { item.ft }

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
        M.guess_indent {
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
--- @param ft string|nil File type (use file type from current buffer if empty)
--- @return Settings|nil 
function M.default_indent(ft)
  return M.ft_defaults[ft or vim.bo.filetype]
end

--- @alias ScanSettings {line_count:uinteger|nil, offset:number|string|nil}

--- Check indentation in current buffer
---
--- @param opts ScanSettings|nil Indentation opts
--- @return {shiftwidth:uinteger|nil, expandtab:boolean|nil} 
function M.indent_info(opts)
  opts = opts or {}

  local line_count = type(opts.line_count) == "number" and math.max(math.floor(opts.line_count), 1) or 25
  --- @type number
  local offset = 0
  if type(opts.offset) == "number" then
    if opts.offset < 1 then
      --[[@as number]]
      offset = opts.offset
    else
      --[[@as number]]
      offset = math.floor(opts.offset)
    end
  elseif type(opts.offset) == "string" and string.match(opts.offset, "^%d+%%$") then
    offset = tonumber(string.gsub(opts.offset, "%%", ""))
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local length = vim.fn.len(lines)

  local min_shiftwidth = nil
  local expand_tab_vote = 0

  local abs_offset = offset < 1 and math.floor(length * offset) or offset

  local scan_from = 1 + abs_offset
  local scan_to = line_count + 1 + abs_offset

  local i = scan_from
  local abs_i = scan_from

  while i <= scan_to and abs_i <= length do
    local line = lines[i]
    local str_len = vim.fn.len(line)

    if str_len > 0 and line:sub(1, 1) == "\t" then
      expand_tab_vote = expand_tab_vote - 1
    else
      local space_len = vim.fn.len(tostring(line:match("^%s+")))
      if space_len > 0 then
        if space_len % 2 == 0 then
          if min_shiftwidth == nil or min_shiftwidth > space_len then
            min_shiftwidth = space_len
          end
        end
        expand_tab_vote = expand_tab_vote + 1

        i = i + 1
      end
    end
    abs_i = abs_i + 1
  end

  local expandtab = nil
  if expand_tab_vote ~= 0 then
    expandtab = expand_tab_vote > 0
  end

  return {
    expandtab = expandtab,
    shiftwidth = min_shiftwidth,
  }
end

--- Set indentation for current buffer
---
--- @param opts {global:boolean|nil, options:Settings}
function M.set_indent(opts)
  local vim_opt = opts.global and vim.opt or vim.bo

  if opts.options.tabstop ~= nil then
    vim_opt.tabstop = opts.options.tabstop
  end
  if opts.options.softtabstop ~= nil then
    vim_opt.softtabstop = opts.options.softtabstop
  end
  if opts.options.shiftwidth ~= nil then
    vim_opt.shiftwidth = opts.options.shiftwidth
  end
  if opts.options.expandtab ~= nil then
    vim_opt.expandtab = opts.options.expandtab
  end
  if opts.options.smartindent ~= nil then
    vim_opt.smartindent = opts.options.smartindent
  end
end

--- Guess indentation
---
--- @param opts {scan:ScanSettings|nil, fallback:Settings|nil}
function M.guess_indent(opts)
  local fallback = opts and opts.fallback or nil
  local indent = M.indent_info(opts.scan)

  if indent and (indent.expandtab ~= nil or indent.shiftwidth ~= nil) then
    M.set_indent({
      global = false,
      options = indent,
    })
  elseif fallback then
    M.set_indent({
      global = false,
      options = fallback,
    })
  end
end

return M
