-- Wiky | Joiner Script - Minimal Style with Whitelist
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- WHITELIST
local WHITELIST = {
    "stealaluckyrot",
    "FelipeZhuL",
    "gerardo19548",
    "Papysavage10",
    "Justblockspin1",
    "LezzoStore7",
	"26is",
	"pabloo33kskxkx"
	"Eduzinnv9",
    "waicol556"
}

-- Verificar whitelist
local function isWhitelisted(username)
    for _, whitelistedUser in ipairs(WHITELIST) do
        if username:lower() == whitelistedUser:lower() then
            return true
        end
    end
    return false
end

-- Kickear si no está en whitelist
if not isWhitelisted(LocalPlayer.Name) then
    LocalPlayer:Kick("❌ You are not whitelisted to use this script.")
    return
end

-- Variables
local isRunning = false
local multiplicate = 1000000
local minValue = 10 * multiplicate
local API_URL = "https://pet-logger.vercel.app/api/instances"
local cachedLogs = {}
local lastFetchTime = 0
local fetchCooldown = 2
local teleportAttempts = 0
local maxTeleportAttempts = 3

-- Función HTTP mejorada con reintentos
local function httpRequest(url, retries)
    retries = retries or 3
    for i = 1, retries do
        local success, result = pcall(function()
            local req = http_request or request or (syn and syn.request)
            if req then
                return req({
                    Url = url, 
                    Method = "GET", 
                    Headers = {["Content-Type"] = "application/json"}
                }).Body
            else
                return HttpService:GetAsync(url, true)
            end
        end)
        if success and result then 
            return result 
        end
        if i < retries then task.wait(0.5) end
    end
    return nil
end

-- Función para cerrar UIs de teleport automáticamente
local function setupTeleportUICloser()
    task.spawn(function()
        while true do
            task.wait(0.1)
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, gui in pairs(playerGui:GetChildren()) do
                    if gui:IsA("ScreenGui") and gui.Name ~= "WikyJoinerMinimal" then
                        for _, descendant in pairs(gui:GetDescendants()) do
                            if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
                                local text = descendant.Text:lower()
                                if text:find("full") or text:find("lleno") or 
                                   text:find("error") or text:find("failed") or 
                                   text:find("unable") or text:find("no disponible") or
                                   text:find("disconnected") or text:find("desconectado") then
                                    
                                    for _, btn in pairs(gui:GetDescendants()) do
                                        if btn:IsA("TextButton") and (
                                           btn.Text:lower():find("ok") or 
                                           btn.Text:lower():find("close") or 
                                           btn.Text:lower():find("cerrar") or
                                           btn.Text == "X") then
                                            pcall(function()
                                                for _, connection in pairs(getconnections(btn.MouseButton1Click)) do
                                                    connection:Fire()
                                                end
                                            end)
                                        end
                                    end
                                    
                                    task.wait(0.2)
                                    pcall(function() gui:Destroy() end)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Crear GUI Minimalista
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WikyJoinerMinimal"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Frame Principal (estilo minimalista azul/gris)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -150)
MainFrame.Size = UDim2.new(0, 350, 0, 300)
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

-- Header minimalista azul
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(60, 110, 180)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 8)
HeaderCorner.Parent = Header

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 8)
HeaderFix.Position = UDim2.new(0, 0, 1, -8)
HeaderFix.BackgroundColor3 = Color3.fromRGB(60, 110, 180)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

local Title = Instance.new("TextLabel")
Title.Parent = Header
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, -90, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "Wiky | Joiner"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Botón de minimizar
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -70, 0, 10)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(70, 120, 190)
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 16
MinimizeBtn.Parent = Header

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 6)
MinimizeCorner.Parent = MinimizeBtn

-- Botón de cerrar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(70, 120, 190)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

-- Efectos hover
MinimizeBtn.MouseEnter:Connect(function()
    TweenService:Create(MinimizeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 130, 200)}):Play()
