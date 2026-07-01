-- @description Run Reaticulate if it is detected in Project
-- @author Grayson Solis
-- @version 1.0
-- @about Polls every 2s; launches Reaticulate if the JSFX is found and then exits

local INTERVAL = 2.0
local t_last = -INTERVAL
local ACTION_ID = reaper.NamedCommandLookup("_RSb4948ff8f1015c2f895a78f11f75d277e14a01b7")

local function has_reaticulate_jsfx()
  for i = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    for j = 0, reaper.TrackFX_GetCount(tr) - 1 do
      local _, nm = reaper.TrackFX_GetFXName(tr, j, "")
      if nm:lower():find("reaticulate", 1, true) then return true end
    end
  end
  return false
end

local function tick()
  local now = reaper.time_precise()
  if now - t_last >= INTERVAL then
    t_last = now
    if has_reaticulate_jsfx() and ACTION_ID ~= 0 then
      reaper.Main_OnCommand(ACTION_ID, 0)
      return
    end
  end
  reaper.defer(tick)
end

reaper.defer(tick)
