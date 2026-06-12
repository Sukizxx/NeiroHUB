--// NEIRO GUI ULTIMATE - FULL ESP (LINE, BOX, HEALTH, NAME, DISTANCE, HOLOGRAM, COLOR)
--// By: Nexsus | ShadowTeam
--// Fitur: Fly (HP/PC), Noclip, Infinite Jump, Walkspeed, Teleport, 5 tema, Brightness, Volume,
--// Anti-AFK, Keybind, Search bar, Auto select tab, Expand sections, FPS, Crown logo,
--// Tombol Telegram & GitHub, ESP lengkap dengan color picker.
--// URUTAN TAB: Information → Main → ESP → Player → Settings

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ========== KONTROL NOTIFIKASI ==========
local notificationsEnabled = true
local function Notify(title, content, duration)
    if not notificationsEnabled then return end
    WindUI:Notify({ Title = title, Content = content, Duration = duration or 3 })
end
local function ForceNotify(title, content, duration)
    WindUI:Notify({ Title = title, Content = content, Duration = duration or 3 })
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local SoundService = game:GetService("SoundService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ========== DRAWING OBJECTS STORAGE (ESP) ==========
local drawings = {
    lines = {},
    boxes = {},
    texts = {},
    healthBars = {},
    holograms = {}
}
local espEnabled = false
local espColor = Color3.fromRGB(255, 255, 255) -- putih default
local lineEnabled = false
local lineMode = "Bottom" -- "Top" atau "Bottom"
local boxEnabled = false
local healthEnabled = false
local distanceEnabled = false
local nameEnabled = false
local hologramEnabled = false

-- Fungsi untuk membersihkan semua drawing
local function clearDrawings()
    for _, tbl in pairs(drawings) do
        for _, obj in pairs(tbl) do
            if obj and obj.Remove then obj:Remove() end
        end
        table.clear(tbl)
    end
end

-- Fungsi untuk mendapatkan warna berdasarkan kesehatan
local function getHealthColor(health, maxHealth)
    local percent = health / maxHealth
    if percent > 0.5 then
        return Color3.fromRGB(0, 255, 0) -- hijau
    elseif percent > 0.25 then
        return Color3.fromRGB(255, 165, 0) -- orange
    else
        return Color3.fromRGB(255, 0, 0) -- merah
    end
end

-- Deteksi musuh (filter tim)
local function isEnemy(character)
    if not character or character == LocalPlayer.Character then return false end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local localTeam = LocalPlayer.Team
    local targetPlayer = Players:GetPlayerFromCharacter(character)
    local targetTeam = targetPlayer and targetPlayer.Team or nil
    if localTeam and targetTeam and localTeam == targetTeam then return false end
    return true
end

-- Update semua ESP setiap frame
local function updateESP()
    if not espEnabled then return end
    
    local camera = Camera
    -- Kumpulkan musuh
    local enemies = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char and isEnemy(char) then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            if hrp and head then
                table.insert(enemies, {char = char, hrp = hrp, head = head, player = player})
            end
        end
    end
    
    -- Hapus drawing yang tidak terpakai (lebih dari jumlah musuh)
    for _, tbl in pairs(drawings) do
        while #tbl > #enemies do
            local obj = table.remove(tbl)
            if obj and obj.Remove then obj:Remove() end
        end
    end
    
    for i, enemy in ipairs(enemies) do
        local hrp = enemy.hrp
        local head = enemy.head
        local char = enemy.char
        local player = enemy.player
        
        local headPos, headOnScreen = camera:WorldToViewportPoint(head.Position)
        local footPos = hrp.Position - Vector3.new(0, 2, 0)
        local footPosScreen, footOnScreen = camera:WorldToViewportPoint(footPos)
        
        local top = math.min(headPos.Y, footPosScreen.Y)
        local bottom = math.max(headPos.Y, footPosScreen.Y)
        local left = headPos.X - (bottom - top) * 0.25
        local right = headPos.X + (bottom - top) * 0.25
        local width = right - left
        local height = bottom - top
        
        -- ESP LINE
        if lineEnabled then
            local line = drawings.lines[i]
            if not line then
                line = Drawing.new("Line")
                line.Thickness = 2
                drawings.lines[i] = line
            end
            line.Visible = true
            line.Color = espColor
            if lineMode == "Top" then
                local topHeadPos = head.Position + Vector3.new(0, 1.5, 0)
                local topHeadScreen, _ = camera:WorldToViewportPoint(topHeadPos)
                line.From = Vector2.new(topHeadScreen.X, topHeadScreen.Y)
                line.To = Vector2.new(headPos.X, headPos.Y)
            else
                line.From = Vector2.new(footPosScreen.X, footPosScreen.Y)
                line.To = Vector2.new(headPos.X, headPos.Y)
            end
        elseif drawings.lines[i] then
            drawings.lines[i].Visible = false
        end
        
        -- ESP BOX
        if boxEnabled then
            local box = drawings.boxes[i]
            if not box then
                box = Drawing.new("Square")
                box.Thickness = 1
                box.Filled = false
                drawings.boxes[i] = box
            end
            box.Visible = true
            box.Color = espColor
            box.Position = Vector2.new(left, top)
            box.Size = Vector2.new(width, height)
        elseif drawings.boxes[i] then
            drawings.boxes[i].Visible = false
        end
        
        -- HOLOGRAM
        if hologramEnabled then
            local hologram = drawings.holograms[i]
            if not hologram then
                hologram = Drawing.new("Square")
                hologram.Thickness = 0
                hologram.Filled = true
                hologram.Transparency = 0.5
                drawings.holograms[i] = hologram
            end
            hologram.Visible = true
            hologram.Color = espColor
            hologram.Position = Vector2.new(left, top)
            hologram.Size = Vector2.new(width, height)
        elseif drawings.holograms[i] then
            drawings.holograms[i].Visible = false
        end
        
        -- ESP NAME
        if nameEnabled then
            local text = drawings.texts[i]
            if not text then
                text = Drawing.new("Text")
                text.Size = 14
                text.Center = true
                text.Outline = true
                text.OutlineColor = Color3.new(0,0,0)
                drawings.texts[i] = text
            end
            text.Visible = true
            text.Color = Color3.fromRGB(255,255,255)
            text.Text = player.Name
            text.Position = Vector2.new(headPos.X, top - 15)
        elseif drawings.texts[i] then
            drawings.texts[i].Visible = false
        end
        
        -- ESP DISTANCE
        if distanceEnabled then
            local distText = drawings.texts[i .. "_dist"]
            if not distText then
                distText = Drawing.new("Text")
                distText.Size = 12
                distText.Center = true
                distText.Outline = true
                distText.OutlineColor = Color3.new(0,0,0)
                drawings.texts[i .. "_dist"] = distText
            end
            distText.Visible = true
            distText.Color = Color3.fromRGB(255,255,255)
            local distance = (hrp.Position - Camera.CFrame.Position).Magnitude
            distText.Text = string.format("%.1fm", distance)
            distText.Position = Vector2.new(headPos.X, bottom + 10)
        elseif drawings.texts[i .. "_dist"] then
            drawings.texts[i .. "_dist"].Visible = false
        end
        
        -- HEALTH BAR (vertikal di kanan box)
        if healthEnabled then
            local healthBar = drawings.healthBars[i]
            if not healthBar then
                healthBar = Drawing.new("Square")
                healthBar.Thickness = 1
                healthBar.Filled = true
                drawings.healthBars[i] = healthBar
            end
            healthBar.Visible = true
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local percent = hum.Health / hum.MaxHealth
                local barHeight = height * percent
                local barTop = top + (height - barHeight)
                healthBar.Position = Vector2.new(right + 5, barTop)
                healthBar.Size = Vector2.new(4, barHeight)
                healthBar.Color = getHealthColor(hum.Health, hum.MaxHealth)
            else
                healthBar.Visible = false
            end
        elseif drawings.healthBars[i] then
            drawings.healthBars[i].Visible = false
        end
    end
end

local espConnection = nil
local function startESP()
    if espConnection then espConnection:Disconnect() end
    espConnection = RunService.RenderStepped:Connect(updateESP)
end
local function stopESP()
    if espConnection then espConnection:Disconnect(); espConnection = nil end
    clearDrawings()
end
local function setMasterESP(enable)
    espEnabled = enable
    if enable then startESP() else stopESP() end
end

-- ========== THEMES ==========
pcall(function()
    WindUI:AddTheme({ Name = "Amethyst", Accent = Color3.fromRGB(156, 81, 255), Background = Color3.fromRGB(18, 12, 28), Button = Color3.fromRGB(109, 40, 217), Text = Color3.fromRGB(248, 250, 252) })
    WindUI:AddTheme({ Name = "Midnight", Accent = Color3.fromRGB(56, 189, 248), Background = Color3.fromRGB(15, 23, 42), Button = Color3.fromRGB(30, 41, 59), Text = Color3.fromRGB(241, 245, 249) })
    WindUI:AddTheme({ Name = "Ocean", Accent = Color3.fromRGB(0, 163, 255), Background = Color3.fromRGB(7, 30, 52), Button = Color3.fromRGB(37, 99, 235), Text = Color3.fromRGB(248, 250, 252) })
    WindUI:AddTheme({ Name = "Rose", Accent = Color3.fromRGB(244, 114, 182), Background = Color3.fromRGB(28, 15, 25), Button = Color3.fromRGB(190, 18, 60), Text = Color3.fromRGB(254, 242, 242) })
    WindUI:AddTheme({ Name = "Emerald", Accent = Color3.fromRGB(16, 185, 129), Background = Color3.fromRGB(6, 25, 20), Button = Color3.fromRGB(5, 150, 105), Text = Color3.fromRGB(236, 253, 245) })
end)
pcall(function() WindUI:SetTheme("Amethyst") end)

local verifiedChar = utf8.char(0xE000)
local Window = WindUI:CreateWindow({
    Title = "Neiro " .. verifiedChar,
    Author = "By: Nexsus",
    Icon = "crown",
    Size = UDim2.fromOffset(580, 580),
    Center = true,
    Draggable = true,
    HideSearchBar = false,
})
task.wait()

-- FPS counter
local fpsTag = Window:Tag({ Title = "FPS: 0", Icon = "" })
fpsTag:SetColor(Color3.fromRGB(200, 200, 200))
local frameTimes = {}
local maxSamples = 10
RunService.RenderStepped:Connect(function(deltaTime)
    table.insert(frameTimes, deltaTime)
    if #frameTimes > maxSamples then table.remove(frameTimes, 1) end
    local sum = 0
    for _, dt in ipairs(frameTimes) do sum = sum + dt end
    local avgDelta = sum / #frameTimes
    local fps = math.floor(1 / avgDelta)
    fpsTag:SetTitle("FPS: " .. fps)
end)

-- Brightness Overlay
local BrightnessFrame
do
    local sg = Instance.new("ScreenGui")
    sg.Name = "NeiroBrightness"
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 9999
    BrightnessFrame = Instance.new("Frame")
    BrightnessFrame.Size = UDim2.fromScale(1, 1)
    BrightnessFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    BrightnessFrame.BackgroundTransparency = 1
    BrightnessFrame.Parent = sg
    sg.Parent = game:GetService("CoreGui")
end

-- Helpers
local function getCharacter() return LocalPlayer.Character end
local function getHRP() local c = getCharacter() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHumanoid() local c = getCharacter() return c and c:FindFirstChildOfClass("Humanoid") end

-- ========== FLY SYSTEM ==========
local flying = false
local flySpeed = 50
local vertical = 0
local bv, bg
local char, hum, hrp

local function refreshCharacter()
    char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    hum = char and char:FindFirstChildOfClass("Humanoid")
    hrp = char and char:FindFirstChild("HumanoidRootPart")
end
refreshCharacter()
LocalPlayer.CharacterAdded:Connect(refreshCharacter)

local function startFly()
    if flying then return end
    if not hrp or not hum then refreshCharacter() end
    if not hrp or not hum then Notify("Error", "Karakter belum siap", 2) return end
    flying = true
    hum.PlatformStand = true
    bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.P = 10000
    bg.Parent = hrp
end

local function stopFly()
    if not flying then return end
    flying = false
    if bv then bv:Destroy() end
    if bg then bg:Destroy() end
    bv, bg = nil, nil
    if hum then hum.PlatformStand = false end
end

RunService.RenderStepped:Connect(function()
    if not flying then return end
    if not hrp or not hum or not bv or not bg then
        refreshCharacter()
        if not hrp or not hum then stopFly() return end
        if not bv or not bg then startFly() end
        return
    end
    local move = hum.MoveDirection
    local localMove = hrp.CFrame:VectorToObjectSpace(move)
    local velocity = (hrp.CFrame.LookVector * -localMove.Z) + (hrp.CFrame.RightVector * localMove.X)
    velocity = velocity + Vector3.new(0, vertical, 0)
    if velocity.Magnitude > 0 then velocity = velocity.Unit end
    bv.Velocity = velocity * (flySpeed * 20)
    bg.CFrame = Camera.CFrame
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not flying then return end
    if input.KeyCode == Enum.KeyCode.Space then vertical = 1
    elseif input.KeyCode == Enum.KeyCode.LeftControl then vertical = -1 end
end)
UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed or not flying then return end
    if input.KeyCode == Enum.KeyCode.Space and vertical == 1 then vertical = 0
    elseif input.KeyCode == Enum.KeyCode.LeftControl and vertical == -1 then vertical = 0 end
end)