end)

MinimizeBtn.MouseLeave:Connect(function()
    TweenService:Create(MinimizeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 120, 190)}):Play()
end)

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 130, 200)}):Play()
end)

CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 120, 190)}):Play()
end)

-- Funcionalidad de minimizar (sin animación)
local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 350, 0, 50)
        MainFrame.Position = UDim2.new(0.5, -175, 0, 10)
    else
        MainFrame.Size = UDim2.new(0, 350, 0, 300)
        MainFrame.Position = UDim2.new(0.5, -175, 0.5, -150)
    end
    MinimizeBtn.Text = isMinimized and "+" or "—"
end)

CloseBtn.MouseButton1Click:Connect(function()
    isRunning = false
    ScreenGui:Destroy()
end)

-- Tabs
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -30, 0, 32)
TabContainer.Position = UDim2.new(0, 15, 0, 58)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = MainFrame

local MainTab = Instance.new("TextButton")
MainTab.Size = UDim2.new(0.48, 0, 1, 0)
MainTab.BackgroundColor3 = Color3.fromRGB(60, 110, 180)
MainTab.BorderSizePixel = 0
MainTab.Text = "Main"
MainTab.TextColor3 = Color3.fromRGB(255, 255, 255)
MainTab.Font = Enum.Font.GothamBold
MainTab.TextSize = 12
MainTab.Parent = TabContainer

local MainTabCorner = Instance.new("UICorner")
MainTabCorner.CornerRadius = UDim.new(0, 6)
MainTabCorner.Parent = MainTab

local LogsTab = Instance.new("TextButton")
LogsTab.Size = UDim2.new(0.48, 0, 1, 0)
LogsTab.Position = UDim2.new(0.52, 0, 0, 0)
LogsTab.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
LogsTab.BorderSizePixel = 0
LogsTab.Text = "Logs"
LogsTab.TextColor3 = Color3.fromRGB(150, 150, 150)
LogsTab.Font = Enum.Font.GothamBold
LogsTab.TextSize = 12
LogsTab.Parent = TabContainer

local LogsTabCorner = Instance.new("UICorner")
LogsTabCorner.CornerRadius = UDim.new(0, 6)
LogsTabCorner.Parent = LogsTab

-- Content Frame
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -30, 1, -105)
ContentFrame.Position = UDim2.new(0, 15, 0, 98)
ContentFrame.BackgroundTransparency = 1
ContentFrame.ClipsDescendants = true
ContentFrame.Parent = MainFrame

-- MAIN PANEL
local MainPanel = Instance.new("Frame")
MainPanel.Size = UDim2.new(1, 0, 1, 0)
MainPanel.BackgroundTransparency = 1
MainPanel.Visible = true
MainPanel.Parent = ContentFrame

local MinLabel = Instance.new("TextLabel")
MinLabel.Size = UDim2.new(1, 0, 0, 16)
MinLabel.BackgroundTransparency = 1
MinLabel.Text = "Min Value"
MinLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
MinLabel.Font = Enum.Font.Gotham
MinLabel.TextSize = 11
MinLabel.TextXAlignment = Enum.TextXAlignment.Left
MinLabel.Parent = MainPanel

local MinInput = Instance.new("TextBox")
MinInput.Size = UDim2.new(1, 0, 0, 36)
MinInput.Position = UDim2.new(0, 0, 0, 20)
MinInput.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
MinInput.BorderSizePixel = 1
MinInput.BorderColor3 = Color3.fromRGB(70, 70, 80)
MinInput.Text = minValue
MinInput.TextColor3 = Color3.fromRGB(255, 255, 255)
MinInput.Font = Enum.Font.Gotham
MinInput.TextSize = 13
MinInput.ClearTextOnFocus = false
MinInput.PlaceholderText = "Enter minimum value..."
MinInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
MinInput.Parent = MainPanel

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinInput

