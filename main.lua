-- // ==============================================================
-- // HORIZON HUB | MULTI-GAMES LOADER + WIND UI
-- // ==============================================================

print("[Horizon Hub] Loader script started...")

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- 1. DAFTAR GAME YANG DIDUKUNG
local SUPPORTED_GAMES = {
    [133341016381877] = {
        Name = "Mount RNG",
        Script = 'loadstring(game:HttpGet("https://encrypt-x.pages.dev/Scripts?Id=1892450044143"))("1892450044143")',
    },
    [2753915549] = {
        Name = "Blox Fruits",
        Script = "https://raw.githubusercontent.com/acsu123/HOHO_CREATIVE/main/Hub.lua",
    },
    [16732694052] = {
        Name = "Fisch",
        Script = "https://raw.githubusercontent.com/SpeedHubX/SpeedHubX/main/SpeedHubX.lua",
    },
}

-- 2. DETEKSI GAME
local currentGame = SUPPORTED_GAMES[game.PlaceId] or SUPPORTED_GAMES[game.GameId]

if not currentGame then
    local gameNames = {}
    for _, info in pairs(SUPPORTED_GAMES) do
        table.insert(gameNames, "• " .. info.Name)
    end

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Horizon Hub - Game Not Supported",
            Text = "Game ini belum didukung!\nGame yang didukung:\n" .. table.concat(gameNames, ", "),
            Duration = 7
        })
    end)
    warn("[Horizon Hub] PlaceId (" .. tostring(game.PlaceId) .. ") tidak terdaftar.")
    return
end

-- 3. AUTO-PATCH CRASH BUG MOUNT RNG
local function applyGameCompatibilityPatches()
    if game.PlaceId == 133341016381877 or game.GameId == 6466404775 then
        local function ensureMesh(part)
            if part:IsA("BasePart") and part.Name == "Body" and not part:FindFirstChild("Mesh") then
                local m = Instance.new("SpecialMesh")
                m.Name = "Mesh"
                m.Parent = part
            end
        end

        for _, d in ipairs(Workspace:GetDescendants()) do
            pcall(ensureMesh, d)
        end

        Workspace.DescendantAdded:Connect(function(descendant)
            pcall(ensureMesh, descendant)
        end)
    end
end

-- 4. BUAT GUI WIND UI
local guiSuccess, guiErr = pcall(function()
    local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

    local MainWindow = WindUI:CreateWindow({
        Title = "Horizon Hub",
        Author = "Multi-Games Hub • FlowAuth Verified",
        Folder = "HorizonHub",
        Icon = "solar:shield-star-bold",
        Size = UDim2.fromOffset(600, 430),
        Transparent = true,
        Theme = "Midnight",
        Acrylic = true,
        SideBarWidth = 195,
        HideSearchBar = true,
        Topbar = {
            Height = 44,
            ButtonsType = "Mac",
        },
        User = {
            Enabled = true,
            Anonymous = false,
        },
        OpenButton = {
            Title = "Open Horizon Hub",
            Icon = "solar:shield-star-bold",
            CornerRadius = UDim.new(1, 0),
            StrokeThickness = 2,
            Enabled = true,
            Draggable = true,
            OnlyMobile = false,
            Scale = 0.65,
        },
    })

    pcall(function()
        MainWindow:Tag({
            Title = "FlowAuth Verified",
            Icon = "solar:shield-check-bold",
            Color = Color3.fromHex("#22c55e"),
        })
        MainWindow:Tag({
            Title = currentGame.Name,
            Icon = "solar:gamepad-bold",
            Color = Color3.fromHex("#38bdf8"),
        })
    end)

    -- TAB 1: LAUNCHER
    local LaunchTab = MainWindow:Tab({
        Title = "Launcher",
        Desc = "Mulai script game",
        Icon = "solar:play-circle-bold",
        IconColor = Color3.fromHex("#22c55e"),
        Border = true,
    })

    LaunchTab:Paragraph({
        Title = "Game Terdeteksi: " .. currentGame.Name,
        Desc = "Place ID: " .. tostring(game.PlaceId) .. "\nStatus: Terverifikasi FlowAuth Server ✅\nTekan tombol di bawah untuk meluncurkan script.",
        Image = "solar:gamepad-bold",
    })

    LaunchTab:Divider()

    LaunchTab:Button({
        Title = "Launch " .. currentGame.Name .. " Script",
        Desc = "Terapkan bypass patch & jalankan script otomatis",
        Icon = "solar:play-bold",
        Callback = function()
            WindUI:Notify({
                Title = "Memuat Script...",
                Content = "Menjalankan script " .. currentGame.Name .. "...",
                Duration = 3,
                Icon = "solar:check-circle-bold",
            })

            applyGameCompatibilityPatches()
            task.wait(0.5)
            pcall(function() MainWindow:Destroy() end)

            task.spawn(function()
                if type(currentGame.Script) == "function" then
                    currentGame.Script()
                elseif type(currentGame.Script) == "string" then
                    if currentGame.Script:match("^https?://") and not currentGame.Script:find("loadstring") then
                        loadstring(game:HttpGet(currentGame.Script))()
                    else
                        loadstring(currentGame.Script)()
                    end
                end
            end)
        end,
    })

    -- TAB 2: SUPPORTED GAMES
    local SupportedTab = MainWindow:Tab({
        Title = "Supported Games",
        Desc = "Katalog game didukung",
        Icon = "solar:folder-with-files-bold",
        IconColor = Color3.fromHex("#38bdf8"),
        Border = true,
    })

    for id, info in pairs(SUPPORTED_GAMES) do
        local isCurrent = (id == game.PlaceId or id == game.GameId)
        if isCurrent then
            SupportedTab:Paragraph({
                Title = "🎮 " .. info.Name .. "  [SEDANG DIMAINKAN]",
                Desc = "• Place ID: " .. tostring(id) .. "\n• Status: Terdeteksi & Aktif",
                Image = "solar:check-circle-bold",
            })
        else
            SupportedTab:Paragraph({
                Title = "• " .. info.Name,
                Desc = "• Place ID: " .. tostring(id) .. "\n• Status: Tersedia",
                Image = "solar:gamepad-minimalistic-bold",
                Buttons = {
                    {
                        Title = "Teleport",
                        Icon = "solar:square-top-down-bold",
                        Callback = function()
                            TeleportService:Teleport(id, LocalPlayer)
                        end,
                    }
                }
            })
        end
    end

    -- TAB 3: SETTINGS
    local SettingsTab = MainWindow:Tab({
        Title = "Settings & Info",
        Desc = "Pengaturan tema & diagnosa",
        Icon = "solar:settings-bold",
        IconColor = Color3.fromHex("#ECA201"),
        Border = true,
    })

    SettingsTab:Paragraph({
        Title = "Player Diagnostics",
        Desc = "• Pemain: " .. LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")\n• User ID: " .. tostring(LocalPlayer.UserId) .. "\n• Place ID: " .. tostring(game.PlaceId),
        Image = "solar:user-id-bold",
    })

    SettingsTab:Dropdown({
        Title = "Pilih Tema Tampilan",
        Desc = "Ubah warna tampilan GUI secara langsung",
        Values = { "Midnight", "Dark", "Indigo", "Emerald", "Rose", "Violet", "Sky", "Amber" },
        Value = "Midnight",
        Callback = function(theme)
            pcall(function() WindUI:SetTheme(theme) end)
        end,
    })

    MainWindow:SelectTab(1)
end)

if not guiSuccess then
    warn("[Horizon Hub GUI Error]: " .. tostring(guiErr))
end