-- NOCLIP
local noclipEnabled = false
local noclipConn = nil
local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    if noclipEnabled then
        if noclipConn then noclipConn:Disconnect() end
        noclipConn = RunService.Stepped:Connect(function()
            local c = LocalPlayer.Character
            if c then
                for _, part in ipairs(c:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        local c = LocalPlayer.Character
        if c then
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

-- INFINITE JUMP
local infiniteJumpConnection = nil
local function startInfiniteJump()
    if infiniteJumpConnection then infiniteJumpConnection:Disconnect() end
    infiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping); task.wait(); hum:ChangeState(Enum.HumanoidStateType.Landed) end
    end)
end
local function stopInfiniteJump()
    if infiniteJumpConnection then infiniteJumpConnection:Disconnect(); infiniteJumpConnection = nil end
end

-- ANTI-AFK
local antiAFKConnection = nil
local function startAntiAFK()
    if antiAFKConnection then antiAFKConnection:Disconnect() end
    antiAFKConnection = LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end
local function stopAntiAFK()
    if antiAFKConnection then antiAFKConnection:Disconnect(); antiAFKConnection = nil end
end

-- PLAYER LIST
local function getPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    if #names == 0 then table.insert(names, "(No Players)") end
    return names
end

-- STATE & RESPAWN
local State = { Fly = false, Noclip = false, InfiniteJump = false, AntiAFK = false, WalkSpeedEnabled = true, WalkSpeed = 16, JumpPower = 50, FlySpeed = 50, SelectedPlayer = nil, UIVisible = true }
local FlyToggleRef, NoclipToggleRef, IJumpToggleRef, FlySliderRef, WalkSpeedToggleRef, WalkSliderRef, JumpSliderRef

