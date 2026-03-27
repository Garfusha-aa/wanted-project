script_name("District Tracker HUD")
script_author("Garfusha")

local sampev = require "samp.events"

local allowedTextDraws = {
    [2110] = true,
    [2077] = true
}

local zones = zones or {
    {"Idlewood", 1812.6, -1852.8, 0.0, 1971.6, -1742.3, 0.0},
    {"Ganton", 2222.5, -1852.8, 0.0, 2632.8, -1722.3, 0.0},
    {"Jefferson", 1996.9, -1449.6, 0.0, 2222.5, -1350.7, 0.0},
    {"East Los Santos", 2222.5, -1628.5, 0.0, 2421.0, -1494.0, 0.0}
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

function main()
    repeat wait(0) until isSampAvailable()

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
                    "{00FFFF}District Tracker | {98FB98}  Найдена цель: " .. targetName .. " [" .. targetId .. "]",
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