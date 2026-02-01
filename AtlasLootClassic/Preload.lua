-- AtlasLootClassic - 3.3.5a preload compatibility
-- Loaded before embedded libraries.

-- Some Ace3 builds use region to namespace profiles.
if type(GetCurrentRegion) ~= "function" then
  function GetCurrentRegion()
    return 1
  end
end

-- Added after Wrath; on 3.3.5 it's not required.
if type(RegisterAddonMessagePrefix) ~= "function" then
  function RegisterAddonMessagePrefix(prefix)
    return true
  end
end

-- Added after Wrath; safe fallback.
if type(Ambiguate) ~= "function" then
  function Ambiguate(name, context)
    return name
  end
end

-- Modern APIs may expose Enum; keep empty table.
if type(Enum) ~= "table" then
  Enum = {}
end
