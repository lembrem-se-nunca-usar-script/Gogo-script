-- ============================================
-- SCRIPT GOGO V21.0 
-- ============================================
-- ALL FEATURES:
-- - Full GUI with tabs, bars, buttons, logs
-- - Emergency mode
-- - File logging system
-- - Auto Save (30s)
-- - Data cache
-- - Webhook notifications
-- - Auto Redeem codes (2x XP)
-- - Daily key (LootLabs) + Permanent key (UserId)
-- - Automatic permanent key generator (admin mode)
-- - Auto-update (GitHub, no player kick)
-- - Auto-protection (detection + safe mode)
-- - Async AI (no freezes)
-- - Farm, Mastery, GodHuman, Raids, Quest, Haki, Fruits
-- ============================================

print("SCRIPT GOGO - STARTING...")

local Config = {
    REPO_URL = "https://raw.githubusercontent.com/SEU_USUARIO/Gogo-script/main/",
    VERSION_FILE = "version.txt",
    SCRIPT_FILE = "Gogo-script.lua",
    LOCAL_VERSION_FILE = "scriptgogo_version.txt",
    LOCAL_UPDATE_FILE = "scriptgogo_update.lua",
    CACHE_TTL = 3600,
    SAVE_INTERVAL = 30,
    LOG_FILE = "scriptgogo_log.txt",
}

local Lootlabs_Config = {
    Enabled = true,
    API_Key = "SUA_CHAVE_DE_API_AQUI",
    Link = "URL_DO_SEU_LINK_LOOTLABS",
    API_URL = "https://api.lootlabs.xyz/verify",
    ExpiryHours = 24
}

local KeyConfig = {
    PERMANENT_KEY_PREFIX = "GOGO-PERM-",
    PERMANENT_LIST_URL = "https://raw.githubusercontent.com/SEU_USUARIO/Gogo-script/main/perm_keys.json",
    USE_PREFIX = true,
    USE_EXTERNAL_LIST = true,
    EXTERNAL_LIST_CACHE = 3600,
}

local WebhookConfig = {
    URL = "",
    Enabled = false,
}

local CodeConfig = {
    Enabled = true,
    CheckInterval = 60,
    CodesURL = "",
    FixedCodes = {
        "KITT_RESET", "Sub2Officiel", "Starcodeheo", "Bluxxy",
        "Fudd10", "Bignews", "Noob2Pro", "2MillionVisits"
    }
}

local ADMIN_MODE = false

-- ============================================
-- WEBHOOK SYSTEM
-- ============================================
local Webhook = {}
Webhook.__index = Webhook

function Webhook.send(message)
    if not WebhookConfig.Enabled or WebhookConfig.URL == "" then return end
    pcall(function()
        local data = {
            content = message,
            username = "Script GOGO",
        }
        local json = game:GetService("HttpService"):JSONEncode(data)
        if syn and syn.request then
            syn.request({
                Url = WebhookConfig.URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = json
            })
        end
    end)
end

local Logger = {}
Logger.__index = Logger

function Logger.log(msg)
    pcall(function()
        local time = os.date("%Y-%m-%d %H:%M:%S")
        local line = "[" .. time .. "] " .. msg .. "\n"
        local content = ""
        if isfile(Config.LOG_FILE) then
            content = readfile(Config.LOG_FILE)
        end
        writefile(Config.LOG_FILE, content .. line)
    end)
end

function Logger.clear()
    pcall(function()
        writefile(Config.LOG_FILE, "")
    end)
end

local ProtectionSystem = {}
ProtectionSystem.__index = ProtectionSystem

function ProtectionSystem.new()
    local self = setmetatable({}, ProtectionSystem)
    self.detectedFile = "scriptgogo_detected.txt"
    self.safeMode = false
    self.lastBanTime = 0
    self.banCooldown = 3600
    return self
end

function ProtectionSystem:checkDetection()
    local detected = false
    pcall(function()
        if isfile(self.detectedFile) then
            local content = readfile(self.detectedFile)
            local data = game:GetService("HttpService"):JSONDecode(content)
            if data and data.timestamp then
                local now = os.time()
                if now - data.timestamp < self.banCooldown then
                    detected = true
                    self.lastBanTime = data.timestamp
                    self.safeMode = true
                end
            end
        end
    end)
    return detected
end

function ProtectionSystem:registerDetection(reason)
    pcall(function()
        local data = { timestamp = os.time(), reason = reason or "Unknown", version = "21.0" }
        local json = game:GetService("HttpService"):JSONEncode(data)
        writefile(self.detectedFile, json)
        self.safeMode = true
        self.lastBanTime = os.time()
        Webhook.send("DETECTION REGISTERED: " .. reason)
        Logger.log("DETECTION: " .. reason)
    end)
end

function ProtectionSystem:clearDetection()
    pcall(function()
        if isfile(self.detectedFile) then
            writefile(self.detectedFile, "")
        end
        self.safeMode = false
        Logger.log("Detection record cleared.")
    end)
end

function ProtectionSystem:loadEmergencyScript()
    local emergencyContent = nil
    pcall(function()
        local url = Config.REPO_URL .. "Gogo-script_safe.lua"
        emergencyContent = game:HttpGet(url)
    end)
    if emergencyContent and #emergencyContent > 100 then
        return loadstring(emergencyContent)
    end
    return nil
end

local UpdateSystem = {}
UpdateSystem.__index = UpdateSystem

function UpdateSystem.new()
    local self = setmetatable({}, UpdateSystem)
    self.currentVersion = self:getLocalVersion()
    self.latestVersion = nil
    self.updateAvailable = false
    self.updateDownloaded = false
    self.lastCheck = 0
    return self
end

function UpdateSystem:getLocalVersion()
    local version = "0.0.0"
    pcall(function()
        if isfile(Config.LOCAL_VERSION_FILE) then
            local content = readfile(Config.LOCAL_VERSION_FILE)
            if content and content ~= "" then
                version = content
            end
        end
    end)
    return version
end

function UpdateSystem:saveLocalVersion(version)
    pcall(function() writefile(Config.LOCAL_VERSION_FILE, version) end)
end

function UpdateSystem:checkForUpdate(force)
    local now = os.time()
    if not force and (now - self.lastCheck) < Config.CACHE_TTL then
        return self.updateAvailable
    end
    self.lastCheck = now

    local success, remoteVersion = pcall(function()
        local url = Config.REPO_URL .. Config.VERSION_FILE
        return game:HttpGet(url)
    end)

    if success and remoteVersion and remoteVersion ~= "" then
        remoteVersion = string.gsub(remoteVersion, "%s+", "")
        self.latestVersion = remoteVersion
        if remoteVersion ~= self.currentVersion then
            self.updateAvailable = true
            Logger.log("New version available: " .. remoteVersion)
            Webhook.send("New version available: " .. remoteVersion)
        else
            self.updateAvailable = false
        end
    else
        self.updateAvailable = false
    end
    return self.updateAvailable
end

function UpdateSystem:downloadUpdate()
    if not self.updateAvailable then return false end
    local success, scriptContent = pcall(function()
        return game:HttpGet(Config.REPO_URL .. Config.SCRIPT_FILE)
    end)
    if success and scriptContent and #scriptContent > 100 then
        pcall(function()
            writefile(Config.LOCAL_UPDATE_FILE, scriptContent)
            self:saveLocalVersion(self.latestVersion)
            self.updateDownloaded = true
            Logger.log("Update downloaded: V" .. self.latestVersion)
            Webhook.send("Update downloaded: V" .. self.latestVersion)
        end)
        return true
    end
    return false
end

