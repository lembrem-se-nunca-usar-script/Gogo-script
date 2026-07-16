-- ============================================
-- SCRIPT GOGO
-- ============================================

print("SCRIPT GOGO - INICIANDO...")

-- ============================================
-- CONFIGURAÇÕES
-- ============================================
Configuração local = {
    REPO_URL = "https://raw.githubusercontent.com/SEU_USUARIO/Gogo-script/main/",
    ARQUIVO_DE_VERSÃO = "versão.txt",
    SCRIPT_FILE = "Gogo-script.lua",
    LOCAL_VERSION_FILE = "scriptgogo_version.txt",
    LOCAL_UPDATE_FILE = "scriptgogo_update.lua",
    CACHE_TTL = 3600,
    INTERVALO_DE_SALVAMENTO = 30,
    LOG_FILE = "scriptgogo_log.txt",
}

local Lootlabs_Config = {
    Ativado = verdadeiro,
    API_Key = "SUA_CHAVE_DE_API_AQUI",
    Link = "URL_DO_SEU_LINK_LOOTLABS",
    API_URL = "https://api.lootlabs.xyz/verify",
    Validade = 24
}

local KeyConfig = {
    PREFIXO_CHAVE_PERMANENTE = "GOGO-PERM-",
    PERMANENT_LIST_URL = "https://raw.githubusercontent.com/SEU_USUARIO/Gogo-script/main/perm_keys.json",
    USAR_PREFIXO = verdadeiro,
    USE_EXTERNAL_LIST = true,
    CACHE_LISTA_EXTERNA = 3600,
}

-- Webhook (opcional – deixe vazio para desativar)
local WebhookConfig = {
    URL = "",
    Ativado = falso,
}

- Resgate automático de códigos (2x XP)
local CodeConfig = {
    Ativado = verdadeiro,
    CheckInterval = 60,
    CodesURL = "",
    CódigosFixados = {
        "KITT_RESET", "Sub2Officiel", "Starcodeheo", "Bluxxy",
        "Fudd10", "Bignews", "Noob2Pro", "2MillionVisits"
    }
}

-- ============================================
-- MODO ADMINISTRADOR (GERADOR DE CHAVES)
-- ============================================
-- ATENÇÃO: Altere esta variável para true APENAS quando quiser gerar chaves.
-- Depois de gerar, coloque false novamente para que o script funcione normalmente.
-- ============================================
local ADMIN_MODE = false -- <--- Mude para true para gerar chaves, depois volte a false

-- ============================================
-- SISTEMA DE WEBHOOK
-- ============================================
Webhook local = {}
Webhook.__index = Webhook

função Webhook.send(mensagem)
    Se não WebhookConfig.Enabled ou WebhookConfig.URL == "", retorne o fim.
    pcall(função()
        dados locais = {
            conteúdo = mensagem,
            nome de usuário = "Script GOGO",
        }
        local json = game:GetService("HttpService"):JSONEncode(data)
        se syn e syn.request então
            syn.request({
                Url = WebhookConfig.URL,
                Método = "POST",
                Cabeçalhos = { ["Content-Type"] = "application/json" },
                Corpo = json
            })
        fim
    fim)
fim

-- ============================================
-- SISTEMA DE LOGS (FICHEIRO)
-- ============================================
local Logger = {}
Logger.__index = Logger

função Logger.log(msg)
    pcall(função()
        hora local = os.date("%Y-%m-%d %H:%M:%S")
        linha local = "[" .. tempo .. "] " .. msg .. "\n"
        conteúdo local = ""
        se isfile(Config.LOG_FILE) então
            conteúdo = lerararquivo(Config.LOG_FILE)
        fim
        writefile(Config.LOG_FILE, conteúdo .. linha)
    fim)
fim

função Logger.clear()
    pcall(função()
        writefile(Config.LOG_FILE, "")
    fim)
fim

-- ============================================
-- SISTEMA DE AUTO-PROTEÇÃO
-- ============================================
Sistema de proteção local = {}
SistemaProteção.__index = SistemaProteção

função ProtectionSystem.new()
    local self = setmetatable({}, ProtectionSystem)
    self.detectedFile = "scriptgogo_detected.txt"
    self.safeMode = falso
    self.lastBanTime = 0
    self.banCooldown = 3600
    retornar a si mesmo
fim

função ProtectionSystem:checkDetection()
    local detectado = falso
    pcall(função()
        se isfile(self.detectedFile) então
            conteúdo local = lerararquivo(self.detectedFile)
            dados locais = jogo:GetService("HttpService"):JSONDecode(conteúdo)
            se data e data.timestamp então
                local agora = os.time()
                se agora - data.timestamp < self.banCooldown então
                    detectado = verdadeiro
                    self.lastBanTime = data.timestamp
                    self.safeMode = true
                fim
            fim
        fim
    fim)
    retorno detectado
fim

função ProtectionSystem:registerDetection(motivo)
    pcall(função()
        dados locais = { timestamp = os.time(), motivo = motivo ou "Desconhecido", versão = "21.0" }
        local json = game:GetService("HttpService"):JSONEncode(data)
        escreverarquivo(self.detectedFile, json)
        self.safeMode = true
        self.lastBanTime = os.time()
        Webhook.send("DETECÇÃO REGISTADA: " .. motivo)
        Logger.log("DETECÇÃO: " .. motivo)
    fim)
fim

função ProtectionSystem:clearDetection()
    pcall(função()
        se isfile(self.detectedFile) então
            escreverarquivo(self.detectedFile, "")
        fim
        self.safeMode = falso
        Logger.log("Registo de detecção limpo.")
    fim)
fim

função ProtectionSystem:loadEmergencyScript()
    conteúdo de emergência local = nulo
    pcall(função()
        URL local = Config.REPO_URL .. "Gogo-script_safe.lua"
        emergencyContent = game:HttpGet(url)
    fim)
    se emergencyContent e #emergencyContent > 100 então
        retornar carregarstring(conteúdo de emergência)
    fim
    retornar nulo
fim

-- ============================================
-- SISTEMA DE AUTO-UPDATE
-- ============================================
local UpdateSystem = {}
UpdateSystem.__index = UpdateSystem

função UpdateSystem.new()
    local self = setmetatable({}, UpdateSystem)
    self.currentVersion = self:getLocalVersion()
    self.latestVersion = nulo
    self.updateAvailable = false
    self.updateDownloaded = false
    self.lastCheck = 0
    retornar a si mesmo
fim

função UpdateSystem:getLocalVersion()
    versão local = "0.0.0"
    pcall(função()
        se isfile(Config.LOCAL_VERSION_FILE) então
            conteúdo local = readfile(Config.LOCAL_VERSION_FILE)
            se conteúdo e conteúdo ~= "" então
                versão = conteúdo
            fim
        fim
    fim)
    versão de retorno
fim

função UpdateSystem:saveLocalVersion(versão)
    pcall(function() writefile(Config.LOCAL_VERSION_FILE, version) end)
fim

função UpdateSystem:checkForUpdate(force)
    local agora = os.time()
    se não forçar e (agora - self.lastCheck) < Config.CACHE_TTL então
        retornar self.updateDisponível
    fim
    self.lastCheck = agora

    sucesso local, versãoRemota = pcall(função()
        URL local = Config.REPO_URL .. Config.VERSION_FILE
        retornar jogo:HttpGet(url)
    fim)

    se sucesso e remoteVersion e remoteVersion ~= "" então
        remoteVersion = string.gsub(remoteVersion, "%s+", "")
        self.latestVersion = remoteVersion
        se remoteVersion ~= self.currentVersion então
            self.updateAvailable = true
            Logger.log("Nova versão disponível: " .. remoteVersion)
            Webhook.send("Nova versão disponível: " .. remoteVersion)
        outro
            self.updateAvailable = false
        fim
    outro
        self.updateAvailable = false
    fim
    retornar self.updateDisponível
fim

função UpdateSystem:downloadUpdate()
    Se não houver atualização disponível, retorne falso.
    sucesso local, scriptContent = pcall(function()
        retornar jogo:HttpGet(Config.REPO_URL .. Config.SCRIPT_FILE)
    fim)
    Se sucesso e scriptContent e #scriptContent > 100 então
        pcall(função()
            escreverarquivo(Config.LOCAL_UPDATE_FILE, conteúdo_do_script)
            self:saveLocalVersion(self.latestVersion)
            self.updateDownloaded = true
            Logger.log("Atualização baixada: V" .. self.latestVersion)
            Webhook.send("Atualização baixada: V" .. self.latestVersion)
        fim)
        retornar verdadeiro
    fim
    retornar falso
fim

função UpdateSystem:loadScript()
    local updateContent = nulo
    pcall(função()
        se isfile(Config.LOCAL_UPDATE_FILE) então
            atualizarConteúdo = lerarquivo(Config.LOCAL_UPDATE_FILE)
        fim
    fim)

    se updateContent e #updateContent > 100 então
        pcall(function() writefile(Config.LOCAL_UPDATE_FILE, "") end)
        self.versãoAtual = self.versãoMaisRecente
        retornar carregarstring(atualizarConteúdo)
    outro
        conteúdo do script local = nulo
        pcall(função()
            scriptContent = game:HttpGet(Config.REPO_URL .. Config.SCRIPT_FILE)
        fim)
        se scriptContent e #scriptContent > 100 então
            retornar carregarstring(conteúdo do script)
        fim
    fim
    retornar nulo
fim

-- ============================================
-- SISTEMA DE CHAVE (COM USERID)
-- ============================================
local KeySystem = {}
KeySystem.__index = KeySystem

função KeySystem.new()
    local self = setmetatable({}, KeySystem)
    self.keyFile = "scriptgogo_key.txt"
    self.verificado = falso
    self.retryAttempts = 0
    self.maxRetries = 5
    self.expiryHours = 24
    self.currentUser = nulo
    self.userId = self:generateUserId()
    self.isPermanent = falso
    self.permanentCache = {}
    self.lastPermanentCheck = 0
    retornar a si mesmo
