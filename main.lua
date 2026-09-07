-- // ==============================================================
-- // HORIZON HUB | MULTI-GAMES LOADER + FLOWAUTH KEY SYSTEM
-- // ==============================================================

-- 0. HANDSHAKE RECURSION GUARD (DIGUNAKAN SAAT VERIFIKASI KEY DENGAN FLOWAUTH)
if _G.HORIZON_AUTH_CHECK then
    _G.HORIZON_KEY_VALID = true
    return
end

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- KONFIGURASI FLOWAUTH & FILE KEY
local FLOWAUTH_LOADER_URL = "https://flowauth.net/v1/loaders/3fe6c1e7254bd698ef096d675071e7cd.lua"
local FLOWAUTH_GETKEY_URL = "https://flowauth.net/reward/4a3a799b84b7f927699ee033c487ca36"
local KEY_FILE = "HorizonHub_Key.txt"

-- 1. DAFTAR GAME DIDUKUNG
local SUPPORTED_GAMES: { [number]: { Name: string, Script: any } } = {
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
            Title = "Horizon Hub",
            Text = "Game belum didukung:\n" .. table.concat(gameNames, ", "),
            Duration = 6
        })
    end)
    return
end

-- 3. AUTO-PATCH MOUNT RNG CRASH
local function applyGameCompatibilityPatches()
    if game.PlaceId == 133341016381877 or game.GameId == 6466404775 then
        local function ensureMesh(part: Instance)
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

-- 4. LOAD WIND UI LIBRARY
local WindUI: any = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- 5. FUNGSI VERIFIKASI KEY LANGSUNG KE FLOWAUTH SERVER
local function verifyKeyWithFlowAuth(candidateKey: string): (boolean, string)
    if not candidateKey or candidateKey:gsub("%s+", "") == "" then
        return false, "Key tidak boleh kosong."
    end
    candidateKey = candidateKey:gsub("%s+", "")

    _G.HORIZON_AUTH_CHECK = true
    _G.HORIZON_KEY_VALID = false

    local getOk, getRes = pcall(game.HttpGet, game, FLOWAUTH_LOADER_URL)
    if not getOk or not getRes or #getRes < 50 then
        _G.HORIZON_AUTH_CHECK = nil
        return false, "Gagal mengunduh loader FlowAuth. Periksa koneksi internet."
    end

    local loaderFn, loadErr = loadstring(getRes, "=FlowAuthVerify")
    if not loaderFn then
        _G.HORIZON_AUTH_CHECK = nil
        return false, "Gagal meng-compile loader FlowAuth: " .. tostring(loadErr)
    end

    local ok, err = pcall(loaderFn, candidateKey)
    _G.HORIZON_AUTH_CHECK = nil

    if ok and _G.HORIZON_KEY_VALID then
        return true, "Key valid dan terverifikasi di FlowAuth!"
    else
        local errMsg = tostring(err or "")
        if errMsg:find("invalid_key") then
            return false, "Key tidak valid atau telah dihapus di FlowAuth."
        else
            return false, "Key tidak cocok atau gagal diverifikasi di FlowAuth."
        end
    end
end

-- FORWARD DECLARATIONS
local openMainHubWindow
local openKeySystemWindow

