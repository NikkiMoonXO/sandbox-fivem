local threading = false
local bankAcc = nil
local depositData = {
	amount = 0,
	transactions = 0,
}

AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		Wait(1000)
		RegisterCallbacks()

		if not threading then
			CreateThread(function()
				while true do
					Wait(1000 * 60 * 10)
					if depositData.amount > 0 then
						exports['sandbox-base']:LoggerTrace(
							"Fuel",
							string.format("Depositing ^2$%s^7 To ^3%s^7", math.abs(depositData.amount), bankAcc)
						)
						exports['sandbox-finance']:BalanceDeposit(bankAcc, math.abs(depositData.amount), {
							type = "deposit",
							title = "Fuel Services",
							description = string.format(
								"Payment For Fuel Services For %s Vehicles",
								depositData.transactions
							),
							data = {},
						}, true)
						depositData = {
							amount = 0,
							transactions = 0,
						}
					end
				end
			end)
			threading = true
		end

		Wait(2000)
		local f = exports['sandbox-finance']:AccountsGetOrganization("dgang")
		if f ~= true then
			bankAcc = f.Account
		end
	end
end)

function RegisterCallbacks()
	exports["sandbox-base"]:RegisterServerCallback("Fuel:CheckBank", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char and data?.cost then
			cb(exports['sandbox-finance']:BalanceHas(char:GetData("BankAccount"), data.cost))
		else
			cb(false)
		end
	end)

	exports["sandbox-base"]:RegisterServerCallback("Fuel:CompleteFueling", function(source, data, cb)
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char and data and data.vehNet and type(data.vehClass) == "number" and type(data.fuelAmount) == "number" then
			local veh = NetworkGetEntityFromNetworkId(data.vehNet)
			if veh and DoesEntityExist(veh) then
				local vehState = Entity(veh)
				local totalCost = CalculateFuelCost(data.vehClass, data.fuelAmount)

				if vehState and vehState.state and totalCost then
					local paymentSuccess = false
					if data.useBank then
						paymentSuccess = exports['sandbox-finance']:BalanceCharge(char:GetData("BankAccount"),
							math.abs(totalCost), {
								type = 'bill',
								title = 'Fuel Purchase',
								description = 'Fuel Purchase',
								data = {
									vehicle = vehState.state.VIN,
									fuel = data.fuelAmount,
								}
							})

						if paymentSuccess then
							exports['sandbox-phone']:NotificationAdd(source,
								string.format("Fuel Purchase of $%s Successful", math.ceil(totalCost)), false, os.time(),
								3000, "bank", {})
						end
					else
						paymentSuccess = exports['sandbox-finance']:WalletModify(source, -math.abs(totalCost), true)
					end

					if paymentSuccess then
						-- TODO: Incorporate the shop bank accounts where possible so money
						-- is sent to those accounts instead of a static one
						depositData.amount += math.abs(totalCost)
						depositData.transactions += 1

						vehState.state.Fuel = math.min(math.ceil(vehState.state.Fuel + data.fuelAmount), 100)
						cb(true, totalCost)
						return
					end
				end
			end
		end
		cb(false)
	end)

	exports["sandbox-base"]:RegisterServerCallback("Fuel:CompleteJerryFueling", function(source, data, cb)
	    local char = exports['sandbox-characters']:FetchCharacterSource(source)
	    if char and data and data.vehNet and type(data.newAmount) == "number" and data.fuelUsed and type(data.fuelUsed) == "number" then
	        local veh = NetworkGetEntityFromNetworkId(data.vehNet)
	        if veh and DoesEntityExist(veh) then
	            local vehState = Entity(veh)
	            if vehState and vehState.state then
	                local jerryCan = exports.ox_inventory:GetSlotWithItem(source, 'weapon_petrolcan')
	                if jerryCan then
	                    local currentAmmo = jerryCan.metadata and jerryCan.metadata.ammo or 0
	                    local currentDurability = jerryCan.metadata and jerryCan.metadata.durability or 0
	                    local degrade = jerryCan.metadata and jerryCan.metadata.degrade or 0

	                    local newAmmo = math.max(0, currentAmmo - data.fuelUsed)

	                    if newAmmo > 0 then
	                        local newMetadata = {
	                            ammo = newAmmo,
	                            durability = currentDurability,
	                            degrade = degrade
	                        }
	                        exports.ox_inventory:SetMetadata(source, jerryCan.slot, newMetadata)
	                    else
	                        exports.ox_inventory:RemoveItem(source, 'weapon_petrolcan', 1, jerryCan.metadata, jerryCan.slot)
	                    end

	                    vehState.state.Fuel = math.min(data.newAmount, 100)
	                    cb(true)
	                    return
	                end
	            end
	        end
	    end
	    cb(false)
	end)

	exports["sandbox-base"]:RegisterServerCallback("Fuel:FillCan", function(source, data, cb)
		local totalCost = CalculateFuelCost(0, math.floor(100 - (data.pct * 100)))
		cb(totalCost and exports['sandbox-finance']:WalletModify(source, -math.abs(totalCost), true))
	end)
end