fim

função KeySystem:generateUserId()
    userId local = ""
    pcall(função()
        jogador local = jogo.Jogadores.JogadorLocal
        local accountId = player.UserId ou "desconhecido"
        hwid local = "desconhecido"
        se syn e syn.crypt então
            hwid = syn.crypt.customhash("HWID") ou "desconhecido"
        fim
        local rawId = accountId .. "_" .. hwid
        userId = game:GetService("HttpService"):SHA512(rawId):sub(1, 16)
    fim)
    se userId == "" então
        userId = game.Players.LocalPlayer.Name
    fim
    retornar userId
fim

função KeySystem:isKeyExpired(savedData)
    se saveData e saveData.isPermanent então
        retornar falso
    fim
    se não houver dados salvos ou se a data de expiração de dados salvos não for válida, então
        retornar verdadeiro
    fim
    retornar os.time() > savedData.expiryDate
fim

função KeySystem:saveUserKey(userId, key, expiryDate, isPermanent)
    pcall(função()
        dados locais = {
            userId = userId,
            chave = chave,
            data = os.date("%Y-%m-%d %H:%M:%S"),
            dataDeExpiração = dataDeExpiração ou (os.time() + (24 * 3600)),
            isPermanent = isPermanent ou falso
        }
        local json = game:GetService("HttpService"):JSONEncode(data)
        escreverarquivo(self.keyFile, json)
        Logger.log("Chave guardada: " .. (isPermanent e "PERMANENTE" ou "DIARIA"))
    fim)
fim

função KeySystem:loadUserKey(userId)
    resultado local = nulo
    pcall(função()
        se isfile(self.keyFile) então
            conteúdo local = readfile(self.keyFile)
            dados locais = jogo:GetService("HttpService"):JSONDecode(conteúdo)
            Se data e data.userId == userId então
                resultado = dados
            fim
        fim
    fim)
    retornar resultado
fim

função KeySystem:isPermanentKey(chave)
    se KeyConfig.USE_EXTERNAL_LIST então
        local agora = os.time()
        se agora - self.lastPermanentCheck > KeyConfig.EXTERNAL_LIST_CACHE então
            self.lastPermanentCheck = agora
            pcall(função()
                conteúdo local = jogo:HttpGet(KeyConfig.PERMANENT_LIST_URL)
                dados locais = jogo:GetService("HttpService"):JSONDecode(conteúdo)
                se data e type(data) == "tabela" então
                    self.permanentCache = dados
                fim
            fim)
        fim
        jogador local = jogo.Jogadores.JogadorLocal
        local userId = tostring(player.UserId)
        Se self.permanentCache[key] e self.permanentCache[key] == userId então
            retornar verdadeiro
        fim
    fim
    Se KeyConfig.USE_PREFIX e não KeyConfig.USE_EXTERNAL_LIST então
        se string.sub(key, 1, #KeyConfig.PERMANENT_KEY_PREFIX) == KeyConfig.PERMANENT_KEY_PREFIX então
            retornar verdadeiro
        fim
    fim
    retornar falso
fim

função KeySystem:verifyWithLootlabs(chave)
    se self:isPermanentKey(key) então
        self.isPermanent = true
        retornar verdadeiro
    fim
    se Lootlabs_Config não estiver habilitado, então
        retornar falso
    fim
    sucesso local, resposta = pcall(função()
        dados locais = { chave = chave, token_api = Lootlabs_Config.API_Key }
        local jsonData = game:GetService("HttpService"):JSONEncode(data)
        se syn e syn.request então
            retornar syn.request({
                URL = Lootlabs_Config.API_URL,
                Método = "POST",
                Cabeçalhos = { ["Content-Type"] = "application/json" },
                Corpo = dados JSON
            })
        outro
            retornar jogo:HttpGet(Lootlabs_Config.API_URL .. "?key=" .. key .. "&api_token=" .. Lootlabs_Config.API_Key)
        fim
    fim)
    se for bem-sucedido, então
        se type(response) == "string" então
            local decodificado = jogo:GetService("HttpService"):JSONDecode(resposta)
            retorna decodificado e decodificado.válido == verdadeiro
        senão se resposta e resposta.StatusCode == 200 então
            local decodificado = game:GetService("HttpService"):JSONDecode(response.Body)
            retorna decodificado e decodificado.válido == verdadeiro
        fim
    fim
    retornar falso
fim

função KeySystem:showKeyUI()
    -- (UI da key – mantida da versão anterior)
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
    mainFrame.Parent = fundo

    logotipo local = Instance.new("TextLabel")
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
    userIdLabel.Text = "ID do usuário: " .. self.userId
    userIdLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    userIdLabel.TextSize = 13
    userIdLabel.Font = Enum.Font.GothamMedium
    userIdLabel.Parent = mainFrame

    local expiryLabel = Instance.new("TextLabel")
    expiryLabel.Size = UDim2.new(1, 0, 0, 25)
    expiryLabel.Position = UDim2.new(0, 0, 0, 85)
    expiryLabel.BackgroundTransparency = 1
    expiryLabel.Text = "TIPOS DE CHAVE: DIÁRIO (24H) OU PERMANENTE"
    expiryLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    expiryLabel.TextSize = 13
    expiryLabel.Font = Enum.Font.GothamBold
    rótuloDeExpiração.Pai = quadroPrincipal

    local dateLabel = Instance.new("TextLabel")
    dateLabel.Size = UDim2.new(1, 0, 0, 20)
    dateLabel.Position = UDim2.new(0, 0, 0, 110)
    dateLabel.BackgroundTransparency = 1
    dateLabel.Text = "Data: " .. os.date("%d/%m/%Y %H:%M")
    dateLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    dateLabel.TextSize = 12
    dateLabel.Font = Enum.Font.GothamMedium
    dateLabel.Parent = mainFrame

    instruções locais = Instance.new("TextLabel")
    instruções.Tamanho = UDim2.novo(1, 0, 0, 50)
    instruções.Posição = UDim2.new(0, 0, 0, 135)
    instruções.TransparênciaDeFundo = 1
    instruções.Text = "INSIRA SUA KEY\n(Diário grátis via LootLabs ou compra permanente)"
    instruções.TextColor3 = Color3.fromRGB(180, 180, 180)
    instruções.TamanhoDoTexto = 14
    instruções.Fonte = Enum.Fonte.GothamMedium
    instruções.TextWrapped = true
    instruções.Pai = mainFrame

    local getKeyBtn = Instance.new("TextButton")
    getKeyBtn.Size = UDim2.new(0.6, 0, 0, 35)
    getKeyBtn.Position = UDim2.new(0.2, 0, 0, 195)
    getKeyBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    getKeyBtn.BorderSizePixel = 0
    getKeyBtn.Text = "OBTER DIÁRIO DE CHAVE (LOOTLABS)"
    getKeyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    getKeyBtn.TextSize = 13
    getKeyBtn.Font = Enum.Font.GothamBold
    getKeyBtn.Parent = mainFrame

    getKeyBtn.MouseButton1Click:Connect(function()
        se Lootlabs_Config.Link e Lootlabs_Config.Link ~= "" então
            setclipboard(Lootlabs_Config.Link)
            status.Text = "LINK COPIADO. ACESSE E OBTENHA SUA KEY DIARIA"
            status.TextColor3 = Color3.fromRGB(0, 255, 100)
        outro
            status.Text = "ERRO: LINK DO LOOTLABS NÃO CONFIGURADO"
            status.TextColor3 = Color3.fromRGB(255, 80, 80)
        fim
    fim)

    local permInfo = Instance.new("TextLabel")
    permInfo.Size = UDim2.new(1, 0, 0, 25)
    permInfo.Position = UDim2.new(0, 0, 0, 240)
    permInfo.BackgroundTransparency = 1
    permInfo.Text = "KEY PERMANENTE: Compre e receba uma chave única"
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
    textBox.PlaceholderText = "Cole sua chave aqui..."
    textBox.ClearTextOnFocus = false
    textBox.Parent = mainFrame

    local verifyBtn = Instance.new("TextButton")
    verifyBtn.Size = UDim2.new(0.4, 0, 0, 45)
    verifyBtn.Position = UDim2.new(0.3, 0, 0, 335)
    verifyBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    verifyBtn.BorderSizePixel = 0
    verifyBtn.Text = "VERIFICAR"
    verificarBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    tamanhoTexto do botão de verificação = 18
    verifyBtn.Font = Enum.Font.GothamBold
    verifyBtn.Parent = mainFrame

    status local = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 30)
    status.Position = UDim2.new(0, 0, 0, 395)
    status.BackgroundTransparency = 1
    status.Text = "Aguardando chave..."
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
    status.TextSize = 14
    status.Font = Enum.Font.GothamMedium
    status.Parent = mainFrame

    local retryInfo = Instance.new("TextLabel")
    retryInfo.Size = UDim2.new(1, 0, 0, 25)
    retryInfo.Position = UDim2.new(0, 0, 0, 430)
    retryInfo.BackgroundTransparency = 1
    retryInfo.Text = "Tentativas: 0/5"
    retryInfo.TextColor3 = Color3.fromRGB(150, 150, 150)
    retryInfo.TextSize = 12
    retryInfo.Font = Enum.Font.GothamMedium
    retryInfo.Parent = mainFrame

    local validInfo = Instance.new("TextLabel")
    validInfo.Size = UDim2.new(1, 0, 0, 20)
    validInfo.Position = UDim2.new(0, 0, 0, 460)
    validInfo.BackgroundTransparency = 1
    validInfo.Text = "Chave diária 24h | Permanente nunca expira"
    validInfo.TextColor3 = Color3.fromRGB(100, 100, 100)
    validInfo.TextSize = 11
    validInfo.Font = Enum.Font.GothamMedium
    validInfo.Parent = mainFrame

    função local verifyKey(chave)
        se não houver chave ou chave == "" então
            status.Text = "Digite uma chave válida."
            status.TextColor3 = Color3.fromRGB(255, 80, 80)
            retornar falso
        fim

        status.Text = "Verificando chave..."
        status.TextColor3 = Color3.fromRGB(255, 215, 0)

        local isValid = falso
        local isPermanent = falso

        isPermanent = self:isPermanentKey(chave)

        Se Lootlabs_Config.Enabled e não isPermanent então
            local verificado = self:verifyWithLootlabs(chave)
            se verificado então
                é válido = verdadeiro
            fim
        senão se for permanente então
            é válido = verdadeiro
        fim

        se isValid então
            self.verificado = verdadeiro
            self.usuárioAtual = self.idDoUsuário
            self.isPermanent = isPermanent
            local dataDeExpiração = isPermanent e 0 ou (os.time() + (24 * 3600))
            self:saveUserKey(self.userId, key, expiryDate, isPermanent)
            status.Text = isPermanent e "KEY PERMANENTE VALIDA. (Nunca expira)" ou "KEY DIARIA VALIDA. (24h)"
            status.TextColor3 = Color3.fromRGB(0, 255, 100)
            aguarde(0.8)
            screenGui:Destruir()
            retornar verdadeiro
        outro
            self.retryAttempts = self.retryAttempts + 1
            retryInfo.Text = "Tentativas: " .. self.retryAttempts .. "/5"
            status.Text = "CHAVE INVÁLIDA. Tente novamente."
            status.TextColor3 = Color3.fromRGB(255, 80, 80)
            se self.retryAttempts >= 5 então
                status.Text = "Muitas tentativas de falhas."
                status.TextColor3 = Color3.fromRGB(255, 80, 80)
                verifyBtn.Visible = false
                textBox.Visible = false
                local closeBtn = Instance.new("TextButton")
                closeBtn.Size = UDim2.new(0.4, 0, 0, 40)
                closeBtn.Position = UDim2.new(0.3, 0, 0, 335)
                closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                closeBtn.BorderSizePixel = 0
                closeBtn.Text = "FECHAR"
                closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                closeBtn.TextSize = 16
                closeBtn.Font = Enum.Font.GothamBold
                closeBtn.Parent = mainFrame
                closeBtn.MouseButton1Click:Connect(function()
                    screenGui:Destruir()
                fim)
            fim
            retornar falso
        fim
    fim

    verifyBtn.MouseButton1Click:Connect(function()
        chave local = textBox.Text
        verificarChave(chave)
    fim)

    textBox.FocusLost:Connect(function(enterPressed)
        se EnterPressionado então
            chave local = textBox.Text
            verificarChave(chave)
        fim
    fim)

    local savedData = self:loadUserKey(self.userId)
    se savedData então
        se não self:isKeyExpired(savedData) então
            textBox.Text = savedData.key
            aguarde(0,5)
            verificarChave(dados salvos.chave)
        outro
            status.Text = saveData.isPermanent e "KEY PERMANENTE EXPIRADA? (Erro)" ou "KEY DIARIA EXPIRADA. Pegue uma nova."
            status.TextColor3 = Color3.fromRGB(255, 200, 0)
        fim
    fim

    retornar screenGui
