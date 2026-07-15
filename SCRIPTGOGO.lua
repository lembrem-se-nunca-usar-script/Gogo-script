-- ============================================
-- SCRIPT GOGO - GODHUMAN FARMER V9.0
-- SISTEMA DE KEY LOOTLABS COM VALIDADE 24H
-- ============================================

print("SCRIPT GOGO - CARREGANDO...")

-- ============================================
-- CONFIGURACAO LOOTLABS
-- ============================================
local Lootlabs_Config = {
    Enabled = true,
    API_Key = "SUA_CHAVE_DE_API_AQUI", 
    Link = "URL_DO_SEU_LINK_LOOTLABS",
    API_URL = "https://api.lootlabs.xyz/verify",
    ExpiryHours = 24
}

-- ============================================
-- 1. SISTEMA DE KEY LOOTLABS COM 24H
-- ============================================
local KeySystem = {}
KeySystem.__index = KeySystem

function KeySystem.new()
    local self = setmetatable({}, KeySystem)
    self.keyFile = "scriptgogo_key.txt"
    self.verified = false
    self.retryAttempts = 0
    self.maxRetries = 5
    self.expiryHours = Lootlabs_Config.ExpiryHours
    self.currentUser = nil
    self.userId = self:generateUserId()
    return self
end

function KeySystem:generateUserId()
    local userId = ""
    pcall(function()
        local player = game.Players.LocalPlayer
        local accountId = player.UserId or "unknown"
        local hwid = "unknown"
        if syn and syn.crypt then
            hwid = syn.crypt.customhash("HWID") or "unknown"
        end
        local rawId = accountId .. "_" .. hwid
        userId = game:GetService("HttpService"):SHA512(rawId):sub(1, 16)
    end)
    if userId == "" then
        userId = game.Players.LocalPlayer.Name
    end
    return userId
end

function KeySystem:getCurrentDate()
    return os.date("%Y-%m-%d")
end

function KeySystem:isKeyExpired(savedData)
    if not savedData or not savedData.expiryDate then
        return true
    end
    return os.time() > savedData.expiryDate
end

function KeySystem:saveUserKey(userId, key, expiryDate)
    pcall(function()
        local data = {
            userId = userId,
            key = key,
            date = os.date("%Y-%m-%d %H:%M:%S"),
            expiryDate = expiryDate or (os.time() + (self.expiryHours * 3600))
        }
        local json = game:GetService("HttpService"):JSONEncode(data)
        writefile(self.keyFile, json)
    end)
end

function KeySystem:loadUserKey(userId)
    local result = nil
    pcall(function()
        if isfile(self.keyFile) then
            local content = readfile(self.keyFile)
            local data = game:GetService("HttpService"):JSONDecode(content)
            if data and data.userId == userId then
                result = data
            end
        end
    end)
    return result
end

function KeySystem:verifyWithLootlabs(key)
    if not Lootlabs_Config.Enabled then
        return false
    end
    
    local success, response = pcall(function()
        local data = {
            key = key,
            api_token = Lootlabs_Config.API_Key
        }
        local jsonData = game:GetService("HttpService"):JSONEncode(data)
        
        if syn and syn.request then
            return syn.request({
                Url = Lootlabs_Config.API_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = jsonData
            })
        else
            return game:HttpGet(Lootlabs_Config.API_URL .. "?key=" .. key .. "&api_token=" .. Lootlabs_Config.API_Key)
        end
    end)
    
    if success then
        if type(response) == "string" then
            local decoded = game:GetService("HttpService"):JSONDecode(response)
            return decoded and decoded.valid == true
        elseif response and response.StatusCode == 200 then
            local decoded = game:GetService("HttpService"):JSONDecode(response.Body)
            return decoded and decoded.valid == true
        end
    end
    return false
end

