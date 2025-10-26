local tempTakenPlates = {}

function IsPersonalPlateValid(plate)
    plate = string.upper(plate)

    local res = string.match(plate, "[A-HJ-NPR-Z0-9 ]+", 1)
    local trimmedLength = #plate:gsub(" ", "")

    local addedSpacing = math.floor((8 - trimmedLength) / 2)

    if res and res == plate and trimmedLength >= 4 then
        if trimmedLength < 8 then
            return string.rep(" ", addedSpacing) .. plate .. string.rep(" ", (8 - trimmedLength) - addedSpacing)
        else
            return plate
        end
    end

    return false
end

function IsPersonalPlateTaken(plate)
    if GENERATED_TEMP_PLATES[plate] then
        return true
    end

    if tempTakenPlates[plate] then
        return true
    end

    local test = IsPlateOwned(plate)
    return test
end

function PrivatePlateStuff(char, source, itemData)
    exports["sandbox-base"]:ClientCallback(source, "Vehicles:GetPersonalPlate", {}, function(veh, plate)
        if not veh or not plate then
            return
        end
        veh = NetworkGetEntityFromNetworkId(veh)
        if veh and DoesEntityExist(veh) then
            local vehState = Entity(veh).state
            if not vehState.VIN then
                exports['sandbox-hud']:Notification(source, "error", "Unable to Set Personal Plate")
                return
            end

            local vehicle = exports['sandbox-vehicles']:OwnedGetActive(vehState.VIN)
            if not vehicle then
                exports['sandbox-hud']:Notification(source, "error", "Can't Do It on This Vehicle")
                return
            end

            if vehicle:GetData("FakePlate") then
                exports['sandbox-hud']:Notification(source, "error", "Can't Do It on This Vehicle")
                return
            end

            local originalPlate = vehicle:GetData("RegisteredPlate")
            local newPlate = IsPersonalPlateValid(plate)

            if not newPlate then
                exports['sandbox-hud']:Notification(source, "error", "Invalid Plate Formatting")
                return
            end

            if IsPersonalPlateTaken(newPlate) then
                exports['sandbox-hud']:Notification(source, "error", "That Plate is Taken")
                return
            end

            tempTakenPlates[vehicle:GetData("RegisteredPlate")] = true
            tempTakenPlates[newPlate] = true

            local previousPlateChanges = vehicle:GetData("PreviousPlates") or {}

            table.insert(previousPlateChanges, {
                time = os.time(),
                oldPlate = vehicle:GetData("RegisteredPlate"),
                newPlate = newPlate,
                doneBy = char:GetData("SID")
            })

            vehicle:SetData("PreviousPlates", previousPlateChanges)
            vehicle:SetData("RegisteredPlate", newPlate)
            SetVehicleNumberPlateText(veh, newPlate)
            vehState.Plate = newPlate
            vehState.RegisteredPlate = newPlate

            exports['sandbox-vehicles']:OwnedForceSave(vehState.VIN)
            exports.ox_inventory:RemoveSlot(itemData.Owner, itemData.Name, 1, itemData.Slot, itemData.invType)

            exports['sandbox-hud']:Notification(source, "success", "Personal Plate Setup")
            exports['sandbox-base']:LoggerInfo('Vehicles',
                string.format("Personal Plate Change For Vehicle: %s. %s -> %s", vehState.VIN, originalPlate, newPlate))
        else
            exports['sandbox-hud']:Notification(source, "error", "Unable to Set Personal Plate")
        end
    end)
end

function RegisterPersonalPlateCallbacks()
    RegisterItems()
    exports["sandbox-chat"]:RegisterAdminCommand("adddonatorplates", function(source, args, rawCommand)
        local license = table.unpack(args)

        if license then
            local success = exports['sandbox-vehicles']:DonatorPlatesAdd(license)
            if success then
                exports["sandbox-chat"]:SendSystemSingle(source, "Successfully Added")
            else
                exports["sandbox-chat"]:SendSystemSingle(source, "Failed")
            end
        end
    end, {
        help = "[Admin] Add donator plates",
        params = {
            {
                name = "Player Identifier",
                help = "Player License",
            },
        },
    }, 1)

    exports["sandbox-chat"]:RegisterAdminCommand("getdonatorplates", function(source, args, rawCommand)
        local license = table.unpack(args)

        if license then
            local success = exports['sandbox-vehicles']:DonatorPlatesCheck(license)
            if success and success.pending then
                exports["sandbox-chat"]:SendSystemSingle(source,
                    string.format("Player Identifier: %s<br>Pending Plates: %s<br>Redeemed Plates: %s", license,
                        success.pending, success.redeemed or 0))
            else
                exports["sandbox-chat"]:SendSystemSingle(source, "Failed")
            end
        end
    end, {
        help = "[Admin] Check donator plates",
        params = {
            {
                name = "Player Identifier",
                help = "Player License",
            },
        },
    }, 1)

    exports["sandbox-chat"]:RegisterAdminCommand("removedonatorplates", function(source, args, rawCommand)
        local license = table.unpack(args)

        if license then
            local success = exports['sandbox-vehicles']:DonatorPlatesRemove(license, 1)
            if success then
                exports["sandbox-chat"]:SendSystemSingle(source, "Successfully Removed")
            else
                exports["sandbox-chat"]:SendSystemSingle(source, "Failed")
            end
        end
    end, {
        help = "[Admin] Remove donator plates",
        params = {
            {
                name = "Player Identifier",
                help = "Player License",
            },
        },
    }, 1)

    exports["sandbox-base"]:RegisterServerCallback("Vehicles:CheckDonatorPersonalPlates", function(source, data, cb)
        local plyr = exports['sandbox-base']:FetchSource(source)
        if plyr then
            local res = exports['sandbox-vehicles']:DonatorPlatesCheck(plyr:GetData("Identifier"))

            cb(res and res.pending or 0)
        else
            cb(false)
        end
    end)

    exports["sandbox-base"]:RegisterServerCallback("Vehicles:ClaimDonatorPersonalPlates", function(source, data, cb)
        local plyr = exports['sandbox-base']:FetchSource(source)
        if plyr then
            local char = exports['sandbox-characters']:FetchCharacterSource(source)
            local res = exports['sandbox-vehicles']:DonatorPlatesCheck(plyr:GetData("Identifier"))

            if char and res and res.pending >= data then
                local isRemoved = exports['sandbox-vehicles']:DonatorPlatesRemove(plyr:GetData("Identifier"), data)

                if isRemoved then
                    exports.ox_inventory:AddItem(char:GetData("SID"), "personal_plates_donator", data, {}, 1)
                    cb(true)

                    exports['sandbox-base']:LoggerWarn(
                        "Donator",
                        string.format(
                            "%s [%s] Redeemed %s Donator Plates - Character %s %s (%s)",
                            plyr:GetData("Name"),
                            plyr:GetData("AccountID"),
                            data,
                            char:GetData('First'),
                            char:GetData('Last'),
                            char:GetData('SID')
                        ),
                        {
                            console = true,
                            file = false,
                            database = true,
                            discord = {
                                embed = true,
                                type = "error",
                                webhook = GetConvar("discord_donation_webhook", ''),
                            }
                        }
                    )
                    return
                end
            end
        else
            cb(false)
        end
    end)
