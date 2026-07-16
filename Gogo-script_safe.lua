
print("[SAFE MODE] Emergency script loaded.")

local function checkKey()
    local keyFile = "scriptgogo_key.txt"
    local keyValid = false
    
    pcall(function()
        if isfile(keyFile) then
            local content = readfile(keyFile)
            local data = game:GetService("HttpService"):JSONDecode(content)
            if data and data.isPermanent then
                keyValid = true
            elseif data and data.expiryDate and os.time() < data.expiryDate then
                keyValid = true
            end
        end
    end)
    
    if not keyValid then
        print("[SAFE MODE] No valid key found. Waiting for key...")
      
        print("Enter your key in the console or press ENTER to skip.")
        local key = readconsole()
        if key and key ~= "" then
  
            keyValid = true
            print("[SAFE MODE] Key accepted (basic mode).")
        else
            print("[SAFE MODE] No key provided. Continuing in limited mode.")
            keyValid = true
        end
    end
    
    return keyValid
end

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")

local CONFIG = {
    AttackRadius = 80,
    MoveRadius = 200,
    AttackDelay = 0.1,
    MaxAttacks = 4,
    AutoHeal = true,
    HealthThreshold = 30,
    TeleportToEnemy = true,
}

local isRunning = true
local currentTarget = nil

local function getNearbyEnemies(radius)
    local enemies = {}
    local charPos = rootPart.Position
    
    for _, v in pairs(game.Workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Name ~= character.Name and v.Humanoid.Health > 0 then
                local dist = (v.HumanoidRootPart.Position - charPos).Magnitude
                if dist <= radius then
                    table.insert(enemies, v)
                end
            end
        end
    end
    
    return enemies
end

local function moveTo(position)
    pcall(function()
        local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        local tween = tweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(position)})
        tween:Play()
        tween.Completed:Wait()
    end)
end

local function teleportTo(position)
    pcall(function()
        rootPart.CFrame = CFrame.new(position)
    end)
end

local function attackEnemy(target)
    pcall(function()
        if not target or not target:FindFirstChild("Humanoid") or target.Humanoid.Health <= 0 then
            return
        end
        
        local targetPos = target.HumanoidRootPart.Position
        rootPart.CFrame = CFrame.new(rootPart.Position, targetPos)
        
        local remote = replicatedStorage:FindFirstChild("Remotes")
        if remote and remote:FindFirstChild("CommF_") then
            remote.CommF_:InvokeServer("Attack", {target.HumanoidRootPart})
        end
        
        wait(CONFIG.AttackDelay)
    end)
end

local function checkHealth()
    if not CONFIG.AutoHeal then return end
    if humanoid.Health < CONFIG.HealthThreshold then
        
        print("[SAFE MODE] Low health (" .. math.floor(humanoid.Health) .. "). Healing...")
        wait(5)
    end
end

local function farmLoop()
    print("[SAFE MODE] Starting auto farm...")
    
    while isRunning do
        pcall(function()
          
            checkHealth()
            
            
            local enemies = getNearbyEnemies(CONFIG.AttackRadius)
            
            if #enemies > 0 then
                
                local target = enemies[1]
                currentTarget = target
                
                if CONFIG.TeleportToEnemy then
                    local targetPos = target.HumanoidRootPart.Position
                    local distance = (targetPos - rootPart.Position).Magnitude
                    if distance > 15 then
                        teleportTo(targetPos + Vector3.new(0, 5, 0))
                        wait(0.2)
                    end
                end
                
                local attackCount = math.random(2, CONFIG.MaxAttacks)
                for i = 1, attackCount do
                    attackEnemy(target)
                    wait(CONFIG.AttackDelay + math.random(0, 50) / 1000)
                end
                
                
                if math.random(1, 10) == 1 then
                    print("[SAFE MODE] Farming: " .. target.Name .. " | Health: " .. math.floor(humanoid.Health))
                end
            else
          
                print("[SAFE MODE] No enemies. Searching...")
                local randomPos = rootPart.Position + Vector3.new(
                    math.random(-CONFIG.MoveRadius, CONFIG.MoveRadius),
                    0,
                    math.random(-CONFIG.MoveRadius, CONFIG.MoveRadius)
                )
                moveTo(randomPos)
                wait(1)
            end
            
            wait(0.3)
        end)
    end
end

local function fallbackFarm()
    print("[SAFE MODE] Fallback mode: Basic auto-click")
    while isRunning do
        pcall(function()
            local enemies = getNearbyEnemies(100)
            if #enemies > 0 then
                local target = enemies[1]
                attackEnemy(target)
                wait(0.5)
            else
                wait(2)
            end
        end)
    end
end

print("[SAFE MODE] Initializing emergency farm...")

-- Check if key exists (but continue anyway in emergency)
checkKey()

-- Wait for character to be fully loaded
if not character or not humanoid then
    print("[SAFE MODE] Waiting for character...")
    repeat wait(1)
        character = player.Character
        humanoid = character and character:FindFirstChild("Humanoid")
    until humanoid
end

print("[SAFE MODE] Character ready. Level: " .. (player.Data and player.Data.Level and player.Data.Level.Value or "?"))

-- Start farming
local success, err = pcall(farmLoop)
if not success then
    print("[SAFE MODE] Error in farm loop: " .. tostring(err))
    print("[SAFE MODE] Starting fallback mode...")
    pcall(fallbackFarm)
end

-- Keep script alive
while isRunning do
    wait(1)
end

print("[SAFE MODE] Emergency script ended.")
