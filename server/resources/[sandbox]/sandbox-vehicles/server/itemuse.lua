function RegisterItemUses()
	exports.ox_inventory:RegisterUse("lockpick", "Vehicles", function(source, slot, itemData)
		SetTimeout(500, function()
			exports["sandbox-base"]:ClientCallback(source, "Vehicles:Lockpick", true, function(using, success)
				if using then
					local newValue = slot.CreateDate - (60 * 60 * 24)
					if success then
						newValue = slot.CreateDate - (60 * 60 * 12)
					end
					if (os.time() - itemData.durability >= newValue) then
						exports.ox_inventory:RemoveId(slot.Owner, slot.invType, slot)
					else
						exports.ox_inventory:SetItemCreateDate(slot.id, newValue)
					end
				end
			end)
		end)
	end)

	exports.ox_inventory:RegisterUse("adv_lockpick", "Vehicles", function(source, slot, itemData)
		SetTimeout(500, function()
			exports["sandbox-base"]:ClientCallback(source, "Vehicles:AdvLockpick", true, function(using, success)
				if using then
					local newValue = slot.CreateDate - (60 * 60 * 24)
					if success then
						newValue = slot.CreateDate - (60 * 60 * 12)
					end
					if (os.time() - itemData.durability >= newValue) then
						exports.ox_inventory:RemoveId(slot.Owner, slot.invType, slot)
					else
						exports.ox_inventory:SetItemCreateDate(slot.id, newValue)
					end
				end
			end)
		end)
	end)

	exports.ox_inventory:RegisterUse("electronics_kit", "Vehicles", function(source, slot, itemData)
		SetTimeout(500, function()
			exports["sandbox-base"]:ClientCallback(source, "Vehicles:Hack", true, function(using, success)
				if using then
					local newValue = slot.CreateDate - (60 * 60 * 24)
					if success then
						newValue = slot.CreateDate - (60 * 60 * 12)
					end
					if (os.time() - itemData.durability >= newValue) then
						exports.ox_inventory:RemoveId(slot.Owner, slot.invType, slot)
					else
						exports.ox_inventory:SetItemCreateDate(slot.id, newValue)
					end
				end
			end)
		end)
	end)

	exports.ox_inventory:RegisterUse("adv_electronics_kit", "Vehicles", function(source, slot, itemData)
		SetTimeout(500, function()
			exports["sandbox-base"]:ClientCallback(source, "Vehicles:AdvHack", true, function(using, success)
				if using then
					local newValue = slot.CreateDate - (60 * 60 * 24)
					if success then
						newValue = slot.CreateDate - (60 * 60 * 12)
					end
					if (os.time() - itemData.durability >= newValue) then
						exports.ox_inventory:RemoveId(slot.Owner, slot.invType, slot)
					else
						exports.ox_inventory:SetItemCreateDate(slot.id, newValue)
					end
				end
			end)
		end)
	end)

	exports.ox_inventory:RegisterUse("screwdriver", "Vehicles", function(source, slot, itemData)
		SetTimeout(1500, function()
			exports["sandbox-base"]:ClientCallback(source, "Vehicles:Lockpick", {
				{
					base = 4000,
					mod = 900,
				},
				{

					base = 3500,
					mod = 900,
				},
				false
			}, function(using, success)
				if using then
					local newValue = slot.CreateDate - (60 * 60 * 24)
					if success then
						newValue = slot.CreateDate - (60 * 60 * 12)
					end
					if (os.time() - itemData.durability >= newValue) then
						exports.ox_inventory:RemoveId(slot.Owner, slot.invType, slot)
					else
						exports.ox_inventory:SetItemCreateDate(slot.id, newValue)
					end
				end
			end)
		end)
	end)

	exports.ox_inventory:RegisterUse("repairkit", "Vehicles", function(source, itemData)
		exports["sandbox-base"]:ClientCallback(source, "Vehicles:RepairKit", false, function(success)
			if success then
				exports.ox_inventory:RemoveSlot(itemData.Owner, itemData.Name, 1, itemData.Slot, itemData
					.invType)
			end
		end)
	end)

	exports.ox_inventory:RegisterUse("repairkitadv", "Vehicles", function(source, itemData)
		exports["sandbox-base"]:ClientCallback(source, "Vehicles:RepairKit", true, function(success)
			if success then
				exports.ox_inventory:RemoveSlot(itemData.Owner, itemData.Name, 1, itemData.Slot, itemData
					.invType)
			end
		end)
	end)

	exports.ox_inventory:RegisterUse("fakeplates", "Vehicles", function(source, itemData)
		local currentMeta = itemData.MetaData or {}
		if not currentMeta.Plate then -- Data needs generating
			local updatingMetaData = {}

			updatingMetaData.Plate = Vehicles.Identification.Plate:Generate(true)
			updatingMetaData.VIN = Vehicles.Identification.VIN:GenerateLocal() -- Might not be completely unique but odds are low and idc
			updatingMetaData.OwnerName = exports['sandbox-base']:GeneratorNameFirst() ..
				" " .. exports['sandbox-base']:GeneratorNameLast()
			updatingMetaData.SID = exports['sandbox-base']:SequenceGet("Character")
			updatingMetaData.Vehicle = exports['sandbox-vehicles']:RandomName()

			currentMeta = exports.ox_inventory:UpdateMetaData(itemData.id, updatingMetaData)
		end

		if not currentMeta.Vehicle then
			currentMeta.Vehicle = exports['sandbox-vehicles']:RandomName()

			exports.ox_inventory:UpdateMetaData(iitemData.id, {
				Vehicle = currentMeta.Vehicle
			})
		end

		if currentMeta then
			exports["sandbox-base"]:ClientCallback(source, "Vehicles:GetFakePlateAddingVehicle", {}, function(veh)
				if not veh then
					return
				end
				veh = NetworkGetEntityFromNetworkId(veh)
				if veh and DoesEntityExist(veh) then
					local vehState = Entity(veh).state
					if not vehState.VIN then
						return
					end

					local vehicle = exports['sandbox-vehicles']:OwnedGetActive(vehState.VIN)
					if not vehicle then
						return
					end
					if not vehicle:GetData("FakePlate") then
						vehicle:SetData("FakePlate", currentMeta.Plate)
						vehicle:SetData("FakePlateData", currentMeta)

						SetVehicleNumberPlateText(veh, currentMeta.Plate)
						vehState.FakePlate = currentMeta.Plate

						exports['sandbox-vehicles']:OwnedForceSave(vehState.VIN)

						exports.ox_inventory:RemoveSlot(itemData.Owner, itemData.Name, 1, itemData.Slot,
							itemData.invType)

						exports['sandbox-hud']:Notification(source, "success", "Fake Plate Installed")
					else
						exports['sandbox-hud']:Notification(source, "error",
							"A Fake Plate is Already Installed")
					end
				end
			end)
		end
	end)

	exports.ox_inventory:RegisterUse("carpolish", "Vehicles", function(source, itemData)
		UseCarPolish(source, itemData, 1)
	end)

	exports.ox_inventory:RegisterUse("carpolish_high", "Vehicles", function(source, itemData)
		UseCarPolish(source, itemData, 2)
	end)

	exports.ox_inventory:RegisterUse("carclean", "Vehicles", function(source, itemData)
		TriggerClientEvent("Vehicles:Client:CleaningKit", source)
	end)

	exports.ox_inventory:RegisterUse("purgecontroller", "Vehicles", function(source, itemData)
		UsePurgeColorController(source, itemData)
	end)

	exports.ox_inventory:RegisterUse("car_bomb", "Vehicles", function(source, itemData)
		exports["sandbox-base"]:ClientCallback(source, "Vehicles:UseCarBomb", {}, function(veh, reason, config)
			if not veh then
				if reason then
					exports['sandbox-hud']:Notification(source, "error", reason)
				end
				return
			end
			veh = NetworkGetEntityFromNetworkId(veh)
			if veh and DoesEntityExist(veh) then
				local char = exports['sandbox-characters']:FetchCharacterSource(source)
				if char then
					local vehState = Entity(veh).state
					if not vehState.VIN then
						return
					end

					if not vehState.CarBomb then
						vehState.CarBomb = {
							Speed = config.minSpeed,
							Removal = config.removalTime,
							ExplosionTicks = config.preExplosionTicks,
							InstalledBy = char:GetData("SID"),
						}

						exports.ox_inventory:RemoveSlot(itemData.Owner, itemData.Name, 1, itemData.Slot,
							itemData.invType)

						exports['sandbox-hud']:Notification(source, "success", "Car Bomb Installed")
					else
						exports['sandbox-hud']:Notification(source, "error",
							"Vehicle Already Has Car Bomb")
					end
				else
					exports['sandbox-hud']:Notification(source, "error", "Error Installing Car Bomb")
				end
			end
		end)
	end)

	exports.ox_inventory:RegisterUse("harness", "Vehicles", function(source, itemData)
		exports["sandbox-base"]:ClientCallback(source, "Vehicles:InstallHarness", {}, function(veh)
			if not veh then
				return
			end
			veh = NetworkGetEntityFromNetworkId(veh)
			if veh and DoesEntityExist(veh) then
				local vehState = Entity(veh).state
				if not vehState.VIN then
					return
				end

				if exports.ox_inventory:RemoveSlot(itemData.Owner, itemData.Name, 1, itemData.Slot, itemData.invType) then
					vehState.Harness = 10
					exports['sandbox-hud']:Notification(source, "success", "Harness Installed")
				end
			end
		end)
	end)

	exports.ox_inventory:RegisterUse("nitrous", "Vehicles", function(source, itemData)
		if itemData?.MetaData?.Nitrous and itemData?.MetaData?.Nitrous > 0 then
			exports["sandbox-base"]:ClientCallback(source, "Vehicles:InstallNitrous", {}, function(veh)
				if not veh then
					return
				end
				veh = NetworkGetEntityFromNetworkId(veh)
				if veh and DoesEntityExist(veh) then
					local vehState = Entity(veh).state
					if not vehState.VIN then
						return
					end

					if exports.ox_inventory:RemoveId(itemData.Owner, itemData.invType, itemData) then
						vehState.Nitrous = itemData.MetaData.Nitrous + 0.0
						exports['sandbox-hud']:Notification(source, "success",
							"Nitrous Oxide Installed")
					end
				end
			end)
		else
			exports['sandbox-hud']:Notification(source, "error", "The Bottle is Empty!")
		end
	end)
