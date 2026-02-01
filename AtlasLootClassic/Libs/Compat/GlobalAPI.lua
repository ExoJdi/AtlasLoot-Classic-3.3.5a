if not GetCurrentRegion then
  local portalToRegion = {
    US = 1,
    EU = 2,
    KR = 3,
    TW = 4,
    CN = 5,
  }

  function GetCurrentRegion()
    local portal
    if GetCVar then
      portal = GetCVar("portal")
    end
    if type(portal) == "string" then
      local key = portal:upper()
      if portalToRegion[key] then
        return portalToRegion[key]
      end
    end
    -- Fallback: treat unknown as US.
    return 1
  end
end

if not Ambiguate then
  function Ambiguate(name)
    return name
  end
end

if not RegisterAddonMessagePrefix then
  function RegisterAddonMessagePrefix()
    return true
  end
end


if not UnitPosition then
  function UnitPosition(unit)
    unit = unit or "player"
    if not UnitExists or not UnitExists(unit) then
      return nil
    end
    -- 3.3.5: requires the map to be set to the current zone for sane coords.
    if SetMapToCurrentZone then
      pcall(SetMapToCurrentZone)
    end
    if GetPlayerMapPosition then
      local x, y = GetPlayerMapPosition(unit)
      if x and y and (x > 0 or y > 0) then
        local areaID = GetCurrentMapAreaID and GetCurrentMapAreaID() or nil
        return x, y, areaID
      end
    end
    return nil
  end
end
