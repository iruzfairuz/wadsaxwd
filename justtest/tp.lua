--[[
    TeleportModule - Updated for new Evade structure
    Last Update: 7 Nov 2026
    Compatible with: workspace.Map (NOT workspace.Game.Map)
]]

local TeleportModule = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- ==================== STATE ====================
local currentMap = "Unknown"
local mapConnections = {}
local isMonitoring = false
local lastMapUpdate = os.time()

-- ==================== DATABASE ====================
-- Normalized lookup table
local mapSpots = {
    ["funrooms"] = {
        DisplayName = "FunRooms",
        Far = CFrame.new(-84.314712524414, -228.51164245605, 891.68713378906, -0.028415257111192, 0, -0.99959617853165, 0, 1.0000001192093, 0, 0.99959629774094, 0, -0.028415253385901),
        -- Sky = nil -- Not available yet
    },
}

-- ==================== UTILITY ====================

local function normalizeMapName(name)
    if not name or name == "" then return nil end
    -- Remove spaces, convert to lowercase
    return name:gsub("%s+", ""):lower()
end

local function log(category, message)
    print(string.format("[TeleportModule:%s] %s", category, message))
end

local function validateCFrame(cf)
    if typeof(cf) ~= "CFrame" then return false end
    local pos = cf.Position
    if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z then
        return false -- NaN check
    end
    return true
end

-- ==================== MAP DETECTION ====================

local function detectMapFromWorkspace()
    local mapFolder = workspace:FindFirstChild("Map")
    if not mapFolder then
        return nil, "workspace.Map not found"
    end
    
    -- Try Attribute first
    local mapName = mapFolder:GetAttribute("MapName")
    if mapName and mapName ~= "" then
        return mapName, "workspace.Map.Attribute:MapName"
    end
    
    -- Try Name property as fallback
    if mapFolder.Name and mapFolder.Name ~= "Map" then
        return mapFolder.Name, "workspace.Map.Name"
    end
    
    return nil, "No MapName attribute or unique Name"
end

local function detectMapFromRemotes()
    -- Check if UpdateMap remote exists
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return nil, "ReplicatedStorage.Remotes not found" end
    
    local session = remotes:FindFirstChild("Session")
    if not session then return nil, "Remotes.Session not found" end
    
    local updateMap = session:FindFirstChild("UpdateMap")
    if not updateMap then return nil, "UpdateMap remote not found" end
    
    -- Can't read current value from RemoteEvent, only listen
    return nil, "UpdateMap exists but requires event listening"
end

function TeleportModule.GetCurrentMap()
    return currentMap
end

local function updateCurrentMap()
    local detectedMap, source = detectMapFromWorkspace()
    
    if detectedMap and detectedMap ~= currentMap then
        currentMap = detectedMap
        lastMapUpdate = os.time()
        log("MapDetect", string.format("Map changed to '%s' (source: %s)", detectedMap, source))
        return true
    elseif not detectedMap and currentMap ~= "Unknown" then
        log("MapDetect", "Map detection failed: " .. (source or "unknown reason"))
    end
    
    return false
end

-- ==================== MAP MONITORING ====================