function UpdateSystem:loadScript()
    local updateContent = nil
    pcall(function()
        if isfile(Config.LOCAL_UPDATE_FILE) then
            updateContent = readfile(Config.LOCAL_UPDATE_FILE)
        end
    end)

    if updateContent and #updateContent > 100 then
        pcall(function() writefile(Config.LOCAL_UPDATE_FILE, "") end)
        self.currentVersion = self.latestVersion
        return loadstring(updateContent)
    else
        local scriptContent = nil
        pcall(function()
            scriptContent = game:HttpGet(Config.REPO_URL .. Config.SCRIPT_FILE)
        end)
        if scriptContent and #scriptContent > 100 then
            return loadstring(scriptContent)
        end
    end
    return nil
end

local KeySystem = {}
KeySystem.__index = KeySystem

function KeySystem.new()
    local self = setmetatable({}, KeySystem)
    self.keyFile = "scriptgogo_key.txt"
    self.verified = false
    self.retryAttempts = 0
    self.maxRetries = 5
    self.expiryHours = 24
    self.currentUser = nil
    self.userId = self:generateUserId()
    self.isPermanent = false
    self.permanentCache = {}
    self.lastPermanentCheck = 0
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

function KeySystem:isKeyExpired(savedData)
    if savedData and savedData.isPermanent then
        return false
    end
    if not savedData or not savedData.expiryDate then
        return true
    end
    return os.time() > savedData.expiryDate
end