local MinPadding = Instance.new("UIPadding")
MinPadding.PaddingLeft = UDim.new(0, 10)
MinPadding.Parent = MinInput

MinInput.Focused:Connect(function()
    TweenService:Create(MinInput, TweenInfo.new(0.2), {BorderColor3 = Color3.fromRGB(60, 110, 180)}):Play()
end)

MinInput.FocusLost:Connect(function()
    TweenService:Create(MinInput, TweenInfo.new(0.2), {BorderColor3 = Color3.fromRGB(70, 70, 80)}):Play()
    local input = tonumber(MinInput.Text)
    if input and input > 0 then
        minValue = input
        MinInput.Text = tostring(input)
    else
        MinInput.Text = tostring(minValue)
    end
end)

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(1, 0, 0, 38)
ToggleButton.Position = UDim2.new(0, 0, 0, 64)
ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 110, 180)
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "START"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 13
ToggleButton.AutoButtonColor = false
ToggleButton.Parent = MainPanel

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleButton

ToggleButton.MouseEnter:Connect(function()
    if not isRunning then
        TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 120, 190)}):Play()
    else
        TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}):Play()
    end
end)

ToggleButton.MouseLeave:Connect(function()
    if not isRunning then
        TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 110, 180)}):Play()
    else
        TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 60, 60)}):Play()
    end
end)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 80)
StatusLabel.Position = UDim2.new(0, 0, 0, 110)
StatusLabel.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
StatusLabel.BorderSizePixel = 1
StatusLabel.BorderColor3 = Color3.fromRGB(70, 70, 80)
StatusLabel.Text = "Ready"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.TextWrapped = true
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top
StatusLabel.Parent = MainPanel

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 6)
StatusCorner.Parent = StatusLabel

local StatusPadding = Instance.new("UIPadding")
StatusPadding.PaddingTop = UDim.new(0, 8)
StatusPadding.PaddingLeft = UDim.new(0, 10)
StatusPadding.PaddingRight = UDim.new(0, 10)
StatusPadding.Parent = StatusLabel

-- LOGS PANEL
local LogsPanel = Instance.new("Frame")
LogsPanel.Size = UDim2.new(1, 0, 1, 0)
LogsPanel.BackgroundTransparency = 1
LogsPanel.Visible = false
LogsPanel.Parent = ContentFrame

local LogsScroll = Instance.new("ScrollingFrame")
LogsScroll.Size = UDim2.new(1, 0, 1, 0)
LogsScroll.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
LogsScroll.BorderSizePixel = 1
LogsScroll.BorderColor3 = Color3.fromRGB(70, 70, 80)
LogsScroll.ScrollBarThickness = 4
LogsScroll.ScrollBarImageColor3 = Color3.fromRGB(60, 110, 180)
LogsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
LogsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
LogsScroll.Parent = LogsPanel

local LogsScrollCorner = Instance.new("UICorner")
LogsScrollCorner.CornerRadius = UDim.new(0, 6)
LogsScrollCorner.Parent = LogsScroll

local LogsLayout = Instance.new("UIListLayout")
LogsLayout.Padding = UDim.new(0, 6)
LogsLayout.SortOrder = Enum.SortOrder.LayoutOrder
LogsLayout.Parent = LogsScroll

local LogsPadding = Instance.new("UIPadding")
LogsPadding.PaddingTop = UDim.new(0, 6)
LogsPadding.PaddingLeft = UDim.new(0, 6)
LogsPadding.PaddingRight = UDim.new(0, 6)
LogsPadding.PaddingBottom = UDim.new(0, 6)
LogsPadding.Parent = LogsScroll

-- Funciones
local function updateStatus(text, color)
    StatusLabel.Text = text
    if color then
        StatusLabel.TextColor3 = color
    end
end