local function resetOnRespawn()
    if flying then stopFly() end
    State.Fly = false; State.Noclip = false; State.InfiniteJump = false
    State.WalkSpeedEnabled = true; State.WalkSpeed = 16; State.JumpPower = 50; State.FlySpeed = 50
    flySpeed = 50; vertical = 0
    if noclipEnabled then toggleNoclip() end
    stopInfiniteJump()
    task.wait(0.5)
    if FlyToggleRef then FlyToggleRef:Set(false) end
    if NoclipToggleRef then NoclipToggleRef:Set(false) end
    if IJumpToggleRef then IJumpToggleRef:Set(false) end
    if WalkSpeedToggleRef then WalkSpeedToggleRef:Set(true) end
    if FlySliderRef then FlySliderRef:Set(50) end
    if WalkSliderRef then WalkSliderRef:Set(16) end
    if JumpSliderRef then JumpSliderRef:Set(50) end
    task.wait(0.5)
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
end
LocalPlayer.CharacterAdded:Connect(function() task.wait(1); resetOnRespawn() end)

-- ========== TAB: INFORMATION ==========
local TabInfo = Window:Tab({ Title = "Information", Icon = "info" })
local SecWelcome = TabInfo:Section({ Title = "Welcome to Neiro" })
SecWelcome:Paragraph({
    Title = "About",
    Desc = "Neiro adalah universal script untuk Roblox yang dikembangkan oleh Nexsus | ShadowTeam.",
    Image = "info"
})
local userId = LocalPlayer.UserId
local avatarThumb = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(userId)
local function buildStatsDesc()
    return string.format("Username: %s\nDisplay Name: %s\nUser ID: %d\nAccount Age: %d Days\nMembership: %s",
        LocalPlayer.Name, LocalPlayer.DisplayName, userId, LocalPlayer.AccountAge,
        LocalPlayer.MembershipType == Enum.MembershipType.Premium and "Premium" or "Free")