end

RegisterNetEvent('ox_inventory:ready', function()
	if GetResourceState(GetCurrentResourceName()) == 'started' then
		RegisterItemUses()
	end
end)

local polishTypes = {
	{                          -- Normal Polish
		length = (60 * 60 * 24 * 7), -- Lasts for a week
		multiplier = 10.0,
	},
	{                           -- High Polish
		length = (60 * 60 * 24 * 14), -- Lasts for 2 weeks
		multiplier = 15.0,
	}
}

function UseCarPolish(source, itemData, type)
	local typeData = polishTypes[type]
	if not type then return end

	exports["sandbox-base"]:ClientCallback(source, "Vehicles:UseCarPolish", {}, function(veh)
		if not veh then
			return
		end
		veh = NetworkGetEntityFromNetworkId(veh)
		if veh and DoesEntityExist(veh) then
			local vehState = Entity(veh).state
			if not vehState.VIN then
				return
			end

			if (not vehState.Polish) or (vehState.Polish?.Type ~= type) or (vehState.Polish?.Time and (os.time() - vehState.Polish?.Time) >= (60 * 60 * 24)) then
				vehState.Polish = {
					Type = t,
					Expires = os.time() + typeData.length,
					Time = os.time(),
					Mult = typeData.multiplier,
				}

				exports.ox_inventory:RemoveSlot(itemData.Owner, itemData.Name, 1, itemData.Slot, itemData
					.invType)

				exports['sandbox-hud']:Notification(source, "success", "Polish Applied")
			else
				exports['sandbox-hud']:Notification(source, "error",
					"Vehicle Already Has That Polish and It Was Recently Installed")
			end
		end
	end)