function KeySystem:saveUserKey(userId, key, expiryDate, isPermanent)
    pcall(function()
        local data = {
            userId = userId,
            key = key,
            date = os.date("%Y-%m-%d %H:%M:%S"),
            expiryDate = expiryDate or (os.time() + (24 * 3600)),
            isPermanent = isPermanent or false
        }
        local json = game:GetService("HttpService"):JSONEncode(data)
        writefile(self.keyFile, json)
        Logger.log("Key saved: " .. (isPermanent and "PERMANENT" or "DAILY"))
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

function KeySystem:isPermanentKey(key)
    if KeyConfig.USE_EXTERNAL_LIST then
        local now = os.time()
        if now - self.lastPermanentCheck > KeyConfig.EXTERNAL_LIST_CACHE then
            self.lastPermanentCheck = now
            pcall(function()
                local content = game:HttpGet(KeyConfig.PERMANENT_LIST_URL)
                local data = game:GetService("HttpService"):JSONDecode(content)
                if data and type(data) == "table" then
                    self.permanentCache = data
                end
            end)
        end
        local player = game.Players.LocalPlayer
        local userId = tostring(player.UserId)
        if self.permanentCache[key] and self.permanentCache[key] == userId then
            return true
        end
    end
    if KeyConfig.USE_PREFIX and not KeyConfig.USE_EXTERNAL_LIST then
        if string.sub(key, 1, #KeyConfig.PERMANENT_KEY_PREFIX) == KeyConfig.PERMANENT_KEY_PREFIX then
            return true
        end
    end
    return false
end

function KeySystem:verifyWithLootlabs(key)
    if self:isPermanentKey(key) then
        self.isPermanent = true
        return true
    end
    if not Lootlabs_Config.Enabled then
        return false
    end
    local success, response = pcall(function()
        local data = { key = key, api_token = Lootlabs_Config.API_Key }
        local jsonData = game:GetService("HttpService"):JSONEncode(data)
        if syn and syn.request then
            return syn.request({
                Url = Lootlabs_Config.API_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
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
    mainFrame.Size = UDim2.new(0, 450, 0, 520)
    mainFrame.Position = UDim2.new(0.5, -225, 0.5, -260)
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
    userIdLabel.Text = "YOUR ID: " .. self.userId
    userIdLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    userIdLabel.TextSize = 13
    userIdLabel.Font = Enum.Font.GothamMedium
    userIdLabel.Parent = mainFrame

    local expiryLabel = Instance.new("TextLabel")
    expiryLabel.Size = UDim2.new(1, 0, 0, 25)
    expiryLabel.Position = UDim2.new(0, 0, 0, 85)
    expiryLabel.BackgroundTransparency = 1
    expiryLabel.Text = "KEY TYPES: DAILY (24H) OR PERMANENT"
    expiryLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    expiryLabel.TextSize = 13
    expiryLabel.Font = Enum.Font.GothamBold
    expiryLabel.Parent = mainFrame

    local dateLabel = Instance.new("TextLabel")
    dateLabel.Size = UDim2.new(1, 0, 0, 20)
    dateLabel.Position = UDim2.new(0, 0, 0, 110)
    dateLabel.BackgroundTransparency = 1
    dateLabel.Text = "Date: " .. os.date("%d/%m/%Y %H:%M")
    dateLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    dateLabel.TextSize = 12
    dateLabel.Font = Enum.Font.GothamMedium
    dateLabel.Parent = mainFrame

    local instructions = Instance.new("TextLabel")
    instructions.Size = UDim2.new(1, 0, 0, 50)
    instructions.Position = UDim2.new(0, 0, 0, 135)
    instructions.BackgroundTransparency = 1
    instructions.Text = "ENTER YOUR KEY\n(Daily free via LootLabs or Permanent purchased)"
    instructions.TextColor3 = Color3.fromRGB(180, 180, 180)
    instructions.TextSize = 14
    instructions.Font = Enum.Font.GothamMedium
    instructions.TextWrapped = true
    instructions.Parent = mainFrame

    local getKeyBtn = Instance.new("TextButton")
    getKeyBtn.Size = UDim2.new(0.6, 0, 0, 35)
    getKeyBtn.Position = UDim2.new(0.2, 0, 0, 195)
    getKeyBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    getKeyBtn.BorderSizePixel = 0
    getKeyBtn.Text = "GET DAILY KEY (LOOTLABS)"
    getKeyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    getKeyBtn.TextSize = 13
    getKeyBtn.Font = Enum.Font.GothamBold
    getKeyBtn.Parent = mainFrame

    getKeyBtn.MouseButton1Click:Connect(function()
        if Lootlabs_Config.Link and Lootlabs_Config.Link ~= "" then
            setclipboard(Lootlabs_Config.Link)
            status.Text = "LINK COPIED. ACCESS AND GET YOUR DAILY KEY"
            status.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            status.Text = "ERROR: LOOTLABS LINK NOT CONFIGURED"
            status.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end)

    local permInfo = Instance.new("TextLabel")
    permInfo.Size = UDim2.new(1, 0, 0, 25)
    permInfo.Position = UDim2.new(0, 0, 0, 240)
    permInfo.BackgroundTransparency = 1
    permInfo.Text = "PERMANENT KEY: Buy and receive a unique key"
    permInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
    permInfo.TextSize = 12
    permInfo.Font = Enum.Font.GothamMedium
    permInfo.Parent = mainFrame

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0.8, 0, 0, 45)
    textBox.Position = UDim2.new(0.1, 0, 0, 270)
    textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    textBox.BorderSizePixel = 2
    textBox.BorderColor3 = Color3.fromRGB(255, 215, 0)
    textBox.Text = ""
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextSize = 18
    textBox.Font = Enum.Font.GothamMedium
    textBox.PlaceholderText = "Paste your key here..."
    textBox.ClearTextOnFocus = false
    textBox.Parent = mainFrame

    local verifyBtn = Instance.new("TextButton")
    verifyBtn.Size = UDim2.new(0.4, 0, 0, 45)
    verifyBtn.Position = UDim2.new(0.3, 0, 0, 335)
    verifyBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    verifyBtn.BorderSizePixel = 0
    verifyBtn.Text = "VERIFY"
    verifyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    verifyBtn.TextSize = 18
    verifyBtn.Font = Enum.Font.GothamBold
    verifyBtn.Parent = mainFrame

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 30)
    status.Position = UDim2.new(0, 0, 0, 395)
    status.BackgroundTransparency = 1
    status.Text = "Waiting for key..."
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
    status.TextSize = 14
    status.Font = Enum.Font.GothamMedium
    status.Parent = mainFrame

    local retryInfo = Instance.new("TextLabel")
    retryInfo.Size = UDim2.new(1, 0, 0, 25)
    retryInfo.Position = UDim2.new(0, 0, 0, 430)
    retryInfo.BackgroundTransparency = 1
    retryInfo.Text = "Attempts: 0/5"
    retryInfo.TextColor3 = Color3.fromRGB(150, 150, 150)
    retryInfo.TextSize = 12
    retryInfo.Font = Enum.Font.GothamMedium
    retryInfo.Parent = mainFrame

    local validInfo = Instance.new("TextLabel")
    validInfo.Size = UDim2.new(1, 0, 0, 20)
    validInfo.Position = UDim2.new(0, 0, 0, 460)
    validInfo.BackgroundTransparency = 1
    validInfo.Text = "Daily key 24h | Permanent never expires"
    validInfo.TextColor3 = Color3.fromRGB(100, 100, 100)
    validInfo.TextSize = 11
    validInfo.Font = Enum.Font.GothamMedium
    validInfo.Parent = mainFrame

    local function verifyKey(key)
        if not key or key == "" then
            status.Text = "Enter a valid key."
            status.TextColor3 = Color3.fromRGB(255, 80, 80)
            return false
        end

        status.Text = "Verifying key..."
        status.TextColor3 = Color3.fromRGB(255, 215, 0)

        local isValid = false
        local isPermanent = false

        isPermanent = self:isPermanentKey(key)

        if Lootlabs_Config.Enabled and not isPermanent then
            local verified = self:verifyWithLootlabs(key)
            if verified then
                isValid = true
            end
        elseif isPermanent then
            isValid = true
        end

        if isValid then
            self.verified = true
            self.currentUser = self.userId
            self.isPermanent = isPermanent
            local expiryDate = isPermanent and 0 or (os.time() + (24 * 3600))
            self:saveUserKey(self.userId, key, expiryDate, isPermanent)
            status.Text = isPermanent and "PERMANENT KEY VALID. (Never expires)" or "DAILY KEY VALID. (24h)"
            status.TextColor3 = Color3.fromRGB(0, 255, 100)
            wait(0.8)
            screenGui:Destroy()
            return true
        else
            self.retryAttempts = self.retryAttempts + 1
            retryInfo.Text = "Attempts: " .. self.retryAttempts .. "/5"
            status.Text = "INVALID KEY. Try again."
            status.TextColor3 = Color3.fromRGB(255, 80, 80)
            if self.retryAttempts >= 5 then
                status.Text = "Too many failed attempts."
                status.TextColor3 = Color3.fromRGB(255, 80, 80)
                verifyBtn.Visible = false
                textBox.Visible = false
                local closeBtn = Instance.new("TextButton")
                closeBtn.Size = UDim2.new(0.4, 0, 0, 40)
                closeBtn.Position = UDim2.new(0.3, 0, 0, 335)
                closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                closeBtn.BorderSizePixel = 0
                closeBtn.Text = "CLOSE"
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
            status.Text = savedData.isPermanent and "PERMANENT KEY EXPIRED? (Error)" or "DAILY KEY EXPIRED. Get a new one."
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
            if savedData.isPermanent then
                verified = true
            elseif Lootlabs_Config.Enabled then
                verified = self:verifyWithLootlabs(savedData.key)
            end
            if verified then
                self.verified = true
                self.isPermanent = savedData.isPermanent
                return true
            end
        else
            print("Key expired. Get a new one.")
            Logger.log("Key expired for user " .. self.userId)
        end
    end

    self:showKeyUI()

    while not self.verified do
        wait(0.5)
    end

    return self.verified
end

local KeyGenerator = {}
KeyGenerator.__index = KeyGenerator

function KeyGenerator.new()
    local self = setmetatable({}, KeyGenerator)
    return self
end

function KeyGenerator:generateRandomString(length)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = ""
    math.randomseed(os.time() + math.random(1, 99999))
    for i = 1, length do
        local idx = math.random(1, #chars)
        result = result .. string.sub(chars, idx, idx)
    end
    return result
end

function KeyGenerator:generateKey()
    local prefix = KeyConfig.PERMANENT_KEY_PREFIX
    local randomPart = self:generateRandomString(8)
    return prefix .. randomPart
end

function KeyGenerator:showAdminUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AdminKeyGenerator"
    screenGui.Parent = game:GetService("CoreGui")
    screenGui.ResetOnSpawn = false

    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.7
    background.BorderSizePixel = 0
    background.Parent = screenGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 450, 0, 350)
    mainFrame.Position = UDim2.new(0.5, -225, 0.5, -175)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
    mainFrame.Parent = background

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 45)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "PERMANENT KEY GENERATOR"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame

    local labelUserId = Instance.new("TextLabel")
    labelUserId.Size = UDim2.new(1, -20, 0, 25)
    labelUserId.Position = UDim2.new(0, 10, 0, 65)
    labelUserId.BackgroundTransparency = 1
    labelUserId.Text = "Buyer UserId:"
    labelUserId.TextColor3 = Color3.fromRGB(200, 200, 200)
    labelUserId.TextSize = 14
    labelUserId.Font = Enum.Font.GothamMedium
    labelUserId.TextXAlignment = Enum.TextXAlignment.Left
    labelUserId.Parent = mainFrame

    local textBoxUserId = Instance.new("TextBox")
    textBoxUserId.Size = UDim2.new(0.8, 0, 0, 40)
    textBoxUserId.Position = UDim2.new(0.1, 0, 0, 95)
    textBoxUserId.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    textBoxUserId.BorderSizePixel = 2
    textBoxUserId.BorderColor3 = Color3.fromRGB(255, 215, 0)
    textBoxUserId.Text = ""
    textBoxUserId.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBoxUserId.TextSize = 18
    textBoxUserId.Font = Enum.Font.GothamMedium
    textBoxUserId.PlaceholderText = "Enter buyer UserId"
    textBoxUserId.ClearTextOnFocus = false
    textBoxUserId.Parent = mainFrame

    local generateBtn = Instance.new("TextButton")
    generateBtn.Size = UDim2.new(0.6, 0, 0, 45)
    generateBtn.Position = UDim2.new(0.2, 0, 0, 155)
    generateBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    generateBtn.BorderSizePixel = 0
    generateBtn.Text = "GENERATE KEY"
    generateBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    generateBtn.TextSize = 18
    generateBtn.Font = Enum.Font.GothamBold
    generateBtn.Parent = mainFrame

    local resultLabel = Instance.new("TextLabel")
    resultLabel.Size = UDim2.new(1, -20, 0, 30)
    resultLabel.Position = UDim2.new(0, 10, 0, 215)
    resultLabel.BackgroundTransparency = 1
    resultLabel.Text = "Waiting for generation..."
    resultLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    resultLabel.TextSize = 14
    resultLabel.Font = Enum.Font.GothamMedium
    resultLabel.TextWrapped = true
    resultLabel.Parent = mainFrame

    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0.4, 0, 0, 35)
    copyBtn.Position = UDim2.new(0.3, 0, 0, 260)
    copyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    copyBtn.BorderSizePixel = 0
    copyBtn.Text = "COPY KEY"
    copyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    copyBtn.TextSize = 14
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.Parent = mainFrame
    copyBtn.Visible = false

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0.2, 0, 0, 35)
    closeBtn.Position = UDim2.new(0.8, 0, 0, 260)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "CLOSE"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = mainFrame

    local generatedKey = nil

    generateBtn.MouseButton1Click:Connect(function()
        local userId = textBoxUserId.Text
        if userId == "" then
            resultLabel.Text = "ERROR: Enter a valid UserId."
            resultLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            return
        end

        local key = self:generateKey()
        generatedKey = key

        resultLabel.Text = "Key generated: " .. key .. " (linked to UserId " .. userId .. ")"
        resultLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        copyBtn.Visible = true

        setclipboard(key)
        resultLabel.Text = resultLabel.Text .. "\n(Key copied to clipboard)"

        wait(0.5)
        resultLabel.Text = resultLabel.Text .. "\n\nAdd to perm_keys.json:\n\"" .. key .. "\": \"" .. userId .. "\""
    end)

    copyBtn.MouseButton1Click:Connect(function()
        if generatedKey then
            setclipboard(generatedKey)
            resultLabel.Text = "Key copied again."
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        print("Admin mode closed. Run script again for normal mode.")
    end)
