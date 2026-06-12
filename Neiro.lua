--// NEIRO GUI ULTIMATE - FIXED v2
--// By: Nexsus | ShadowTeam

local drawingAvailable = pcall(function()
    local t = Drawing.new("Line")
    t:Remove()
end)

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
if not WindUI then return end

local notificationsEnabled = true
local function Notify(title, content, duration)
    if not notificationsEnabled then return end
    WindUI:Notify({ Title = title, Content = content, Duration = duration or 3 })
end
local function ForceNotify(title, content, duration)
    WindUI:Notify({ Title = title, Content = content, Duration = duration or 3 })
end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService  = game:GetService("TeleportService")
local SoundService     = game:GetService("SoundService")
local VirtualUser      = game:GetService("VirtualUser")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- ========== ESP ==========
-- Pool per-player, keyed by UserId — mencegah ghost drawing saat player sudah keluar viewport
local espPool = {}

local espEnabled      = false
local lineEnabled     = false
local boxEnabled      = false
local healthEnabled   = false
local distanceEnabled = false
local nameEnabled     = false
local hologramEnabled = false
local espColor        = Color3.fromRGB(255, 255, 255)
local lineMode        = "Bottom" -- "Bottom" = dari bawah layar, "Top" = dari atas layar

local function newDrawing(type_, props)
    local d = Drawing.new(type_)
    for k, v in pairs(props) do d[k] = v end
    d.Visible = false
    return d
end

local function getOrCreatePool(userId)
    if not espPool[userId] then
        espPool[userId] = {
            line      = newDrawing("Line",   { Thickness = 1, Color = espColor }),
            box       = newDrawing("Square", { Thickness = 1, Filled = false, Color = espColor }),
            hologram  = newDrawing("Square", { Thickness = 0, Filled = true, Transparency = 0.35, Color = espColor }),
            nameText  = newDrawing("Text",   { Size = 14, Center = true, Outline = true, OutlineColor = Color3.new(0,0,0), Color = Color3.new(1,1,1) }),
            distText  = newDrawing("Text",   { Size = 12, Center = true, Outline = true, OutlineColor = Color3.new(0,0,0), Color = Color3.new(1,1,1) }),
            healthBar = newDrawing("Square", { Thickness = 1, Filled = true }),
        }
    end
    return espPool[userId]
end

local function hidePool(pool)
    for _, d in pairs(pool) do d.Visible = false end
end

local function removePool(userId)
    if espPool[userId] then
        for _, d in pairs(espPool[userId]) do d:Remove() end
        espPool[userId] = nil
    end
end

local function clearAllESP()
    for uid in pairs(espPool) do removePool(uid) end
end

local function getHealthColor(pct)
    if pct > 0.5 then return Color3.fromRGB(0, 255, 0)
    elseif pct > 0.25 then return Color3.fromRGB(255, 165, 0)
    else return Color3.fromRGB(255, 0, 0) end
end

local function isValidTarget(player)
    if player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local localTeam  = LocalPlayer.Team
    local targetTeam = player.Team
    if localTeam and targetTeam and localTeam == targetTeam then return false end
    return true
end

