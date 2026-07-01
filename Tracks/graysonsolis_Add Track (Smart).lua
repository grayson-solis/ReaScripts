-- @description Add Track (Smart)
-- @author Grayson Solis
-- @version 1.0
-- @about Changes how tracks are added: 
--	- Nothing selected - adds at the end.
--	- Normal track selected - adds right after it.
--	- Expanded folder selected - adds inside it (first child).
--	- Collapsed folder selected - adds after the whole folder.

local function main()
  local sel_track = reaper.GetSelectedTrack(0, 0)
  local new_track
  if not sel_track then
    local idx = reaper.CountTracks(0)
    reaper.InsertTrackAtIndex(idx, true)
    new_track = reaper.GetTrack(0, idx)
    reaper.SetMediaTrackInfo_Value(new_track, "I_FOLDERDEPTH", 0)
  else
    local idx = reaper.GetMediaTrackInfo_Value(sel_track, "IP_TRACKNUMBER") - 1
    local folderdepth = reaper.GetMediaTrackInfo_Value(sel_track, "I_FOLDERDEPTH")
    if folderdepth == 1 then
      local compact = reaper.GetMediaTrackInfo_Value(sel_track, "I_FOLDERCOMPACT")
      if compact ~= 2 then
        reaper.InsertTrackAtIndex(idx + 1, true)
        new_track = reaper.GetTrack(0, idx + 1)
        reaper.SetMediaTrackInfo_Value(new_track, "I_FOLDERDEPTH", 0)
      else
        local own_depth = reaper.GetTrackDepth(sel_track)
        local total = reaper.CountTracks(0)
        local insert_idx = total
        for i = idx + 1, total - 1 do
          if reaper.GetTrackDepth(reaper.GetTrack(0, i)) <= own_depth then
            insert_idx = i
            break
          end
        end

        local prev_track  = reaper.GetTrack(0, insert_idx - 1)
        local fd_prev     = reaper.GetMediaTrackInfo_Value(prev_track, "I_FOLDERDEPTH")
        local depth_after = reaper.GetTrackDepth(prev_track) + fd_prev
        local delta       = own_depth - depth_after 

        reaper.InsertTrackAtIndex(insert_idx, true)
        new_track = reaper.GetTrack(0, insert_idx)

        if delta > 0 then
          reaper.SetMediaTrackInfo_Value(prev_track, "I_FOLDERDEPTH", fd_prev + delta)
          reaper.SetMediaTrackInfo_Value(new_track,  "I_FOLDERDEPTH", -delta)
        else
          reaper.SetMediaTrackInfo_Value(new_track, "I_FOLDERDEPTH", 0)
        end
      end
    else
      reaper.InsertTrackAtIndex(idx + 1, true)
      new_track = reaper.GetTrack(0, idx + 1)
      if folderdepth < 0 then
        reaper.SetMediaTrackInfo_Value(new_track, "I_FOLDERDEPTH", folderdepth)
        reaper.SetMediaTrackInfo_Value(sel_track, "I_FOLDERDEPTH", 0)
      else
        reaper.SetMediaTrackInfo_Value(new_track, "I_FOLDERDEPTH", 0)
      end
    end
  end
  reaper.SetOnlyTrackSelected(new_track)
end
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Smart Add Track", -1)
reaper.UpdateArrange()