end

local Cache = {}
Cache.__index = Cache

function Cache.new()
    local self = setmetatable({}, Cache)
    self.data = {
        beli = 0,
        mastery = {},
        level = 0,
        fragments = 0,
    }
    self.lastUpdate = 0
    self.ttl = 2
    return self
end

function Cache:getBeli(agent)
    local now = os.time()
    if now - self.lastUpdate > self.ttl then
        self.data.beli = agent:getBeli()
        for _, style in ipairs(agent.fightingStyles) do
            self.data.mastery[style.name] = agent:getStyleMastery(style.name)
        end
        self.data.level = agent.state.level
        self.data.fragments = agent.state.fragments
        self.lastUpdate = now
    end
    return self.data.beli
end

function Cache:getMastery(styleName)
    return self.data.mastery[styleName] or 0
end

local AntiCheat = {}
AntiCheat.__index = AntiCheat

function AntiCheat.new()
    local self = setmetatable({}, AntiCheat)
    self.delayBase = 0.08
    self.delayVariation = 0.04
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

local function optimizeGame()
    pcall(function()
        print("Applying optimizations...")
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
            if v:IsA("Atmosphere") then v:Destroy() end
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
        print("Optimizations applied.")
        Logger.log("Optimizations applied.")
    end)
end

local GUI = {}
GUI.__index = GUI

function GUI.new(agent)
    local self = setmetatable({}, GUI)
    self.agent = agent
    self.created = false
    self.paused = false
    self.logs = {}
    return self
end

function GUI:create()
    if self.created then return end
    self.created = true

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ScriptGogoGUI"
    screenGui.Parent = game:GetService("CoreGui")
    screenGui.ResetOnSpawn = false
    self.gui = screenGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 420, 0, 520)
    mainFrame.Position = UDim2.new(0, 10, 0, 10)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.fromRGB(50, 50, 60)
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    self.mainFrame = mainFrame

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    header.BackgroundTransparency = 0.1
    header.BorderSizePixel = 0
    header.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.6, 0, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "SCRIPT GOGO - AI"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(0.3, 0, 1, 0)
    statusLabel.Position = UDim2.new(0.7, 0, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "ACTIVE"
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right
    statusLabel.Parent = header
    self.statusLabel = statusLabel

    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, 0, 0, 30)
    tabContainer.Position = UDim2.new(0, 0, 0, 40)
    tabContainer.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = mainFrame

    local tabs = {"Status", "Stats", "Controls"}
    self.tabButtons = {}
    for i, name in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1/#tabs, 0, 1, 0)
        btn.Position = UDim2.new((i-1)/#tabs, 0, 0, 0)
        btn.BackgroundTransparency = 1
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamMedium
        btn.Parent = tabContainer

        local underline = Instance.new("Frame")
        underline.Size = UDim2.new(0.8, 0, 0, 2)
        underline.Position = UDim2.new(0.1, 0, 1, -2)
        underline.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        underline.BackgroundTransparency = i == 1 and 0 or 1
        underline.BorderSizePixel = 0
        underline.Parent = btn
        self.tabButtons[i] = {btn = btn, underline = underline}
        btn.MouseButton1Click:Connect(function()
            self:switchTab(i)
        end)
    end

    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, -100)
    contentFrame.Position = UDim2.new(0, 0, 0, 70)
    contentFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    contentFrame.BackgroundTransparency = 0
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = mainFrame
    self.contentFrame = contentFrame

    self.panels = {}
    self:createStatePanel(contentFrame)
    self:createStatsPanel(contentFrame)
    self:createControlsPanel(contentFrame)
    self:switchTab(1)

    local logFrame = Instance.new("Frame")
    logFrame.Size = UDim2.new(1, 0, 0, 80)
    logFrame.Position = UDim2.new(0, 0, 1, -80)
    logFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    logFrame.BorderSizePixel = 0
    logFrame.Parent = mainFrame

    local logScroll = Instance.new("ScrollingFrame")
    logScroll.Size = UDim2.new(1, -10, 1, -5)
    logScroll.Position = UDim2.new(0, 5, 0, 5)
    logScroll.BackgroundTransparency = 1
    logScroll.BorderSizePixel = 0
    logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    logScroll.ScrollBarThickness = 2
    logScroll.Parent = logFrame
    self.logScroll = logScroll

    self.logContainer = Instance.new("Frame")
    self.logContainer.Size = UDim2.new(1, 0, 0, 0)
    self.logContainer.BackgroundTransparency = 1
    self.logContainer.Parent = logScroll
end

function GUI:switchTab(index)
    for i, panel in ipairs(self.panels) do
        if panel then panel.Visible = (i == index) end
    end
    for i, tab in ipairs(self.tabButtons) do
        tab.underline.BackgroundTransparency = (i == index) and 0 or 1
    end
end

