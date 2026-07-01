-- @description Set envelope segment under mouse to 0 dB
-- @author Grayson Solis
-- @version 1.0

local function GetResetValue(env)
  local _, name = reaper.GetEnvelopeName(env)
  if name:find('Volume') then
    return reaper.GetEnvelopeScalingMode(env) == 1 and 716.21785031263 or 1.0
  end
  local br_env = reaper.BR_EnvAlloc(env, true)
  local center = select(9, reaper.BR_EnvGetProperties(br_env))
  reaper.BR_EnvFree(br_env, false)
  return center
end

local function main()
  if not reaper.APIExists('BR_GetMouseCursorContext') then
    reaper.ShowMessageBox('Please install SWS extension!', 'Missing SWS', 0)
    return
  end

  reaper.BR_GetMouseCursorContext()
  local env = reaper.BR_GetMouseCursorContext_Envelope()
  if not env then env = reaper.GetSelectedEnvelope(0) end
  if not env then return end

  local mousePos = reaper.BR_PositionAtMouseCursor(false)
  if mousePos < 0 then return end

  local aiIdx = -1
  local layerTime = mousePos
  local nAI = reaper.CountAutomationItems(env)
  for i = 0, nAI - 1 do
    local aiPos = reaper.GetSetAutomationItemInfo(env, i, 'D_POSITION', 0, false)
    local aiLen = reaper.GetSetAutomationItemInfo(env, i, 'D_LENGTH',   0, false)
    if mousePos >= aiPos and mousePos < aiPos + aiLen then
      aiIdx = i
      local offs = reaper.GetSetAutomationItemInfo(env, i, 'D_STARTOFFS', 0, false) or 0
      local rate = reaper.GetSetAutomationItemInfo(env, i, 'D_PLAYRATE',  0, false)
      if not rate or rate == 0 then rate = 1 end
      layerTime = (mousePos - aiPos) * rate + offs
      break
    end
  end

  local nPoints = reaper.CountEnvelopePointsEx(env, aiIdx)
  if nPoints < 2 then return end

  local leftIdx, rightIdx = nil, nil
  for i = 0, nPoints - 1 do
    local _, ptTime = reaper.GetEnvelopePointEx(env, aiIdx, i)
    if ptTime <= layerTime then
      leftIdx = i
    elseif rightIdx == nil then
      rightIdx = i
      break
    end
  end

  if leftIdx == nil or rightIdx == nil then return end

  local value = GetResetValue(env)

  reaper.Undo_BeginBlock2(0)
  reaper.PreventUIRefresh(1)
  reaper.SetEnvelopePointEx(env, aiIdx, leftIdx,  nil, value, nil, nil, nil, false)
  reaper.SetEnvelopePointEx(env, aiIdx, rightIdx, nil, value, nil, nil, nil, false)
  reaper.Envelope_SortPointsEx(env, aiIdx)
  reaper.UpdateArrange()
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock2(0, 'Set envelope segment to 0 dB', -1)
end

main()
