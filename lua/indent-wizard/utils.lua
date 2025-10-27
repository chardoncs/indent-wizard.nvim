--- Merge user settings with primary settings
---
---@param settings Settings Primary settings
---@param user_settings Settings User specified settings
---
---@return Settings
function MergeSettings(settings, user_settings)
  for key, value in pairs(user_settings) do
    if settings[key] == nil then
      settings[key] = value
    end
  end

  return settings
end