local function updateESP()
    if not espEnabled or not drawingAvailable then return end

    local vp        = Camera.ViewportSize
    local activeIds = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if not isValidTarget(player) then continue end

        local char = player.Character
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if not hrp or not head then continue end

        local headScreen = Camera:WorldToViewportPoint(head.Position)
        local footPos    = hrp.Position - Vector3.new(0, 2.8, 0)
        local footScreen = Camera:WorldToViewportPoint(footPos)

        -- Jika Z <= 0 berarti di belakang kamera — skip agar tidak ada ghost object
        if headScreen.Z <= 0 then continue end

        local uid  = player.UserId
        local pool = getOrCreatePool(uid)
        activeIds[uid] = true

        for _, d in pairs(pool) do
            if d.Type ~= "Text" then d.Color = espColor end
        end

        local top    = math.min(headScreen.Y, footScreen.Y)
        local bottom = math.max(headScreen.Y, footScreen.Y)
        local height = bottom - top
        local width  = height * 0.5
        local left   = headScreen.X - width / 2
        local right  = headScreen.X + width / 2

        -- LINE TRACER: dari tepi layar ke posisi kepala player
        if lineEnabled then
            local origin
            if lineMode == "Top" then
                origin = Vector2.new(vp.X / 2, 0)
            else
                origin = Vector2.new(vp.X / 2, vp.Y)
            end
            pool.line.From    = origin
            pool.line.To      = Vector2.new(headScreen.X, headScreen.Y)
            pool.line.Color   = espColor
            pool.line.Visible = true
        else
            pool.line.Visible = false
        end

        if boxEnabled then
            pool.box.Position = Vector2.new(left, top)
            pool.box.Size     = Vector2.new(width, height)
            pool.box.Color    = espColor
            pool.box.Visible  = true
        else
            pool.box.Visible = false
        end

        if hologramEnabled then
            pool.hologram.Position = Vector2.new(left, top)
            pool.hologram.Size     = Vector2.new(width, height)
            pool.hologram.Color    = espColor
            pool.hologram.Visible  = true
        else
            pool.hologram.Visible = false
        end

        if nameEnabled then
            pool.nameText.Text     = player.Name
            pool.nameText.Position = Vector2.new(headScreen.X, top - 16)
            pool.nameText.Visible  = true
        else
            pool.nameText.Visible = false
        end

        if distanceEnabled then
            local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
            pool.distText.Text     = string.format("%.0fm", dist)
            pool.distText.Position = Vector2.new(headScreen.X, bottom + 4)
            pool.distText.Visible  = true
        else
            pool.distText.Visible = false
        end

        if healthEnabled then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.MaxHealth > 0 then
                local pct    = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                local barH   = height * pct
                local barTop = bottom - barH
                pool.healthBar.Position = Vector2.new(right + 4, barTop)
                pool.healthBar.Size     = Vector2.new(4, barH)
                pool.healthBar.Color    = getHealthColor(pct)
                pool.healthBar.Visible  = true
            else
                pool.healthBar.Visible = false
            end
        else
            pool.healthBar.Visible = false
        end
    end

    -- Hide drawing untuk player yang tidak aktif/sudah keluar viewport
    for uid, pool in pairs(espPool) do
        if not activeIds[uid] then
            hidePool(pool)
        end
    end
end

Players.PlayerRemoving:Connect(function(p) removePool(p.UserId) end)

local espConnection = nil
local function startESP()
    if not drawingAvailable then return end
    if espConnection then espConnection:Disconnect() end
    espConnection = RunService.RenderStepped:Connect(updateESP)
end
local function stopESP()
    if espConnection then espConnection:Disconnect(); espConnection = nil end
    clearAllESP()
end
local function setMasterESP(enable)
    espEnabled = enable
    if enable then startESP() else stopESP() end
end
local function recheckMasterESP()
    local anyOn = lineEnabled or boxEnabled or hologramEnabled or healthEnabled or distanceEnabled or nameEnabled
    if anyOn and not espEnabled then
        setMasterESP(true)
    elseif not anyOn and espEnabled then
        setMasterESP(false)
    end
end

-- ========== THEMES ==========
pcall(function()
    WindUI:AddTheme({ Name="Amethyst", Accent=Color3.fromRGB(156,81,255),  Background=Color3.fromRGB(18,12,28),  Button=Color3.fromRGB(109,40,217), Text=Color3.fromRGB(248,250,252) })
    WindUI:AddTheme({ Name="Midnight", Accent=Color3.fromRGB(56,189,248),  Background=Color3.fromRGB(15,23,42),  Button=Color3.fromRGB(30,41,59),   Text=Color3.fromRGB(241,245,249) })
    WindUI:AddTheme({ Name="Ocean",    Accent=Color3.fromRGB(0,163,255),   Background=Color3.fromRGB(7,30,52),   Button=Color3.fromRGB(37,99,235),  Text=Color3.fromRGB(248,250,252) })
    WindUI:AddTheme({ Name="Rose",     Accent=Color3.fromRGB(244,114,182), Background=Color3.fromRGB(28,15,25),  Button=Color3.fromRGB(190,18,60),  Text=Color3.fromRGB(254,242,242) })
    WindUI:AddTheme({ Name="Emerald",  Accent=Color3.fromRGB(16,185,129),  Background=Color3.fromRGB(6,25,20),   Button=Color3.fromRGB(5,150,105),  Text=Color3.fromRGB(236,253,245) })
end)
pcall(function() WindUI:SetTheme("Amethyst") end)

