---@class IndentResult
---@field spaces uinteger?
---@field expandtab boolean?
---@field mixed boolean?

--- Check indentation in current buffer
---
---@param line_count number How many lines will be scanned
---@param offset number How many lines (integer) or percentage of lines (float between 0~1) will be skipped
---
---@return IndentResult
function GuessIndent(line_count, offset)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local length = vim.fn.len(lines)

  local min_spaces = nil

  local votes = {
    expandtab = 0,
    noexpandtab = 0,
  }

  local abs_offset = offset < 1 and math.floor(length * offset) or offset

  local scan_from = 1 + abs_offset
  local scan_to = line_count + 1 + abs_offset

  local i = scan_from
  local lines_passed = scan_from

  -- Main scan loop
  while i <= scan_to and lines_passed <= length do
    local line = lines[i]
    local str_len = string.len(line)

    if str_len > 0 and line:sub(1, 1) == "\t" then
      -- Seems like noexpandtab
      votes.noexpandtab = votes.noexpandtab + 1
    else
      local space_len = string.len(tostring(line:match("^%s+")))
      if space_len > 0 then
        -- If it is even number spaces
        if space_len % 2 == 0 then
          if min_spaces == nil or min_spaces > space_len then
            min_spaces = space_len
          end
        end

        -- Seems like expandtab
        votes.expandtab = votes.expandtab + 1

        i = i + 1
      end
    end

    lines_passed = lines_passed + 1
  end

  local expandtab = nil
  if votes.expandtab ~= votes.noexpandtab then
    expandtab = votes.expandtab > votes.noexpandtab
  end

  return {
    expandtab = expandtab,
    spaces = min_spaces,
    mixed = votes.expandtab > 0 and votes.noexpandtab > 0,
  }
end
