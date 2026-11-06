local TeleportModule = {}

TeleportModule.mapSpots = {
    ["FunRooms"] = {
        Far = CFrame.new(-84.314712524414, -228.51164245605, 891.68713378906, -0.028415257111192, 0, -0.99959617853165, 0, 1.0000001192093, 0, 0.99959629774094, 0, -0.028415253385901)
    },
}

-- ==================== FUNGSI ====================

function TeleportModule.GetCurrentMap()
    local gameFolder = workspace:FindFirstChild("Game")
    if gameFolder then
        local mapFolder = gameFolder:FindFirstChild("Map")
        if mapFolder then
            local mapName = mapFolder:GetAttribute("MapName")
            if mapName and mapName ~= "" then
                return mapName
            end
        end
    end
    return "Unknown"
end

function TeleportModule.HasMapData(mapName)
    return TeleportModule.mapSpots[mapName] ~= nil
end

function TeleportModule.GetMapSpot(mapName, spotType)
    if not TeleportModule.mapSpots[mapName] then return nil end
    return TeleportModule.mapSpots[mapName][spotType]
end

function TeleportModule.GetAllMapNames()
    local names = {}
    for name, _ in pairs(TeleportModule.mapSpots) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

function TeleportModule.GetMapCount()
    local count = 0
    for _ in pairs(TeleportModule.mapSpots) do
        count = count + 1
    end
    return count
end

function TeleportModule.GetLastUpdate()
    return "22 Feb 2026"
end

return TeleportModule
