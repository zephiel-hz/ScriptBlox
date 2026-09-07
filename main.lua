-- // ==============================================================
-- // HORIZON HUB | MULTI-GAMES LOADER + WIND UI KEY SYSTEM
-- // ==============================================================

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- Executor Environment Compatibility
local env: any = (getgenv and getgenv()) or _G
local getclipboard = env.getclipboard
local setclipboard = env.setclipboard
local toclipboard = env.toclipboard
local identifyexecutor = env.identifyexecutor or env.getexecutorname
local isfile = env.isfile
local readfile = env.readfile
local writefile = env.writefile
local delfile = env.delfile

-- 1. DAFTAR GAME YANG DIDUKUNG
local SUPPORTED_GAMES: { [number]: { Name: string, Script: any } } = {
    -- [PlaceId] = { Nama Game, Script / Link }
    [133341016381877] = {
        Name = "Mount RNG",
        Script = 'loadstring(game:HttpGet("https://encrypt-x.pages.dev/Scripts?Id=1892450044143"))("1892450044143")',
    },
    
    -- Contoh menambah game lain:
    [2753915549] = {
        Name = "Blox Fruits",
        Script = "https://raw.githubusercontent.com/acsu123/HOHO_CREATIVE/main/Hub.lua",
    },
    [16732694052] = {
        Name = "Fisch",
        Script = "https://raw.githubusercontent.com/SpeedHubX/SpeedHubX/main/SpeedHubX.lua",
    },
}

-- 2. DETEKSI GAME SAAT INI
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
    warn("[Horizon Hub] PlaceId (" .. tostring(game.PlaceId) .. ") tidak terdaftar dalam Multi-Games.")
    return
end

-- 3. KONFIGURASI KEY SYSTEM & REWARD
local FLOWAUTH_LOADER_URL = "https://flowauth.net/v1/loaders/4a3a799b84b7f927699ee033c487ca36.lua"
local REWARD_URL = "https://flowauth.net/reward/4a3a799b84b7f927699ee033c487ca36"
local KEY_FILE = "HorizonHub_Key.txt"