local verifiedChar = utf8.char(0xE000)
local Window = WindUI:CreateWindow({
    Title         = "Neiro " .. verifiedChar,
    Author        = "By: Nexsus",
    Icon          = "crown",
    Size          = UDim2.fromOffset(580, 580),
    Center        = true,
    Draggable     = true,
    HideSearchBar = false,
})
task.wait()

local fpsTag = Window:Tag({ Title = "FPS: 0", Icon = "" })
fpsTag:SetColor(Color3.fromRGB(200,200,200))
local frameTimes = {}
RunService.RenderStepped:Connect(function(dt)
    table.insert(frameTimes, dt)
    if #frameTimes > 10 then table.remove(frameTimes, 1) end
    local sum = 0
    for _, v in ipairs(frameTimes) do sum = sum + v end
    fpsTag:SetTitle("FPS: " .. math.floor(1 / (sum / #frameTimes)))
end)

local BrightnessFrame
do
    local sg = Instance.new("ScreenGui")
    sg.Name             = "NeiroBrightness"
    sg.IgnoreGuiInset   = true
    sg.ResetOnSpawn     = false
    sg.DisplayOrder     = 9999
    BrightnessFrame     = Instance.new("Frame")
    BrightnessFrame.Size                   = UDim2.fromScale(1, 1)
    BrightnessFrame.BackgroundColor3       = Color3.new(0, 0, 0)
    BrightnessFrame.BackgroundTransparency = 1
    BrightnessFrame.Parent                 = sg
    sg.Parent = game:GetService("CoreGui")
end

local function getCharacter() return LocalPlayer.Character end
local function getHRP()       local c = getCharacter(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHumanoid()  local c = getCharacter(); return c and c:FindFirstChildOfClass("Humanoid") end

-- ========== FLY ==========
local flying, flySpeed, vertical = false, 50, 0
local bv, bg, char, hum, hrp
local function refreshCharacter()
    char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    hum  = char and char:FindFirstChildOfClass("Humanoid")
    hrp  = char and char:FindFirstChild("HumanoidRootPart")
end
refreshCharacter()
LocalPlayer.CharacterAdded:Connect(refreshCharacter)

local function startFly()
    if flying then return end
    if not hrp or not hum then refreshCharacter() end
    if not hrp or not hum then Notify("Error", "Karakter belum siap", 2); return end
    flying = true
    hum.PlatformStand = true
    bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge); bv.Velocity = Vector3.zero; bv.Parent = hrp
    bg = Instance.new("BodyGyro");     bg.MaxTorque = Vector3.new(math.huge,math.huge,math.huge); bg.P = 10000; bg.Parent = hrp
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
        if not hrp or not hum then stopFly(); return end
        if not bv or not bg then startFly() end
        return
    end
    local move      = hum.MoveDirection
    local localMove = hrp.CFrame:VectorToObjectSpace(move)
    local vel       = (hrp.CFrame.LookVector * -localMove.Z) + (hrp.CFrame.RightVector * localMove.X) + Vector3.new(0, vertical, 0)
    if vel.Magnitude > 0 then vel = vel.Unit end
    bv.Velocity = vel * (flySpeed * 20)
    bg.CFrame   = Camera.CFrame
end)
UserInputService.InputBegan:Connect(function(i, gp)
    if gp or not flying then return end
    if i.KeyCode == Enum.KeyCode.Space           then vertical =  1
    elseif i.KeyCode == Enum.KeyCode.LeftControl then vertical = -1 end
end)
UserInputService.InputEnded:Connect(function(i, gp)
    if gp or not flying then return end
    if (i.KeyCode == Enum.KeyCode.Space and vertical == 1) or
       (i.KeyCode == Enum.KeyCode.LeftControl and vertical == -1) then
        vertical = 0
    end
end)

-- ========== NOCLIP ==========
local noclipEnabled, noclipConn = false, nil
local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    if noclipEnabled then
        if noclipConn then noclipConn:Disconnect() end
        noclipConn = RunService.Stepped:Connect(function()
            local c = LocalPlayer.Character
            if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        local c = LocalPlayer.Character
        if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
    end
end

-- ========== INFINITE JUMP ==========
local ijConn = nil
local function startInfiniteJump()
    if ijConn then ijConn:Disconnect() end
    ijConn = UserInputService.JumpRequest:Connect(function()
        local h = getHumanoid()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping); task.wait(); h:ChangeState(Enum.HumanoidStateType.Landed) end
    end)
end
local function stopInfiniteJump()
    if ijConn then ijConn:Disconnect(); ijConn = nil end
end

-- ========== ANTI-AFK ==========
local afkConn = nil
local function startAntiAFK()
    if afkConn then afkConn:Disconnect() end
    afkConn = LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end
local function stopAntiAFK()
    if afkConn then afkConn:Disconnect(); afkConn = nil end
end

-- ========== PLAYER LIST ==========
local function getPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    if #names == 0 then table.insert(names, "(No Players)") end
    return names
end

-- ========== STATE ==========
local State = {
    Fly=false, Noclip=false, InfiniteJump=false, AntiAFK=false,
    WalkSpeedEnabled=true, WalkSpeed=16, JumpPower=50, FlySpeed=50, UIVisible=true
}
local FlyToggleRef, NoclipToggleRef, IJumpToggleRef, FlySliderRef
local WalkSpeedToggleRef, WalkSliderRef, JumpSliderRef

local function resetOnRespawn()
    if flying then stopFly() end
    State.Fly, State.Noclip, State.InfiniteJump = false, false, false
    State.WalkSpeedEnabled, State.WalkSpeed, State.JumpPower, State.FlySpeed = true, 16, 50, 50
    flySpeed, vertical = 50, 0
    if noclipEnabled then toggleNoclip() end
    stopInfiniteJump()
    task.wait(0.5)
    if FlyToggleRef       then pcall(function() FlyToggleRef:Set(false) end) end
    if NoclipToggleRef    then pcall(function() NoclipToggleRef:Set(false) end) end
    if IJumpToggleRef     then pcall(function() IJumpToggleRef:Set(false) end) end
    if WalkSpeedToggleRef then pcall(function() WalkSpeedToggleRef:Set(true) end) end
    if FlySliderRef       then pcall(function() FlySliderRef:Set(50) end) end
    if WalkSliderRef      then pcall(function() WalkSliderRef:Set(16) end) end
    if JumpSliderRef      then pcall(function() JumpSliderRef:Set(50) end) end
    task.wait(0.5)
    local h = getHumanoid()
    if h then h.WalkSpeed, h.JumpPower = 16, 50 end
end
LocalPlayer.CharacterAdded:Connect(function() task.wait(1); resetOnRespawn() end)

-- ============================================================
-- TAB: INFORMATION
-- ============================================================
local TabInfo    = Window:Tab({ Title = "Information", Icon = "info" })
local SecWelcome = TabInfo:Section({ Title = "Welcome to Neiro" })

SecWelcome:Paragraph({
    Title = "About",
    Desc  = "Neiro adalah universal script untuk Roblox yang dikembangkan oleh Nexsus | ShadowTeam.",
    Image = "info"
})

local userId      = LocalPlayer.UserId
local avatarThumb = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(userId)
local function buildStatsDesc()
    return string.format(
        "Username: %s\nDisplay Name: %s\nUser ID: %d\nAccount Age: %d Days\nMembership: %s",
        LocalPlayer.Name, LocalPlayer.DisplayName, userId, LocalPlayer.AccountAge,
        LocalPlayer.MembershipType == Enum.MembershipType.Premium and "Premium" or "Free"
    )
end
local StatsParagraph = SecWelcome:Paragraph({ Title="User Statistics", Desc=buildStatsDesc(), Image=avatarThumb, ImageSize=80 })

SecWelcome:Button({ Title="Refresh Info", Desc="Reload statistik akun", Callback=function()
    pcall(function() StatsParagraph:SetDesc(buildStatsDesc()) end)
    pcall(function() StatsParagraph:SetImage(avatarThumb, 80) end)
    Notify("Profile","Info diperbarui",2)
end })

SecWelcome:Paragraph({
    Title = "Credit",
    Desc  = "Neiro GUI v1.0\nPowered by WindUI Library\nhttps://github.com/Footagesus/WindUI",
    Image = "crown"
})

-- Tombol Telegram & GitHub sejajar horizontal via native Roblox GUI
-- WindUI tidak punya HStack yang reliable, jadi inject Frame langsung ke CoreGui
task.defer(function()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end

    local sg = Instance.new("ScreenGui")
    sg.Name             = "NeiroSocial"
    sg.ResetOnSpawn     = false
    sg.DisplayOrder     = 10002
    sg.IgnoreGuiInset   = true
    sg.Parent           = pg

    -- Container horizontal, posisi bawah layar dalam GUI — akan muncul di bawah section
    local container = Instance.new("Frame")
    container.Name                   = "SocialRow"
    container.AnchorPoint            = Vector2.new(0.5, 1)
    container.Position               = UDim2.new(0.5, 0, 1, -12)
    container.Size                   = UDim2.fromOffset(320, 44)
    container.BackgroundTransparency = 1
    container.Parent                 = sg

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.SortOrder     = Enum.SortOrder.LayoutOrder
    layout.Padding       = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment   = Enum.VerticalAlignment.Center
    layout.Parent              = container

    local function makeBtn(label, color, order, callback)
        local btn            = Instance.new("TextButton")
        btn.LayoutOrder      = order
        btn.Size             = UDim2.fromOffset(152, 40)
        btn.BackgroundColor3 = color
        btn.Text             = label
        btn.TextColor3       = Color3.new(1,1,1)
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = 13
        btn.AutoButtonColor  = true
        btn.BorderSizePixel  = 0
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn
        local stroke = Instance.new("UIStroke")
        stroke.Color       = Color3.fromRGB(255,255,255)
        stroke.Transparency = 0.7
        stroke.Thickness    = 1
        stroke.Parent       = btn
        btn.MouseButton1Click:Connect(callback)
        btn.Parent = container
    end

    makeBtn("📨  Telegram", Color3.fromRGB(32, 149, 209), 1, function()
        local link = "https://t.me/Nexsus009"
        if setclipboard then setclipboard(link); Notify("Telegram","Link dicopy!",3)
        else ForceNotify("Telegram","Copy manual: "..link,5) end
    end)

    makeBtn("🐱  GitHub", Color3.fromRGB(30, 35, 42), 2, function()
        local link = "https://github.com/Sukizxx"
        if setclipboard then setclipboard(link); Notify("GitHub","Link dicopy!",3)
        else ForceNotify("GitHub","Copy manual: "..link,5) end
    end)
end)

-- ============================================================
-- TAB: MAIN
-- ============================================================
local TabMain = Window:Tab({ Title = "Main", Icon = "house" })
local SecFly  = TabMain:Section({ Title = "Fly" })
FlyToggleRef = SecFly:Toggle({ Title="Fly Mode", Desc="Terbang (WASD + Spasi naik + Ctrl turun)", Value=false, Callback=function(val)
    State.Fly = val; if val then startFly() else stopFly() end; Notify("Fly Mode", val and "Aktif" or "Mati")
end })
FlySliderRef = SecFly:Slider({ Title="Fly Speed", Desc="Kecepatan terbang", Step=1, Value={Min=5,Max=200,Default=50}, Callback=function(val) flySpeed=val; State.FlySpeed=val end })
NoclipToggleRef = SecFly:Toggle({ Title="Noclip", Desc="Tembus tembok", Value=false, Callback=function(val)
    State.Noclip = val; toggleNoclip(); Notify("Noclip", val and "Aktif" or "Mati")
end })

local SecJump = TabMain:Section({ Title = "Jump" })
IJumpToggleRef = SecJump:Toggle({ Title="Infinite Jump", Desc="Lompat tanpa batas", Value=false, Callback=function(val)
    State.InfiniteJump = val; if val then startInfiniteJump() else stopInfiniteJump() end; Notify("Infinite Jump", val and "Aktif" or "Mati")
end })
JumpSliderRef = SecJump:Slider({ Title="Jump Power", Desc="Kekuatan lompatan", Step=1, Value={Min=50,Max=500,Default=50}, Callback=function(val)
    State.JumpPower = val; local h = getHumanoid(); if h then h.JumpPower = val end
end })

local SecMove = TabMain:Section({ Title = "Movement" })
WalkSpeedToggleRef = SecMove:Toggle({ Title="Walkspeed Override", Desc="Aktifkan untuk ubah kecepatan jalan", Value=true, Callback=function(val)
    State.WalkSpeedEnabled = val
    local h = getHumanoid(); if h then h.WalkSpeed = val and State.WalkSpeed or 16 end
    Notify("Walkspeed", val and ("Override aktif: "..State.WalkSpeed) or "Default 16")
end })
WalkSliderRef = SecMove:Slider({ Title="Walkspeed Value", Desc="Kecepatan jalan", Step=1, Value={Min=16,Max=200,Default=16}, Callback=function(val)
    State.WalkSpeed = val
    if State.WalkSpeedEnabled then local h = getHumanoid(); if h then h.WalkSpeed = val end end
end })

-- ============================================================
-- TAB: ESP
-- ============================================================
local TabESP = Window:Tab({ Title = "ESP", Icon = "eye" })
if drawingAvailable then
    local SecLine = TabESP:Section({ Title = "ESP Line (Tracer)" })
    SecLine:Toggle({ Title="Enable Line", Desc="Garis dari tepi layar ke arah player", Value=false, Callback=function(val)
        lineEnabled = val; recheckMasterESP()
    end })
    SecLine:Dropdown({
        Title  = "Line Origin",
        Desc   = "Titik asal garis tracer",
        Values = { "Bottom (bawah layar)", "Top (atas layar)" },
        Value  = "Bottom (bawah layar)",
        Callback = function(val)
            lineMode = val:find("Top") and "Top" or "Bottom"
        end
    })

    local SecBox = TabESP:Section({ Title = "ESP Box" })
    SecBox:Toggle({ Title="Enable Box",  Desc="Kotak di sekitar player",  Value=false, Callback=function(val) boxEnabled=val;      recheckMasterESP() end })
    SecBox:Toggle({ Title="Health Bar",  Desc="Bar HP di samping box",    Value=false, Callback=function(val) healthEnabled=val;    recheckMasterESP() end })
    SecBox:Toggle({ Title="Distance",    Desc="Jarak di bawah box",       Value=false, Callback=function(val) distanceEnabled=val;  recheckMasterESP() end })
    SecBox:Toggle({ Title="Name",        Desc="Nama di atas box",         Value=false, Callback=function(val) nameEnabled=val;      recheckMasterESP() end })

    local SecHolo = TabESP:Section({ Title = "Hologram" })
    SecHolo:Toggle({ Title="Enable Hologram", Desc="Box transparan overlay", Value=false, Callback=function(val) hologramEnabled=val; recheckMasterESP() end })

    local SecESPSet = TabESP:Section({ Title = "Settings ESP" })
    SecESPSet:Colorpicker({ Title="ESP Color", Desc="Warna semua ESP element", Default=Color3.fromRGB(255,255,255), Callback=function(col) espColor=col end })
    SecESPSet:Button({ Title="Reset / Clear ESP", Desc="Hapus semua drawing object", Callback=function()
        clearAllESP(); Notify("ESP","Drawing direset",2)
    end })
else
    TabESP:Paragraph({
        Title = "ESP Tidak Tersedia",
        Desc  = "Executor tidak mendukung Drawing API.\nFitur lain tetap berfungsi normal.",
        Image = "alert-triangle"
    })
end

-- ============================================================
-- TAB: PLAYER
-- ============================================================
local TabPlayer   = Window:Tab({ Title = "Player", Icon = "users" })
local SecTeleport = TabPlayer:Section({ Title = "Teleport" })
local playerNames    = getPlayerNames()
local selectedPlayer = playerNames[1]
local PlayerDropdown = SecTeleport:Dropdown({
    Title    = "Select Player",
    Desc     = "Pilih target teleport",
    Values   = playerNames,
    Value    = playerNames[1],
    Callback = function(val) selectedPlayer = val end
})
SecTeleport:Button({ Title="Teleport to Player", Desc="Teleport ke lokasi player yang dipilih", Callback=function()
    if not selectedPlayer or selectedPlayer == "(No Players)" then Notify("Teleport","Pilih player dulu!",3); return end
    local t     = Players:FindFirstChild(selectedPlayer)
    local tChar = t and t.Character
    local tHRP  = tChar and tChar:FindFirstChild("HumanoidRootPart")
    local myHRP = getHRP()
    if tHRP and myHRP then myHRP.CFrame = tHRP.CFrame + Vector3.new(0, 3, 0); Notify("Teleport","Teleport ke "..selectedPlayer,3)
    else Notify("Teleport","Karakter tidak ditemukan",3) end
end })
local function refreshDropdown()
    local updated = getPlayerNames()
    selectedPlayer = updated[1]
    if PlayerDropdown then pcall(function() PlayerDropdown:Refresh(updated); PlayerDropdown:Set(updated[1]) end) end
end
SecTeleport:Button({ Title="Refresh Player List", Desc="Update daftar player aktif", Callback=function()
    refreshDropdown(); Notify("Player","Daftar direfresh",2)
end })
Players.PlayerAdded:Connect(function()   task.wait(0.5); refreshDropdown() end)
Players.PlayerRemoving:Connect(function() task.wait(0.1); refreshDropdown() end)

-- ============================================================
-- TAB: SETTINGS
-- ============================================================
local TabSettings = Window:Tab({ Title = "Settings", Icon = "settings" })
local SecUI = TabSettings:Section({ Title = "Tampilan" })
SecUI:Dropdown({
    Title  = "UI Theme", Desc = "Ganti tema warna UI",
    Values = {"Amethyst","Midnight","Ocean","Rose","Emerald"}, Value = "Amethyst",
    Callback = function(val)
        local ok = pcall(function() WindUI:SetTheme(val) end)
        Notify("Theme", ok and val or "Gagal", ok and 2 or 3)
    end
})
SecUI:Slider({ Title="Screen Brightness", Desc="Overlay gelap di layar", Step=1, Value={Min=0,Max=100,Default=0}, Icons={From="sun",To="moon"}, IsTooltip=true, IsTextbox=false, Callback=function(val) BrightnessFrame.BackgroundTransparency = 1-(val/100) end })
SecUI:Slider({ Title="Game Volume", Desc="Volume audio game", Step=1, Value={Min=0,Max=100,Default=100}, Icons={From="volume-2",To="volume-x"}, IsTooltip=true, IsTextbox=false, Callback=function(val) SoundService.GlobalVolume = val/100 end })

local SecNotif = TabSettings:Section({ Title = "Notifications" })
SecNotif:Toggle({ Title="Enable Notifications", Desc="Aktif/matikan popup notifikasi", Value=true, Callback=function(val)
    notificationsEnabled = val
    ForceNotify("Notifications", val and "Diaktifkan" or "Dinonaktifkan")
end })

local SecProt = TabSettings:Section({ Title = "Protection" })
SecProt:Toggle({ Title="Anti-AFK", Desc="Cegah kick AFK otomatis", Value=false, Callback=function(val) State.AntiAFK=val; if val then startAntiAFK() else stopAntiAFK() end; Notify("Anti-AFK",val and "Aktif" or "Mati") end })
SecProt:Toggle({ Title="Anti-Ban", Desc="Simulasi perlindungan (tidak 100% aman)", Value=false, Callback=function(val) Notify("Anti-Ban",val and "Aktif" or "Mati") end })

local SecSrv = TabSettings:Section({ Title = "Server Tools" })
SecSrv:Input({ Title="Join Server ID", Desc="Masukkan Job ID server tujuan", Placeholder="Paste Job ID...", Callback=function(val)
    if type(val)=="string" and #val>0 then
        pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, val, LocalPlayer)
    end
end })
SecSrv:Button({ Title="Copy My Server ID", Desc="Copy Job ID server saat ini", Callback=function()
    if setclipboard then setclipboard(game.JobId); Notify("Server ID","Dicopy!",3)
    else Notify("Server ID","setclipboard tidak tersedia",3) end
end })

local SecBind = TabSettings:Section({ Title = "Keybind" })
local currentToggleKey = Enum.KeyCode.RightControl
SecBind:Keybind({ Title="Toggle UI", Desc="Buka/tutup GUI (default: RightCtrl)", Value=Enum.KeyCode.RightControl, Callback=function(key) currentToggleKey = key end })
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == currentToggleKey then
        State.UIVisible = not State.UIVisible
        if State.UIVisible then Window:Show() else Window:Hide() end
    end
end)

-- ========== INIT ==========
task.wait(0.1)
Window:Show()
ForceNotify("Neiro GUI", "Loaded!\nESP butuh Drawing API.\nFly: WASD + Spasi (naik) + Ctrl (turun)\nToggle UI: RightCtrl", 6)