end

function RegisterItems()
    exports.ox_inventory:RegisterUse("personal_plates", "Vehicles", function(source, itemData)
        local char = exports['sandbox-characters']:FetchCharacterSource(source)
        if not char or (Player(source).state.onDuty ~= "government" and Player(source).state.onDuty ~= "dgang") then
            exports['sandbox-hud']:Notification(source, "error", "Unable to Set Personal Plate")
            return
        end

        PrivatePlateStuff(char, source, itemData)
    end)

    exports.ox_inventory:RegisterUse("personal_plates_donator", "Vehicles", function(source, itemData)
        local char = exports['sandbox-characters']:FetchCharacterSource(source)
        if not char then
            exports['sandbox-hud']:Notification(source, "error", "Unable to Set Personal Plate")
            return
        end

        PrivatePlateStuff(char, source, itemData)
    end)
end

RegisterNetEvent('ox_inventory:ready', function()
    if GetResourceState(GetCurrentResourceName()) == 'started' then
        RegisterItems()
    end
end)

-- SetTimeout(2500, function()
--     print(IsPersonalPlateValid('FFFF'))
--     print(IsPersonalPlateValid('FFFFF'))
--     print(IsPersonalPlateValid('FFFFFF'))
--     print(IsPersonalPlateValid('FFFFFFF'))
--     print(IsPersonalPlateValid('FFFFFFFF'))
-- end)

exports("DonatorPlatesAdd", function(playerIdentifier)
    local p = promise.new()

    exports.oxmysql:execute('UPDATE donator_plates SET pending = pending + 1 WHERE player = ?', { playerIdentifier },
        function(affectedRows)
            if affectedRows > 0 then
                p:resolve(true)
            else
                exports.oxmysql:insert(
                    'INSERT INTO donator_plates (player, pending, redeemed) VALUES (?, 1, 0) ON DUPLICATE KEY UPDATE pending = pending + 1',
                    { playerIdentifier }, function(insertId)
                        p:resolve(insertId and insertId > 0)
                    end)
            end
        end)

    return Citizen.Await(p)
end)

exports("DonatorPlatesCheck", function(playerIdentifier)
    local p = promise.new()

    exports.oxmysql:execute('SELECT pending, redeemed FROM donator_plates WHERE player = ?', { playerIdentifier },
        function(result)
            if result and #result > 0 then
                p:resolve(result[1])
            else
                p:resolve(false)
            end
        end)

    return Citizen.Await(p)
end)

exports("DonatorPlatesRemove", function(playerIdentifier, amount)
    local p = promise.new()

    exports.oxmysql:execute(
        'UPDATE donator_plates SET pending = pending - ?, redeemed = redeemed + ? WHERE player = ? AND pending >= ?',
        { amount, amount, playerIdentifier, amount }, function(affectedRows)
            p:resolve(affectedRows > 0)
        end)

    return Citizen.Await(p)
end)

AddEventHandler("Vehicles:Server:AddDonatorPlates", function(license)
    exports['sandbox-vehicles']:DonatorPlatesAdd(license)
end)

function TebexAddDonatorPlate(source, args)
    local sid = table.unpack(args)
    sid = tonumber(sid)
    if sid == nil or sid == 0 then
        exports['sandbox-base']:LoggerWarn(
            "Donator Plate",
            "Provided SID (server ID) was empty.",
            {
                console = true,
                file = false,
                database = true,
                discord = {
                    embed = true,
                    type = "error",
                    webhook = GetConvar("discord_donation_webhook", ''),
                }
            }
        )
        return
    end
    local player = exports['sandbox-base']:FetchSource(sid)
    if player then
        local license = player:GetData("Identifier")
        local success = exports['sandbox-vehicles']:DonatorPlatesAdd(license)
        if success then
            exports["sandbox-chat"]:SendSystemSingle(sid, "Successfully Added")
        else
            exports["sandbox-chat"]:SendSystemSingle(sid, "Failed")
        end
    end
end

RegisterCommand("tebexadddonatorplate", TebexAddDonatorPlate, true)
