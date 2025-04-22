local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Riq Hub - " .. identifyexecutor(),
    Icon = 0,
    LoadingTitle = "Riq Hub Loading...",
    LoadingSubtitle = "by Riq",
    Theme = "Default",
 
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
 
    ConfigurationSaving = {
       Enabled = true,
       FolderName = nil,
       FileName = "Riq Hub"
    },
 
    Discord = {
       Enabled = true,
       Invite = "twl",
       RememberJoins = false
    },
 
    KeySystem = false,
    KeySettings = {
       Title = "Untitled",
       Subtitle = "Key System",
       Note = "No method of obtaining the key is provided",
       FileName = "Key",
       SaveKey = true,
       GrabKeyFromSite = false,
       Key = {"Hello"}
    }
 })

local TabRoles1 = Window:CreateTab("Roles", "user-round-search")
local TabESP1 = Window:CreateTab("ESP", "eye")

local TabESP = TabESP1:CreateSection("ESP Settings")
local TabRoles = TabRoles1:CreateSection("Sheriff Section")

local murderESPEnabled = false
local sheriffESPEnabled = false
local playerESPEnabled = false
local gunESPEnabled = false
local autoShootEnabled = false
local autoTeleportToGunEnabled = false
local autoGetDroppedGunEnabled = false
local loopTpToGun
local gunDropConnection
local gunESPChildAddedConnection
local gunESPChildRemovedConnection 
local sheriff
local murderer
local character
local shootOffset = 2.8

local runService = game:GetService("RunService")
local lastUpdate = tick()
local updateInterval = 1
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local murderHighlights = {}
local sheriffHighlights = {}
local playerHighlights = {}
local gunHighlights = {}

local function applyHighlight(target, color, highlightTable)
    if highlightTable[target] then return end

    local highlight = Instance.new("Highlight")
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0

    if target:IsA("Model") then
        highlight.Adornee = target
    elseif target:IsA("BasePart") then
        highlight.Adornee = target
    elseif target:IsA("Tool") then
        local handle = target:FindFirstChild("Handle")
        if handle then
            highlight.Adornee = handle
        else
            return
        end
    else
        return
    end

    highlight.Parent = game.CoreGui
    highlightTable[target] = highlight
end

local function removeHighlights(highlightTable)
    for character, highlight in pairs(highlightTable) do
        highlight:Destroy()
        highlightTable[character] = nil
    end
end

local function getMap()
    for _, o in ipairs(workspace:GetChildren()) do
        if o and o:FindFirstChild("CoinContainer") and o:FindFirstChild("Spawns") then
            return o
        end
    end
    return nil
end

local function updateMurderESP()
    if not murderESPEnabled then
        removeHighlights(murderHighlights)
        return
    end

    local existingMurderHighlights = {}
    for _, model in pairs(Workspace:GetChildren()) do
        if model:IsA("Model") then
            local player = Players:GetPlayerFromCharacter(model)
            if player then
                local backpack = player.Backpack
                if backpack then
                    local knife = backpack:FindFirstChild("Knife")
                    if knife or player.Character:FindFirstChild("Knife") then
                        existingMurderHighlights[player.Character] = true
                        applyHighlight(player.Character, Color3.new(1, 0, 0), murderHighlights)
                    end
                end
            end
        end
    end
    
    for character, _ in pairs(murderHighlights) do
        if not existingMurderHighlights[character] then
            murderHighlights[character]:Destroy()
            murderHighlights[character] = nil
        end
    end
end

local function updateSheriffESP()
    if not sheriffESPEnabled then
        removeHighlights(sheriffHighlights)
        return
    end

    local existingSheriffHighlights = {}
    for _, model in pairs(Workspace:GetChildren()) do
        if model:IsA("Model") then
            local player = Players:GetPlayerFromCharacter(model)
            if player then
                local backpack = player.Backpack
                if backpack then
                    local gun = backpack:FindFirstChild("Gun")
                    if gun or player.Character:FindFirstChild("Gun") then
                        existingSheriffHighlights[player.Character] = true
                        applyHighlight(player.Character, Color3.new(0, 0, 1), sheriffHighlights)
                    end
                end
            end
        end
    end
    
    for character, _ in pairs(sheriffHighlights) do
        if not existingSheriffHighlights[character] then
            sheriffHighlights[character]:Destroy()
            sheriffHighlights[character] = nil
        end
    end
end

local function updatePlayerESP()
    if not playerESPEnabled then
        removeHighlights(playerHighlights)
        return
    end

    local existingPlayerHighlights = {}
    for _, model in pairs(Workspace:GetChildren()) do
        if model:IsA("Model") then
            local player = Players:GetPlayerFromCharacter(model)
            if player and not murderHighlights[player.Character] and not sheriffHighlights[player.Character] then
                existingPlayerHighlights[player.Character] = true
                applyHighlight(player.Character, Color3.new(0, 1, 0), playerHighlights)
            end
        end
    end
    
    for character, _ in pairs(playerHighlights) do
        if not existingPlayerHighlights[character] then
            playerHighlights[character]:Destroy()
            playerHighlights[character] = nil
        end
    end
