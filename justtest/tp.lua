local TeleportModule = {}

TeleportModule.mapSpots = {
    ["FunRooms"] = {
        Far = CFrame.new(-84.314712524414, -228.51164245605, 891.68713378906, -0.028415257111192, 0, -0.99959617853165, 0, 1.0000001192093, 0, 0.99959629774094, 0, -0.028415253385901)
    },
    ["ScorchingOutpost"] = {
        Far = CFrame.new(167.85266113281, 24.066555023193, 111.37776947021, -0.16992954909801, 0, 0.98545622825623, 0, 1, 0, -0.98545622825623, 0, -0.16992954909801)
    },
    ["Alleyways"] = {
        Far = CFrame.new(-173.97702026367, 2.2024083137512, -31.386837005615, -0.13816849887371, 0, -0.99040871858597, 0, 1, 0, 0.99040883779526, 0, -0.13816848397255)
    },
    ["Garden"] = {
        Far = CFrame.new(-431.40875244141, 162.43862915039, -708.68322753906, -0.64098244905472, 0, 0.76755553483963, 0, 1, 0, -0.76755565404892, 0, -0.64098238945007)
    },
    ["Mayday"] = {
        Far = CFrame.new(-1096.4613037109, 384.28344726562, 463.46029663086, -0.84483110904694, 0, 0.53503316640854, 0, 1, 0, -0.53503322601318, 0, -0.84483098983765)
    },
    ["Vibrance"] = {
        Far = CFrame.new(-153.12182617188, 56.789089202881, -5.4342374801636, -0.52045804262161, 0, -0.85388720035553, 0, 1, 0, 0.85388731956482, 0, -0.52045798301697)
    },
    ["Bedroom"] = {
        Far = CFrame.new(-92.372207641602, 66.308059692383, -373.15640258789, 0.47337934374809, 0, -0.88085865974426, 0, 1, 0, 0.88085865974426, 0, 0.47337934374809)
    },
    ["SpringBus"] = {
        Far = CFrame.new(184.22711181641, -82.783325195312, -257.76364135742, -0.99209207296371, 0, 0.12551225721836, 0, 1, 0, -0.12551225721836, 0, -0.99209207296371)
    },
    ["DrabSmall"] = {
        Far = CFrame.new(374.30477905273, -45.478126525879, -251.35067749023, 0.70146411657333, 0, -0.71270477771759, 0, 1, 0, 0.71270477771759, 0, 0.70146411657333)
    },
    ["Poolrooms"] = {
        Far = CFrame.new(-112.42768859863, 72.5, -520.18579101562, 0.0025635475758463, 0, -0.99999672174454, 0, 1, 0, 0.99999672174454, 0, 0.0025635475758463)
    },
    ["Shire"] = {
        Far = CFrame.new(-268.76318359375, -15.157480239868, 454.92501831055, -0.11324097961187, 0, 0.99356752634048, 0, 1, 0, -0.99356764554977, 0, -0.11324096471071)
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