end
local StatsParagraph = SecWelcome:Paragraph({
    Title = "User Statistics",
    Desc = buildStatsDesc(),
    Image = avatarThumb,
    ImageSize = 80
})
SecWelcome:Button({
    Title = "Refresh Info",
    Desc = "Reload statistik akun",
    Callback = function()
        pcall(function() StatsParagraph:SetDesc(buildStatsDesc()) end)
        pcall(function() StatsParagraph:SetImage(avatarThumb, 80) end)
        Notify("Profile", "Info diperbarui", 2)
    end
})
SecWelcome:Paragraph({
    Title = "Credit",
    Desc = "Neiro GUI v1.0\nPowered by WindUI Library\nhttps://github.com/Footagesus/WindUI",
    Image = "crown"
})
local SocialStack = SecWelcome:HStack({ AutoSpace = true })
SocialStack:Button({
    Title = "Telegram",
    Icon = "send",
    Color = "Primary",
    Callback = function()
        local link = "https://t.me/Nexsus009"
        if setclipboard then setclipboard(link); Notify("Telegram", "Link grup berhasil di-copy: " .. link, 3)
        else ForceNotify("Telegram", "setclipboard tidak tersedia, silakan copy manual: " .. link, 5) end
    end
})
SocialStack:Button({
    Title = "GitHub",
    Icon = "github",
    Color = "Secondary",
    Callback = function()
        local link = "https://github.com/Sukizxx"
        if setclipboard then setclipboard(link); Notify("GitHub", "Link repository berhasil di-copy: " .. link, 3)
        else ForceNotify("GitHub", "setclipboard tidak tersedia, silakan copy manual: " .. link, 5) end
    end
})