local function formatValue(v)
    if v >= 1e9 then return string.format("%.2fB", v / 1e9)
    elseif v >= 1e6 then return string.format("%.2fM", v / 1e6)
    elseif v >= 1e3 then return string.format("%.1fK", v / 1e3)
    else return tostring(v) end
end

local function addHoverEffect(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = normalColor}):Play()
    end)
end

local function createLogEntry(log, index)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -12, 0, 70)
    entry.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    entry.BorderSizePixel = 1
    entry.BorderColor3 = Color3.fromRGB(70, 70, 80)
    entry.LayoutOrder = index
    
    local entryCorner = Instance.new("UICorner")
    entryCorner.CornerRadius = UDim.new(0, 6)
    entryCorner.Parent = entry
    
    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -110, 0, 16)
    name.Position = UDim2.new(0, 8, 0, 6)
    name.BackgroundTransparency = 1
    name.Text = log.animal.name or "Unknown"
    name.TextColor3 = Color3.fromRGB(255, 255, 255)
    name.Font = Enum.Font.GothamBold
    name.TextSize = 12
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.TextTruncate = Enum.TextTruncate.AtEnd
    name.Parent = entry
    
    local value = Instance.new("TextLabel")
    value.Size = UDim2.new(0.5, -8, 0, 14)
    value.Position = UDim2.new(0, 8, 0, 24)
    value.BackgroundTransparency = 1
    value.Text = "💎 " .. formatValue(log.animal.value or 0)
    value.TextColor3 = Color3.fromRGB(200, 200, 200)
    value.Font = Enum.Font.Gotham
    value.TextSize = 10
    value.TextXAlignment = Enum.TextXAlignment.Left
    value.Parent = entry
    
    local rarity = Instance.new("TextLabel")
    rarity.Size = UDim2.new(0.5, -8, 0, 14)
    rarity.Position = UDim2.new(0.5, 0, 0, 24)
    rarity.BackgroundTransparency = 1
    rarity.Text = "⭐ " .. (log.animal.rarity or "N/A")
    rarity.TextColor3 = Color3.fromRGB(200, 200, 200)
    rarity.Font = Enum.Font.Gotham
    rarity.TextSize = 10
    rarity.TextXAlignment = Enum.TextXAlignment.Left
    rarity.Parent = entry
    
    local age = Instance.new("TextLabel")
    age.Size = UDim2.new(1, -110, 0, 14)
    age.Position = UDim2.new(0, 8, 0, 40)
    age.BackgroundTransparency = 1
    age.Text = "⏱ " .. (log.age or 0) .. "s ago"
    age.TextColor3 = Color3.fromRGB(180, 180, 180)
    age.Font = Enum.Font.Gotham
    age.TextSize = 9
    age.TextXAlignment = Enum.TextXAlignment.Left
    age.Parent = entry
    
    local players = Instance.new("TextLabel")
    players.Size = UDim2.new(1, -110, 0, 14)
    players.Position = UDim2.new(0, 8, 0, 52)
    players.BackgroundTransparency = 1
    players.Text = "👥 " .. (log.playerCount or 0) .. " players"
    players.TextColor3 = Color3.fromRGB(180, 180, 180)
    players.Font = Enum.Font.Gotham
    players.TextSize = 9
    players.TextXAlignment = Enum.TextXAlignment.Left
    players.Parent = entry
    
    local joinBtn = Instance.new("TextButton")
    joinBtn.Size = UDim2.new(0, 48, 0, 24)
    joinBtn.Position = UDim2.new(1, -104, 0, 6)
    joinBtn.BackgroundColor3 = Color3.fromRGB(60, 110, 180)
    joinBtn.BorderSizePixel = 0
    joinBtn.Text = "Join"
    joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    joinBtn.Font = Enum.Font.GothamBold
    joinBtn.TextSize = 10
    joinBtn.AutoButtonColor = false
    joinBtn.Parent = entry
    
    local joinCorner = Instance.new("UICorner")
    joinCorner.CornerRadius = UDim.new(0, 4)
    joinCorner.Parent = joinBtn
    
    addHoverEffect(joinBtn, Color3.fromRGB(60, 110, 180), Color3.fromRGB(70, 120, 190))
    
    local forceBtn = Instance.new("TextButton")
    forceBtn.Size = UDim2.new(0, 48, 0, 24)
    forceBtn.Position = UDim2.new(1, -52, 0, 6)
    forceBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    forceBtn.BorderSizePixel = 0
    forceBtn.Text = "Force"
    forceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    forceBtn.Font = Enum.Font.GothamBold
    forceBtn.TextSize = 10
    forceBtn.AutoButtonColor = false
    forceBtn.Parent = entry
    
    local forceCorner = Instance.new("UICorner")
    forceCorner.CornerRadius = UDim.new(0, 4)
    forceCorner.Parent = forceBtn
    
    addHoverEffect(forceBtn, Color3.fromRGB(220, 60, 60), Color3.fromRGB(200, 50, 50))
    
    joinBtn.MouseButton1Click:Connect(function()
        joinBtn.Text = "..."
        pcall(function()
            if log.placeId and log.gameInstanceId then
                TeleportService:TeleportToPlaceInstance(tonumber(log.placeId), log.gameInstanceId, LocalPlayer)
            end
        end)
        task.wait(1)
        joinBtn.Text = "Join"
    end)
    
    forceBtn.MouseButton1Click:Connect(function()
        forceBtn.Text = "..."
        pcall(function()
            if log.placeId and log.gameInstanceId then
                TeleportService:TeleportToPlaceInstance(tonumber(log.placeId), log.gameInstanceId, LocalPlayer)
            end
        end)
        task.wait(1)
        forceBtn.Text = "Force"
    end)
    
    return entry