end

local function notify(title, text, time)
    Rayfield:Notify({
        Title = title,
        Content = text,
        Duration = time,
        Image = "settings",
     })
end

local function updateGunESP()
    if not gunESPEnabled then
        removeHighlights(gunHighlights)
        return
    end

    local map = getMap()
    local gun = map and map:FindFirstChild("GunDrop")
    if gun then
        applyHighlight(gun, Color3.new(1, 1, 0), gunHighlights)
    else
        removeHighlights(gunHighlights)
    end
end

local function findMurderer()
    for _, i in ipairs(game.Players:GetPlayers()) do
        if i.Backpack:FindFirstChild("Knife") then
            return i
        end
    end

    for _, i in ipairs(game.Players:GetPlayers()) do
        if not i.Character then continue end
        if i.Character:FindFirstChild("Knife") then
            return i
        end
    end

    if playerData then
        for player, data in playerData do
            if data.Role == "Murderer" then
                if game.Players:FindFirstChild(player) then
                    return game.Players:FindFirstChild(player)
                end
            end
        end
    end
    return nil
end

local function findSheriff()
    for _, i in ipairs(game.Players:GetPlayers()) do
        if i.Backpack:FindFirstChild("Gun") then
            return i
        end
    end

    for _, i in ipairs(game.Players:GetPlayers()) do
        if not i.Character then continue end
        if i.Character:FindFirstChild("Gun") then
            return i
        end
    end

    if playerData then
        for player, data in playerData do
            if data.Role == "Sheriff" then
                if game.Players:FindFirstChild(player) then
                    return game.Players:FindFirstChild(player)
                end
            end
        end
    end
    return nil
end


local function getPredictedPosition(player, shootOffset)
    pcall(function()
        player = player.Character
        if not player then notify("Riq Hub" ,"Não existe murder para prever os movimentos dele.", 2) return end
    end)
    local playerHRP = player:FindFirstChild("UpperTorso")
    local playerHum = player:FindFirstChild("Humanoid")
    if not playerHRP or not playerHum then
        return Vector3.new(0,0,0), "Não consegui encontrar HumanoidRootPart do jogador."
    end

    local playerPosition = playerHRP.Position
    local velocity = playerHRP.AssemblyLinearVelocity
    local playerMoveDirection = playerHum.MoveDirection
    local predictedPosition = playerHRP.Position + (velocity * Vector3.new(0, 0.5, 0)) * (shootOffset / 15) + playerMoveDirection * shootOffset

    return predictedPosition
end

local function performAutoShoot()
    if not autoShootEnabled then
        return
    end

    local foundSheriff = findSheriff()
    local foundMurderer = findMurderer()

    if foundSheriff == LP then
        if not foundMurderer then
            return
        end

        local murdererPosition = foundMurderer.Character.HumanoidRootPart.Position
        local characterRootPart = LP.Character.HumanoidRootPart
        local rayDirection = murdererPosition - characterRootPart.Position

        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {LP.Character}

        local hit = workspace:Raycast(characterRootPart.Position, rayDirection, raycastParams)
        if not hit or hit.Instance.Parent == foundMurderer.Character then
            if not LP.Character:FindFirstChild("Gun") then
                local gun = LP.Backpack:FindFirstChild("Gun")
                if gun then
                    LP.Character:FindFirstChild("Humanoid"):EquipTool(gun)
                else
                    notify("Riq Hub" ,"Você não tem a Gun...?", 2)
                    return
                end
            end

            local predictedPosition = getPredictedPosition(foundMurderer, shootOffset)

            local args = {
                [1] = 1,
                [2] = predictedPosition,
                [3] = "AH2"
            }

            LP.Character.Gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(unpack(args))
        end
    end
end

local function performAutoGetDroppedGun()
    if isGrabbingGun then return end
    isGrabbingGun = true

    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then
        notify("Riq Hub", "HumanoidRootPart não encontrado", 2)
        isGrabbingGun = false
        return
    end

    local oldCFrame = root.CFrame
    local trying = true

    local connection
    connection = LP.Backpack.ChildAdded:Connect(function(child)
        if child.Name == "Gun" then
            trying = false
            root.CFrame = oldCFrame
            connection:Disconnect()
        end
    end)

    task.spawn(function()
        while trying do
            local map = getMap()
            local gun = map and map:FindFirstChild("GunDrop")
            if gun then
                root.CFrame = gun.CFrame + Vector3.new(0, 2, 0)
            end
            task.wait(0.2)
        end

        if connection.Connected then
            connection:Disconnect()
        end

        if trying then
            notify("Riq Hub", "Não conseguiu pegar a arma.", 2)
            root.CFrame = oldCFrame
        end
        isGrabbingGun = false
    end)
end

local function onBackpackChanged()
    local gun = LP.Backpack:FindFirstChild("Gun")
    if autoShootEnabled then
        if gun then
            performAutoShoot()
        end
    end