-- ========== TAB: MAIN ==========
local TabMain = Window:Tab({ Title = "Main", Icon = "house" })
local SecFly = TabMain:Section({ Title = "Fly" })
FlyToggleRef = SecFly:Toggle({ Title = "Fly Mode", Desc = "Aktifkan/matiin mode terbang (WASD, Spasi, Ctrl)", Value = false, Callback = function(val) State.Fly = val; if val then startFly() else stopFly() end; Notify("Fly Mode", val and "Fly aktif" or "Fly mati") end })
FlySliderRef = SecFly:Slider({ Title = "Fly Speed", Desc = "Kecepatan terbang (5-200)", Step = 1, Value = { Min = 5, Max = 200, Default = 50 }, Callback = function(val) flySpeed = val; State.FlySpeed = val end })
NoclipToggleRef = SecFly:Toggle({ Title = "Noclip", Desc = "Tembus tembok", Value = false, Callback = function(val) State.Noclip = val; toggleNoclip(); Notify("Noclip", val and "Noclip aktif" or "Noclip mati") end })

local SecJump = TabMain:Section({ Title = "Jump" })
IJumpToggleRef = SecJump:Toggle({ Title = "Infinite Jump", Desc = "Lompat tanpa batas", Value = false, Callback = function(val) State.InfiniteJump = val; if val then startInfiniteJump() else stopInfiniteJump() end; Notify("Infinite Jump", val and "Aktif" or "Mati") end })
JumpSliderRef = SecJump:Slider({ Title = "Jump Power", Desc = "Kekuatan lompatan", Step = 1, Value = { Min = 50, Max = 200, Default = 50 }, Callback = function(val) State.JumpPower = val; local hum = getHumanoid(); if hum then hum.JumpPower = val end end })