end

local function updateLogsList()
    for _, child in pairs(LogsScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then 
            child:Destroy() 
        end
    end
    
    if #cachedLogs == 0 then
        local empty = Instance.new("TextLabel")
        empty.Name = "EmptyMessage"
        empty.Size = UDim2.new(1, -12, 0, 50)
        empty.BackgroundTransparency = 1
        empty.Text = "No logs available\nSwitch to Main tab to start"
        empty.TextColor3 = Color3.fromRGB(150, 150, 150)
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 12
        empty.Parent = LogsScroll
        return
    end
    
    for i, log in ipairs(cachedLogs) do
        if i <= 20 and log and log.animal then
            local entry = createLogEntry(log, i)
            entry.Parent = LogsScroll
        end
    end
end

local function fetchInstances()
    if tick() - lastFetchTime < fetchCooldown then
        return cachedLogs
    end
    
    lastFetchTime = tick()
    local url = API_URL .. "?minValue=" .. minValue .. "&limit=150"
    local body = httpRequest(url)
    
    if not body then 
        return cachedLogs
    end
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)
    
    if success and data and data.success and data.instances then
        cachedLogs = data.instances
        if LogsPanel.Visible then
            updateLogsList()
        end
        return data.instances
    end
    
    return cachedLogs
end

-- Sistema de actualización automática de logs
task.spawn(function()
    while task.wait(3) do
        pcall(function()
            fetchInstances()
        end)
    end
end)