-- Fungsi untuk menjalankan script target game
local function launchTargetGameScript()
    print("[Horizon Hub] Menjalankan script untuk game: " .. currentGame.Name)
    local ok, err = pcall(function()
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
    if not ok then
        warn("[Horizon Hub Error]: " .. tostring(err))
    end
end

-- Fungsi verifikasi key ke server FlowAuth
local function verifyKeyWithFlowAuth(key: string)
    local success, result = pcall(function()
        local loader = loadstring(game:HttpGet(FLOWAUTH_LOADER_URL))
        if not loader then
            error("Gagal mengunduh loader FlowAuth", 2)
        end
        return loader(key)
    end)
    return success, result
end

-- 4. CEK APAKAH KEY SUDAH TERSIMPAN & MASIH VALID
if isfile and readfile and isfile(KEY_FILE) then
    local savedKey = readfile(KEY_FILE)
    if savedKey and savedKey:gsub("%s+", "") ~= "" then
        local ok, _ = verifyKeyWithFlowAuth(savedKey:gsub("%s+", ""))
        if ok then
            print("[Horizon Hub] Key tersimpan valid! Menjalankan " .. currentGame.Name)
            launchTargetGameScript()
            return
        else
            if delfile then pcall(delfile, KEY_FILE) end
        end
    end
end

-- 5. LOAD WIND UI LIBRARY
local WindUI: any = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- 6. BUAT WINDOW KEY SYSTEM MODERN (WIND UI)
local KeyWindow = WindUI:CreateWindow({
    Title = "Horizon Hub",
    Author = "Multi-Games Hub • Authentication",
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
        ButtonsType = "Mac", -- macOS style traffic lights
    },
    User = {
        Enabled = true,
        Anonymous = false, -- Menampilkan avatar & nama user di sidebar bawah
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

-- Header Tag Badges
pcall(function()
    KeyWindow:Tag({
        Title = "FlowAuth v1",
        Icon = "solar:lock-keyhole-minimalistic-bold",
        Color = Color3.fromHex("#38bdf8"),
    })
    KeyWindow:Tag({
        Title = currentGame.Name,
        Icon = "solar:gamepad-bold",
        Color = Color3.fromHex("#22c55e"),
    })
end)

-- ==============================================================
-- TAB 1: 🔑 KEY AUTHENTICATION
-- ==============================================================
local KeyTab = KeyWindow:Tab({
    Title = "Authentication",
    Desc = "Aktivasi lisensi script",
    Icon = "solar:shield-keyhole-bold",
    IconColor = Color3.fromHex("#7775F2"),
    Border = true,
})

-- Status Banner Game
KeyTab:Paragraph({
    Title = "Game Terdeteksi: " .. currentGame.Name,
    Desc = "Place ID: " .. tostring(game.PlaceId) .. "  •  Status: Menunggu Kunci Akses\nMasukkan key yang valid untuk membuka skrip otomatisasi penuh.",
    Image = "solar:gamepad-bold",
})

-- Panduan Pengambilan Key
KeyTab:Paragraph({
    Title = "Panduan Memperoleh Key:",
    Desc = "1. Tekan tombol [Get Key Link] di bawah ini.\n2. Buka link di browser lalu selesaikan checkpoint FlowAuth.\n3. Gunakan [Paste from Clipboard] atau masukkan key manual, lalu tekan [Verify & Launch].",
    Image = "solar:lightbulb-bolt-bold",
})

KeyTab:Divider()

local enteredKey = ""
local KeyInput: any

-- Input Kolom Key
KeyInput = KeyTab:Input({
    Title = "Access Key",
    Desc = "Masukkan atau tempel kunci akses kamu di sini",
    Placeholder = "Tempel key FlowAuth di sini...",
    Icon = "solar:key-bold",
    Callback = function(val: string)
        enteredKey = val:gsub("%s+", "")
    end,
})

-- Tombol Verifikasi Key
KeyTab:Button({
    Title = "Verify & Launch Script",
    Desc = "Validasi key ke server FlowAuth dan jalankan " .. currentGame.Name,
    Icon = "solar:play-circle-bold",
    Callback = function()
        if enteredKey == "" then
            WindUI:Notify({
                Title = "Peringatan",
                Content = "Mohon masukkan key terlebih dahulu!",
                Duration = 4,
                Icon = "solar:danger-triangle-bold",
            })
            return
        end

        WindUI:Notify({
            Title = "Memverifikasi...",
            Content = "Sedang menghubungkan ke server FlowAuth...",
            Duration = 3,
            Icon = "solar:clock-circle-bold",
        })

        task.spawn(function()
            local success, err = verifyKeyWithFlowAuth(enteredKey)
            if success then
                -- Simpan key jika valid
                if writefile then
                    pcall(writefile, KEY_FILE, enteredKey)
                end

                WindUI:Notify({
                    Title = "Akses Diterima!",
                    Content = "Key Valid! Memuat script " .. currentGame.Name .. "...",
                    Duration = 3,
                    Icon = "solar:check-circle-bold",
                })

                task.wait(1)
                pcall(function() KeyWindow:Destroy() end)

                -- Luncurkan script game target
                launchTargetGameScript()
            else
                WindUI:Notify({
                    Title = "Verifikasi Gagal",
                    Content = "Key salah, tidak sah, atau sudah kedaluwarsa!",
                    Duration = 5,
                    Icon = "solar:close-circle-bold",
                })
            end
        end)
    end,
})

-- Tombol Paste dari Clipboard
KeyTab:Button({
    Title = "Paste Key from Clipboard",
    Desc = "Ambil key otomatis dari clipboard perangkat Anda",
    Icon = "solar:clipboard-text-bold",
    Callback = function()
        local clip = ""
        if getclipboard then
            pcall(function() clip = getclipboard() end)
        end

        clip = (clip or ""):gsub("%s+", "")
        if clip ~= "" then
            enteredKey = clip
            if KeyInput and KeyInput.Set then
                KeyInput:Set(clip)
            end
            WindUI:Notify({
                Title = "Key Ditempel!",
                Content = "Key berhasil disalin dari clipboard ke kolom input.",
                Duration = 3,
                Icon = "solar:clipboard-check-bold",
            })
        else
            WindUI:Notify({
                Title = "Clipboard Kosong",
                Content = "Tidak ditemukan teks key pada clipboard Anda.",
                Duration = 4,
                Icon = "solar:danger-triangle-bold",
            })
        end
    end,
})

-- Tombol Ambil Link Key (Reward Checkpoint)
KeyTab:Button({
    Title = "Get Key Link (Copy URL)",
    Desc = "Salin link checkpoint reward FlowAuth ke clipboard",
    Icon = "solar:link-circle-bold",
    Callback = function()
        local copied = false
        if setclipboard then
            pcall(setclipboard, REWARD_URL)
            copied = true
        elseif toclipboard then
            pcall(toclipboard, REWARD_URL)
            copied = true
        end

        if copied then
            WindUI:Notify({
                Title = "Link Berhasil Disalin!",
                Content = "Buka browser Anda dan selesaikan untuk memperoleh key.",
                Duration = 5,
                Icon = "solar:link-round-bold",
            })
        else
            WindUI:Notify({
                Title = "Info Link Key",
                Content = "Buka browser Anda ke:\n" .. REWARD_URL,
                Duration = 8,
                Icon = "solar:info-circle-bold",
            })
        end
    end,
})

-- ==============================================================
-- TAB 2: 🎮 SUPPORTED GAMES
-- ==============================================================
local SupportedTab = KeyWindow:Tab({
    Title = "Supported Games",
    Desc = "Daftar katalog game yang didukung",
    Icon = "solar:gamepad-bold",
    IconColor = Color3.fromHex("#10C550"),
    Border = true,
})

SupportedTab:Paragraph({
    Title = "Multi-Games Network Hub",
    Desc = "Horizon Hub mendukung berbagai game. Script otomatis menyesuaikan fungsionalitas dan bypass berdasarkan PlaceId saat ini.",
    Image = "solar:planet-bold",
})

SupportedTab:Divider()

for id, info in pairs(SUPPORTED_GAMES) do
    local isCurrent = (id == game.PlaceId or id == game.GameId)
    if isCurrent then
        SupportedTab:Paragraph({
            Title = "🎮 " .. info.Name .. "  [SEDANG DIMAINKAN]",
            Desc = "• Place ID: " .. tostring(id) .. "\n• Status: Aktif & Siap Dieksekusi\n• Jalur Autentikasi: FlowAuth Checkpoint",
            Image = "solar:check-circle-bold",
        })
    else
        SupportedTab:Paragraph({
            Title = "• " .. info.Name,
            Desc = "• Place ID: " .. tostring(id) .. "\n• Status: Didukung (Tersedia)",
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

-- ==============================================================
-- TAB 3: ⚙️ SETTINGS & SYSTEM INFO
-- ==============================================================
local SettingsTab = KeyWindow:Tab({
    Title = "Settings & Info",
    Desc = "Konfigurasi tampilan & diagnosa",
    Icon = "solar:settings-bold",
    IconColor = Color3.fromHex("#ECA201"),
    Border = true,
})

-- Info Client / Diagnostik
local pingValue = "N/A"
pcall(function()
    local stats: any = game:GetService("Stats")
    local network = stats:FindFirstChild("Network")
    if network then
        local serverStats = network:FindFirstChild("ServerStatsItem")
        if serverStats and serverStats:FindFirstChild("Data Ping") then
            pingValue = tostring(math.floor(serverStats["Data Ping"]:GetValue())) .. " ms"
        end
    end
end)

local executorName = "Unknown"
pcall(function()
    if identifyexecutor then
        executorName = identifyexecutor()
    end
end)

SettingsTab:Paragraph({
    Title = "System & Player Diagnostics",
    Desc = "• Pemain: " .. LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")\n• User ID: " .. tostring(LocalPlayer.UserId) .. "\n• Executor: " .. executorName .. "\n• Ping: " .. pingValue .. "\n• Place ID: " .. tostring(game.PlaceId),
    Image = "solar:user-id-bold",
})

SettingsTab:Divider()

-- Dropdown Ganti Tema Secara Real-time
SettingsTab:Dropdown({
    Title = "Pilih Tema Tampilan",
    Desc = "Ubah skema warna UI secara langsung",
    Values = { "Midnight", "Dark", "Indigo", "Emerald", "Rose", "Violet", "Sky", "Amber" },
    Value = "Midnight",
    Callback = function(selectedTheme: string)
        pcall(function()
            WindUI:SetTheme(selectedTheme)
        end)
    end,
})

-- Tombol Hapus Cache Key
SettingsTab:Button({
    Title = "Hapus Cache Key Lokal",
    Desc = "Hapus file " .. KEY_FILE .. " jika key mengalami error / expired",
    Icon = "solar:trash-bin-trash-bold",
    Callback = function()
        if delfile and isfile and isfile(KEY_FILE) then
            pcall(delfile, KEY_FILE)
            enteredKey = ""
            if KeyInput and KeyInput.Set then
                KeyInput:Set("")
            end
            WindUI:Notify({
                Title = "Cache Dihapus",
                Content = "File " .. KEY_FILE .. " berhasil dihapus.",
                Duration = 4,
                Icon = "solar:trash-bin-trash-bold",
            })
        else
            WindUI:Notify({
                Title = "Info",
                Content = "Tidak ada cache key tersimpan yang ditemukan.",
                Duration = 3,
                Icon = "solar:info-circle-bold",
            })
        end
    end,
})

-- Pilih Tab Pertama Otomatis saat Terbuka
KeyWindow:SelectTab(1)