local SecMove = TabMain:Section({ Title = "Movement" })
WalkSpeedToggleRef = SecMove:Toggle({ Title = "Walkspeed Override", Desc = "Aktifkan untuk ubah kecepatan jalan", Value = true, Callback = function(val)
    State.WalkSpeedEnabled = val
    if val then local hum = getHumanoid(); if hum then hum.WalkSpeed = State.WalkSpeed end; Notify("Walkspeed", "Override aktif: " .. State.WalkSpeed)
    else local hum = getHumanoid(); if hum then hum.WalkSpeed = 16 end; Notify("Walkspeed", "Override nonaktif (default 16)") end
end })
WalkSliderRef = SecMove:Slider({ Title = "Walkspeed Value", Desc = "Kecepatan jalan", Step = 1, Value = { Min = 16, Max = 100, Default = 16 }, Callback = function(val) State.WalkSpeed = val; if State.WalkSpeedEnabled then local hum = getHumanoid(); if hum then hum.WalkSpeed = val end end end })

-- ========== TAB: ESP (SETELAH MAIN) ==========
local TabESP = Window:Tab({ Title = "ESP", Icon = "eye" })

local SecLine = TabESP:Section({ Title = "ESP Line" })
local lineToggle = SecLine:Toggle({
    Title = "Enable Line",
    Desc = "Tampilkan garis tracer dari atas/bawah ke kepala musuh",
    Value = false,
    Callback = function(val)
        lineEnabled = val
        if not espEnabled and val then setMasterESP(true) end
        if not espEnabled and not lineEnabled and not boxEnabled and not hologramEnabled then setMasterESP(false) end
    end
})
local lineModeDropdown = SecLine:Dropdown({
    Title = "Line Mode",
    Desc = "Pilih posisi awal garis",
    Values = { "Top (dari atas kepala)", "Bottom (dari bawah kaki)" },
    Value = "Bottom (dari bawah kaki)",
    Callback = function(val)
        lineMode = (val == "Top (dari atas kepala)") and "Top" or "Bottom"
    end
})

