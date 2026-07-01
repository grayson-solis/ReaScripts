-- @description No Send Dialog when Adding Sends
-- @author Grayson Solis
-- @version 1.0
-- @about Bypass the send dialog popup when dragging sends from one track IO to another track / fx
-- can still access send info by clicking respective tracks' IO button

local last_mouse = 0
local start_x, start_y = 0, 0
local is_dragging = false
local watch_until = 0

local DRAG_THRESHOLD = 5 

local function main()

  local mouse = reaper.JS_Mouse_GetState(1)
  local x, y = reaper.GetMousePosition()

  if last_mouse == 0 and mouse == 1 then
    start_x, start_y = x, y
    is_dragging = false
  end

  if mouse == 1 then
    if math.abs(x - start_x) > DRAG_THRESHOLD or math.abs(y - start_y) > DRAG_THRESHOLD then
      is_dragging = true
    end
  end

  if last_mouse == 1 and mouse == 0 then
    if is_dragging then
      watch_until = reaper.time_precise() + 0.35
    end
  end

  last_mouse = mouse

  if reaper.time_precise() < watch_until then
    for _, title in ipairs({"controls for", "routing for"}) do
      local hwnd = reaper.JS_Window_Find(title, false)
      if hwnd then
        reaper.JS_Window_Destroy(hwnd)
      end
    end
  end

  reaper.defer(main)
end

if reaper.JS_Window_Find then
  main()
else
  reaper.ShowMessageBox("Requires js_ReaScriptAPI extension", "Error", 0)
end
