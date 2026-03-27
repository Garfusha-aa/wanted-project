script_name("District Tracker HUD")
script_author("Garfusha")

local sampev = require "samp.events"
local http = require("ssl.https")
local ltn12 = require("ltn12")

-- ссылка на список пользователей
local USERS_URL = "https://raw.githubusercontent.com/Garfusha-aa/wanted-project/main/users.txt"

local allowedTextDraws = {
    [2110] = true,
    [2077] = true
}

local zones = zones or {
    {"Avispa Country Club", -2667.810, -302.135, -28.831, -2646.400, -262.320, 71.169},
}

local renderFont = renderCreateFont("Arial", 10, 5)

local targetZone = "Нет цели"
local targetName = "Неизвестно"
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

-- ?? ПРОВЕРКА ЧЕРЕЗ СЕРВЕР
local function checkAccess(nickname)
    local data = {}

    local _, code = http.request{
        url = USERS_URL,
        sink = ltn12.sink.table(data)
    }

    if code ~= 200 then
        sampAddChatMessage("[DT] Ошибка проверки доступа!", 0xFF0000)
        return false
    end

    local content = table.concat(data)

    for line in content:gmatch("[^\r\n]+") do
        if line == nickname then
            return true
        end
    end

    return false
end

function main()
    repeat wait(0) until isSampAvailable()

    local nickname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))

    sampAddChatMessage("{00FFFF}District Tracker | {98FB98} Проверка доступа...", -1)

    if not checkAccess(nickname) then
        sampAddChatMessage("{00FFFF}District Tracker | {FF0000} У тебя нет доступа!", 0xFF0000)
        thisScript():unload()
        return
    end

    sampAddChatMessage("{00FFFF}District Tracker | {98FB98} Доступ разрешён: "..nickname, 0x00FF00)

    while true do
        wait(0)

        local text = ""

        if waypointX then
            local px, py, _ = getCharCoordinates(PLAYER_PED)
            local dist = getDistance(px, py, waypointX, waypointY)

            text = string.format(
                "Цель: %s [%s]\nРайон: %s\nДистанция: %.0f м",
                targetName,
                targetId,
                targetZone,
                dist
            )
        else
            text = "Цель не установлена"
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
                    "{00FFFF}District Tracker | {98FB98}  Установленная цель: " .. targetName .. " [" .. targetId .. "]",
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

                    sampAddChatMessage("{00FFFF}District Tracker | {98FB98}  Район цели: " .. name, 0x00FF00)
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