end

local Toggle = TabESP1:CreateToggle({
    Name = "Murder ESP",
    CurrentValue = false,
    Flag = "Toggle1",
    Callback = function(Value)
        murderESPEnabled = Value
    end,
})

local Toggle2 = TabESP1:CreateToggle({
    Name = "Sheriff ESP",
    CurrentValue = false,
    Flag = "Toggle2",
    Callback = function(Value)
        sheriffESPEnabled = Value
    end,
})

local Toggle3 = TabESP1:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Flag = "Toggle3",
    Callback = function(Value)
        playerESPEnabled = Value
    end,
})

local Toggle4 = TabESP1:CreateToggle({
    Name = "Gun ESP",
    CurrentValue = false,
    Flag = "Toggle4",
    Callback = function(Value)
        gunESPEnabled = Value
        local map = getMap()

        if Value and map then
            updateGunESP()

            gunESPChildAddedConnection = map.ChildAdded:Connect(function(child)
                if child.Name == "GunDrop" and gunESPEnabled then
                    notify("Riq Hub", "Gun dropped, follow the highlight", 2)
                    applyHighlight(child, Color3.new(1, 1, 0), gunHighlights)
                end
            end)

            gunESPChildRemovedConnection = map.ChildRemoved:Connect(function(child)
                if child.Name == "GunDrop" and gunESPEnabled then
                    notify("Riq Hub", "Gun taken", 2)
                    removeHighlights(gunHighlights)
                end
            end)
        else
            if gunESPChildAddedConnection then
                gunESPChildAddedConnection:Disconnect()
                gunESPChildAddedConnection = nil
            end
            if gunESPChildRemovedConnection then
                gunESPChildRemovedConnection:Disconnect()
                gunESPChildRemovedConnection = nil
            end
            removeHighlights(gunHighlights)
        end
    end,
})

local Toggle5 = TabRoles1:CreateToggle({
    Name = "Auto Shoot",
    CurrentValue = false,
    Flag = "Toggle5",
    Callback = function(Value)
        autoShootEnabled = Value
    end,
})

local Keybind = TabRoles1:CreateKeybind({
    Name = "Auto Shoot Bind",
    CurrentKeybind = "E",
    HoldToInteract = false,
    Flag = "Keybind1",
    Callback = function(Keybind)
        sheriff = findSheriff()
        murderer = findMurderer()
        character = LP.Character

        if sheriff == LP then
            if not murderer then
                return
            end

            local murdererPosition = murderer.Character.HumanoidRootPart.Position
            local characterRootPart = character.HumanoidRootPart
            local rayDirection = murdererPosition - characterRootPart.Position

            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = {character}

            local hit = workspace:Raycast(characterRootPart.Position, rayDirection, raycastParams)
            if not hit or hit.Instance.Parent == murderer.Character then
                if not character:FindFirstChild("Gun") then
                    local gun = LP.Backpack:FindFirstChild("Gun")
                    if gun then
                        character:FindFirstChild("Humanoid"):EquipTool(gun)
                    else
                        notify("Riq Hub", "Você não tem a Gun...?", 2)
                        return
                    end
                end

                local predictedPosition = getPredictedPosition(murderer, shootOffset)

                local args = {
                    [1] = 1,
                    [2] = predictedPosition,
                    [3] = "AH2"
                }

                character.Gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(unpack(args))
            end
        end
    end,
})

local Keybind2 = TabRoles1:CreateKeybind({
    Name = "Grab Gun Bind",
    CurrentKeybind = "G",
    HoldToInteract = false,
    Flag = "Keybind2",
    Callback = function(Keybind)
        if getMap() and getMap():FindFirstChild("GunDrop") then
            performAutoGetDroppedGun()
        end
    end,
})

LP.Backpack.ChildAdded:Connect(onBackpackChanged)

runService.Heartbeat:Connect(function()
    if tick() - lastUpdate >= updateInterval then
        if murderESPEnabled then updateMurderESP() end
        if sheriffESPEnabled then updateSheriffESP() end
        if playerESPEnabled then updatePlayerESP() end
        if gunESPEnabled then updateGunESP() end
        lastUpdate = tick()
    end

    if autoShootEnabled then
        performAutoShoot()
    end
end)

ReplicatedStorage.Remotes.Gameplay.RoundStart.OnClientEvent:Connect(function()
    notify("Riq Hub", "Atualizando ESP...", 3)
    if murderESPEnabled then updateMurderESP() end
    if sheriffESPEnabled then updateSheriffESP() end
    if playerESPEnabled then updatePlayerESP() end
    if gunESPEnabled then updateGunESP() end
    if autoShootEnabled then
        performAutoShoot()
        wait(2)
        notify("Riq Hub", "Atualizando o Auto Shoot.", 2)
    end
end)

wait(2)
notify("Riq Hub", "Carregado com Sucesso!", 2)
wait(2)
notify("Riq Hub", "Último Update em 21/04/25 às 23:16.", 2)