function KeySystem:showKeyUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KeySystem"
    screenGui.Parent = game:GetService("CoreGui")
    screenGui.ResetOnSpawn = false
    
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.8
    background.BorderSizePixel = 0
    background.Parent = screenGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 450, 0, 480)
    mainFrame.Position = UDim2.new(0.5, -225, 0.5, -240)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
    mainFrame.Parent = background
    
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(1, 0, 0, 45)
    logo.Position = UDim2.new(0, 0, 0, 10)
    logo.BackgroundTransparency = 1
    logo.Text = "SCRIPT GOGO"
    logo.TextColor3 = Color3.fromRGB(255, 215, 0)
    logo.TextSize = 30
    logo.Font = Enum.Font.GothamBold
    logo.Parent = mainFrame
    
    local userIdLabel = Instance.new("TextLabel")
    userIdLabel.Size = UDim2.new(1, 0, 0, 25)
    userIdLabel.Position = UDim2.new(0, 0, 0, 60)
    userIdLabel.BackgroundTransparency = 1
    userIdLabel.Text = "SEU ID: " .. self.userId
    userIdLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    userIdLabel.TextSize = 13
    userIdLabel.Font = Enum.Font.GothamMedium
    userIdLabel.Parent = mainFrame
    
    local expiryLabel = Instance.new("TextLabel")
    expiryLabel.Size = UDim2.new(1, 0, 0, 25)
    expiryLabel.Position = UDim2.new(0, 0, 0, 85)
    expiryLabel.BackgroundTransparency = 1
    expiryLabel.Text = "KEY VALIDA POR: 24 HORAS"
    expiryLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    expiryLabel.TextSize = 14
    expiryLabel.Font = Enum.Font.GothamBold
    expiryLabel.Parent = mainFrame
    
    local dateLabel = Instance.new("TextLabel")
    dateLabel.Size = UDim2.new(1, 0, 0, 20)
    dateLabel.Position = UDim2.new(0, 0, 0, 110)
    dateLabel.BackgroundTransparency = 1
    dateLabel.Text = "Data: " .. os.date("%d/%m/%Y %H:%M")
    dateLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    dateLabel.TextSize = 12
    dateLabel.Font = Enum.Font.GothamMedium
    dateLabel.Parent = mainFrame
    
    local instructions = Instance.new("TextLabel")
    instructions.Size = UDim2.new(1, 0, 0, 40)
    instructions.Position = UDim2.new(0, 0, 0, 135)
    instructions.BackgroundTransparency = 1
    instructions.Text = "INSIRA SUA KEY DIARIA\n(Obtenha no link abaixo)"
    instructions.TextColor3 = Color3.fromRGB(180, 180, 180)
    instructions.TextSize = 14
    instructions.Font = Enum.Font.GothamMedium
    instructions.TextWrapped = true
    instructions.Parent = mainFrame
    
    local getKeyBtn = Instance.new("TextButton")
    getKeyBtn.Size = UDim2.new(0.6, 0, 0, 35)
    getKeyBtn.Position = UDim2.new(0.2, 0, 0, 190)
    getKeyBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    getKeyBtn.BorderSizePixel = 0
    getKeyBtn.Text = "OBTER KEY (LOOTLABS)"
    getKeyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    getKeyBtn.TextSize = 14
    getKeyBtn.Font = Enum.Font.GothamBold
    getKeyBtn.Parent = mainFrame
    
    getKeyBtn.MouseButton1Click:Connect(function()
        if Lootlabs_Config.Link and Lootlabs_Config.Link ~= "" then
            setclipboard(Lootlabs_Config.Link)
            status.Text = "LINK COPIADO! Acesse e obtenha sua key"
            status.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            status.Text = "ERRO: Link da LootLabs nao configurado"
            status.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end)
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0.8, 0, 0, 45)
    textBox.Position = UDim2.new(0.1, 0, 0, 240)
    textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    textBox.BorderSizePixel = 2
    textBox.BorderColor3 = Color3.fromRGB(255, 215, 0)
    textBox.Text = ""
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextSize = 18
    textBox.Font = Enum.Font.GothamMedium
    textBox.PlaceholderText = "Cole sua key aqui..."
    textBox.ClearTextOnFocus = false
    textBox.Parent = mainFrame
    
    local verifyBtn = Instance.new("TextButton")
    verifyBtn.Size = UDim2.new(0.4, 0, 0, 45)
    verifyBtn.Position = UDim2.new(0.3, 0, 0, 305)
    verifyBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    verifyBtn.BorderSizePixel = 0
    verifyBtn.Text = "VERIFICAR"
    verifyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    verifyBtn.TextSize = 18
    verifyBtn.Font = Enum.Font.GothamBold
    verifyBtn.Parent = mainFrame
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 30)
    status.Position = UDim2.new(0, 0, 0, 365)
    status.BackgroundTransparency = 1
    status.Text = "Aguardando key..."
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
    status.TextSize = 14
    status.Font = Enum.Font.GothamMedium
    status.Parent = mainFrame
    
    local retryInfo = Instance.new("TextLabel")
    retryInfo.Size = UDim2.new(1, 0, 0, 25)
    retryInfo.Position = UDim2.new(0, 0, 0, 400)
    retryInfo.BackgroundTransparency = 1
    retryInfo.Text = "Tentativas: 0/" .. self.maxRetries
    retryInfo.TextColor3 = Color3.fromRGB(150, 150, 150)
    retryInfo.TextSize = 12
    retryInfo.Font = Enum.Font.GothamMedium
    retryInfo.Parent = mainFrame
    
    local validInfo = Instance.new("TextLabel")
    validInfo.Size = UDim2.new(1, 0, 0, 20)
    validInfo.Position = UDim2.new(0, 0, 0, 430)
    validInfo.BackgroundTransparency = 1
    validInfo.Text = "Key valida por 24h | Renove diariamente"
    validInfo.TextColor3 = Color3.fromRGB(100, 100, 100)
    validInfo.TextSize = 11
    validInfo.Font = Enum.Font.GothamMedium
    validInfo.Parent = mainFrame
    
    local function verifyKey(key)
        if not key or key == "" then
            status.Text = "Digite uma key valida!"
            status.TextColor3 = Color3.fromRGB(255, 80, 80)
            return false
        end
        
        status.Text = "Verificando key na LootLabs..."
        status.TextColor3 = Color3.fromRGB(255, 215, 0)
        
        local isValid = false
        
        if Lootlabs_Config.Enabled then
            local verified = self:verifyWithLootlabs(key)
            if verified then
                isValid = true
            end
        end
        
        if not isValid then
            status.Text = "KEY INVALIDA! Tente novamente"
            status.TextColor3 = Color3.fromRGB(255, 80, 80)
            self.retryAttempts = self.retryAttempts + 1
            retryInfo.Text = "Tentativas: " .. self.retryAttempts .. "/" .. self.maxRetries
            
            if self.retryAttempts >= self.maxRetries then
                status.Text = "Muitas tentativas falhas!"
                status.TextColor3 = Color3.fromRGB(255, 80, 80)
                verifyBtn.Visible = false
                textBox.Visible = false
                
                local closeBtn = Instance.new("TextButton")
                closeBtn.Size = UDim2.new(0.4, 0, 0, 40)
                closeBtn.Position = UDim2.new(0.3, 0, 0, 305)
                closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                closeBtn.BorderSizePixel = 0
                closeBtn.Text = "FECHAR"
                closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                closeBtn.TextSize = 16
                closeBtn.Font = Enum.Font.GothamBold
                closeBtn.Parent = mainFrame
                
                closeBtn.MouseButton1Click:Connect(function()
                    screenGui:Destroy()
                end)
            end
            return false
        end
        
        if isValid then
            self.verified = true
            self.currentUser = self.userId
            local expiryDate = os.time() + (self.expiryHours * 3600)
            self:saveUserKey(self.userId, key, expiryDate)
            status.Text = "KEY VALIDA! (Valida por 24h)"
            status.TextColor3 = Color3.fromRGB(0, 255, 100)
            wait(0.8)
            screenGui:Destroy()
            return true
        end
        
        return false
    end
    
    verifyBtn.MouseButton1Click:Connect(function()
        local key = textBox.Text
        verifyKey(key)
    end)
    
    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local key = textBox.Text
            verifyKey(key)
        end
    end)
    
    local savedData = self:loadUserKey(self.userId)
    if savedData then
        if not self:isKeyExpired(savedData) then
            textBox.Text = savedData.key
            wait(0.5)
            verifyKey(savedData.key)
        else
            status.Text = "KEY EXPIRADA! Pegue uma nova"
            status.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
    end
    
    return screenGui