fim

função KeySystem:verificar()
    Se self.verified então retorne verdadeiro fim

    local savedData = self:loadUserKey(self.userId)
    se savedData então
        se não self:isKeyExpired(savedData) então
            local verificado = falso
            se savedData.isPermanent então
                verificado = verdadeiro
            senão se Lootlabs_Config.Enabled então
                verificado = self:verifyWithLootlabs(savedData.key)
            fim
            se verificado então
                self.verificado = verdadeiro
                self.isPermanent=salvoData.isPermanent
                retornar verdadeiro
            fim
        outro
            print("Chave expirada. Pegue uma nova.")
            Logger.log("Chave expirada para usuário " .. self.userId)
        fim
    fim

    self:showKeyUI()

    embora não seja autoverificado
        aguarde(0,5)
    fim

    retornar self.verificado
fim

-- ============================================
-- GERADOR AUTOMÁTICO DE CHAVES PERMANENTES (MODO ADMIN)
-- ============================================
local KeyGenerator = {}
KeyGenerator.__index = KeyGenerator

função KeyGenerator.new()
    local self = setmetatable({}, KeyGenerator)
    retornar a si mesmo
fim

função KeyGenerator:generateRandomString(comprimento)
    caracteres locais = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    resultado local = ""
    math.randomseed(os.time() + math.random(1, 99999))
    para i = 1, comprimento faça
        local idx = math.random(1, #chars)
        resultado = resultado .. string.sub(chars, idx, idx)
    fim
    retornar resultado
fim

função KeyGenerator:generateKey()
    prefixo local = KeyConfig.PERMANENT_KEY_PREFIX
    local randomPart = self:generateRandomString(8)
    retornar prefixo .. parteAleatória
fim

função KeyGenerator:showAdminUI()
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
    mainFrame.Parent = fundo

    título local = Instance.new("TextLabel")
    título.Tamanho = UDim2.novo(1, 0, 0, 45)
    título.Posição = UDim2.new(0, 0, 0, 10)
    título.TransparênciaDeFundo = 1
    title.Text = "GERADOR DE CHAVES PERMANENTES"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    título.TamanhoDoTexto = 24
    título.Fonte = Enum.Fonte.GothamBold
    título.Pai = mainFrame

    local labelUserId = Instance.new("TextLabel")
    rótuloUserId.Size = UDim2.new(1, -20, 0, 25)
    labelUserId.Position = UDim2.new(0, 10, 0, 65)
    labelUserId.BackgroundTransparency = 1
    labelUserId.Text = "UserId do comprador:"
    labelUserId.TextColor3 = Color3.fromRGB(200, 200, 200)
    labelUserId.TextSize = 14
    labelUserId.Font = Enum.Font.GothamMedium
    labelUserId.TextXAlignment = Enum.TextXAlignment.Left
    rótuloUserId.Parent = mainFrame

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
    textBoxUserId.PlaceholderText = "Insira o UserId do comprador"
    textBoxUserId.ClearTextOnFocus = false
    textBoxUserId.Parent = mainFrame

    local generateBtn = Instance.new("TextButton")
    generateBtn.Size = UDim2.new(0.6, 0, 0, 45)
    generateBtn.Position = UDim2.new(0.2, 0, 0, 155)
    gerarBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    generateBtn.BorderSizePixel = 0
    generateBtn.Text = "GERAR CHAVE"
    gerarBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    generateBtn.TextSize = 18
    generateBtn.Font = Enum.Font.GothamBold
    generateBtn.Parent = mainFrame

    local resultLabel = Instance.new("TextLabel")
    resultLabel.Size = UDim2.new(1, -20, 0, 30)
    resultLabel.Position = UDim2.new(0, 10, 0, 215)
    resultLabel.BackgroundTransparency = 1
    resultLabel.Text = "Aguardando geração..."
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
    copyBtn.Text = "COPIAR CHAVE"
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
    closeBtn.Text = "FECHAR"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = mainFrame

    local generatedKey = nil

    generateBtn.MouseButton1Click:Connect(function()
        local userId = textBoxUserId.Text
        se userId == "" então
            resultLabel.Text = "ERRO: Insira um UserId válido."
            resultLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            retornar
        fim

        -- Chave Gerar
        chave local = self:generateKey()
        chaveGerada = chave

        resultLabel.Text = "Chave gerada: " .. key .. " (associada ao UserId " .. userId .. ")"
        resultLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        copyBtn.Visible = true

        -- Copiar automaticamente
        definirá a área de transferência (tecla)
        resultLabel.Text = resultLabel.Text .. "\n(Chave copiada para a área de transferência)"

        -- Instruções adicionais
        aguarde(0,5)
        resultLabel.Text = resultLabel.Text .. "\n\nAdicione ao perm_keys.json:\n\"" .. key .. "\": \"" .. userId .. "\""
    fim)

    copyBtn.MouseButton1Click:Connect(function()
        se generatedKey então
            definiráaáreadetransferência(chavegerada)
            resultLabel.Text = "Chave copiada novamente."
        fim
    fim)

    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destruir()
        print("Modo administrador encerrado. Execute o script novamente para usar o modo normal.")
    fim)
fim

-- ============================================
-- SISTEMA DE CACHE
-- ============================================
local Cache = {}
Cache.__index = Cache

função Cache.new()
    local self = setmetatable({}, Cache)
    self.dados = {
        beli = 0,
        domínio = {},
        nível = 0,
        fragmentos = 0,
    }
    self.lastUpdate = 0
    self.ttl = 2
    retornar a si mesmo
fim

função Cache:getBeli(agente)
    local agora = os.time()
    se agora - self.lastUpdate > self.ttl então
        self.data.beli = agente:getBeli()
        para _, estilo em ipairs(agent.fightingStyles) faça
            self.data.mastery[style.name] = agent:getStyleMastery(style.name)
        fim
        self.data.level = agent.state.level
        self.data.fragments = agent.state.fragments
        self.lastUpdate = agora
    fim
    retornar self.data.beli
fim

função Cache:getMastery(styleName)
    retornar self.data.mastery[styleName] ou 0
fim

-- ============================================
-- BYPASS ANTI-CHEAT
-- ============================================
local AntiCheat = {}
AntiCheat.__index = AntiCheat

função AntiCheat.new()
    local self = setmetatable({}, AntiCheat)
    self.delayBase = 0.08
    self.delayVariation = 0.04
    retornar a si mesmo
fim

função AntiCheat:obterAtrasoAleatório()
    retornar self.delayBase + math.random() * self.delayVariation
fim

função AntiCheat:humanizarAção(callback)
    pcall(função()
        atraso local = self:getRandomDelay()
        aguarde(atraso)
        se math.random(1, 10) == 1 então
            aguarde(math.random(1, 5) * 0.01)
        fim
        ligar de volta()
    fim)
fim

