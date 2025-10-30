--- Merge user settings with primary settings
---
---@param settings Settings Primary settings
---@param user_settings Settings User specified settings
---
---@return Settings
function MergeSettings(settings, user_settings)
  local out_settings = {}

  for key, value in pairs(user_settings) do
    if settings[key] == nil then
      out_settings[key] = value
    else
      out_settings[key] = settings[key]
    end
  end

  if settings.spaces ~= nil then
    -- Restore related options
    out_settings.shiftwidth = settings.shiftwidth
    out_settings.tabstop = settings.tabstop
    out_settings.softtabstop = settings.softtabstop
  end

  return out_settings
end