function GUI:createStatePanel(parent)
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(1, 0, 1, 0)
    panel.BackgroundTransparency = 1
    panel.Visible = false
    panel.Parent = parent
    table.insert(self.panels, panel)

    local y = 10
    local function addLabel(text, color, size, bold)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 22)
        lbl.Position = UDim2.new(0, 10, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = color or Color3.fromRGB(220, 220, 220)
        lbl.TextSize = size or 13
        lbl.Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = panel
        y = y + 26
        return lbl
    end

    self.stateLabels = {}
    self.stateLabels.decision = addLabel("Decision: Waiting...", Color3.fromRGB(255, 200, 0), 14, true)
    self.stateLabels.level = addLabel("Level: 1 / 2800", Color3.fromRGB(255, 255, 255))
    self.stateLabels.fragments = addLabel("Fragments: 0 / 16500", Color3.fromRGB(255, 255, 255))
    self.stateLabels.beli = addLabel("Beli: 0", Color3.fromRGB(255, 200, 0))
    self.stateLabels.style = addLabel("Style: None", Color3.fromRGB(255, 255, 255))
    self.stateLabels.mastery = addLabel("Mastery: 0", Color3.fromRGB(255, 255, 255))
    self.stateLabels.godhuman = addLabel("GodHuman: LOCKED", Color3.fromRGB(255, 80, 80))
    self.stateLabels.uptime = addLabel("Uptime: 0s", Color3.fromRGB(200, 200, 200), 12, false)
    self.stateLabels.boost = addLabel("2x XP: INACTIVE", Color3.fromRGB(255, 200, 0), 12, false)
end

function GUI:createStatsPanel(parent)
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(1, 0, 1, 0)
    panel.BackgroundTransparency = 1
    panel.Visible = false
    panel.Parent = parent
    table.insert(self.panels, panel)

    local y = 10
    local function addProgress(label, value, max, color)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -20, 0, 28)
        frame.Position = UDim2.new(0, 10, 0, y)
        frame.BackgroundTransparency = 1
        frame.Parent = panel

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.4, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frame

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(0.5, 0, 0.7, 0)
        bg.Position = UDim2.new(0.45, 0, 0.15, 0)
        bg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        bg.BorderSizePixel = 0
        bg.Parent = frame

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 0, 1, 0)
        bar.BackgroundColor3 = color or Color3.fromRGB(255, 200, 0)
        bar.BorderSizePixel = 0
        bar.Parent = bg

        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(0.5, 0, 1, 0)
        val.Position = UDim2.new(0.45, 0, 0, 0)
        val.BackgroundTransparency = 1
        val.Text = "0%"
        val.TextColor3 = Color3.fromRGB(220, 220, 220)
        val.TextSize = 11
        val.Font = Enum.Font.GothamMedium
        val.TextXAlignment = Enum.TextXAlignment.Right
        val.Parent = frame

        y = y + 32
        return {bar = bar, val = val, max = max, label = label}
    end

    self.statsBars = {}
    self.statsBars.level = addProgress("Level", 1, 2800, Color3.fromRGB(255, 200, 0))
    self.statsBars.fragments = addProgress("Fragments", 0, 16500, Color3.fromRGB(0, 200, 255))
    self.statsBars.combat = addProgress("Combat", 0, 1, Color3.fromRGB(200, 200, 200))
    self.statsBars.water = addProgress("Water Kung Fu", 0, 500, Color3.fromRGB(100, 200, 255))
    self.statsBars.electric = addProgress("Electric", 0, 500, Color3.fromRGB(255, 200, 0))
    self.statsBars.dragon = addProgress("Dragon Breath", 0, 500, Color3.fromRGB(255, 100, 50))
    self.statsBars.superhuman = addProgress("Superhuman", 0, 400, Color3.fromRGB(0, 255, 100))
    self.statsBars.deathstep = addProgress("Death Step", 0, 400, Color3.fromRGB(150, 0, 200))
    self.statsBars.sharkman = addProgress("Sharkman Karate", 0, 400, Color3.fromRGB(0, 150, 255))
    self.statsBars.electricclaw = addProgress("Electric Claw", 0, 400, Color3.fromRGB(255, 255, 0))
    self.statsBars.dragontalon = addProgress("Dragon Talon", 0, 400, Color3.fromRGB(255, 50, 0))
end

function GUI:createControlsPanel(parent)
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(1, 0, 1, 0)
    panel.BackgroundTransparency = 1
    panel.Visible = false
    panel.Parent = parent
    table.insert(self.panels, panel)

    local y = 10
    local function addButton(text, color, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.8, 0, 0, 35)
        btn.Position = UDim2.new(0.1, 0, 0, y)
        btn.BackgroundColor3 = color or Color3.fromRGB(255, 200, 0)
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
        btn.Parent = panel
        btn.MouseButton1Click:Connect(callback)
        y = y + 42
        return btn
    end

    self.pauseBtn = addButton("PAUSE AI", Color3.fromRGB(255, 200, 0), function()
        self.paused = not self.paused
        self.pauseBtn.Text = self.paused and "RESUME AI" or "PAUSE AI"
        self.statusLabel.Text = self.paused and "PAUSED" or "ACTIVE"
        self.statusLabel.TextColor3 = self.paused and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(0, 255, 100)
        self:addLog(self.paused and "AI PAUSED" or "AI RESUMED")
        Logger.log(self.paused and "AI paused" or "AI resumed")
        Webhook.send(self.paused and "AI paused" or "AI resumed")
    end)

    addButton("RESET PROGRESS", Color3.fromRGB(255, 80, 80), function()
        self:addLog("Resetting progress...")
        self.agent:resetProgress()
        self:addLog("Progress reset.")
        Logger.log("Progress reset.")
        Webhook.send("Progress reset.")
    end)

    addButton("SAVE NOW", Color3.fromRGB(0, 200, 100), function()
        self.agent:saveState()
        self:addLog("State saved.")
        Logger.log("State saved manually.")
    end)

    self.redeemBtn = addButton("AUTO REDEEM: ON", Color3.fromRGB(0, 200, 100), function()
        CodeConfig.Enabled = not CodeConfig.Enabled
        self.redeemBtn.Text = CodeConfig.Enabled and "AUTO REDEEM: ON" or "AUTO REDEEM: OFF"
        self.redeemBtn.BackgroundColor3 = CodeConfig.Enabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 80, 80)
        self:addLog("Auto Redeem " .. (CodeConfig.Enabled and "enabled" or "disabled"))
        Logger.log("Auto Redeem " .. (CodeConfig.Enabled and "enabled" or "disabled"))
    end)
end