end

function KeySystem:verify()
    if self.verified then return true end
    
    local savedData = self:loadUserKey(self.userId)
    if savedData then
        if not self:isKeyExpired(savedData) then
            local verified = false
            if Lootlabs_Config.Enabled then
                verified = self:verifyWithLootlabs(savedData.key)
            end
            if verified then
                self.verified = true
                return true
            end
        else
            print("Key expirada! Pegue uma nova.")
        end
    end
    
    self:showKeyUI()
    
    while not self.verified do
        wait(0.5)
    end
    
    return self.verified
end

-- ============================================
-- 2. INTRO SCRIPT GOGO
-- ============================================
local function showIntro()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Intro"
    screenGui.Parent = game:GetService("CoreGui")
    screenGui.ResetOnSpawn = false
    
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0
    background.BorderSizePixel = 0
    background.Parent = screenGui
    
    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(1, 0, 1, 0)
    glow.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    glow.BackgroundTransparency = 0.95
    glow.BorderSizePixel = 0
    glow.Parent = background
    
    local scriptName = Instance.new("TextLabel")
    scriptName.Size = UDim2.new(1, 0, 0, 50)
    scriptName.Position = UDim2.new(0, 0, 0.2, 0)
    scriptName.BackgroundTransparency = 1
    scriptName.Text = "SCRIPT GOGO"
    scriptName.TextColor3 = Color3.fromRGB(255, 215, 0)
    scriptName.TextSize = 50
    scriptName.Font = Enum.Font.GothamBold
    scriptName.TextScaled = true
    scriptName.Parent = background
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0, 40)
    subtitle.Position = UDim2.new(0, 0, 0.35, 0)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "GODHUMAN FARMER ULTIMATE"
    subtitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    subtitle.TextSize = 30
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.TextScaled = true
    subtitle.TextTransparency = 0.5
    subtitle.Parent = background
    
    local version = Instance.new("TextLabel")
    version.Size = UDim2.new(1, 0, 0, 25)
    version.Position = UDim2.new(0, 0, 0.45, 0)
    version.BackgroundTransparency = 1
    version.Text = "V9.0 - LOOTLABS KEY 24H"
    version.TextColor3 = Color3.fromRGB(255, 215, 0)
    version.TextSize = 16
    version.Font = Enum.Font.GothamMedium
    version.TextScaled = true
    version.TextTransparency = 0.7
    version.Parent = background
    
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0.5, 0, 0, 2)
    line.Position = UDim2.new(0.25, 0, 0.52, 0)
    line.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    line.BackgroundTransparency = 0.5
    line.BorderSizePixel = 0
    line.Parent = background
    
    local loadText = Instance.new("TextLabel")
    loadText.Size = UDim2.new(1, 0, 0, 30)
    loadText.Position = UDim2.new(0, 0, 0.65, 0)
    loadText.BackgroundTransparency = 1
    loadText.Text = "CARREGANDO SISTEMA DE MASTERIZACAO..."
    loadText.TextColor3 = Color3.fromRGB(255, 255, 255)
    loadText.TextSize = 16
    loadText.Font = Enum.Font.GothamMedium
    loadText.TextTransparency = 0.5
    loadText.Parent = background
    
    local loadBarBg = Instance.new("Frame")
    loadBarBg.Size = UDim2.new(0.4, 0, 0, 4)
    loadBarBg.Position = UDim2.new(0.3, 0, 0.72, 0)
    loadBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    loadBarBg.BorderSizePixel = 0
    loadBarBg.Parent = background
    
    local loadBar = Instance.new("Frame")
    loadBar.Size = UDim2.new(0, 0, 1, 0)
    loadBar.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    loadBar.BorderSizePixel = 0
    loadBar.Parent = loadBarBg
    
    local credits = Instance.new("TextLabel")
    credits.Size = UDim2.new(1, 0, 0, 20)
    credits.Position = UDim2.new(0, 0, 0.88, 0)
    credits.BackgroundTransparency = 1
    credits.Text = "POWERED BY SCRIPT GOGO"
    credits.TextColor3 = Color3.fromRGB(100, 100, 100)
    credits.TextSize = 12
    credits.Font = Enum.Font.GothamMedium
    credits.TextTransparency = 0.5
    credits.Parent = background
    
    local startTime = tick()
    local duration = 3.5
    
    game:GetService("RunService").RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        local progress = math.min(elapsed / duration, 1)
        
        scriptName.TextTransparency = 1 - progress
        scriptName.Position = UDim2.new(0, 0, 0.2 - (1 - progress) * 0.05, 0)
        subtitle.TextTransparency = 0.5 - progress * 0.5
        loadBar.Size = UDim2.new(progress, 0, 1, 0)
        glow.BackgroundTransparency = 0.95 - progress * 0.3
        
        if progress >= 1 then
            wait(0.5)
            screenGui:Destroy()
        end
    end)
    
    wait(4)
    return true