end

function UsePurgeColorController(source, itemData)
	exports["sandbox-base"]:ClientCallback(source, "Vehicles:UsePurgeColorController", {}, function(veh)
		if not veh then
			return
		end
		veh = NetworkGetEntityFromNetworkId(veh)
		if veh and DoesEntityExist(veh) then
			local vehState = Entity(veh).state
			if not vehState.VIN then
				return
			end

			exports["sandbox-base"]:ClientCallback(source, "Vehicles:UsePurgeColorControllerMenu",
				{ purgeColor = vehState?.PurgeColor, purgeLocation = vehState?.PurgeLocation }, function(retval)
					if retval then
						if retval.purgeColor then
							vehState.PurgeColor = {
								r = retval.purgeColor.r,
								g = retval.purgeColor.g,
								b = retval.purgeColor.b,
							}
						end
						if retval.purgeLocation then
							vehState.PurgeLocation = retval.purgeLocation
						end
						exports['sandbox-hud']:Notification(source, "success", "Purge Changes Applied")
					else
						exports['sandbox-hud']:Notification(source, "error", "Changes were discarded")
					end
				end)
		end
	end)
end

RegisterNetEvent('Vehicles:Server:HarnessDamage', function()
	local src = source
	local veh = GetVehiclePedIsIn(GetPlayerPed(src), false)
	if DoesEntityExist(veh) then
		local vehState = Entity(veh)
		if vehState and vehState.state.VIN and vehState.state.Harness and vehState.state.Harness > 0 then
			vehState.state.Harness = vehState.state.Harness - 1
		end
	end
end)

RegisterNetEvent('Vehicles:Server:RemoveBomb', function(vNet)
	local veh = NetworkGetEntityFromNetworkId(vNet)
	if veh and DoesEntityExist(veh) then
		local vehState = Entity(veh)
		if vehState and vehState.state.VIN and vehState.state.CarBomb then
			vehState.state.CarBomb = false
		end
	end
end)

RegisterServerEvent('Vehicles:Server:NitrousUsage', function(vNet, used)
	local src = source
	local veh = NetworkGetEntityFromNetworkId(vNet)

	local ent = Entity(veh)
	if ent and ent.state and ent.state.Nitrous then
		ent.state.Nitrous = ent.state.Nitrous - used
		if ent.state.Nitrous < 0 then
			ent.state.Nitrous = 0.0
		end
	end
end)