function GUI:addLog(msg)
    local time = os.date("%H:%M:%S")
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = "[" .. time .. "] " .. msg
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = self.logContainer

    self.logContainer.Size = UDim2.new(1, 0, 0, #self.logContainer:GetChildren() * 18)
    self.logScroll.CanvasSize = UDim2.new(0, 0, 0, #self.logContainer:GetChildren() * 18)
    self.logScroll.ScrollBarPosition = Enum.ScrollBarPosition.Bottom
    wait(0.1)
    self.logScroll.CanvasPosition = Vector2.new(0, self.logScroll.CanvasSize.Y.Offset)
end

function GUI:update(state, agent)
    if not self.created then return end
    pcall(function()
        if self.stateLabels then
            self.stateLabels.decision.Text = "Decision: " .. (state.currentDecision or "Waiting...")
            self.stateLabels.level.Text = "Level: " .. (state.level or 1) .. " / 2800"
            self.stateLabels.fragments.Text = "Fragments: " .. (state.fragments or 0) .. " / 16500"
            local beli = agent:getBeli()
            self.stateLabels.beli.Text = "Beli: " .. beli
            self.stateLabels.style.Text = "Style: " .. (state.currentStyle or "None")
            local mastery = agent:getStyleMastery(state.currentStyle or "")
            self.stateLabels.mastery.Text = "Mastery: " .. mastery
            self.stateLabels.godhuman.Text = state.godhuman and "GodHuman: UNLOCKED" or "GodHuman: LOCKED"
            self.stateLabels.godhuman.TextColor3 = state.godhuman and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 80, 80)
            self.stateLabels.uptime.Text = "Uptime: " .. (state.uptime or 0) .. "s"
            self.stateLabels.boost.Text = "2x XP: " .. (agent.xpBoostActive and "ACTIVE" or "INACTIVE")
            self.stateLabels.boost.TextColor3 = agent.xpBoostActive and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(200, 200, 200)
        end

        if self.statsBars then
            local function updateBar(bar, val, max)
                if bar and max and max > 0 then
                    local pct = math.min(val / max, 1)
                    bar.bar.Size = UDim2.new(pct, 0, 1, 0)
                    bar.val.Text = math.floor(pct * 100) .. "%"
                end
            end
            updateBar(self.statsBars.level, state.level, 2800)
            updateBar(self.statsBars.fragments, state.fragments, 16500)
            for _, style in ipairs(agent.fightingStyles) do
                local barName = style.name:gsub(" ", ""):lower()
                if barName == "waterkungfu" then barName = "water" end
                if barName == "deathstep" then barName = "deathstep" end
                if barName == "electricclaw" then barName = "electricclaw" end
                if barName == "dragontalon" then barName = "dragontalon" end
                if barName == "dragonbreath" then barName = "dragon" end
                local bar = self.statsBars[barName]
                if bar then
                    local mastery = agent:getStyleMastery(style.name)
                    local required = style.v1 and 500 or 400
                    if style.name == "Combat" then required = 1 end
                    updateBar(bar, mastery, required)
                end
            end
        end
    end)
end

-- ============================================
-- MAIN AGENT
-- ============================================
local Agent = {}
Agent.__index = Agent

function Agent.new()
    local self = setmetatable({}, Agent)

    self.keySystem = KeySystem.new()
    print("Verifying key...")
    if not self.keySystem:verify() then
        print("Invalid or expired key.")
        return nil
    end
    print("Key verified successfully.")

    self.antiCheat = AntiCheat.new()
    self.fileName = "scriptgogo_data.json"
    self.state = self:loadState()
    self.cache = Cache.new()

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
    self.masteryV1 = 500
    self.masteryV2 = 400
    self.targetBeli = 50000
    self.xpBoostActive = false
    self.lastCodeCheck = 0
    self.lastSaveTime = 0

    self.fightingStyles = {
        {name = "Combat", v1 = true, sea = "First Sea", masteryRequired = 1, unlocked = false, mastery = 0, obtained = false},
        {name = "Water Kung Fu", v1 = true, sea = "First Sea", masteryRequired = 500, unlocked = false, mastery = 0, obtained = false},
        {name = "Electric", v1 = true, sea = "First Sea", masteryRequired = 500, unlocked = false, mastery = 0, obtained = false},
        {name = "Dragon Breath", v1 = true, sea = "Second Sea", masteryRequired = 500, unlocked = false, mastery = 0, obtained = false},
        {name = "Superhuman", v1 = false, sea = "Second Sea", masteryRequired = 400, unlocked = false, mastery = 0, obtained = false, requires = {"Combat", "Water Kung Fu", "Electric"}},
        {name = "Death Step", v1 = false, sea = "Second Sea", masteryRequired = 400, unlocked = false, mastery = 0, obtained = false, requires = {"Combat", "Water Kung Fu", "Electric"}},
        {name = "Sharkman Karate", v1 = false, sea = "Third Sea", masteryRequired = 400, unlocked = false, mastery = 0, obtained = false, requires = {"Water Kung Fu", "Dragon Breath"}},
        {name = "Electric Claw", v1 = false, sea = "Third Sea", masteryRequired = 400, unlocked = false, mastery = 0, obtained = false, requires = {"Electric", "Dragon Breath"}},
        {name = "Dragon Talon", v1 = false, sea = "Third Sea", masteryRequired = 400, unlocked = false, mastery = 0, obtained = false, requires = {"Dragon Breath", "Superhuman"}}
    }

    self.godhumanRequirements = {
        styles = {"Superhuman", "Death Step", "Sharkman Karate", "Electric Claw", "Dragon Talon"},
        fragmentsNeeded = 16500,
        levelRequired = 2000
    }

    self.haki = {unlocked = false, mastery = 0, active = false}
    self.state.currentDecision = "Initializing..."
    self.runningActions = {}

    self.gui = GUI.new(self)
    self.gui:create()
    self.gui:addLog("Script loaded. Waiting for start...")
    Logger.log("Script started for user " .. self.keySystem.userId)
    Webhook.send("Script started. Version 21.0")

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
        stylesObtained = {},
        redeemedCodes = {},
        settings = {
            autoFarm = true, autoQuest = true, autoRaid = true,
            autoMastery = true, autoSpinFruit = true,
            autoTeleportFruit = true, autoSwitchSea = true,
            autoHaki = true, autoMasteryAllStyles = true
        }
    }
end

function Agent:saveState()
    pcall(function()
        local json = self.httpService:JSONEncode(self.state)
        writefile(self.fileName, json)
        Logger.log("State saved automatically.")
    end)
end

function Agent:resetProgress()
    self.state = {
        level = 1, xp = 0, fragments = 0, godhuman = false,
        raidsCompleted = 0, currentSea = "First Sea",
        currentStyle = nil, uptime = 0, lastRaidTime = 0,
        questsCompleted = 0,
        haki = {unlocked = false, mastery = 0, level = 0},
        stylesObtained = {},
        redeemedCodes = {},
        settings = {
            autoFarm = true, autoQuest = true, autoRaid = true,
            autoMastery = true, autoSpinFruit = true,
            autoTeleportFruit = true, autoSwitchSea = true,
            autoHaki = true, autoMasteryAllStyles = true
        }
    }
    for _, style in ipairs(self.fightingStyles) do
        style.obtained = false
        style.unlocked = false
        style.mastery = 0
    end
    self:saveState()
    Logger.log("Progress reset.")
end

function Agent:getBeli()
    local beli = 0
    pcall(function()
        local data = self.player:FindFirstChild("Data")
        if data then
            local b = data:FindFirstChild("Beli")
            if b then beli = b.Value end
        end
    end)
    return beli
end

function Agent:getStyleMastery(styleName)
    local mastery = 0
    pcall(function()
        local data = self.player:FindFirstChild("Data")
        if data then
            local m = data:FindFirstChild(styleName .. "Mastery")
            if m then mastery = m.Value end
        end
    end)
    return mastery
end

function Agent:getStyleData(styleName)
    for _, style in ipairs(self.fightingStyles) do
        if style.name == styleName then return style end
    end
    return nil
end

function Agent:hasStyleRequirements(style)
    if not style.requires then return true end
    for _, reqName in ipairs(style.requires) do
        local reqStyle = self:getStyleData(reqName)
        if not reqStyle or not reqStyle.obtained then return false end
        local mastery = self:getStyleMastery(reqName)
        if mastery < 500 then return false end
    end
    return true
end

function Agent:obtainStyle(styleName)
    pcall(function()
        local style = self:getStyleData(styleName)
        if not style or style.obtained then return end
        if style.sea ~= self.state.currentSea then return end
        if not style.v1 and not self:hasStyleRequirements(style) then return end
        self.antiCheat:humanizeAction(function()
            self.replicatedStorage.Remotes.CommF_:InvokeServer("Buy", styleName)
        end)
        style.obtained = true
        self.state.stylesObtained[styleName] = true
        self:saveState()
        self.gui:addLog("Style obtained: " .. styleName)
        Logger.log("Style obtained: " .. styleName)
        Webhook.send("Style obtained: " .. styleName)
    end)
end

function Agent:equipStyle(styleName)
    pcall(function()
        self.antiCheat:humanizeAction(function()
            self.replicatedStorage.Remotes.CommF_:InvokeServer("Equip", styleName)
        end)
        self.state.currentStyle = styleName
        self:saveState()
        self.gui:addLog("Style equipped: " .. styleName)
        Logger.log("Style equipped: " .. styleName)
    end)
end

function Agent:getNextStyleToMaster()
    if self.state.currentStyle == "Combat" then
        local beli = self:getBeli()
        if beli < self.targetBeli then
            return "Combat"
        else
            for _, style in ipairs(self.fightingStyles) do
                if style.name ~= "Combat" and not style.obtained and self:canObtainStyle(style) then
                    return style.name
                end
            end
            return nil
        end
    end
    for _, requiredStyle in ipairs(self.godhumanRequirements.styles) do
        local styleData = self:getStyleData(requiredStyle)
        if styleData then
            local mastery = self:getStyleMastery(requiredStyle)
            local required = styleData.v1 and self.masteryV1 or self.masteryV2
            if not styleData.obtained then
                if self:canObtainStyle(styleData) then return requiredStyle end
            elseif mastery < required then
                return requiredStyle
            end
        end
    end
    for _, style in ipairs(self.fightingStyles) do
        if style.v1 and style.name ~= "Combat" then
            local mastery = self:getStyleMastery(style.name)
            if not style.obtained and self:canObtainStyle(style) then return style.name end
            if style.obtained and mastery < self.masteryV1 then return style.name end
        end
    end
    for _, style in ipairs(self.fightingStyles) do
        if not style.v1 then
            local mastery = self:getStyleMastery(style.name)
            if not style.obtained and self:canObtainStyle(style) then return style.name end
            if style.obtained and mastery < self.masteryV2 then return style.name end
        end
    end
    return nil
