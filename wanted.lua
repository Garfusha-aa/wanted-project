script_name("District Tracker")
script_author("Garfusha1")

local sampev = require "samp.events"
local http = require("ssl.https")
local ltn12 = require("ltn12")

local SCRIPT_VERSION = "3.0"

local UPDATE_URL = "https://raw.githubusercontent.com/Garfusha-aa/wanted-project/main/wanted.lua"
local VERSION_URL = "https://raw.githubusercontent.com/Garfusha-aa/wanted-project/main/version.txt"

-- ================= ÀÂÒÎÎÁÍÎÂÀ =================

function checkUpdate()
    sampAddChatMessage("[DT] Ïðîâåðêà îáíîâëåíèÿ...", -1)

    local versionData = {}
    local _, code = http.request{
        url = VERSION_URL,
        sink = ltn12.sink.table(versionData)
    }

    if code ~= 200 then
        sampAddChatMessage("[DT] Îøèáêà ïðîâåðêè âåðñèè: "..tostring(code), -1)
        return
    end

    local new_version = table.concat(versionData):gsub("%s+", "")

    sampAddChatMessage("[DT] online: "..new_version, -1)
    sampAddChatMessage("[DT] local: "..SCRIPT_VERSION, -1)

    if new_version ~= SCRIPT_VERSION then
        sampAddChatMessage("[DT] Íàéäåíà îáíîâà!", 0x00FF00)
        updateScript()
    else
        sampAddChatMessage("[DT] Îáíîâëåíèå íå òðåáóåòñÿ", -1)
    end
end

function updateScript()
    sampAddChatMessage("[DT] Ñêà÷èâàíèå îáíîâû...", -1)

    local script_path = thisScript().path
    local data = {}

    local _, code = http.request{
        url = UPDATE_URL,
        sink = ltn12.sink.table(data)
    }

    if code ~= 200 then
        sampAddChatMessage("[DT] HTTP îøèáêà: "..tostring(code), -1)
        return
    end

    local content = table.concat(data)

    local file = io.open(script_path, "wb")
    if not file then
        sampAddChatMessage("[DT] Íå óäàëîñü ñîçäàòü ôàéë", -1)
        return
    end

    file:write(content)
    file:close()

    sampAddChatMessage("[DT] Îáíîâëåíî! Ïåðåçàãðóçêà...", 0x00FF00)

    wait(500)
    thisScript():reload()
end

-- ================= ÒÂÎÉ ÊÎÄ =================

local allowedTextDraws = {
    [2110] = true,
    [2077] = true
}

local zones = zones or {
    -- (îñòàâèë êàê ó òåáÿ, íå òðîãàë)
}

local renderFont = renderCreateFont("Arial", 10, 5)

local targetZone = "Íåò öåëè"
local targetName = "Íåèçâåñòíî"
local targetId = "?"

local waypointX, waypointY = nil, nil
local lastZone = nil

local function getCenter(zone)
    local _, minX, minY, _, maxX, maxY, _ = table.unpack(zone)
    return (minX + maxX) / 2, (minY + maxY) / 2
end

local function getDistance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

function main()
    repeat wait(0) until isSampAvailable()

    sampAddChatMessage("[HUD] Ñêðèïò çàïóùåí.", 0x00FF00)

    -- ?? çàïóñê àâòîîáíîâû
    lua_thread.create(function()
        wait(3000)
        checkUpdate()
    end)

    while true do
        wait(0)

        local text = ""

        if waypointX then
            local px, py, _ = getCharCoordinates(PLAYER_PED)
            local dist = getDistance(px, py, waypointX, waypointY)

            text = string.format(
                "Öåëü: %s [%s]\nÐàéîí: %s\nÄèñòàíöèÿ: %.0f ì",
                targetName,
                targetId,
                targetZone,
                dist
            )
        else
            text = "Öåëü íå óñòàíîâëåíà"
        end

        renderFontDrawText(renderFont, text, 20, 300, 0xFFFFFFFF)
    end
end

local function processText(id, text)
    text = text:gsub("~.-~", "")

    for line in text:gmatch("[^\n]+") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")

        if line:lower():find("wanted") then
            local nickname, playerId = line:match("([%w_]+)%s*%[(%d+)%]")

            if nickname and playerId then
                targetName = nickname
                targetId = playerId

                sampAddChatMessage(
                    "[HUD] Íàéäåíà öåëü: " .. targetName .. " [" .. targetId .. "]",
                    0x00FF00
                )
            end
        end

        if allowedTextDraws[id] then
            for _, data in ipairs(zones) do
                local name = data[1]

                if line:lower():find(name:lower(), 1, true) then
                    if lastZone == name then goto continue end

                    local x, y = getCenter(data)

                    lastZone = name
                    waypointX, waypointY = x, y
                    targetZone = name

                    placeWaypoint(x, y)

                    sampAddChatMessage("[HUD] Ðàéîí öåëè: " .. name, 0x00FF00)
                    return
                end

                ::continue::
            end
        end
    end

    return text
end

function sampev.onTextDrawSetString(id, text)
    return processText(id, text)
end

function sampev.onPlayerTextDrawSetString(id, text)
    return processText(id, text)
end