-- ============================================
-- OTIMIZAÃ‡ÃƒO
-- ============================================
função local optimizeGame()
    pcall(função()
        print("Aplicando otimizações...")
        iluminação local = jogo:GetService("Iluminação")
        se houver iluminação então
            iluminação.FimDaNévoa = 100000
            iluminação.InícioDaNévoa = 100000
            iluminação.FogColor = Color3.fromRGB(0, 0, 0)
            iluminação.Ambiente = Cor3.deRGB(100, 100, 100)
            iluminação.Brilho = 1
            iluminação.SombrasGlobais = falso
            iluminação.ClockTime = 12
        fim
        para _, v em pares(iluminação:GetChildren()) faça
            se v:IsA("Atmosfera") então v:Destruir() fim
        fim
        configurações locais = Configurações do Usuário()
        qualidade local = configurações:GetService("UserGameSettings")
        se for qualidade então
            qualidade.MasterVolume = 0
            quality.QualityLevel = 1
        fim
        para _, v em pares(game.Workspace:GetDescendants()) faça
            se v:IsA("ParticleEmitter") ou v:IsA("Trail") ou v:IsA("Smoke") ou v:IsA("Fire") então
                v.Ativado = falso
            fim
            se v:IsA("Decalque") e não v.Name:find("Importante") então
                v:Destruir()
            fim
        fim
        coletarlixo()
        print("Otimizações aplicadas.")
        Logger.log("Otimizações aplicadas.")
    fim)
fim

-- ============================================
-- GUI COMPLETA (ABAS, BARRAS, BOTÃ•ES, LOGS)
-- ============================================
GUI local = {}
GUI.__index = GUI

função GUI.new(agente)
    local self = setmetatable({}, GUI)
    self.agente = agente
    self.created = falso
    self.paused = falso
    self.logs = {}
    retornar a si mesmo
fim

função GUI:criar()
    se self.created então retorne fim
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

    -- Cabeceira
    cabeçalho local = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 40)
    cabeçalho.CorDeFundo3 = Cor3.fromRGB(255, 200, 0)
    header.BackgroundTransparency = 0.1
    header.BorderSizePixel = 0
    cabeçalho.Pai = mainFrame

    título local = Instance.new("TextLabel")
    título.Tamanho = UDim2.novo(0.6, 0, 1, 0)
    título.Posição = UDim2.new(0, 10, 0, 0)
    título.TransparênciaDeFundo = 1
    título.Texto = "SCRIPT GOGO - IA"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    título.TamanhoDoTexto = 16
    título.Fonte = Enum.Fonte.GothamBold
    título.TextXAlignment = Enum.TextXAlignment.Left
    título.Pai = cabeçalho

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(0.3, 0, 1, 0)
    statusLabel.Position = UDim2.new(0.7, 0, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "ATIVO"
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right
    statusLabel.Parent = cabeçalho
    self.statusLabel = statusLabel

    -- Abas
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, 0, 0, 30)
    tabContainer.Position = UDim2.new(0, 0, 0, 40)
    tabContainer.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = mainFrame

    local tabs = {"Estado", "Estatísticas", "Controles"}
    self.tabButtons = {}
    para i, nome em ipairs(tabs) faça
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1/#tabs, 0, 1, 0)
        btn.Position = UDim2.new((i-1)/#tabs, 0, 0, 0)
        btn.BackgroundTransparency = 1
        btn.Text = nome
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamMedium
        btn.Parent = tabContainer

        local underline = Instance.new("Frame")
        underline.Size = UDim2.new(0.8, 0, 0, 2)
        underline.Position = UDim2.new(0.1, 0, 1, -2)
        underline.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        underline.BackgroundTransparency = i == 1 e 0 ou 1
        underline.BorderSizePixel = 0
        sublinhado.Pai = btn
        self.tabButtons[i] = {btn = btn, underline = underline}
        btn.MouseButton1Click:Connect(function()
            self:switchTab(i)
        fim)
    fim

    -- Área de conteúdo
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

    -- Ã rea de toras
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
fim

função GUI:switchTab(índice)
    para i, painel em ipairs(self.painéis) faça
        se painel então painel.Visível = (i == índice) fim
    fim
    para i, tab em ipairs(self.tabButtons) faça
        tab.underline.BackgroundTransparency = (i == index) e 0 ou 1
    fim
fim

função GUI:createStatePanel(pai)
    painel local = Instance.new("Frame")
    panel.Size = UDim2.new(1, 0, 1, 0)
    painel.TransparênciaDeFundo = 1
    painel.Visível = falso
    painel.Pai = pai
    tabela.inserir(self.painéis, painel)

    local y = 10
    função local adicionarRótulo(texto, cor, tamanho, negrito)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 22)
        lbl.Position = UDim2.new(0, 10, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Texto = texto
        lbl.TextColor3 = cor ou Color3.fromRGB(220, 220, 220)
        lbl.TextSize = tamanho ou 13
        lbl.Font = negrito e Enum.Font.GothamBold ou Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = painel
        y = y + 26
        retornar lbl
    fim

    self.stateLabels = {}
    self.stateLabels.decision = addLabel("Decisão: Aguardando...", Color3.fromRGB(255, 200, 0), 14, true)
    self.stateLabels.level = addLabel("Nível: 1 / 2800", Color3.fromRGB(255, 255, 255))
    self.stateLabels.fragments = addLabel("Fragmentos: 0 / 16500", Color3.fromRGB(255, 255, 255))
    self.stateLabels.beli = addLabel("Beli: 0", Color3.fromRGB(255, 200, 0))
    self.stateLabels.style = addLabel("Estilo: Nenhum", Color3.fromRGB(255, 255, 255))
    self.stateLabels.mastery = addLabel("Domínio: 0", Color3.fromRGB(255, 255, 255))
    self.stateLabels.godhuman = addLabel("GodHuman: BLOQUEADO", Color3.fromRGB(255, 80, 80))
    self.stateLabels.uptime = addLabel("Tempo: 0s", Color3.fromRGB(200, 200, 200), 12, false)
    self.stateLabels.boost = addLabel("2x XP: INATIVO", Color3.fromRGB(255, 200, 0), 12, false)
fim

função GUI:criarPainelDeEstatísticas(pai)
    painel local = Instance.new("Frame")
    panel.Size = UDim2.new(1, 0, 1, 0)
    painel.TransparênciaDeFundo = 1
    painel.Visível = falso
    painel.Pai = pai
    tabela.inserir(self.painéis, painel)

    local y = 10
    função local adicionarProgresso(rótulo, valor, máximo, cor)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -20, 0, 28)
        frame.Position = UDim2.new(0, 10, 0, y)
        frame.BackgroundTransparency = 1
        frame.Parent = painel

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.4, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Texto = rótulo
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
        bar.BackgroundColor3 = cor ou Color3.fromRGB(255, 200, 0)
        bar.BorderSizePixel = 0
        barra.Pai = fundo

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
        retornar {barra = barra, val = val, max = max, label = label}
    fim

    self.statsBars = {}
    self.statsBars.level = addProgress("Level", 1, 2800, Color3.fromRGB(255, 200, 0))
    self.statsBars.fragments = addProgress("Fragmentos", 0, 16500, Color3.fromRGB(0, 200, 255))
    self.statsBars.combat = addProgress("Combat", 0, 1, Color3.fromRGB(200, 200, 200))
    self.statsBars.water = addProgress("Water Kung Fu", 0, 500, Color3.fromRGB(100, 200, 255))
    self.statsBars.electric = addProgress("Electric", 0, 500, Color3.fromRGB(255, 200, 0))
    self.statsBars.dragon = addProgress("Sopro de Dragão", 0, 500, Color3.fromRGB(255, 100, 50))
    self.statsBars.superhuman = addProgress("Superhuman", 0, 400, Color3.fromRGB(0, 255, 100))
    self.statsBars.deathstep = addProgress("Death Step", 0, 400, Color3.fromRGB(150, 0, 200))
    self.statsBars.sharkman = addProgress("Sharkman Karate", 0, 400, Color3.fromRGB(0, 150, 255))
    self.statsBars.electricclaw = addProgress("Electric Claw", 0, 400, Color3.fromRGB(255, 255, 0))
    self.statsBars.dragontalon = addProgress("Dragon Talon", 0, 400, Color3.fromRGB(255, 50, 0))
fim

função GUI:criarPainelDeControles(pai)
    painel local = Instance.new("Frame")
    panel.Size = UDim2.new(1, 0, 1, 0)
    painel.TransparênciaDeFundo = 1
    painel.Visível = falso
    painel.Pai = pai
    tabela.inserir(self.painéis, painel)

    local y = 10
    função local addButton(texto, cor, retorno de chamada)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.8, 0, 0, 35)
        btn.Position = UDim2.new(0.1, 0, 0, y)
        btn.BackgroundColor3 = cor ou Color3.fromRGB(255, 200, 0)
        btn.BorderSizePixel = 0
        btn.Text = texto
        btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
        btn.Parent = painel
        btn.MouseButton1Click:Conectar(callback)
        y = y + 42
        botão de retorno
    fim

    self.pauseBtn = addButton("PAUSAR IA", Color3.fromRGB(255, 200, 0), function()
        self.paused = não self.paused
        self.pauseBtn.Text = self.paused e "RETOMAR IA" ou "PAUSAR IA"
        self.statusLabel.Text = self.paused e "PAUSADO" ou "ATIVO"
        self.statusLabel.TextColor3 = self.paused e Color3.fromRGB(255, 200, 0) ou Color3.fromRGB(0, 255, 100)
        self:addLog(self.paused and "IA PAUSADA" or "IA RETOMADA")
        Logger.log(self.paused e "IA pausada" ou "IA retomada")
        Webhook.send(self.paused and "IA pausada" or "IA retomada")
    fim)

    addButton("RESETAR PROGRESSO", Color3.fromRGB(255, 80, 80), function()
        self:addLog("Redefinindo progresso...")
        self.agent:resetProgress()
        self:addLog("Progresso redefinido.")
        Logger.log("Progresso redefinido.")
        Webhook.send("Progresso redefinido.")
    fim)

    addButton("SALVAR AGORA", Color3.fromRGB(0, 200, 100), function()
        self.agent:saveState()
        self:addLog("Estado salvo.")
        Logger.log("Estado salvo manualmente.")
    fim)

    self.redeemBtn = addButton("RESGATE AUTOMÁTICO: ATIVO", Color3.fromRGB(0, 200, 100), function()
        CodeConfig.Enabled = não CodeConfig.Enabled
        self.redeemBtn.Text = CodeConfig.Enabled e "AUTO RESGATAR: ATIVO" ou "AUTO RESGATAR: INATIVO"
        self.redeemBtn.BackgroundColor3 = CodeConfig.Enabled e Color3.fromRGB(0, 200, 100) ou Color3.fromRGB(200, 80, 80)
        self:addLog("Auto Redeem " .. (CodeConfig.Enabled e "ativado" ou "desativado"))
        Logger.log("Resgate Automático " .. (CodeConfig.Enabled e "ativado" ou "desativado"))
    fim)