local function teleportLoop()
    local lastTeleportedAge = nil
    
    while isRunning do
        updateStatus("Searching...", Color3.fromRGB(100, 100, 100))
        
        local instances = fetchInstances()
        
        if instances and #instances > 0 then
            local validInstance = nil
            
            for _, instance in ipairs(instances) do
                if instance and instance.placeId and instance.gameInstanceId and 
                   instance.animal and instance.animal.value and 
                   instance.animal.value >= minValue then
                    
                    local age = instance.age or 0
                    
                    if age < 20 then
                        if not lastTeleportedAge or age < lastTeleportedAge then
                            validInstance = instance
                            break
                        end
                    end
                end
            end
            
            if validInstance then
                local animalName = validInstance.animal.name or "Unknown"
                local animalValue = validInstance.animal.value or 0
                local animalAge = validInstance.age or 0
                
                updateStatus("Found: " .. animalName .. "\nValue: " .. formatValue(animalValue) .. " | Age: " .. animalAge .. "s\nTeleporting...", 
                    Color3.fromRGB(255, 255, 255))
                
                lastTeleportedAge = animalAge
                
                task.wait(0.3)
                
                local success, err = pcall(function()
                    TeleportService:TeleportToPlaceInstance(
                        tonumber(validInstance.placeId), 
                        validInstance.gameInstanceId, 
                        LocalPlayer
                    )
                end)
                
                if not success then
                    teleportAttempts = teleportAttempts + 1
                    updateStatus("Failed (Attempt " .. teleportAttempts .. "/" .. maxTeleportAttempts .. ")", 
                        Color3.fromRGB(200, 50, 50))
                    
                    if teleportAttempts >= maxTeleportAttempts then
                        teleportAttempts = 0
                        lastTeleportedAge = nil
                        task.wait(5)
                    else
                        task.wait(2)
                    end
                else
                    teleportAttempts = 0
                    task.wait(3)
                end
            else
                updateStatus("No fresh instances\n(age < 20s)", Color3.fromRGB(180, 180, 180))
                lastTeleportedAge = nil
                task.wait(2)
            end
        else
            updateStatus("No instances available\nRetrying...", Color3.fromRGB(200, 150, 100))
            lastTeleportedAge = nil
            task.wait(3)
        end
        
        task.wait(0.5)
    end
    
    teleportAttempts = 0
end

-- Tab Switching
local function switchTab(showMain)
    local fromPanel = showMain and LogsPanel or MainPanel
    local toPanel = showMain and MainPanel or LogsPanel
    local activeTab = showMain and MainTab or LogsTab
    local inactiveTab = showMain and LogsTab or MainTab
    
    TweenService:Create(fromPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(showMain and 1 or -1, 0, 0, 0)
    }):Play()
    
    task.wait(0.2)
    fromPanel.Visible = false
    fromPanel.Position = UDim2.new(0, 0, 0, 0)
    
    toPanel.Position = UDim2.new(showMain and -1 or 1, 0, 0, 0)
    toPanel.Visible = true
    
    TweenService:Create(toPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
    
    TweenService:Create(activeTab, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(60, 110, 180),
        TextColor3 = Color3.fromRGB(255, 255, 255)
    }):Play()
    
    TweenService:Create(inactiveTab, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(55, 55, 65),
        TextColor3 = Color3.fromRGB(150, 150, 150)
    }):Play()
    
    if not showMain then
        updateLogsList()
    end
end

MainTab.MouseButton1Click:Connect(function()
    switchTab(true)
end)

LogsTab.MouseButton1Click:Connect(function()
    switchTab(false)
end)

-- Toggle Button Logic
ToggleButton.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    
    local input = tonumber(MinInput.Text)
    if input and input > 0 then 
        minValue = input 
        MinInput.Text = tostring(input)
    end
    
    if isRunning then
        ToggleButton.Text = "STOP"
        TweenService:Create(ToggleButton, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        }):Play()
        updateStatus("Starting...", Color3.fromRGB(255, 255, 255))
        task.spawn(teleportLoop)
    else
        ToggleButton.Text = "START"
        TweenService:Create(ToggleButton, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(60, 110, 180)
        }):Play()
        updateStatus("Stopped", Color3.fromRGB(200, 200, 200))
    end
end)

-- Iniciar sistema de cierre automático
setupTeleportUICloser()

-- Animación de entrada (sin animación, solo aparece)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -150)
MainFrame.BackgroundTransparency = 0

updateStatus("Ready", Color3.fromRGB(200, 200, 200))
