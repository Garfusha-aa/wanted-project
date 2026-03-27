script_name("District Tracker")
script_author("Garfusha")

local SCRIPT_VERSION = "2.0"

local UPDATE_URL = "https://raw.githubusercontent.com/Garfusha-aa/wanted-project/refs/heads/main/wanted.lua"
local VERSION_URL = "https://raw.githubusercontent.com/Garfusha-aa/wanted-project/refs/heads/main/version.txt"

local dlstatus = require('moonloader').download_status

function checkUpdate()
    downloadUrlToFile(VERSION_URL, getWorkingDirectory() .. "\\dt_version.txt",
        function(id, status)
            if status == dlstatus.STATUSEX_ENDDOWNLOAD then
                local f = io.open(getWorkingDirectory() .. "\\dt_version.txt", "r")
                if f then
                    local new_version = f:read("*a")
                    f:close()
                    new_version = new_version:gsub("%s+", "")

                    if new_version ~= SCRIPT_VERSION then
                        sampAddChatMessage("[DT] Есть обнова: "..new_version, 0x00FF00)
                        updateScript()
                    else
                        sampAddChatMessage("[DT] Версия актуальна", 0xAAAAAA)
                    end
                end
            end
        end
    )
end

function updateScript()
    local path = thisScript().path
    downloadUrlToFile(UPDATE_URL, path,
        function(id, status)
            if status == dlstatus.STATUSEX_ENDDOWNLOAD then
                sampAddChatMessage("[DT] Обновился, перезапуск...", 0x00FF00)
                thisScript():reload()
            end
        end
    )
end

function main()
    repeat wait(0) until isSampAvailable()

    sampAddChatMessage("[DT] Загружен. Версия: "..SCRIPT_VERSION, -1)

    lua_thread.create(function()
        wait(3000)
        checkUpdate()
    end)

    while true do
        wait(0)
    end
end
