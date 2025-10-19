--- Merge user settings with primary settings
---
---@param settings Settings Primary settings
---@param user_settings Settings User specified settings
---
---@return Settings
function MergeSettings(settings, user_settings)
  for key, value in pairs(settings) do
    if value == nil then
      settings[key] = user_settings[key]
    end
  end

  return settings
end