fim

função GUI:adicionarLog(msg)
    hora local = os.date("%H:%M:%S")
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = "[" .. tempo .. "] " .. msg
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = self.logContainer

    self.logContainer.Size = UDim2.new(1, 0, 0, #self.logContainer:GetChildren() * 18)
    self.logScroll.CanvasSize = UDim2.new(0, 0, 0, #self.logContainer:GetChildren() * 18)
    self.logScroll.ScrollBarPosition = Enum.ScrollBarPosition.Bottom
    aguarde(0.1)
    self.logScroll.CanvasPosition = Vector2.new(0, self.logScroll.CanvasSize.Y.Offset)
fim

função GUI:atualizar(estado, agente)
    se não for self.created, retorne end
    pcall(função()
        se self.stateLabels então
            self.stateLabels.decision.Text = "Decisão: " .. (state.currentDecision ou "Aguardando...")
            self.stateLabels.level.Text = "Nível: " .. (state.level ou 1) .. " / 2800"
            self.stateLabels.fragments.Text = "Fragmentos: " .. (state.fragments or 0) .. " / 16500"
            local beli = agente:getBeli()
            self.stateLabels.beli.Text = "Beli: "..beli
            self.stateLabels.style.Text = "Estilo: " .. (state.currentStyle or "Nenhum")
            domínio local = agente:obterDomínioDeEstilo(estado.estiloAtual ou "")
            self.stateLabels.mastery.Text = "Domínio: " .. domínio
            self.stateLabels.godhuman.Text = state.godhuman e "GodHuman: DESBLOQUEADO" ou "GodHuman: BLOQUEADO"
            self.stateLabels.godhuman.TextColor3 = state.godhuman e Color3.fromRGB(0, 255, 100) ou Color3.fromRGB(255, 80, 80)
            self.stateLabels.uptime.Text = "Tempo: " .. (state.uptime or 0) .. "s"
            self.stateLabels.boost.Text = "2x XP: " .. (agent.xpBoostActive e "ATIVO" ou "INATIVO")
            self.stateLabels.boost.TextColor3 = agent.xpBoostActive e Color3.fromRGB(0, 255, 100) ou Color3.fromRGB(200, 200, 200)
        fim

        se self.statsBars então
            função local atualizarBarra(barra, valor, máximo)
                se bar e max e max > 0 então
                    local pct = math.min(val / max, 1)
                    bar.bar.Size = UDim2.new(pct, 0, 1, 0)
                    bar.val.Text = math.floor(pct * 100) .. "%"
                fim
            fim
            atualizarBarra(self.statsBars.level, state.level, 2800)
            atualizarBarra(self.statsBars.fragments, state.fragments, 16500)
            para _, estilo em ipairs(agent.fightingStyles) faça
                local barName = style.name:gsub(" ", ""):lower()
                Se barName == "waterkungfu" então barName = "water" fim
                Se barName == "deathstep" então barName = "deathstep" fim
                Se barName == "electricclaw" então barName = "electricclaw" fim
                Se barName == "garra de dragão" então barName = "garra de dragão" fim
                Se barName == "dragonbreath" então barName = "dragon" fim
                local bar = self.statsBars[barName]
                se bar então
                    domínio local = agente:obterDomínioDeEstilo(estilo.nome)
                    local required = style.v1 e 500 ou 400
                    se style.name == "Combat" então required = 1 fim
                    atualizarBarra(barra, domínio, necessário)
                fim
            fim
        fim
    fim)
fim

-- ============================================
-- AGENTE PRINCIPAL
-- ============================================
Agente local = {}
Agente.__index = Agente

função Agente.novo()
    local self = setmetatable({}, Agente)

    self.keySystem = KeySystem.new()
    print("Verificando chave...")
    se não self.keySystem:verify() então
        print("Chave invalida ou expirada.")
        retornar nulo
    fim
    print("Chave verificada com sucesso.")

    self.antiCheat = AntiCheat.new()
    self.fileName = "scriptgogo_data.json"
    self.state = self:loadState()
    self.cache = Cache.new()

    pcall(função()
        self.player = game.Players.LocalPlayer
        self.character = self.player.Character ou self.player.CharacterAdded:Wait()
        self.humanoid = self.character:WaitForChild("Humanoid")
        self.rootPart = self.character:WaitForChild("HumanoidRootPart")
    fim)

    self.httpService = game:GetService("HttpService")
    self.tweenService = game:GetService("TweenService")
    self.replicatedStorage = game:GetService("ReplicatedStorage")

    self.maxLevel = 2800
    self.fragmentsNeeded = 16500
    autodomínioV1 = 500
    autodomínioV2 = 400
    self.targetBeli = 50000
    self.xpBoostActive = falso
    self.lastCodeCheck = 0
    self.lastSaveTime = 0

    self.estilosdeluta = {
        {name = "Combat", v1 = true, sea = "First Sea", masteryRequired = 1, unlocked = false, mastery = 0, obtained = false},
        {name = "Kung Fu da Água", v1 = true, sea = "Primeiro Mar", masteryRequired = 500, unlocked = false, mastery = 0, obtained = false},
        {nome = "Elétrico", v1 = true, mar = "Primeiro Mar", maestriaRequerida = 500, desbloqueado = false, maestria = 0, obtido = false},
        {nome = "Sopro do Dragão", v1 = true, mar = "Segundo Mar", maestriaNecessária = 500, desbloqueado = false, maestria = 0, obtido = false},
        {name = "Superhuman", v1 = false, sea = "Second Sea", masteryRequired = 400, unlocked = false, mastery = 0, obtained = false, requires = {"Combat", "Water Kung Fu", "Electric"}},
        {name = "Passo da Morte", v1 = false, sea = "Segundo Mar", masteryRequired = 400, unlocked = false, mastery = 0, obtained = false, requires = {"Combat", "Water Kung Fu", "Electric"}},
        {name = "Sharkman Karate", v1 = false, sea = "Third Sea", masteryRequired = 400, unlocked = false, mastery = 0, obtained = false, requires = {"Water Kung Fu", "Dragon Breath"}},
        {name = "Garra Elétrica", v1 = false, sea = "Terceiro Mar", masteryRequired = 400, unlocked = false, mastery = 0, obtained = false, requires = {"Elétrica", "Sopro do Dragão"}},
        {name = "Garra de Dragão", v1 = false, sea = "Terceiro Mar", masteryRequired = 400, unlocked = false, mastery = 0, obtained = false, requires = {"Sopro de Dragão", "Super-humano"}}
    }

    self.godhumanRequirements = {
        estilos = {"Superhumano", "Passo da Morte", "Caratê do Homem-Tubarão", "Garra Elétrica", "Garra de Dragão"},
        fragmentosNecessários = 16500,
        nívelRequerido = 2000
    }

    self.haki = {desbloqueado = falso, domínio = 0, ativo = falso}
    self.state.currentDecision = "Inicializando..."
    self.runningActions = {}

    self.gui = GUI.new(self)
    self.gui:criar()
    self.gui:addLog("Script carregado. Aguardando inicio...")
    Logger.log("Script iniciado para usuário " .. self.keySystem.userId)
    Webhook.send("Script iniciado. Versão 21.0")

    retornar a si mesmo
fim

função Agente:carregarEstado()
    sucesso local, dados = pcall(função()
        se isfile(self.fileName) então
            conteúdo local = lerararquivo(self.nomeDoArquivo)
            retornar jogo:GetService("HttpService"):JSONDecode(conteúdo)
        fim
        retornar nulo
    fim)
    Se houver sucesso e os dados estiverem presentes, retorne os dados. Fim.
    retornar {
        nível = 1, xp = 0, fragmentos = 0, deushumano = falso,
        raidsCompleted = 0, currentSea = "First Sea",
        currentStyle = nulo, uptime = 0, lastRaidTime = 0,
        missõesConcluídas = 0,
        haki = {desbloqueado = falso, maestria = 0, nível = 0},
        estilosObtidos = {},
        códigosrecompensados ​​= {},
        configurações = {
            autoFarm = true, autoQuest = true, autoRaid = true,
            autoMastery = verdadeiro, autoSpinFruit = verdadeiro,
            autoTeleportFruit = verdadeiro, autoSwitchSea = verdadeiro,
            autoHaki = true, autoMasteryAllStyles = true
        }
    }
fim

função Agente:saveState()
    pcall(função()
        local json = self.httpService:JSONEncode(self.state)
        escreverarquivo(self.nomeDoArquivo, json)
        Logger.log("Estado salvo automaticamente.")
    fim)
fim

função Agente:redefinirProgresso()
    self.estado = {
        nível = 1, xp = 0, fragmentos = 0, deushumano = falso,
        raidsCompleted = 0, currentSea = "First Sea",
        currentStyle = nulo, uptime = 0, lastRaidTime = 0,
        missõesConcluídas = 0,
        haki = {desbloqueado = falso, maestria = 0, nível = 0},
        estilosObtidos = {},
        códigosrecompensados ​​= {},
        configurações = {
            autoFarm = true, autoQuest = true, autoRaid = true,
            autoMastery = verdadeiro, autoSpinFruit = verdadeiro,
            autoTeleportFruit = verdadeiro, autoSwitchSea = verdadeiro,
            autoHaki = true, autoMasteryAllStyles = true
        }
    }
    para _, estilo em ipairs(self.fightingStyles) faça
        estilo.obtido = falso
        estilo.desbloqueado = falso
        estilo.domínio = 0
    fim
    self:saveState()
    Logger.log("Progresso redefinido.")
fim

função Agente:obterBeli()
    local beli = 0
    pcall(função()
        dados locais = self.player:FindFirstChild("Dados")
        se houver dados então
            local b = data:FindFirstChild("Beli")
            se b então beli = b.Valor fim
        fim
    fim)
    retornar beli
fim

função Agente:obterDomínioDeEstilo(nomeDoEstilo)
    domínio local = 0
    pcall(função()
        dados locais = self.player:FindFirstChild("Dados")
        se houver dados então
            local m = data:FindFirstChild(styleName .. "Mastery")
            se m então domínio = m.Valor fim
        fim
    fim)
    retornar domínio
fim

função Agente:obterDadosDeEstilo(nomeDoEstilo)
    para _, estilo em ipairs(self.fightingStyles) faça
        Se style.name == styleName, então retorne style.
    fim
    retornar nulo
fim

função Agente:hasRequisitosDeEstilo(estilo)
    Se não `style.requires`, retorne verdadeiro.
    para _, reqName em ipairs(style.requires) faça
        local reqStyle = self:getStyleData(reqName)
        Se não reqStyle ou não reqStyle.obtido, retorne falso.
        domínio local = self:getStyleMaster(reqName)
        Se o nível de domínio for menor que 500, retorne falso.
    fim
    retornar verdadeiro
fim

função Agente:obterEstilo(nomeDoEstilo)
    pcall(função()
        estilo local = self:getStyleData(styleName)
        Se não for um estilo ou um estilo obtido, retorne o fim.
        Se style.sea ~= self.state.currentSea então retorne fim
        se não style.v1 e não self:hasStyleRequirements(style) então retorne fim
        self.antiCheat:humanizeAction(function()
            self.replicatedStorage.Remotes.CommF_:InvokeServer("Buy", styleName)
        fim)
        estilo.obtido = verdadeiro
        self.state.stylesObtained[styleName] = true
        self:saveState()
        self.gui:addLog("Estilo obtido: " .. styleName)
        Logger.log("Estilo obtido: " .. styleName)
        Webhook.send("Estilo obtido: " .. styleName)
    fim)
fim

função Agente:equiparEstilo(nomeDoEstilo)
    pcall(função()
        self.antiCheat:humanizeAction(function()
            self.replicatedStorage.Remotes.CommF_:InvokeServer("Equip", styleName)
        fim)
        self.state.currentStyle = styleName
        self:saveState()
        self.gui:addLog("Estilo equipado: " .. styleName)
        Logger.log("Estilo equipado: " ..styleName)
    fim)
fim

função Agente:obterPróximoEstiloParaMestre()
    se self.state.currentStyle == "Combat" então
        local beli = self:getBeli()
        se beli <self.targetBeli então
            retornar "Combate"
        outro
            para _, estilo em ipairs(self.fightingStyles) faça
                se style.name ~= "Combat" e não style.obtained e self:canObtainStyle(style) então
                    retornar estilo.nome
                fim
            fim
            retornar nulo
        fim
    fim
    para _, requiredStyle em ipairs(self.godhumanRequirements.styles) faça
        local styleData = self:getStyleData(requiredStyle)
        se styleData então
            domínio local = self:getStyleMaster(estilo necessário)
            local required = styleData.v1 e self.masteryV1 ou self.masteryV2
            se não styleData.obtido então
                Se self:canObtainStyle(styleData) então retorne requiredStyle fim
            senão se o domínio for menor que o exigido então
                retornar requiredStyle
            fim
        fim
    fim
    para _, estilo em ipairs(self.fightingStyles) faça
        se style.v1 e style.name ~= "Combat" então
            domínio local = self:getStyleMaster(style.name)
            Se não houver um estilo obtido e o próprio estilo puder ser obtido, retorne o nome do estilo.
            Se style.obtido e mastery < self.masteryV1 então retorne style.name fim
        fim
    fim
    para _, estilo em ipairs(self.fightingStyles) faça
        se não for style.v1 então
            domínio local = self:getStyleMaster(style.name)
            Se não houver um estilo obtido e o próprio estilo puder ser obtido, retorne o nome do estilo.
            Se style.obtido e mastery < self.masteryV2 então retorne style.name fim
        fim
    fim
    retornar nulo
fim

função Agente:podeObterEstilo(estilo)
    Se style.sea ~= self.state.currentSea então retorne falso.
    Se não style.v1 e não self:hasStyleRequirements(style), retorne falso.
    retornar verdadeiro
fim

função Agente:autoMasteryAllStyles()
    se não self.state.settings.autoMasteryAllStyles então retorne fim
    se self.state.godhuman então retorne fim

    local nextStyle = self:getNextStyleToMaster()
    se não nextStyle então
        self.gui:addLog("Nenhum estilo disponível para masterizar.")
        retornar
    fim

    local styleData = self:getStyleData(nextStyle)
    Se não houver styleData, retorne end

    se não styleData.obtido então
        self:obterEstilo(próximoEstilo)
        aguarde(1)
        Se não houver styleData.obtido, retorne o fim.
    fim

    se self.state.currentStyle ~= nextStyle então
        self:equiparEstilo(próximoEstilo)
        aguarde(0,5)
    fim

    local currentMastery = self:getStyleMastery(nextStyle)
    local requiredMastery = styleData.masteryRequired
    se domínioAtual < domínioRequerido então
        self:ataquerápido()
    outro
        styleData.unlocked = true
        self:saveState()
        self.gui:addLog(nextStyle .. " masterizado. (" .. currentMastery .. "/" .. requiredMastery .. ")")
        Logger.log(nextStyle .. " masterizado. (" .. currentMastery .. "/" .. requiredMastery .. ")")
    fim
fim

função Agente:desbloquearDeusHumano()
    pcall(função()
        se self.state.godhuman então retorne fim
        local allStylesMastered = true
        para _, styleName em ipairs(self.godhumanRequirements.styles) faça
            estilo local = self:getStyleData(styleName)
            se não houver estilo ou se não houver estilo obtido, então todosOsEstilosDominados = falso. Interrompa o processo.
            domínio local = self:getStyleMaster(styleName)
            se maestria < 400 então todosOsEstilosDominados = falso interromper fim
        fim
        se não todos os estilos estiverem dominados, então
            self.gui:addLog("Ainda faltam estilos para GodHuman.")
            retornar
        fim
        se self.state.fragments < self.fragmentsNeeded então
            self.gui:addLog("Fragmentos insuficientes: " .. self.state.fragments .. "/" .. self.fragmentsNeeded)
            self:autoRaid()
            retornar
        fim
        se self.state.level < 2000 então
            self.gui:addLog("Nível insuficiente: " .. self.state.level .. "/2000")
            retornar
        fim
        self.antiCheat:humanizeAction(function()
            self.replicatedStorage.Remotes.CommF_:InvokeServer("Buy", "GodHuman")
        fim)
        self.state.godhuman = verdadeiro
        self:saveState()
        self.gui:addLog("GODHUMAN DESBLOQUEADO COM SUCESSO.")
        Logger.log("GODHUMAN DESBLOQUEADO")
        Webhook.send("GODHUMAN DESBLOQUEADO!")
    fim)
fim

função Agente:obterInimigosPróximos(raio)
    inimigos locais = {}
    charPos local = self.rootPart.Position
    pcall(função()
        para _, v em pares(game.Workspace:GetChildren()) faça
            se v:IsA("Model") e v:FindFirstChild("Humanoid") e v:FindFirstChild("HumanoidRootPart") então
                se v.Name ~= self.character.Name e v.Humanoid.Health > 0 então
                    local dist = (v.HumanoidRootPart.Position - charPos).Magnitude
                    se dist <= raio então tabela.inserir(inimigos, v) fim
                fim
            fim
        fim
    fim)
    retornar inimigos
fim

função Agente:obterMultiplicadorXP()
    base local = (self.state.currentSea == "First Sea" and 1) or (self.state.currentSea == "Second Sea" and 1.5) or 2
    se self.xpBoostActive então base = base * 2 fim
    retornar base
fim

função Agente:verificarNívelUp()
    local necessário = self.state.level * 100 + 50
    enquanto (self.state.xp ou 0) >= necessário e self.state.level < self.maxLevel faça
        self.state.xp = self.state.xp - necessário
        self.state.level = self.state.level + 1
        necessário = self.state.level * 100 + 50
        self.gui:addLog("Subiu de nível. " .. self.state.level .. "/2800")
        Logger.log("Subiu de nível. " .. self.state.level .. "/2800")
        Webhook.send("Suba de nível. " .. self.state.level .. "/2800")
        self:saveState()
        se self.state.settings.autoSwitchSea então
            se self.state.level >= 700 e self.state.currentSea == "First Sea" então
                self:switchSea("Segundo Mar")
            senão se self.state.level >= 1500 e self.state.currentSea == "Segundo Mar" então
                self:switchSea("Terceiro Mar")
            fim
        fim
    fim
fim

função Agente:teleportarPara(posição)
    pcall(function() self.rootPart.CFrame = CFrame.new(position) end)
fim

função Agente:switchMar(mar)
    pcall(função()
        Se self.state.currentSea == sea então retorne fim
        mares locais = {
            ["Segundo Mar"] = Vector3.new(1200, 150, 8000),
            ["Terceiro Mar"] = Vector3.new(-6000, 150, 6000)
        }
        local pos = mares[mar]
        se positivo então
            self:teleportTo(pos)
            self.state.currentSea = mar
            self.gui:addLog("Mudou para " .. mar)
            Logger.log("Mudou para ".. mar)
            Webhook.send("Mudou para ".. mar)
            self:saveState()
        fim
    fim)
fim

função Agente:moverParaIlhaAleatória()
    ilhas locais = {
        ["Primeiro Mar"] = {Vector3.new(-1200, 80, 2800), Vector3.new(300, 50, 4500), Vector3.new(-4500, 100, -2500)},
        ["Segundo Mar"] = {Vector3.new(1200, 150, 8000), Vector3.new(5000, 500, 0), Vector3.new(-3000, 100, 7000)},
        ["Terceiro Mar"] = {Vector3.new(0, 400, 0), Vector3.new(3000, 300, 3000), Vector3.new(-6000, 150, 6000)}
    }
    local seaIslands = ilhas[self.state.currentSea] ou ilhas["First Sea"]
    local pos = seaIslands[math.random(1, #seaIslands)]
    se pos então self:teleportTo(pos) fim
fim

função Agente:ataquerá
    pcall(função()
        se self.state.settings.autoHaki então self:autoHaki() fim
        inimigos locais = self:getNearbyEnemies(80)
        se #inimigos == 0 então self:moverParaIlhaAleatória() retornar fim
        alvo local = inimigos[1]
        self:teleportTo(target.HumanoidRootPart.Position + Vector3.new(0, 5, 0))
        ataques locais = math.random(2, 5)
        para i = 1, os ataques fazem
            self.antiCheat:humanizeAction(function()
                self.replicatedStorage.Remotes.CommF_:InvokeServer("Attack", {[1] = target.HumanoidRootPart})
            fim)
            aguarde(0,085 + math.random(0, 5) * 0,001)
        fim
        local xpGain = 50 * self:getXPMultiplier()
        self.state.xp = (self.state.xp ou 0) + xpGanho
        self:verificarNívelAvançado()
        local currentStyle = self.state.currentStyle
        se currentStyle então
            domínio local = self:getStyleMaster(estiloAtual)
            self.state.masteryProgress = self.state.masteryProgress ou {}
            self.state.masteryProgress[currentStyle] = maestria
            self:saveState()
        fim
    fim)
fim

função Agente:autoHaki()
    se não self.state.settings.autoHaki então retorne fim
    se não self.state.haki.unlocked então
        se self.state.level >= 50 então
            pcall (função()
                self.replicatedStorage.Remotes.CommF_:InvokeServer("Haki", "Unlock")
                aguarde(1)
                se self.character:FindFirstChild("Haki") então
                    self.state.haki.unlocked = true
                    self:saveState()
                    self.gui:addLog("Haki desbloqueado.")
                    Logger.log("Haki desbloqueado.")
                fim
            fim)
        fim
        retornar
    fim
    pcall(função()
        local hakiAbility = self.character:FindFirstChild("Haki")
        se hakiAbility e não hakiAbility.Enabled então
            self.antiCheat:humanizeAction(function()
                self.replicatedStorage.Remotes.CommF_:InvokeServer("Haki", "Enable")
            fim)
            self.gui:addLog("Haki ativado.")
        fim
    fim)
fim

função Agente:autoRaid()
    se não self.state.settings.autoRaid então retorne fim
    se self.state.godhuman então retorne fim
    Se self.state.level < 700 então retorne fim
    local currentTime = os.time()
    Se currentTime - (self.state.lastRaidTime ou 0) < 120 então retorne fim
    pcall(função()
        self.gui:addLog("Iniciando Raid Ice...")
        Logger.log("Iniciando Raid Ice.")
        self.replicatedStorage.Remotes.CommF_:InvokeServer("Raid", "Start", "Ice")
        aguarde(2)
        local raidTime = 0
        enquanto raidTime < 180 faça
            inimigos locais = self:getNearbyEnemies(150)
            se #inimigos > 0 então self:ataquerápido() fim
            TempoDeIncursão = TempoDeIncursão + 1
            aguarde(1)
        fim
        self.replicatedStorage.Remotes.CommF_:InvokeServer("Raid", "Complete")
        fragmentsEarned local = 300 + math.random(0, 150)
        self.state.fragments = (self.state.fragments ou 0) + fragmentsEarned
        self.state.raidsCompleted = (self.state.raidsCompleted ou 0) + 1
        self.state.lastRaidTime = os.time()
        self:saveState()
        self.gui:addLog("Raid completada. +" .. fragmentosEarned .. "fragmentos")
        Logger.log("Raid concluída. +" .. fragmentsEarned .. " fragmentos")
        Webhook.send("Raid concluída. +" .. fragmentsEarned .. " fragmentos")
    fim)
fim

função Agente:autoQuest()
    se não self.state.settings.autoQuest então retorne fim
    pcall(função()
        local questData = self.replicatedStorage.Remotes.CommF_:InvokeServer("Quest", "Check")
        se não questData ou não questData.Active então
            npcs locais = {}
            para _, v em pares(game.Workspace:GetChildren()) faça
                se v:IsA("Model") e v:FindFirstChild("Humanoid") e
                   (v.Name:find("NPC") ou v.Name:find("Quest")) então
                    tabela.inserir(npcs, v)
                fim
            fim
            se #npcs > 0 então
                local npc = npcs[math.random(1, #npcs)]
                self:teleportTo(npc.HumanoidRootPart.Position + Vector3.new(0, 5, 0))
                aguarde(1)
                self.replicatedStorage.Remotes.CommF_:InvokeServer("Quest", "Start")
                self.gui:addLog("Questão aceita.")
                Logger.log("Missão aceita.")
            fim
        outro
            self:ataquerápido()
            progresso local = self.replicatedStorage.Remotes.CommF_:InvokeServer("Quest", "Check")
            se houver progresso e progresso.Complete então
                self.replicatedStorage.Remotes.CommF_:InvokeServer("Quest", "Complete")
                self.state.questsCompleted = (self.state.questsCompleted ou 0) + 1
                bônus localXP = 200 * self:getXPMultiplier()
                self.state.xp = (self.state.xp ou 0) + bonusXP
                self:verificarNívelAvançado()
                self:saveState()
                self.gui:addLog("Quest completada. +" .. bônusXP .. " XP")
                Logger.log("Missão concluída. +" .. bonusXP .. " XP")
            fim
        fim
    fim)
fim

função Agente:autoGirarFrutas()
    se não self.state.settings.autoSpinFruit então retorne fim
    pcall(função()
        giros locais = self.player.Data.Spins.Value
        se spins > 0 então
            self.antiCheat:humanizeAction(function()
                fruta local = self.replicatedStorage.Remotes.CommF_:InvokeServer("Spin", "Spin")
                se for fruta, então
                    self.gui:addLog("Fruta obtida: " .. fruta)
                    Logger.log("Fruta obtida: " .. fruta)
                fim
            fim)
        fim
    fim)
fim

agente de função:autoTeleportFruit()
    se não self.state.settings.autoTeleportFruit então retorne fim
    pcall(função()
        Frutas lendárias locais = {"Dragão","Leopardo","Massa","Veneno","Espírito","Kitsune","Yeti","Gravidade","Sombra","Luz"}
        para _, v em pares(game.Workspace:GetChildren()) faça
            se v:IsA("Model") e v:FindFirstChild("Fruit") então
                nomeDaFrutaLocal = v.Nome
                local isLegendary = falso
                para _, f em ipairs(legendaryFruits) faça
                    se fruitName:find(f) então isLegendary = true break end
                fim
                se isLegendary então
                    self.antiCheat:humanizeAction(function()
                        local pos = v.HumanoidRootPart.Position
                        self:teleportTo(pos + Vector3.new(0, 5, 0))
                        clique local = v:FindFirstChild("ClickDetector")
                        se clicar então
                            detectordeclique de fogo(clique)
                            self.gui:addLog("Fruta lendaria coletada: " .. frutaName)
                            Logger.log("Fruta lendaria coletada: " .. frutaName)
                            Webhook.send("Fruta lendaria coletada: " .. frutaName)
                        fim
                    fim)
                fim
            fim
        fim
    fim)
fim

função Agente:autoRedeemCodes()
    Se não CodeConfig.Enabled, retorne.
    local agora = os.time()
    Se agora - self.lastCodeCheck < CodeConfig.CheckInterval então retorne fim
    self.lastCodeCheck = agora

    pcall(função()
        códigos locais = {}
        se CodeConfig.CodesURL ~= "" então
            conteúdo local = jogo:HttpGet(CodeConfig.CodesURL)
            para cada linha em string.gmatch(content, "[^\r\n]+") faça
                se linha e linha ~= "" então tabela.inserir(códigos, linha) fim
            fim
        fim
        para _, código em ipairs(CodeConfig.FixedCodes) faça
            tabela.inserir(códigos, código)
        fim

        local único = {}
        para _, código em ipairs(códigos) faça
            se não unique[code] então unique[code] = verdadeiro fim
        fim
        códigos = {}
        para cada código em pares (únicos) faça tabela.inserir(códigos, código) fim

        para _, código em ipairs(códigos) faça
            se não self.state.redeemedCodes[code] então
                self.antiCheat:humanizeAction(function()
                    local remoto = self.replicatedStorage.Remotes.CommF_
                    se for remoto então
                        resultado local = remoto:InvokeServer("Código", código)
                        se resultado e resultado == "Resgatado" então
                            self.state.redeemedCodes[code] = true
                            self.xpBoostActive = true
                            self:saveState()
                            self.gui:addLog("Código resgatado: " .. code .. " (2x XP ativado)")
                            Logger.log("Código resgatado: " .. código)
                            Webhook.send("Código resgatado: " .. código)
                        senão se resultado e resultado == "Já Resgatado" então
                            self.state.redeemedCodes[code] = true
                            self:saveState()
                        fim
                    fim
                fim)
                aguarde(1)
            fim
        fim
    fim)
fim

função Agente:decidirPrioridade()
    se self.gui.paused então
        self.state.currentDecision = "PAUSADO"
        retornar
    fim

    local agora = os.time()
    se agora - self.lastSaveTime >= Config.SAVE_INTERVAL então
        self:saveState()
        self.lastSaveTime = agora
    fim

    self:autoRedeemCodes()

    se self.state.godhuman então
        se self.state.level < self.maxLevel então
            self.state.currentDecision = "Nível Maximo (" .. self.state.level .. "/" .. self.maxLevel .. ")"
            self:ataquerápido()
            self:autoQuest()
        outro
            self.state.currentDecision = "Concluído. (Jogo zerado)"
            self:autoGirarFrutas()
            self:autoTeleportFruit()
        fim
        retornar
    fim

    local allStylesMastered = true
    para _, estilo em ipairs(self.fightingStyles) faça
        se style.name ~= "Combat" então
            domínio local = self:getStyleMaster(style.name)
            local required = style.v1 e self.masteryV1 ou self.masteryV2
            Se o estilo obtido e o domínio forem menores que o exigido, então
                todosOsEstilosDominados = falso
                quebrar
            fim
            se não houver estilo obtido então
                todosOsEstilosDominados = falso
                quebrar
            fim
        fim
    fim

    se todos os estilos estiverem dominados, então
        self.state.currentDecision = "Maestria completa, focando GodHuman"
        se self.state.fragments < self.fragmentsNeeded então
            self.state.currentDecision = "Fragmentos Faltam (" .. self.state.fragments .. "/" .. self.fragmentsNeeded .. ")"
            self:autoRaid()
            retornar
        fim
        se self.state.level < 2000 então
            self.state.currentDecision = "Níveis Faltam (" .. self.state.level .. "/2000)"
            self:ataquerápido()
            self:autoQuest()
            retornar
        fim
        self:desbloquearDeusHumano()
        retornar
    fim

    local nextStyle = self:getNextStyleToMaster()
    se nextStyle então
        self.state.currentDecision = "Masterizando " .. nextStyle
        self:autoMasteryAllStyles()
        retornar
    fim

    se self.state.currentSea == "First Sea" e self.state.level >= 700 então
        self.state.currentDecision = "Mudando para Second Sea"
        self:switchSea("Segundo Mar")
        retornar
    senão se self.state.currentSea == "Segundo Mar" e self.state.level >= 1500 então
        self.state.currentDecision = "Mudando para Third Sea"
        self:switchSea("Terceiro Mar")
        retornar
    fim

    self.state.currentDecision = "Fazenda genérica"
    self:ataquerápido()
    self:autoQuest()
fim

função Agente:executar()
    print("SCRIPT GOGO - EM EXECUÇÃO.")
    self.gui:addLog("IA foi iniciada. Objetivo: Zerar o jogo.")
    Logger.log("IA iniciada.")
    Webhook.send("IA iniciada.")

    enquanto verdadeiro faz
        pcall(função()
            self:decidePriority()
            self:autoHaki()
            self.gui:atualizar(self.state, self)
            self.state.uptime = (self.state.uptime ou 0) + 1
        fim)
        tarefa.esperar(0.5)
    fim
fim

-- ============================================
-- INTRO
-- ============================================
função local showIntro()
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

    brilho local = Instance.new("Frame")
    brilho.Tamanho = UDim2.novo(1, 0, 1, 0)
    brilho.CorDeFundo3 = Cor3.fromRGB(255, 200, 0)
    brilho.Transparência de fundo = 0,95
    brilho.TamanhoDaBordaPixel = 0
    brilho.Pai = fundo

    script local = Instance.new("TextLabel")
    scriptName.Size = UDim2.new(1, 0, 0, 50)
    scriptName.Position = UDim2.new(0, 0, 0.2, 0)
    scriptName.BackgroundTransparency = 1
    scriptName.Text = "SCRIPT GOGO"
    scriptName.TextColor3 = Color3.fromRGB(255, 215, 0)
    scriptName.TextSize = 50
    scriptName.Font = Enum.Font.GothamBold
    scriptName.TextScaled = true
    scriptName.Parent = fundo

    legenda local = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0, 40)
    subtitle.Position = UDim2.new(0, 0, 0.35, 0)
    legenda.TransparênciaDeFundo = 1
    legenda.Texto = "GODHUMAN FARMER ULTIMATE"
    subtítulo.TextColor3 = Color3.fromRGB(255, 255, 255)
    subtitle.TextSize = 30
    legenda.Fonte = Enum.Fonte.GothamMedium
    legenda.TextoEscalado = verdadeiro
    legenda.TextTransparência = 0,5
    legenda.Pai = fundo

    versão local = Instance.new("TextLabel")
    version.Size = UDim2.new(1, 0, 0, 25)
    versão.Posição = UDim2.new(0, 0, 0.45, 0)
    versão.TransparênciaDeFundo = 1
    version.Text = "V21.0 - GERADOR DE CHAVES"
    versão.TextColor3 = Color3.fromRGB(255, 215, 0)
    versão.TextSize = 16
    versão.Fonte = Enum.Fonte.GothamMedium
    versão.TextoEscalado = verdadeiro
    versão.TextTransparência = 0,7
    versão.Pai = fundo

    linha local = Instance.new("Frame")
    line.Size = UDim2.new(0.5, 0, 0, 2)
    linha.Posição = UDim2.new(0.25, 0, 0.52, 0)
    linha.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    linha.TransparênciaDeFundo = 0,5
    linha.BorderSizePixel = 0
    linha.Pai = fundo

    local loadText = Instance.new("TextLabel")
    loadText.Size = UDim2.new(1, 0, 0, 30)
    loadText.Position = UDim2.new(0, 0, 0.65, 0)
    loadText.BackgroundTransparency = 1
    loadText.Text = "CARREGANDO IA DECISIVA..."
    loadText.TextColor3 = Color3.fromRGB(255, 255, 255)
    loadText.TextSize = 16
    loadText.Font = Enum.Font.GothamMedium
    loadText.TextTransparency = 0.5
    loadText.Parent = fundo

    local loadBarBg = Instance.new("Frame")
    loadBarBg.Size = UDim2.new(0.4, 0, 0, 4)
    loadBarBg.Position = UDim2.new(0.3, 0, 0.72, 0)
    loadBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    loadBarBg.BorderSizePixel = 0
    loadBarBg.Parent = fundo

    local loadBar = Instance.new("Frame")
    loadBar.Size = UDim2.new(0, 0, 1, 0)
    loadBar.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    loadBar.BorderSizePixel = 0
    loadBar.Parent = loadBarBg

    créditos locais = Instance.new("TextLabel")
    credits.Size = UDim2.new(1, 0, 0, 20)
    credits.Position = UDim2.new(0, 0, 0.88, 0)
    créditos.TransparênciaDeFundo = 1
    credits.Text = "POWERED BY SCRIPT GOGO"
    créditos.TextColor3 = Color3.fromRGB(100, 100, 100)
    créditos.TamanhoDoTexto = 12
    créditos.Fonte = Enum.Fonte.GothamMedium
    créditos.TextTransparência = 0,5
    créditos.Pai = fundo

    local startTime = tick()
    duração local = 3,5

    jogo:ObterServiço("ExecutarServiço").RenderEscalonado:Conectar(função()
        local decorrido = tick() - tempoInicial
        progresso local = math.min(tempo decorrido / duração, 1)
        scriptName.TextTransparency = 1 - progresso
        scriptName.Position = UDim2.new(0, 0, 0.2 - (1 - progresso) * 0.05, 0)
        legenda.TransparênciaDoTexto = 0,5 - progresso * 0,5
        loadBar.Size = UDim2.new(progress, 0, 1, 0)
        brilho.TransparênciaDeFundo = 0,95 - progresso * 0,3
        se o progresso for maior ou igual a 1, então
            aguarde(0,5)
            screenGui:Destruir()
        fim
    fim)

    aguarde(4)
fim

-- ============================================
-- INICIALIZAÇÃOÃ‡ÃƒO
-- ============================================

-- Se o modo administrador estiver ativo, mostra o gerador de chaves
se ADMIN_MODE então
    print("[ADMIN] Modo administrador ativado. Abrindo gerador de chaves...")
    gerador local = KeyGenerator.new()
    gerador:mostrarInterfaceAdministrativa()
    -- Fica à espera que o administrador feche a janela
    enquanto espere(1) faça
        se não game:GetService("CoreGui"):FindFirstChild("AdminKeyGenerator") então
            quebrar
        fim
    fim
    print("[ADMIN] Gerador de chaves encerrado.")
    return -- Termina o script após gerar uma chave
fim

-- Modo normal (execução principal)
proteção local = ProtectionSystem.new()
se protection:checkDetection() então
    print("[PROTEÇÃO] MODO SEGURO ATIVADO.")
    aguarde(60)
    local emergencyFunc = protection:loadEmergencyScript()
    se emergencyFunc então
        funçãoDeEmergência()
    outro
        print("[PROTECAO] Nenhuma versão de emergência disponível. Encerrando.")
        retornar
    fim
fim

atualizador local = UpdateSystem.new()
atualizador:verificarAtualização()
se updater.updateAvailable então
    tarefa.spawn(função()
        atualizador:baixarAtualização()
    fim)
fim

local func = updater:loadScript()
se func então
    print("[SCRIPT] Executando versão principal...")
    mostrarIntrodução()
    otimizarJogo()
    agente local = Agente.novo()
    se agente então
        agente:executar()
    outro
        print("Falha ao inicializar o agente. Verifique sua chave.")
    fim
outro
    print("[SCRIPT] ERRO: Falha ao carregar script.")
fim

print("SCRIPT GOGO - FINALIZADO")