end

function Agent:canObtainStyle(style)
    if style.sea ~= self.state.currentSea then return false end
    if not style.v1 and not self:hasStyleRequirements(style) then return false end
    return true
end

function Agent:autoMasteryAllStyles()
    if not self.state.settings.autoMasteryAllStyles then return end
    if self.state.godhuman then return end

    local nextStyle = self:getNextStyleToMaster()
    if not nextStyle then
        self.gui:addLog("No styles available to master.")
        return
    end

    local styleData = self:getStyleData(nextStyle)
    if not styleData then return end

    if not styleData.obtained then
        self:obtainStyle(nextStyle)
        wait(1)
        if not styleData.obtained then return end
    end

    if self.state.currentStyle ~= nextStyle then
        self:equipStyle(nextStyle)
        wait(0.5)
    end

    local currentMastery = self:getStyleMastery(nextStyle)
    local requiredMastery = styleData.masteryRequired
    if currentMastery < requiredMastery then
        self:fastAttack()
    else
        styleData.unlocked = true
        self:saveState()
        self.gui:addLog(nextStyle .. " mastered. (" .. currentMastery .. "/" .. requiredMastery .. ")")
        Logger.log(nextStyle .. " mastered. (" .. currentMastery .. "/" .. requiredMastery .. ")")
    end
end

function Agent:unlockGodHuman()
    pcall(function()
        if self.state.godhuman then return end
        local allStylesMastered = true
        for _, styleName in ipairs(self.godhumanRequirements.styles) do
            local style = self:getStyleData(styleName)
            if not style or not style.obtained then allStylesMastered = false break end
            local mastery = self:getStyleMastery(styleName)
            if mastery < 400 then allStylesMastered = false break end
        end
        if not allStylesMastered then
            self.gui:addLog("Still missing styles for GodHuman.")
            return
        end
        if self.state.fragments < self.fragmentsNeeded then
            self.gui:addLog("Insufficient fragments: " .. self.state.fragments .. "/" .. self.fragmentsNeeded)
            self:autoRaid()
            return
        end
        if self.state.level < 2000 then
            self.gui:addLog("Insufficient level: " .. self.state.level .. "/2000")
            return
        end
        self.antiCheat:humanizeAction(function()
            self.replicatedStorage.Remotes.CommF_:InvokeServer("Buy", "GodHuman")
        end)
        self.state.godhuman = true
        self:saveState()
        self.gui:addLog("GODHUMAN UNLOCKED SUCCESSFULLY.")
        Logger.log("GODHUMAN UNLOCKED")
        Webhook.send("GODHUMAN UNLOCKED!")
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
                    if dist <= radius then table.insert(enemies, v) end
                end
            end
        end
    end)
    return enemies
end

function Agent:getXPMultiplier()
    local base = (self.state.currentSea == "First Sea" and 1) or (self.state.currentSea == "Second Sea" and 1.5) or 2
    if self.xpBoostActive then base = base * 2 end
    return base
end

function Agent:checkLevelUp()
    local needed = self.state.level * 100 + 50
    while (self.state.xp or 0) >= needed and self.state.level < self.maxLevel do
        self.state.xp = self.state.xp - needed
        self.state.level = self.state.level + 1
        needed = self.state.level * 100 + 50
        self.gui:addLog("Level UP. " .. self.state.level .. "/2800")
        Logger.log("Level UP. " .. self.state.level .. "/2800")
        Webhook.send("Level UP. " .. self.state.level .. "/2800")
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
    pcall(function() self.rootPart.CFrame = CFrame.new(position) end)
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
            self.gui:addLog("Switched to " .. sea)
            Logger.log("Switched to " .. sea)
            Webhook.send("Switched to " .. sea)
            self:saveState()
        end
    end)
end