-- 6. MAIN HUB WINDOW
openMainHubWindow = function()
    local MainWindow = WindUI:CreateWindow({
        Title = "Horizon Hub",
        Author = "Multi-Games Loader",
        Folder = "HorizonHub",
        Icon = "solar:shield-star-bold",
        Size = UDim2.fromOffset(560, 380),
        Transparent = true,
        Theme = "Midnight",
        Acrylic = true,
        SideBarWidth = 175,
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
            Title = "Open Horizon",
            Icon = "solar:shield-star-bold",
            CornerRadius = UDim.new(1, 0),
            StrokeThickness = 2,
            Enabled = true,
            Draggable = true,
            OnlyMobile = false,
            Scale = 0.6,
        },
    })

    pcall(function()
        MainWindow:Tag({
            Title = currentGame.Name,
            Icon = "solar:gamepad-bold",
            Color = Color3.fromHex("#38bdf8"),
        })
        MainWindow:Tag({
            Title = "Key Verified",
            Icon = "solar:check-circle-bold",
            Color = Color3.fromHex("#22c55e"),
        })
    end)

    -- TAB 1: 🚀 DASHBOARD
    local DashTab = MainWindow:Tab({
        Title = "Dashboard",
        Desc = "Status & eksekusi",
        Icon = "solar:rocket-2-bold",
        IconColor = Color3.fromHex("#22c55e"),
        Border = true,
    })

    DashTab:Paragraph({
        Title = currentGame.Name,
        Desc = "Status: Online & Ready to Execute\nAutentikasi: FlowAuth Matched & Verified",
        Image = "solar:gamepad-bold",
    })

    DashTab:Divider()

    local autoClose = true

    DashTab:Button({
        Title = "Launch Script",
        Desc = "Mulai otomatisasi " .. currentGame.Name,
        Icon = "solar:play-circle-bold",
        Callback = function()
            WindUI:Notify({
                Title = "Launching...",
                Content = "Memuat " .. currentGame.Name .. "...",
                Duration = 2.5,
                Icon = "solar:check-circle-bold",
            })

            applyGameCompatibilityPatches()

            if autoClose then
                task.wait(0.4)
                pcall(function() MainWindow:Destroy() end)
            end

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

    DashTab:Toggle({
        Title = "Auto Close Loader",
        Desc = "Tutup jendela otomatis saat script diluncurkan",
        Value = true,
        Callback = function(val: boolean)
            autoClose = val
        end,
    })

    -- TAB 2: 🎮 GAMES
    local GamesTab = MainWindow:Tab({
        Title = "Games",
        Desc = "Katalog game",
        Icon = "solar:gamepad-bold",
        IconColor = Color3.fromHex("#38bdf8"),
        Border = true,
    })

    for id, info in pairs(SUPPORTED_GAMES) do
        local isCurrent = (id == game.PlaceId or id == game.GameId)
        if isCurrent then
            GamesTab:Paragraph({
                Title = info.Name,
                Desc = "Status: Currently Playing",
                Image = "solar:check-circle-bold",
            })
        else
            GamesTab:Paragraph({
                Title = info.Name,
                Desc = "Place ID: " .. tostring(id),
                Image = "solar:gamepad-minimalistic-bold",
                Buttons = {
                    {
                        Title = "Play",
                        Icon = "solar:square-top-down-bold",
                        Callback = function()
                            TeleportService:Teleport(id, LocalPlayer)
                        end,
                    }
                }
            })
        end
    end

    -- TAB 3: ⚙️ SETTINGS
    local SettingsTab = MainWindow:Tab({
        Title = "Settings",
        Desc = "Tema & diagnosa",
        Icon = "solar:settings-bold",
        IconColor = Color3.fromHex("#ECA201"),
        Border = true,
    })

    local ping = "N/A"
    pcall(function()
        local stats: any = game:GetService("Stats")
        local net = stats:FindFirstChild("Network")
        if net and net:FindFirstChild("ServerStatsItem") and net.ServerStatsItem:FindFirstChild("Data Ping") then
            ping = tostring(math.floor(net.ServerStatsItem["Data Ping"]:GetValue())) .. " ms"
        end
    end)

    SettingsTab:Paragraph({
        Title = LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")",
        Desc = "Ping: " .. ping .. "  •  Account Age: " .. tostring(LocalPlayer.AccountAge) .. " days",
        Image = "solar:user-id-bold",
    })

    SettingsTab:Divider()

    SettingsTab:Dropdown({
        Title = "Theme Accent",
        Desc = "Pilih skema warna antarmuka",
        Values = { "Midnight", "Dark", "Indigo", "Emerald", "Rose", "Violet", "Sky", "Amber" },
        Value = "Midnight",
        Callback = function(theme: string)
            pcall(function() WindUI:SetTheme(theme) end)
        end,
    })

    SettingsTab:Button({
        Title = "Reset Saved Key",
        Desc = "Hapus key tersimpan & logout ke layar aktivasi",
        Icon = "solar:trash-bin-trash-bold",
        Callback = function()
            pcall(function()
                if isfile and isfile(KEY_FILE) then
                    delfile(KEY_FILE)
                end
            end)
            WindUI:Notify({
                Title = "Key Direset",
                Content = "Key lokal berhasil dihapus. Membuka layar aktivasi...",
                Duration = 2.5,
                Icon = "solar:shield-warning-bold",
            })
            task.wait(0.5)
            pcall(function() MainWindow:Destroy() end)
            openKeySystemWindow()
        end,
    })

    MainWindow:SelectTab(1)
end

-- 7. KEY SYSTEM WINDOW (MUNCUL JIKA BELUM ADA KEY / KEY SUDAH DIHAPUS DI FLOWAUTH)
openKeySystemWindow = function(noticeMessage: string?)
    local KeyWindow = WindUI:CreateWindow({
        Title = "Horizon Hub",
        Author = "Key Authentication",
        Folder = "HorizonHubKey",
        Icon = "solar:shield-keyhole-bold",
        Size = UDim2.fromOffset(490, 330),
        Transparent = true,
        Theme = "Midnight",
        Acrylic = true,
        SideBarWidth = 0,
        HideSearchBar = true,
        Topbar = {
            Height = 44,
            ButtonsType = "Mac",
        },
        User = {
            Enabled = false,
        },
    })

    pcall(function()
        KeyWindow:Tag({
            Title = "FlowAuth Required",
            Icon = "solar:lock-keyhole-bold",
            Color = Color3.fromHex("#ef4444"),
        })
    end)

    local KeyTab = KeyWindow:Tab({
        Title = "Activate",
        Icon = "solar:key-square-bold",
    })

    KeyTab:Paragraph({
        Title = "Masukkan Key FlowAuth",
        Desc = noticeMessage or "Key diperlukan untuk mengakses Horizon Hub.\nDapatkan key melalui link FlowAuth lalu masukkan di bawah ini.",
        Image = "solar:shield-warning-bold",
    })

    local enteredKey = ""

    KeyTab:Input({
        Title = "FlowAuth Key",
        Desc = "Tempel access key Anda di sini",
        Placeholder = "Masukkan key di sini...",
        Value = "",
        Callback = function(val: string)
            enteredKey = val:gsub("%s+", "")
        end,
    })

    local isChecking = false

    KeyTab:Button({
        Title = "Verify & Unlock",
        Desc = "Cocokkan key dengan server FlowAuth",
        Icon = "solar:check-circle-bold",
        Callback = function()
            if isChecking then return end
            if not enteredKey or enteredKey == "" then
                WindUI:Notify({
                    Title = "Key Kosong",
                    Content = "Silakan masukkan key terlebih dahulu!",
                    Duration = 3,
                    Icon = "solar:danger-triangle-bold",
                })
                return
            end

            isChecking = true
            WindUI:Notify({
                Title = "Memverifikasi...",
                Content = "Mencocokkan key dengan server FlowAuth...",
                Duration = 2,
                Icon = "solar:refresh-bold",
            })

            task.spawn(function()
                local isValid, msg = verifyKeyWithFlowAuth(enteredKey)
                isChecking = false

                if isValid then
                    pcall(function()
                        if writefile then
                            writefile(KEY_FILE, enteredKey)
                        end
                    end)

                    WindUI:Notify({
                        Title = "Aktivasi Berhasil!",
                        Content = "Key cocok dengan FlowAuth. Membuka Horizon Hub...",
                        Duration = 3,
                        Icon = "solar:check-circle-bold",
                    })

                    task.wait(0.6)
                    pcall(function() KeyWindow:Destroy() end)
                    openMainHubWindow()
                else
                    WindUI:Notify({
                        Title = "Aktivasi Gagal!",
                        Content = msg or "Key tidak valid atau sudah dihapus di FlowAuth.",
                        Duration = 4,
                        Icon = "solar:close-circle-bold",
                    })
                end
            end)
        end,
    })

    KeyTab:Button({
        Title = "Get Key (Copy Link)",
        Desc = "Salin tautan untuk mendapatkan key FlowAuth",
        Icon = "solar:copy-bold",
        Callback = function()
            local copied = false
            pcall(function()
                if setclipboard then
                    setclipboard(FLOWAUTH_GETKEY_URL)
                    copied = true
                end
            end)

            if copied then
                WindUI:Notify({
                    Title = "Link Disalin!",
                    Content = "Tautan FlowAuth telah disalin ke clipboard Anda.",
                    Duration = 3.5,
                    Icon = "solar:copy-bold",
                })
            else
                WindUI:Notify({
                    Title = "Tautan FlowAuth",
                    Content = FLOWAUTH_GETKEY_URL,
                    Duration = 6,
                    Icon = "solar:link-bold",
                })
            end
        end,
    })

    KeyWindow:SelectTab(1)
end

-- 8. STARTUP: CEK KEY FILE & MATCH DENGAN FLOWAUTH
local function initLoader()
    local hasSavedKey = false
    local savedKey = ""

    pcall(function()
        if isfile and isfile(KEY_FILE) then
            savedKey = (readfile(KEY_FILE) or ""):gsub("%s+", "")
            if #savedKey > 0 then
                hasSavedKey = true
            end
        end
    end)

    if hasSavedKey then
        -- Verifikasi key tersimpan langsung ke FlowAuth
        task.spawn(function()
            local isValid, msg = verifyKeyWithFlowAuth(savedKey)
            if isValid then
                openMainHubWindow()
            else
                -- Key tidak match atau sudah dihapus di FlowAuth!
                pcall(function()
                    if delfile and isfile(KEY_FILE) then
                        delfile(KEY_FILE)
                    end
                end)
                openKeySystemWindow("Key yang tersimpan sebelumnya tidak valid atau telah dihapus di FlowAuth. Silakan masukkan key baru.")
            end
        end)
    else
        -- Belum ada key sama sekali
        openKeySystemWindow()
    end
end

initLoader()