local function startMapMonitoring()
    if isMonitoring then return end
    isMonitoring = true
    
    log("Monitor", "Starting map monitoring")
    
    -- Initial detection
    updateCurrentMap()
    
    -- Watch for Map folder changes
    local mapFolder = workspace:FindFirstChild("Map")
    if mapFolder then
        -- Watch for MapName attribute changes
        local attrConn = mapFolder:GetAttributeChangedSignal("MapName"):Connect(function()
            updateCurrentMap()
        end)
        table.insert(mapConnections, attrConn)
        
        -- Watch for child changes (map loading)
        local childConn = mapFolder.ChildAdded:Connect(function()
            task.wait(0.5) -- Wait for map to stabilize
            updateCurrentMap()
        end)
        table.insert(mapConnections, childConn)
    end
    
    -- Listen to UpdateMap remote if available
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local session = remotes:FindFirstChild("Session")
        if session then
            local updateMap = session:FindFirstChild("UpdateMap")
            if updateMap and updateMap:IsA("RemoteEvent") then
                local remoteConn = updateMap.OnClientEvent:Connect(function(...)
                    local args = {...}
                    log("Remote", "UpdateMap fired with args: " .. tostring(#args))
                    -- Try to extract map name from args
                    for _, arg in ipairs(args) do
                        if type(arg) == "string" and arg ~= "" then
                            local normalized = normalizeMapName(arg)
                            if normalized and mapSpots[normalized] then
                                currentMap = arg
                                log("Remote", "Map updated from remote: " .. arg)
                                break
                            end
                        end
                    end
                end)
                table.insert(mapConnections, remoteConn)
            end
        end
    end
    
    -- Fallback polling (every 5 seconds, only when map is Unknown)
    local pollConn = RunService.Heartbeat:Connect(function()
        if currentMap == "Unknown" then
            task.wait(5)
            updateCurrentMap()
        end
    end)
    table.insert(mapConnections, pollConn)
end

local function stopMapMonitoring()
    if not isMonitoring then return end
    isMonitoring = false
    
    log("Monitor", "Stopping map monitoring")
    
    for _, conn in ipairs(mapConnections) do
        pcall(function() conn:Disconnect() end)
    end
    mapConnections = {}
end

-- ==================== DATABASE API ====================

function TeleportModule.HasMapData(mapName)
    if not mapName or mapName == "" then return false end
    local normalized = normalizeMapName(mapName)
    return mapSpots[normalized] ~= nil
end

function TeleportModule.GetMapSpot(mapName, spotType)
    if not mapName or mapName == "" or not spotType then
        return nil
    end
    
    local normalized = normalizeMapName(mapName)
    if not mapSpots[normalized] then
        return nil
    end
    
    local spot = mapSpots[normalized][spotType]
    if spot and validateCFrame(spot) then
        return spot
    end
    
    return nil
end

function TeleportModule.GetAllMapNames()
    local names = {}
    for _, data in pairs(mapSpots) do
        table.insert(names, data.DisplayName)
    end
    table.sort(names)
    return names
end

function TeleportModule.GetMapCount()
    local count = 0
    for _ in pairs(mapSpots) do
        count = count + 1
    end
    return count
end

function TeleportModule.GetLastUpdate()
    return "7 Nov 2026"
end

-- ==================== TELEPORT PLAYER ====================

function TeleportModule.TeleportPlayer(spotType)
    -- 1. Validate player
    local player = Players.LocalPlayer
    if not player then
        warn("[TeleportModule] LocalPlayer not available")
        return false
    end
    
    -- 2. Validate character
    local character = player.Character
    if not character then
        log("Teleport", "Character not found")
        return false
    end
    
    -- 3. Validate HumanoidRootPart
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        log("Teleport", "HumanoidRootPart not found")
        return false
    end
    
    -- 4. Check map detection
    if currentMap == "Unknown" then
        log("Teleport", "Cannot teleport - map is Unknown")
        return false
    end
    
    -- 5. Get spot
    local spot = TeleportModule.GetMapSpot(currentMap, spotType)
    if not spot then
        log("Teleport", string.format("Spot '%s' not found for map '%s'", spotType, currentMap))
        return false
    end
    
    -- 6. Save position before teleport
    local oldPos = hrp.CFrame.Position
    
    -- 7. Teleport with safe method
    local success = pcall(function()
        hrp.CFrame = spot
        -- Reset velocity
        if hrp:IsA("BasePart") then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
    
    if not success then
        log("Teleport", "Failed to set CFrame")
        return false
    end
    
    -- 8. Wait and verify
    task.wait(0.1)
    local newPos = hrp.CFrame.Position
    local moved = (newPos - oldPos).Magnitude > 5
    
    if moved then
        log("Teleport", string.format("Successfully teleported to %s spot", spotType))
        return true
    else
        log("Teleport", "Teleport may have been rejected by server")
        return false
    end
end

-- ==================== PLACE TELEPORTER ====================

local function findTeleporter()
    local player = Players.LocalPlayer
    if not player then return nil, "LocalPlayer not found" end
    
    -- Check backpack
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        local teleporter = backpack:FindFirstChild("Teleporter")
        if teleporter then
            return teleporter, "Backpack"
        end
    end
    
    -- Check character
    local character = player.Character
    if character then
        local teleporter = character:FindFirstChild("Teleporter")
        if teleporter then
            return teleporter, "Character"
        end
    end
    
    -- Check ReplicatedStorage.Items
    local items = ReplicatedStorage:FindFirstChild("Items")
    if items then
        local teleporter = items:FindFirstChild("Teleporter")
        if teleporter then
            return teleporter, "ReplicatedStorage.Items (not usable directly)"
        end
    end
    
    return nil, "Teleporter not found in Backpack, Character, or ReplicatedStorage.Items"
end

local function checkDeployableSystem()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return false, "Remotes not found" end
    
    local items = remotes:FindFirstChild("Items")
    if not items then return false, "Remotes.Items not found" end
    
    local deployables = items:FindFirstChild("Deployables")
    if not deployables then return false, "Remotes.Items.Deployables not found" end
    
    local created = deployables:FindFirstChild("DeployableCreated")
    local used = deployables:FindFirstChild("DeployableUsed")
    
    if created and used then
        return true, "Deployable remotes found"
    end
    
    return false, "Deployable remotes incomplete"
end

function TeleportModule.PlaceTeleporter(spotType)
    -- Validate character first
    local player = Players.LocalPlayer
    if not player then
        warn("[TeleportModule] LocalPlayer not available")
        return false
    end
    
    local character = player.Character
    if not character then
        log("Place", "Character not found")
        return false
    end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        log("Place", "HumanoidRootPart not found")
        return false
    end
    
    -- Check map
    if currentMap == "Unknown" then
        log("Place", "Cannot place - map is Unknown")
        return false
    end
    
    -- Get spot
    local spot = TeleportModule.GetMapSpot(currentMap, spotType)
    if not spot then
        log("Place", string.format("Spot '%s' not found for map '%s'", spotType, currentMap))
        return false
    end
    
    -- Find teleporter
    local teleporter, source = findTeleporter()
    if not teleporter then
        log("Place", "Teleporter not found: " .. source)
        
        -- Check if deployable system exists
        local hasDeployable, deployMsg = checkDeployableSystem()
        if hasDeployable then
            log("Place", "Deployable system detected but cannot verify format - aborting to avoid wrong remote call")
        end
        
        return false
    end
    
    log("Place", "Teleporter found in: " .. source)
    
    -- If teleporter is in ReplicatedStorage, cannot use directly
    if source:find("ReplicatedStorage") then
        log("Place", "Teleporter in ReplicatedStorage cannot be used directly")
        log("Place", "PREVIEW MODE: Moving player to spot without placing teleporter")
        -- Preview mode - just teleport player
        return TeleportModule.TeleportPlayer(spotType)
    end
    
    -- Teleport to spot first
    local teleportSuccess = pcall(function()
        hrp.CFrame = spot
    end)
    
    if not teleportSuccess then
        log("Place", "Failed to teleport to spot")
        return false
    end
    
    task.wait(0.5)
    
    -- Try to equip if in backpack
    if teleporter.Parent == player.Backpack then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local equipSuccess = pcall(function()
                humanoid:EquipTool(teleporter)
            end)
            
            if not equipSuccess then
                log("Place", "Failed to equip teleporter")
                return false
            end
            
            task.wait(0.3)
            log("Place", "Teleporter equipped")
        end
    end
    
    -- Try to activate
    if teleporter:IsA("Tool") then
        local activateSuccess = pcall(function()
            teleporter:Activate()
        end)
        
        if activateSuccess then
            log("Place", "Teleporter activated successfully")
            return true
        else
            log("Place", "Failed to activate teleporter")
            return false
        end
    else
        log("Place", "Teleporter is not a Tool - cannot activate")
        return false
    end
end

-- ==================== REFRESH & CLEANUP ====================

function TeleportModule.Refresh()
    log("Refresh", "Refreshing module...")
    stopMapMonitoring()
    currentMap = "Unknown"
    task.wait(0.5)
    startMapMonitoring()
    return true
end

function TeleportModule.Cleanup()
    log("Cleanup", "Cleaning up module...")
    stopMapMonitoring()
    currentMap = "Unknown"
end

-- ==================== INITIALIZATION ====================

-- Auto-start monitoring
startMapMonitoring()

log("Init", string.format("TeleportModule loaded - %d maps available", TeleportModule.GetMapCount()))

return TeleportModule