local SecBox = TabESP:Section({ Title = "ESP Box" })
local boxToggle = SecBox:Toggle({
    Title = "Enable Box",
    Desc = "Tampilkan kotak di sekitar musuh",
    Value = false,
    Callback = function(val)
        boxEnabled = val
        if not espEnabled and val then setMasterESP(true) end
        if not espEnabled and not lineEnabled and not boxEnabled and not hologramEnabled then setMasterESP(false) end
    end
})
local healthToggle = SecBox:Toggle({
    Title = "Health Bar",
    Desc = "Tampilkan bar kesehatan vertikal di samping kanan",
    Value = false,
    Callback = function(val) healthEnabled = val end
})
local distanceToggle = SecBox:Toggle({
    Title = "Distance",
    Desc = "Tampilkan jarak di bawah kaki",
    Value = false,
    Callback = function(val) distanceEnabled = val end
})
local nameToggle = SecBox:Toggle({
    Title = "Name",
    Desc = "Tampilkan nama pemain di atas kepala",
    Value = false,
    Callback = function(val) nameEnabled = val end
})

local SecHolo = TabESP:Section({ Title = "Hologram" })
local holoToggle = SecHolo:Toggle({
    Title = "Enable Hologram",
    Desc = "Tampilkan efek hologram (box transparan) pada musuh",
    Value = false,
    Callback = function(val)
        hologramEnabled = val
        if not espEnabled and val then setMasterESP(true) end
        if not espEnabled and not lineEnabled and not boxEnabled and not hologramEnabled then setMasterESP(false) end
    end
})

local SecSettings = TabESP:Section({ Title = "Settings ESP" })
local colorPicker = SecSettings:Colorpicker({
    Title = "ESP Color",
    Desc = "Pilih warna untuk box, line, dan hologram",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(col)
        espColor = col
    end
})
SecSettings:Button({
    Title = "Reset ESP",
    Desc = "Bersihkan semua drawing (jika ada glitch)",
    Callback = function()
        clearDrawings()
        Notify("ESP", "Drawing direset", 2)
    end
})

-- ========== TAB: PLAYER ==========
local TabPlayer = Window:Tab({ Title = "Player", Icon = "users" })
local SecTeleport = TabPlayer:Section({ Title = "Teleport" })
local playerNames = getPlayerNames()
local selectedPlayer = playerNames[1]
local PlayerDropdown = SecTeleport:Dropdown({ Title = "Select Player", Desc = "Pilih target", Values = playerNames, Value = playerNames[1], Callback = function(val) selectedPlayer = val end })
SecTeleport:Button({ Title = "Teleport to Player", Desc = "Teleport ke lokasi player", Callback = function()
    if not selectedPlayer or selectedPlayer == "(No Players)" then Notify("Teleport", "Pilih player dulu!", 3) return end
    local target = Players:FindFirstChild(selectedPlayer)
    local targetChar = target and target.Character
    local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    local hrp = getHRP()
    if targetHRP and hrp then hrp.CFrame = targetHRP.CFrame + Vector3.new(0,3,0); Notify("Teleport", "Teleport ke "..selectedPlayer, 3)
    else Notify("Teleport", "Karakter "..selectedPlayer.." tidak ditemukan", 3) end
end })
local function refreshDropdown()
    local updated = getPlayerNames()
    selectedPlayer = updated[1]
    if PlayerDropdown then pcall(function() PlayerDropdown:Refresh(updated); PlayerDropdown:Set(updated[1]) end) end
end
SecTeleport:Button({ Title = "Refresh Player List", Desc = "Refresh", Callback = function() refreshDropdown(); Notify("Player List", "Daftar player direfresh", 2) end })
Players.PlayerAdded:Connect(function() task.wait(0.5); refreshDropdown() end)
Players.PlayerRemoving:Connect(function() task.wait(0.1); refreshDropdown() end)

