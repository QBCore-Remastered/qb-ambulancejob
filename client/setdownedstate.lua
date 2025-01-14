local config = require 'config.client'
local sharedConfig = require 'config.shared'
local doctorCount = 0

local function getDoctorCount()
    return lib.callback.await('qbx_ambulancejob:server:getNumDoctors')
end

local function displayRespawnText()
    local deathTime = exports.qbx_medical:GetDeathTime()
    if deathTime > 0 and doctorCount > 0 then
        qbx.drawText2d({ text = locale('info.respawn_txt', math.ceil(deathTime)), coords = vec2(1.0, 1.44), scale = 0.6 })
    else
        qbx.drawText2d({
            text = locale('info.respawn_revive', exports.qbx_medical:GetRespawnHoldTimeDeprecated(), sharedConfig.checkInCost),
            coords = vec2(1.0, 1.44),
            scale = 0.6
        })
    end
end

---@param ped number
local function playDeadAnimation(ped)
    if IsInHospitalBed then
        if not IsEntityPlayingAnim(ped, InBedDict, InBedAnim, 3) then
            lib.playAnim(ped, InBedDict, InBedAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
        end
    else
        exports.qbx_medical:PlayDeadAnimation()
    end
end

---@param ped number
local function handleDead(ped)
    if not IsInHospitalBed then
        displayRespawnText()
    end

    playDeadAnimation(ped)
end

---Player is able to send a notification to EMS there are any on duty
local function handleRequestingEms()
    if not EmsNotified then
        qbx.drawText2d({ text = locale('info.request_help'), coords = vec2(1.0, 1.40), scale = 0.6 })
        if IsControlJustPressed(0, 47) then
            TriggerServerEvent('hospital:server:ambulanceAlert', locale('info.civ_down'))
            EmsNotified = true
        end
    else
        qbx.drawText2d({ text = locale('info.help_requested'), coords = vec2(1.0, 1.40), scale = 0.6 })
    end
end

local function handleLastStand()
    local laststandTime = exports.qbx_medical:GetLaststandTime()
    if laststandTime > config.laststandTimer or doctorCount == 0 then
        qbx.drawText2d({ text = locale('info.bleed_out', math.ceil(laststandTime)), coords = vec2(1.0, 1.44), scale = 0.6 })
    else
        qbx.drawText2d({ text = locale('info.bleed_out_help', math.ceil(laststandTime)), coords = vec2(1.0, 1.44), scale = 0.6 })
        handleRequestingEms()
    end
end

---Set dead and last stand states.
CreateThread(function()
    local lastUpdate = GetGameTimer()
    while true do
        local isDead = exports.qbx_medical:IsDead()
        local inLaststand = exports.qbx_medical:IsLaststand()
        if isDead or inLaststand then
            if isDead then
                handleDead(cache.ped)
            elseif inLaststand then
                handleLastStand()
            end

            local currentTime = GetGameTimer()
            if (currentTime - lastUpdate) > 60000 then
                doctorCount = getDoctorCount()
                lastUpdate = currentTime
            end

            Wait(0)
        else
            Wait(1000)
        end
    end
end)