function Agent:moveToRandomIsland()
    local islands = {
        ["First Sea"] = {Vector3.new(-1200, 80, 2800), Vector3.new(300, 50, 4500), Vector3.new(-4500, 100, -2500)},
        ["Second Sea"] = {Vector3.new(1200, 150, 8000), Vector3.new(5000, 500, 0), Vector3.new(-3000, 100, 7000)},
        ["Third Sea"] = {Vector3.new(0, 400, 0), Vector3.new(3000, 300, 3000), Vector3.new(-6000, 150, 6000)}
    }
    local seaIslands = islands[self.state.currentSea] or islands["First Sea"]
    local pos = seaIslands[math.random(1, #seaIslands)]
    if pos then self:teleportTo(pos) end
end

function Agent:fastAttack()
    pcall(function()
        if self.state.settings.autoHaki then self:autoHaki() end
        local enemies = self:getNearbyEnemies(80)
        if #enemies == 0 then self:moveToRandomIsland() return end
        local target = enemies[1]
        self:teleportTo(target.HumanoidRootPart.Position + Vector3.new(0, 5, 0))
        local attacks = math.random(2, 5)
        for i = 1, attacks do
            self.antiCheat:humanizeAction(function()
                self.replicatedStorage.Remotes.CommF_:InvokeServer("Attack", {[1] = target.HumanoidRootPart})
            end)
            wait(0.085 + math.random(0, 5) * 0.001)
        end
        local xpGain = 50 * self:getXPMultiplier()
        self.state.xp = (self.state.xp or 0) + xpGain
        self:checkLevelUp()
        local currentStyle = self.state.currentStyle
        if currentStyle then
            local mastery = self:getStyleMastery(currentStyle)
            self.state.masteryProgress = self.state.masteryProgress or {}
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
                    self.gui:addLog("Haki unlocked.")
                    Logger.log("Haki unlocked.")
                end
            end)
        end
        return
    end
    pcall(function()
        local hakiAbility = self.character:FindFirstChild("Haki")
        if hakiAbility and not hakiAbility.Enabled then
            self.antiCheat:humanizeAction(function()
                self.replicatedStorage.Remotes.CommF_:InvokeServer("Haki", "Enable")
            end)
            self.gui:addLog("Haki activated.")
        end
    end)
end

function Agent:autoRaid()
    if not self.state.settings.autoRaid then return end
    if self.state.godhuman then return end
    if self.state.level < 700 then return end
    local currentTime = os.time()
    if currentTime - (self.state.lastRaidTime or 0) < 120 then return end
    pcall(function()
        self.gui:addLog("Starting Ice Raid...")
        Logger.log("Starting Ice Raid.")
        self.replicatedStorage.Remotes.CommF_:InvokeServer("Raid", "Start", "Ice")
        wait(2)
        local raidTime = 0
        while raidTime < 180 do
            local enemies = self:getNearbyEnemies(150)
            if #enemies > 0 then self:fastAttack() end
            raidTime = raidTime + 1
            wait(1)
        end
        self.replicatedStorage.Remotes.CommF_:InvokeServer("Raid", "Complete")
        local fragmentsEarned = 300 + math.random(0, 150)
        self.state.fragments = (self.state.fragments or 0) + fragmentsEarned
        self.state.raidsCompleted = (self.state.raidsCompleted or 0) + 1
        self.state.lastRaidTime = os.time()
        self:saveState()
        self.gui:addLog("Raid completed. +" .. fragmentsEarned .. " fragments")
        Logger.log("Raid completed. +" .. fragmentsEarned .. " fragments")
        Webhook.send("Raid completed. +" .. fragmentsEarned .. " fragments")
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
                self.gui:addLog("Quest accepted.")
                Logger.log("Quest accepted.")
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
                self.gui:addLog("Quest completed. +" .. bonusXP .. " XP")
                Logger.log("Quest completed. +" .. bonusXP .. " XP")
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
                    self.gui:addLog("Fruit obtained: " .. fruit)
                    Logger.log("Fruit obtained: " .. fruit)
                end
            end)
        end
    end)
end

function Agent:autoTeleportFruit()
    if not self.state.settings.autoTeleportFruit then return end
    pcall(function()
        local legendaryFruits = {"Dragon","Leopard","Dough","Venom","Spirit","Kitsune","Yeti","Gravity","Shadow","Light"}
        for _, v in pairs(game.Workspace:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("Fruit") then
                local fruitName = v.Name
                local isLegendary = false
                for _, f in ipairs(legendaryFruits) do
                    if fruitName:find(f) then isLegendary = true break end
                end
                if isLegendary then
                    self.antiCheat:humanizeAction(function()
                        local pos = v.HumanoidRootPart.Position
                        self:teleportTo(pos + Vector3.new(0, 5, 0))
                        local click = v:FindFirstChild("ClickDetector")
                        if click then
                            fireclickdetector(click)
                            self.gui:addLog("Legendary fruit collected: " .. fruitName)
                            Logger.log("Legendary fruit collected: " .. fruitName)
                            Webhook.send("Legendary fruit collected: " .. fruitName)
                        end
                    end)
                end
            end
        end
    end)
end

function Agent:autoRedeemCodes()
    if not CodeConfig.Enabled then return end
    local now = os.time()
    if now - self.lastCodeCheck < CodeConfig.CheckInterval then return end
    self.lastCodeCheck = now

    pcall(function()
        local codes = {}
        if CodeConfig.CodesURL ~= "" then
            local content = game:HttpGet(CodeConfig.CodesURL)
            for line in string.gmatch(content, "[^\r\n]+") do
                if line and line ~= "" then table.insert(codes, line) end
            end
        end
        for _, code in ipairs(CodeConfig.FixedCodes) do
            table.insert(codes, code)
        end

        local unique = {}
        for _, code in ipairs(codes) do
            if not unique[code] then unique[code] = true end
        end
        codes = {}
        for code in pairs(unique) do table.insert(codes, code) end

        for _, code in ipairs(codes) do
            if not self.state.redeemedCodes[code] then
                self.antiCheat:humanizeAction(function()
                    local remote = self.replicatedStorage.Remotes.CommF_
                    if remote then
                        local result = remote:InvokeServer("Code", code)
                        if result and result == "Redeemed" then
                            self.state.redeemedCodes[code] = true
                            self.xpBoostActive = true
                            self:saveState()
                            self.gui:addLog("Code redeemed: " .. code .. " (2x XP activated)")
                            Logger.log("Code redeemed: " .. code)
                            Webhook.send("Code redeemed: " .. code)
                        elseif result and result == "Already Redeemed" then
                            self.state.redeemedCodes[code] = true
                            self:saveState()
                        end
                    end
                end)
                wait(1)
            end
        end
    end)
end

function Agent:decidePriority()
    if self.gui.paused then
        self.state.currentDecision = "PAUSED"
        return
    end

    local now = os.time()
    if now - self.lastSaveTime >= Config.SAVE_INTERVAL then
        self:saveState()
        self.lastSaveTime = now
    end

    self:autoRedeemCodes()

    if self.state.godhuman then
        if self.state.level < self.maxLevel then
            self.state.currentDecision = "Max Level (" .. self.state.level .. "/" .. self.maxLevel .. ")"
            self:fastAttack()
            self:autoQuest()
        else
            self.state.currentDecision = "Completed. (Game finished)"
            self:autoSpinFruit()
            self:autoTeleportFruit()
        end
        return
    end

    local allStylesMastered = true
    for _, style in ipairs(self.fightingStyles) do
        if style.name ~= "Combat" then
            local mastery = self:getStyleMastery(style.name)
            local required = style.v1 and self.masteryV1 or self.masteryV2
            if style.obtained and mastery < required then
                allStylesMastered = false
                break
            end
            if not style.obtained then
                allStylesMastered = false
                break
            end
        end
    end

    if allStylesMastered then
        self.state.currentDecision = "Mastery complete, focusing GodHuman"
        if self.state.fragments < self.fragmentsNeeded then
            self.state.currentDecision = "Need fragments (" .. self.state.fragments .. "/" .. self.fragmentsNeeded .. ")"
            self:autoRaid()
            return
        end
        if self.state.level < 2000 then
            self.state.currentDecision = "Need levels (" .. self.state.level .. "/2000)"
            self:fastAttack()
            self:autoQuest()
            return
        end
        self:unlockGodHuman()
        return
    end

    local nextStyle = self:getNextStyleToMaster()
    if nextStyle then
        self.state.currentDecision = "Mastering " .. nextStyle
        self:autoMasteryAllStyles()
        return
    end

    if self.state.currentSea == "First Sea" and self.state.level >= 700 then
        self.state.currentDecision = "Switching to Second Sea"
        self:switchSea("Second Sea")
        return
    elseif self.state.currentSea == "Second Sea" and self.state.level >= 1500 then
        self.state.currentDecision = "Switching to Third Sea"
        self:switchSea("Third Sea")
        return
    end

    self.state.currentDecision = "Generic farm"
    self:fastAttack()
    self:autoQuest()
end

function Agent:run()
    print("SCRIPT GOGO - RUNNING.")
    self.gui:addLog("AI started. Goal: Complete the game.")
    Logger.log("AI started.")
    Webhook.send("AI started.")

    while true do
        pcall(function()
            self:decidePriority()
            self:autoHaki()
            self.gui:update(self.state, self)
            self.state.uptime = (self.state.uptime or 0) + 1
        end)
        task.wait(0.5)
    end
end

-- ============================================
-- INTRO
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
    version.Text = "V21.0 - KEY GENERATOR"
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
    loadText.Text = "LOADING DECISION AI..."
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
end

-- ============================================
-- INITIALIZATION
-- ============================================

if ADMIN_MODE then
    print("[ADMIN] Admin mode activated. Opening key generator...")
    local generator = KeyGenerator.new()
    generator:showAdminUI()
    while wait(1) do
        if not game:GetService("CoreGui"):FindFirstChild("AdminKeyGenerator") then
            break
        end
    end
    print("[ADMIN] Key generator closed.")
    return
end

local protection = ProtectionSystem.new()
if protection:checkDetection() then
    print("[PROTECTION] SAFE MODE ACTIVATED.")
    wait(60)
    local emergencyFunc = protection:loadEmergencyScript()
    if emergencyFunc then
        emergencyFunc()
    else
        print("[PROTECTION] No emergency version available. Exiting.")
        return
    end
end

local updater = UpdateSystem.new()
updater:checkForUpdate()
if updater.updateAvailable then
    task.spawn(function()
        updater:downloadUpdate()
    end)
end

local func = updater:loadScript()
if func then
    print("[SCRIPT] Running main version...")
    showIntro()
    optimizeGame()
    local agent = Agent.new()
    if agent then
        agent:run()
    else
        print("Failed to initialize agent. Check your key.")
    end
else
    print("[SCRIPT] ERROR: Failed to load script.")
end

print("SCRIPT GOGO - FINISHED")