-- ========== TAB: SETTINGS ==========
local TabSettings = Window:Tab({ Title = "Settings", Icon = "settings" })
local SecTampilan = TabSettings:Section({ Title = "Tampilan" })
SecTampilan:Dropdown({ Title = "UI Theme", Desc = "Ganti tema", Values = { "Amethyst", "Midnight", "Ocean", "Rose", "Emerald" }, Value = "Amethyst", Callback = function(val) local ok = pcall(function() WindUI:SetTheme(val) end); Notify("Theme", ok and ("Theme: "..val) or "Gagal", ok and 2 or 3) end })
SecTampilan:Slider({ Title = "Screen Brightness", Desc = "Gelap/terang layar", Step = 1, Value = { Min = 0, Max = 100, Default = 0 }, Icons = { From = "sun", To = "moon" }, IsTooltip = true, IsTextbox = false, Callback = function(val) BrightnessFrame.BackgroundTransparency = 1 - (val/100) end })
SecTampilan:Slider({ Title = "Game Volume", Desc = "Volume suara game", Step = 1, Value = { Min = 0, Max = 100, Default = 100 }, Icons = { From = "volume-2", To = "volume-x" }, IsTooltip = true, IsTextbox = false, Callback = function(val) SoundService.GlobalVolume = val/100 end })

local SecNotif = TabSettings:Section({ Title = "Notifications" })
SecNotif:Toggle({ Title = "Enable Notifications", Desc = "Aktif/mati notifikasi", Value = true, Callback = function(val)
    notificationsEnabled = val
    ForceNotify("Notifications", val and "Notifikasi diaktifkan" or "Notifikasi dinonaktifkan")
end })

local SecProtection = TabSettings:Section({ Title = "Protection" })
SecProtection:Toggle({ Title = "Anti-AFK", Desc = "Cegah kick AFK", Value = false, Callback = function(val) State.AntiAFK = val; if val then startAntiAFK() else stopAntiAFK() end; Notify("Anti-AFK", val and "Aktif" or "Mati") end })
SecProtection:Toggle({ Title = "Anti-Ban", Desc = "Simulasi deteksi (tidak 100% aman)", Value = false, Callback = function(val) Notify("Anti-Ban", val and "Aktif" or "Mati") end })

local SecServer = TabSettings:Section({ Title = "Server Tools" })
SecServer:Input({ Title = "Join Server ID", Desc = "Masukkan Job ID", Placeholder = "Paste Job ID...", Callback = function(val) if type(val)=="string" and #val>0 then pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, val, LocalPlayer) end end })
SecServer:Button({ Title = "Copy My Server ID", Desc = "Copy ID server", Callback = function() if setclipboard then setclipboard(game.JobId); Notify("Server ID", "Job ID dicopy!", 3) else Notify("Server ID", "setclipboard tidak tersedia", 3) end end })

local SecKeybind = TabSettings:Section({ Title = "Keybind" })
local currentToggleKey = Enum.KeyCode.RightControl
SecKeybind:Keybind({ Title = "Toggle UI", Desc = "Tombol buka/tutup UI", Value = Enum.KeyCode.RightControl, Callback = function(key) currentToggleKey = key end })
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == currentToggleKey then
        State.UIVisible = not State.UIVisible
        if State.UIVisible then Window:Show() else Window:Hide() end
    end
end)

-- ========== AUTO SELECT TAB & EXPAND SECTION ==========
task.wait(0.1)
Window:Show()
task.wait(0.2)

local function selectFirstTab()
    if Window.TabModule and Window.TabModule.SelectTab then
        Window.TabModule:SelectTab(1)
        return true
    end
    return false
end

local function expandAllSections()
    if Window.AllElements then
        for _, elem in ipairs(Window.AllElements) do
            if elem.__type == "Section" and elem.Open then
                elem:Open(true)
            end
        end
    end
    if Window.TabModule and Window.TabModule.Tabs then
        for _, tab in ipairs(Window.TabModule.Tabs) do
            if tab.Elements then
                for _, elem in ipairs(tab.Elements) do
                    if elem.__type == "Section" and elem.Open then
                        elem:Open(true)
                    end
                end
            end
        end
    end
end

task.spawn(function()
    task.wait(0.6)
    selectFirstTab()
    task.wait(0.2)
    expandAllSections()
end)

ForceNotify("Neiro GUI", "Loaded! ESP tersedia di tab ESP (setelah Main).\nKontrol: WASD, Spasi naik, Ctrl turun.", 6)
