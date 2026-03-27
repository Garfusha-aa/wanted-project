script_name("AutoUpdater")
script_author("you")

local UPDATE_URL = "https://codeberg.org/USERNAME/REPO/raw/branch/main/wanted.lua"
local TEMP_FILE = getWorkingDirectory() .. "\\wanted_update.lua"
local LOCAL_FILE = thisScript().path

-- =========================
-- Чтение файла
-- =========================
function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

-- =========================
-- Получение версии
-- (поддерживает разные форматы)
-- =========================
function get_version(content)
    if not content then return nil end
    
    return content:match('[Vv][Ee][Rr][Ss][Ii][Oo][Nn]%s*=%s*"(.-)"')
        or content:match('[Vv][Ee][Rr][Ss][Ii][Oo][Nn]%s*=%s*(%d+%.?%d*)')
end

-- =========================
-- Сравнение версий (1.2.3)
-- =========================
function compare_versions(v1, v2)
    if not v1 or not v2 then return false end
    
    local function split(v)
        local t = {}
        for num in v:gmatch("%d+") do
            table.insert(t, tonumber(num))
        end
        return t
    end
    
    local t1, t2 = split(v1), split(v2)
    
    for i = 1, math.max(#t1, #t2) do
        local a = t1[i] or 0
        local b = t2[i] or 0
        if a > b then return true end
        if a < b then return false end
    end
    
    return false
end

-- =========================
-- Основная логика
-- =========================
function main()
    if not isSampAvailable() then return end
    wait(1000)

    print("[Updater] Проверка обновления...")

    -- качаем файл
    downloadUrlToFile(UPDATE_URL, TEMP_FILE,
        function(id, status)
            if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                
                local remote_content = read_file(TEMP_FILE)
                local local_content = read_file(LOCAL_FILE)

                local remote_version = get_version(remote_content)
                local local_version = get_version(local_content)

                print("[Updater] Локальная версия:", local_version)
                print("[Updater] Удалённая версия:", remote_version)

                if remote_version and (not local_version or compare_versions(remote_version, local_version)) then
                    print("[Updater] Найдено обновление!")

                    -- перезаписываем текущий скрипт
                    local f = io.open(LOCAL_FILE, "w")
                    f:write(remote_content)
                    f:close()

                    print("[Updater] Скрипт обновлён, перезагрузка...")

                    thisScript():reload()
                else
                    print("[Updater] Обновление не требуется")
                end

                os.remove(TEMP_FILE)
            else
                print("[Updater] Ошибка загрузки")
            end
        end
    )

    while true do wait(0) end
end