end

-- ============================================
-- 3. OTIMIZACAO (FPS BOOST + REMOVER FOG)
-- ============================================
local function optimizeGame()
    pcall(function()
        print("Aplicando otimizacoes...")
        
        local lighting = game:GetService("Lighting")
        if lighting then
            lighting.FogEnd = 100000
            lighting.FogStart = 100000
            lighting.FogColor = Color3.fromRGB(0, 0, 0)
            lighting.Ambient = Color3.fromRGB(100, 100, 100)
            lighting.Brightness = 1
            lighting.GlobalShadows = false
            lighting.ClockTime = 12
        end
        
        for _, v in pairs(lighting:GetChildren()) do
            if v:IsA("Atmosphere") then
                v:Destroy()
            end
        end
        
        local settings = UserSettings()
        local quality = settings:GetService("UserGameSettings")
        if quality then
            quality.MasterVolume = 0
            quality.QualityLevel = 1
        end
        
        for _, v in pairs(game.Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
                v.Enabled = false
            end
            if v:IsA("Decal") and not v.Name:find("Important") then
                v:Destroy()
            end
        end
        
        collectgarbage()
        print("Otimizacoes aplicadas!")
    end)
end

-- ============================================
-- 4. ANTI-CHEAT BYPASS
-- ============================================
local AntiCheat = {}
AntiCheat.__index = AntiCheat

function AntiCheat.new()
    local self = setmetatable({}, AntiCheat)
    self.delayBase = 0.1
    self.delayVariation = 0.05
    return self
end

function AntiCheat:getRandomDelay()
    return self.delayBase + math.random() * self.delayVariation
end

function AntiCheat:humanizeAction(callback)
    pcall(function()
        local delay = self:getRandomDelay()
        wait(delay)
        if math.random(1, 10) == 1 then
            wait(math.random(1, 5) * 0.01)
        end
        callback()
    end)
end

-- ============================================
-- 5. AGENTE PRINCIPAL
-- ============================================
local Agent = {}
Agent.__index = Agent

function Agent.new()
    local self = setmetatable({}, Agent)
    
    self.keySystem = KeySystem.new()
    
    print("Verificando key LootLabs 24h...")
    print("Seu ID: " .. self.keySystem.userId)
    
    if not self.keySystem:verify() then
        print("Key invalida ou expirada!")
        return nil
    end
    print("Key verificada com sucesso!")
    
    self.antiCheat = AntiCheat.new()
    self.fileName = "scriptgogo_data.json"
    self.state = self:loadState()
    
    pcall(function()
        self.player = game.Players.LocalPlayer
        self.character = self.player.Character or self.player.CharacterAdded:Wait()
        self.humanoid = self.character:WaitForChild("Humanoid")
        self.rootPart = self.character:WaitForChild("HumanoidRootPart")
    end)
    
    self.httpService = game:GetService("HttpService")
    self.tweenService = game:GetService("TweenService")
    self.replicatedStorage = game:GetService("ReplicatedStorage")
    
    self.maxLevel = 2800
    self.fragmentsNeeded = 16500
    self.masteryV1 = 400
    self.masteryV2 = 500
    
    self.fightingStyles = {
        {name = "Combat", v1 = true, sea = "First Sea", masteryRequired = 400, unlocked = false, mastery = 0, obtained = false},
        {name = "Water Kung Fu", v1 = true, sea = "First Sea", masteryRequired = 400, unlocked = false, mastery = 0, obtained = false},
        {name = "Electric", v1 = true, sea = "First Sea", masteryRequired = 400, unlocked = false, mastery = 0, obtained = false},
        {name = "Dragon Breath", v1 = true, sea = "Second Sea", masteryRequired = 400, unlocked = false, mastery = 0, obtained = false},
        {name = "Superhuman", v1 = false, sea = "Second Sea", masteryRequired = 500, unlocked = false, mastery = 0, obtained = false, requires = {"Combat", "Water Kung Fu", "Electric"}},
        {name = "Death Step", v1 = false, sea = "Second Sea", masteryRequired = 500, unlocked = false, mastery = 0, obtained = false, requires = {"Combat", "Water Kung Fu", "Electric"}},
        {name = "Sharkman Karate", v1 = false, sea = "Third Sea", masteryRequired = 500, unlocked = false, mastery = 0, obtained = false, requires = {"Water Kung Fu", "Dragon Breath"}},
        {name = "Electric Claw", v1 = false, sea = "Third Sea", masteryRequired = 500, unlocked = false, mastery = 0, obtained = false, requires = {"Electric", "Dragon Breath"}},
        {name = "Dragon Talon", v1 = false, sea = "Third Sea", masteryRequired = 500, unlocked = false, mastery = 0, obtained = false, requires = {"Dragon Breath", "Superhuman"}}
    }
    
    self.godhumanRequirements = {
        styles = {"Superhuman", "Death Step", "Sharkman Karate", "Electric Claw", "Dragon Talon"},
        fragmentsNeeded = 16500,
        levelRequired = 2000
    }
    
    self.haki = {unlocked = false, mastery = 0, active = false}
    self.masteryProgress = {}
    
    return self
end

function Agent:loadState()
    local success, data = pcall(function()
        if isfile(self.fileName) then
            local content = readfile(self.fileName)
            return game:GetService("HttpService"):JSONDecode(content)
        end
        return nil
    end)
    if success and data then return data end
    return {
        level = 1, xp = 0, fragments = 0, godhuman = false,
        raidsCompleted = 0, currentSea = "First Sea",
        currentStyle = nil, uptime = 0, lastRaidTime = 0,
        questsCompleted = 0,
        haki = {unlocked = false, mastery = 0, level = 0},
        masteryProgress = {},
        stylesObtained = {},
        settings = {
            autoFarm = true,
            autoQuest = true,
            autoRaid = true,
            autoMastery = true,
            autoSpinFruit = true,
            autoTeleportFruit = true,
            autoSwitchSea = true,
            autoHaki = true,
            autoMasteryAllStyles = true
        }
    }
end

function Agent:saveState()
    pcall(function()
        local json = self.httpService:JSONEncode(self.state)
        writefile(self.fileName, json)
    end)
end

function Agent:getStyleMastery(styleName)
    local mastery = 0
    pcall(function()
        local data = self.player:FindFirstChild("Data")
        if data then
            local m = data:FindFirstChild(styleName .. "Mastery")
            if m then
                mastery = m.Value
            end
        end
    end)
    return mastery
end

function Agent:getStyleData(styleName)
    for _, style in ipairs(self.fightingStyles) do
        if style.name == styleName then
            return style
        end
    end
    return nil
end

function Agent:hasStyleRequirements(style)
    if not style.requires then return true end
    for _, reqName in ipairs(style.requires) do
        local reqStyle = self:getStyleData(reqName)
        if not reqStyle or not reqStyle.obtained then
            return false
        end
        local mastery = self:getStyleMastery(reqName)
        if mastery < (reqStyle.v1 and 400 or 500) then
            return false
        end
    end
    return true
end

function Agent:obtainStyle(styleName)
    pcall(function()
        local style = self:getStyleData(styleName)
        if not style or style.obtained then return end
        
        if style.sea ~= self.state.currentSea then
            print("Precisa estar no " .. style.sea .. " para obter " .. styleName)
            return
        end
        
        if not style.v1 and not self:hasStyleRequirements(style) then
            print("Faltam pre-requisitos para " .. styleName)
            return
        end
        
        self.antiCheat:humanizeAction(function()
            self.replicatedStorage.Remotes.CommF_:InvokeServer("Buy", styleName)
        end)
        
        style.obtained = true
        self.state.stylesObtained[styleName] = true
        self:saveState()
        print("Estilo obtido: " .. styleName)
    end)
end

function Agent:equipStyle(styleName)
    pcall(function()
        self.antiCheat:humanizeAction(function()
            self.replicatedStorage.Remotes.CommF_:InvokeServer("Equip", styleName)
        end)
        self.state.currentStyle = styleName
        self:saveState()
        print("Estilo equipado: " .. styleName)
    end)
end

function Agent:getNextStyleToMaster()
    for _, requiredStyle in ipairs(self.godhumanRequirements.styles) do
        local styleData = self:getStyleData(requiredStyle)
        if styleData then
            local mastery = self:getStyleMastery(requiredStyle)
            local required = styleData.v1 and self.masteryV1 or self.masteryV2
            
            if not styleData.obtained then
                if self:canObtainStyle(styleData) then
                    return requiredStyle
                end
            elseif mastery < required then
                return requiredStyle
            end
        end
    end
    
    for _, style in ipairs(self.fightingStyles) do
        if style.v1 then
            local mastery = self:getStyleMastery(style.name)
            if not style.obtained and self:canObtainStyle(style) then
                return style.name
            elseif style.obtained and mastery < self.masteryV1 then
                return style.name
            end
        end
    end
    
    for _, style in ipairs(self.fightingStyles) do
        if not style.v1 then
            local mastery = self:getStyleMastery(style.name)
            if not style.obtained and self:canObtainStyle(style) then
                return style.name
            elseif style.obtained and mastery < self.masteryV2 then
                return style.name
            end
        end
    end
    
    return nil
end

function Agent:canObtainStyle(style)
    if style.sea ~= self.state.currentSea then
        return false
    end
    if not style.v1 and not self:hasStyleRequirements(style) then
        return false
    end
    return true
end

function Agent:autoMasteryAllStyles()
    if not self.state.settings.autoMasteryAllStyles then return end
    if self.state.godhuman then 
        print("GodHuman ja desbloqueado! Mastery completa.")
        return 
    end
    
    local allMastered = true
    for _, style in ipairs(self.fightingStyles) do
        local mastery = self:getStyleMastery(style.name)
        local required = style.v1 and self.masteryV1 or self.masteryV2
        if style.obtained and mastery < required then
            allMastered = false
            break
        end
        if not style.obtained then
            allMastered = false
            break
        end
    end
    
    if allMastered then
        print("Todos os estilos masterizados! Iniciando GodHuman...")
        self:unlockGodHuman()
        return
    end
    
    local nextStyle = self:getNextStyleToMaster()
    if not nextStyle then
        print("Nenhum estilo disponivel para masterizar.")
        return
    end
    
    local styleData = self:getStyleData(nextStyle)
    if not styleData then return end
    
    if not styleData.obtained then
        self:obtainStyle(nextStyle)
        wait(1)
        if not styleData.obtained then
            print("Nao foi possivel obter " .. nextStyle .. ". Movendo para proximo...")
            return
        end
    end
    
    if self.state.currentStyle ~= nextStyle then
        self:equipStyle(nextStyle)
        wait(0.5)
    end
    
    local currentMastery = self:getStyleMastery(nextStyle)
    local requiredMastery = styleData.v1 and self.masteryV1 or self.masteryV2
    
    if currentMastery < requiredMastery then
        self:fastAttack()
    else
        styleData.unlocked = true
        self:saveState()
        print(nextStyle .. " masterizado! (" .. currentMastery .. "/" .. requiredMastery .. ")")
    end
end

function Agent:unlockGodHuman()
    pcall(function()
        if self.state.godhuman then return end
        
        local allStylesMastered = true
        for _, styleName in ipairs(self.godhumanRequirements.styles) do
            local style = self:getStyleData(styleName)
            if not style or not style.obtained then
                allStylesMastered = false
                break
            end
            local mastery = self:getStyleMastery(styleName)
            if mastery < 500 then
                allStylesMastered = false
                break
            end
        end
        
        if not allStylesMastered then
            print("Ainda faltam estilos para GodHuman.")
            return
        end
        
        if self.state.fragments < self.fragmentsNeeded then
            print("Fragmentos insuficientes: " .. self.state.fragments .. "/" .. self.fragmentsNeeded)
            self:autoRaid()
            return
        end
        
        if self.state.level < 2000 then
            print("Nivel insuficiente: " .. self.state.level .. "/2000")
            return
        end
        
        self.antiCheat:humanizeAction(function()
            self.replicatedStorage.Remotes.CommF_:InvokeServer("Buy", "GodHuman")
        end)
        
        self.state.godhuman = true
        self:saveState()
        print("GODHUMAN DESBLOQUEADO COM SUCESSO!")
    end)
end

function Agent:getNearbyEnemies(radius)
    local enemies = {}
    local charPos = self.rootPart.Position
    pcall(function()
        for _, v in pairs(game.Workspace:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
                if v.Name ~= self.character.Name and v.Humanoid.Health > 0 then
                    local dist = (v.HumanoidRootPart.Position - charPos).Magnitude
                    if dist <= radius then
                        table.insert(enemies, v)
                    end
                end
            end
        end
    end)
    return enemies
end

function Agent:getXPMultiplier()
    local sea = self.state.currentSea
    if sea == "First Sea" then return 1
    elseif sea == "Second Sea" then return 1.5
    else return 2 end
end

function Agent:checkLevelUp()
    local needed = self.state.level * 100 + 50
    while (self.state.xp or 0) >= needed and self.state.level < self.maxLevel do
        self.state.xp = self.state.xp - needed
        self.state.level = self.state.level + 1
        needed = self.state.level * 100 + 50
        print("Level: " .. self.state.level .. "/" .. self.maxLevel)
        self:saveState()
        if self.state.settings.autoSwitchSea then
            if self.state.level >= 700 and self.state.currentSea == "First Sea" then
                self:switchSea("Second Sea")
            elseif self.state.level >= 1500 and self.state.currentSea == "Second Sea" then
                self:switchSea("Third Sea")
            end
        end
    end
end

function Agent:teleportTo(position)
    pcall(function()
        self.rootPart.CFrame = CFrame.new(position)
    end)
end

function Agent:switchSea(sea)
    pcall(function()
        if self.state.currentSea == sea then return end
        local seas = {
            ["Second Sea"] = Vector3.new(1200, 150, 8000),
            ["Third Sea"] = Vector3.new(-6000, 150, 6000)
        }
        local pos = seas[sea]
        if pos then
            self:teleportTo(pos)
            self.state.currentSea = sea
            print("Mudou para: " .. sea)
            self:saveState()
        end
    end)
end

function Agent:moveToRandomIsland()
    local islands = {
        ["First Sea"] = {
            Vector3.new(-1200, 80, 2800),
            Vector3.new(300, 50, 4500),
            Vector3.new(-4500, 100, -2500)
        },
        ["Second Sea"] = {
            Vector3.new(1200, 150, 8000),
            Vector3.new(5000, 500, 0),
            Vector3.new(-3000, 100, 7000)
        },
        ["Third Sea"] = {
            Vector3.new(0, 400, 0),
            Vector3.new(3000, 300, 3000),
            Vector3.new(-6000, 150, 6000)
        }
    }
    local seaIslands = islands[self.state.currentSea] or islands["First Sea"]
    local pos = seaIslands[math.random(1, #seaIslands)]
    if pos then
        self:teleportTo(pos)
    end
end

function Agent:fastAttack()
    pcall(function()
        if self.state.settings.autoHaki then
            self:autoHaki()
        end
        
        local enemies = self:getNearbyEnemies(80)
        if #enemies == 0 then
            self:moveToRandomIsland()
            return
        end
        
        local target = enemies[1]
        self:teleportTo(target.HumanoidRootPart.Position + Vector3.new(0, 5, 0))
        
        local attacks = math.random(2, 5)
        for i = 1, attacks do
            self.antiCheat:humanizeAction(function()
                local args = {[1] = target.HumanoidRootPart}
                self.replicatedStorage.Remotes.CommF_:InvokeServer("Attack", args)
            end)
            wait(0.085 + math.random(0, 5) * 0.001)
        end
        
        local xpGain = 50 * self:getXPMultiplier()
        self.state.xp = (self.state.xp or 0) + xpGain
        self:checkLevelUp()
        
        local currentStyle = self.state.currentStyle
        if currentStyle then
            local mastery = self:getStyleMastery(currentStyle)
            self.state.masteryProgress[currentStyle] = mastery
            self:saveState()
        end
    end)
end

function Agent:autoHaki()
    if not self.state.settings.autoHaki then return end
    if not self.state.haki.unlocked then
        if self.state.level >= 50 then
            pcall(function()
                self.replicatedStorage.Remotes.CommF_:InvokeServer("Haki", "Unlock")
                wait(1)
                if self.character:FindFirstChild("Haki") then
                    self.state.haki.unlocked = true
                    self:saveState()
                    print("Haki desbloqueado!")
                end
            end)
        end
        return
    end
    
    pcall(function()
        local hakiActive = false
        local hakiAbility = self.character:FindFirstChild("Haki")
        if hakiAbility then
            hakiActive = hakiAbility.Enabled
        end
        
        if not hakiActive then
            self.antiCheat:humanizeAction(function()
                self.replicatedStorage.Remotes.CommF_:InvokeServer("Haki", "Enable")
            end)
            self.haki.active = true
            print("Haki ativado!")
        end
    end)
end

function Agent:autoRaid()
    if not self.state.settings.autoRaid then return end
    if self.state.godhuman then return end
    if self.state.level < 700 then return end
    
    local currentTime = os.time()
    if currentTime - self.state.lastRaidTime < 120 then return end
    
    pcall(function()
        print("Iniciando Raid Ice...")
        self.replicatedStorage.Remotes.CommF_:InvokeServer("Raid", "Start", "Ice")
        wait(2)
        
        local raidTime = 0
        while raidTime < 180 do
            local enemies = self:getNearbyEnemies(150)
            if #enemies > 0 then
                self:fastAttack()
            end
            raidTime = raidTime + 1
            wait(1)
        end
        
        self.replicatedStorage.Remotes.CommF_:InvokeServer("Raid", "Complete")
        local fragmentsEarned = 300 + math.random(0, 150)
        self.state.fragments = (self.state.fragments or 0) + fragmentsEarned
        self.state.raidsCompleted = (self.state.raidsCompleted or 0) + 1
        self.state.lastRaidTime = os.time()
        
        print("Raid completada! +" .. fragmentsEarned .. " fragmentos")
        print("Total: " .. self.state.fragments .. "/" .. self.fragmentsNeeded)
        self:saveState()
    end)
end

function Agent:autoQuest()
    if not self.state.settings.autoQuest then return end
    
    pcall(function()
        local questData = self.replicatedStorage.Remotes.CommF_:InvokeServer("Quest", "Check")
        
        if not questData or not questData.Active then
            local npcs = {}
            for _, v in pairs(game.Workspace:GetChildren()) do
                if v:IsA("Model") and v:FindFirstChild("Humanoid") and 
                   (v.Name:find("NPC") or v.Name:find("Quest")) then
                    table.insert(npcs, v)
                end
            end
            
            if #npcs > 0 then
                local npc = npcs[math.random(1, #npcs)]
                self:teleportTo(npc.HumanoidRootPart.Position + Vector3.new(0, 5, 0))
                wait(1)
                self.replicatedStorage.Remotes.CommF_:InvokeServer("Quest", "Start")
                print("Quest aceita!")
            end
        else
            self:fastAttack()
            
            local progress = self.replicatedStorage.Remotes.CommF_:InvokeServer("Quest", "Check")
            if progress and progress.Complete then
                self.replicatedStorage.Remotes.CommF_:InvokeServer("Quest", "Complete")
                self.state.questsCompleted = (self.state.questsCompleted or 0) + 1
                local bonusXP = 200 * self:getXPMultiplier()
                self.state.xp = (self.state.xp or 0) + bonusXP
                self:checkLevelUp()
                self:saveState()
                print("Quest completada! +" .. bonusXP .. " XP")
            end
        end
    end)
end

function Agent:autoSpinFruit()
    if not self.state.settings.autoSpinFruit then return end
    
    pcall(function()
        local spins = self.player.Data.Spins.Value
        if spins > 0 then
            self.antiCheat:humanizeAction(function()
                local fruit = self.replicatedStorage.Remotes.CommF_:InvokeServer("Spin", "Spin")
                if fruit then
                    print("Fruta obtida: " .. fruit)
                end
            end)
        end
    end)
end

function Agent:autoTeleportFruit()
    if not self.state.settings.autoTeleportFruit then return end
    
    pcall(function()
        local legendaryFruits = {
            "Dragon", "Leopard", "Dough", "Venom", "Spirit",
            "Kitsune", "Yeti", "Gravity", "Shadow", "Light"
        }
        
        for _, v in pairs(game.Workspace:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("Fruit") then
                local fruitName = v.Name
                local isLegendary = false
                
                for _, f in ipairs(legendaryFruits) do
                    if fruitName:find(f) then
                        isLegendary = true
                        break
                    end
                end
                
                if isLegendary then
                    self.antiCheat:humanizeAction(function()
                        local pos = v.HumanoidRootPart.Position
                        self:teleportTo(pos + Vector3.new(0, 5, 0))
                        local click = v:FindFirstChild("ClickDetector")
                        if click then
                            fireclickdetector(click)
                            print("Fruta lendaria coletada: " .. fruitName)
                        end
                    end)
                end
            end
        end
    end)
end

function Agent:decidePriority()
    if not self.state.godhuman then
        if self.state.settings.autoMasteryAllStyles then
            self:autoMasteryAllStyles()
            local currentStyle = self.state.currentStyle
            if currentStyle then
                local mastery = self:getStyleMastery(currentStyle)
                local styleData = self:getStyleData(currentStyle)
                if styleData and mastery < (styleData.v1 and self.masteryV1 or self.masteryV2) then
                    return
                end
            end
        end
        
        if self.state.fragments < self.fragmentsNeeded and self.state.level >= 700 then
            self:autoRaid()
            return
        end
        
        if self.state.level < 2000 then
            self:fastAttack()
            self:autoQuest()
            return
        end
        
        if self.state.fragments >= self.fragmentsNeeded and self.state.level >= 2000 then
            self:unlockGodHuman()
            return
        end
    end
    
    if self.state.level < self.maxLevel then
        self:fastAttack()
        self:autoQuest()
        return
    end
    
    self:autoSpinFruit()
    self:autoTeleportFruit()
end

function Agent:run()
    print("SCRIPT GOGO - EM EXECUCAO!")
    print("Kaitun Mode: Masterizando todos os estilos...")
    print("Key LootLabs 24h ativada")
    
    while true do
        pcall(function()
            self:decidePriority()
            self:autoHaki()
            self:saveState()
            self.state.uptime = (self.state.uptime or 0) + 1
        end)
        wait(1)
    end
end

-- ============================================
-- 6. INICIALIZACAO
-- ============================================
local function main()
    local player = game.Players.LocalPlayer
    if not player then
        print("Aguardando jogador...")
        repeat wait(1) until game.Players.LocalPlayer
        print("Jogador encontrado!")
    end
    
    showIntro()
    optimizeGame()
    
    local agent = Agent.new()
    if agent then
        agent:run()
    else
        print("Falha ao inicializar o agente. Verifique sua key.")
    end
end

local success, err = pcall(main)
if not success then
    print("ERRO: " .. tostring(err))
    print("Tente reiniciar o executor ou o jogo.")
end

print("SCRIPT GOGO - FINALIZADO")
