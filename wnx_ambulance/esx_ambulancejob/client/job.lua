local CurrentAction, CurrentActionMsg, CurrentActionData = nil, '', {}
local HasAlreadyEnteredMarker, LastHospital, LastPart, LastPartNum
local IsBusy = false
local spawnedVehicles, isInShopMenu = {}, false
local playerPed = PlayerPedId()
local blipsCops = {}

function OpenAmbulanceActionsMenu()
	local elements = {
		{label = _U('cloakroom'), value = 'cloakroom'}
	}

	if Config.EnablePlayerManagement and ESX.PlayerData.job.grade_name == 'boss' or Config.EnablePlayerManagement and ESX.PlayerData.job.grade_name == 'viceboss' then
		table.insert(elements, {label = _U('boss_actions'), value = 'boss_actions'})
	end

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'ambulance_actions', {
		title    = _U('ambulance'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		if data.current.value == 'cloakroom' then
			OpenCloakroomMenu()
		elseif data.current.value == 'boss_actions' then
			TriggerEvent('esx_society:openBossMenu', 'ambulance', function(data, menu)
				menu.close()
			end, {wash = false})
		end
	end, function(data, menu)
		menu.close()
	end)
end

function OpenMobileAmbulanceActionsMenu()

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mobile_ambulance_actions', {
		title    = _U('ambulance'),
		align    = 'top-left',
		elements = {
			{label = _U('ems_menu'), value = 'citizen_interaction'}
		}
	}, function(data, menu)
		if data.current.value == 'citizen_interaction' then
			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'citizen_interaction', {
				title    = _U('ems_menu_title'),
				align    = 'top-left',
				elements = {
					{label = _U('ems_menu_revive'), value = 'revive'},
					{label = _U('ems_menu_small'), value = 'big'},
					{label = ('📋 | Faktura'), value = 'fine'}
				}
			}, function(data, menu)
				if IsBusy then return end

				local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

				if closestPlayer == -1 or closestDistance > 1.0 then
					exports['dopeNotify']:Alert("EMS", "Žádní hráči v okolí", 5000, 'error')
    --exports['mythic_notify']:SendAlert('false', 'Žádní hráči v okolí')
				else

					if data.current.value == 'revive' then

						IsBusy = true

						ESX.TriggerServerCallback('esx_ambulancejob:getItemAmount', function(quantity)
							if quantity > 0 then
								local closestPlayerPed = GetPlayerPed(closestPlayer)

								if IsPedDeadOrDying(closestPlayerPed, 1) then
									local playerPed = PlayerPedId()

                                    exports['progressBars']:startUI(15000, "Oživuješ Civilistu")
									exports['system_notify']:Notify('msg', 'Probíhá oživení')

									local lib, anim = 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest'

									for i=1, 15, 1 do
										Citizen.Wait(900)
								
										ESX.Streaming.RequestAnimDict(lib, function()
											TaskPlayAnim(PlayerPedId(), lib, anim, 8.0, -8.0, -1, 0, 0, false, false, false)
										end)
									end

									TriggerServerEvent('esx_ambulancejob:removeItem', 'medikit')
									TriggerServerEvent('esx_ambulancejob:revive', GetPlayerServerId(closestPlayer))

									-- Show revive award?
									if Config.ReviveReward > 0 then
										exports['dopeNotify']:Alert("EMS", "Oživil si hráče", 5000, 'info')
    --exports['mythic_notify']:SendAlert('true', 'Oživil si hráče')
									else
										exports['dopeNotify']:Alert("EMS", "Byl si oživen!", 5000, 'error')
    --exports['mythic_notify']:SendAlert('msg', 'Byl si oživen!')
									end
								else
									exports['dopeNotify']:Alert("EMS", "Tento hráč není při vědomí", 5000, 'error')
									--exports['mythic_notify']:SendAlert('false', 'Tento hráč není při vědomí')
								end
							else
								exports['dopeNotify']:Alert("EMS", "Nemáš u sebe medikit", 5000, 'info')
								--exports['mythic_notify']:SendAlert('false', 'Nemáš u sebe medikit')
							end

							IsBusy = false

						end, 'medikit')

					elseif data.current.value == 'big' then

						ESX.TriggerServerCallback('esx_ambulancejob:getItemAmount', function(quantity)
							if quantity > 0 then
								local closestPlayerPed = GetPlayerPed(closestPlayer)
								local health = GetEntityHealth(closestPlayerPed)

								if health > 0 then
									local playerPed = PlayerPedId()

									IsBusy = true
									exports['progressBars']:startUI(10000, "Ošetřuješ Civilistu")
									exports['system_notify']:Notify('msg', 'Probíhá uzdravení')
									TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
									Citizen.Wait(10000)
									ClearPedTasks(playerPed)

									TriggerServerEvent('esx_ambulancejob:removeItem', 'medikit')
									TriggerServerEvent('esx_ambulancejob:heal', GetPlayerServerId(closestPlayer), 'big')
									exports['system_notify']:Notify('true', 'Uzdravil jsi hráče')
									IsBusy = false
								else
									exports['dopeNotify']:Alert("EMS", "Tento hráč není při vědomí", 5000, 'error')
									--exports['mythic_notify']:SendAlert('false', 'Tento hráč není při vědomí')
								end
							else
								exports['dopeNotify']:Alert("EMS", "Nemáš u sebe obvazy", 5000, 'error')
								--exports['mythic_notify']:SendAlert('false', 'Nemáš u sebe obvazy')
							end
						end, 'bandage')

					elseif data.current.value == 'fine' then
						OpenFineMenu(closestPlayer)
					end
				end
			end, function(data, menu)
				menu.close()
			end)
		end

	end, function(data, menu)
		menu.close()
	end)
end

function FastTravel(coords, heading)
	local playerPed = PlayerPedId()

	DoScreenFadeOut(800)

	while not IsScreenFadedOut() do
		Citizen.Wait(500)
	end

	ESX.Game.Teleport(playerPed, coords, function()
		DoScreenFadeIn(800)

		if heading then
			SetEntityHeading(playerPed, heading)
		end
	end)
end

-- Draw markers & Marker logic
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerCoords = GetEntityCoords(PlayerPedId())
		local letSleep, isInMarker, hasExited = true, false, false
		local currentHospital, currentPart, currentPartNum

		for hospitalNum,hospital in pairs(Config.Hospitals) do

			-- Ambulance Actions
			for k,v in ipairs(hospital.AmbulanceActions) do
				local distance = GetDistanceBetweenCoords(playerCoords, v, true)

				if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' and distance < Config.DrawDistance then
					DrawMarker(Config.Marker.type, v, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Marker.x, Config.Marker.y, Config.Marker.z, Config.Marker.r, Config.Marker.g, Config.Marker.b, Config.Marker.a, false, false, 2, Config.Marker.rotate, nil, nil, false)
					letSleep = false
				end

				if distance < Config.Marker.x then
					isInMarker, currentHospital, currentPart, currentPartNum = true, hospitalNum, 'AmbulanceActions', k
				end
			end

			-- Pharmacies
			for k,v in ipairs(hospital.Pharmacies) do
				local distance = GetDistanceBetweenCoords(playerCoords, v, true)

				if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' and distance < Config.DrawDistance then
					DrawMarker(Config.Marker2.type, v, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Marker.x, Config.Marker.y, Config.Marker.z, Config.Marker.r, Config.Marker.g, Config.Marker.b, Config.Marker.a, false, false, 2, Config.Marker.rotate, nil, nil, false)
					letSleep = false
				end

				if distance < Config.Marker.x then
					isInMarker, currentHospital, currentPart, currentPartNum = true, hospitalNum, 'Pharmacy', k
				end
			end

			-- Vehicle Spawners
			for k,v in ipairs(hospital.Vehicles) do
				local distance = GetDistanceBetweenCoords(playerCoords, v.Spawner, true)

				if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' and distance < Config.DrawDistance then
					DrawMarker(v.Marker.type, v.Spawner, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Marker.x, v.Marker.y, v.Marker.z, v.Marker.r, v.Marker.g, v.Marker.b, v.Marker.a, false, false, 2, v.Marker.rotate, nil, nil, false)
					letSleep = false
				end

				if distance < v.Marker.x then
					isInMarker, currentHospital, currentPart, currentPartNum = true, hospitalNum, 'Vehicles', k
				end
			end

			-- Helicopter Spawners
			for k,v in ipairs(hospital.Helicopters) do
				local distance = GetDistanceBetweenCoords(playerCoords, v.Spawner, true)

				if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' and distance < Config.DrawDistance then
					DrawMarker(v.Marker.type, v.Spawner, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Marker.x, v.Marker.y, v.Marker.z, v.Marker.r, v.Marker.g, v.Marker.b, v.Marker.a, false, false, 2, v.Marker.rotate, nil, nil, false)
					letSleep = false
				end

				if distance < v.Marker.x then
					isInMarker, currentHospital, currentPart, currentPartNum = true, hospitalNum, 'Helicopters', k
				end
			end

			-- Fast Travels
			for k,v in ipairs(hospital.FastTravels) do
				local distance = GetDistanceBetweenCoords(playerCoords, v.From, true)

				if distance < Config.DrawDistance then
					DrawMarker(v.Marker.type, v.From, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Marker.x, v.Marker.y, v.Marker.z, v.Marker.r, v.Marker.g, v.Marker.b, v.Marker.a, false, false, 2, v.Marker.rotate, nil, nil, false)
					letSleep = false
				end


				if distance < v.Marker.x then
					FastTravel(v.To.coords, v.To.heading)
				end
			end

		end

		-- Logic for exiting & entering markers
		if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (LastHospital ~= currentHospital or LastPart ~= currentPart or LastPartNum ~= currentPartNum)) then

			if
				(LastHospital ~= nil and LastPart ~= nil and LastPartNum ~= nil) and
				(LastHospital ~= currentHospital or LastPart ~= currentPart or LastPartNum ~= currentPartNum)
			then
				TriggerEvent('esx_ambulancejob:hasExitedMarker', LastHospital, LastPart, LastPartNum)
				hasExited = true
			end

			HasAlreadyEnteredMarker, LastHospital, LastPart, LastPartNum = true, currentHospital, currentPart, currentPartNum

			TriggerEvent('esx_ambulancejob:hasEnteredMarker', currentHospital, currentPart, currentPartNum)

		end

		if not hasExited and not isInMarker and HasAlreadyEnteredMarker then
			HasAlreadyEnteredMarker = false
			TriggerEvent('esx_ambulancejob:hasExitedMarker', LastHospital, LastPart, LastPartNum)
		end

		if letSleep then
			Citizen.Wait(500)
		end
	end
end)

AddEventHandler('esx_ambulancejob:hasEnteredMarker', function(hospital, part, partNum)
	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
		if part == 'AmbulanceActions' then
			CurrentAction = part
			CurrentActionMsg = _U('actions_prompt')
			CurrentActionData = {}
		elseif part == 'Pharmacy' then
			CurrentAction = part
			CurrentActionMsg = _U('open_pharmacy')
			CurrentActionData = {}
		elseif part == 'Vehicles' then
			CurrentAction = part
			CurrentActionMsg = _U('garage_prompt')
			CurrentActionData = {hospital = hospital, partNum = partNum}
		elseif part == 'Helicopters' then
			CurrentAction = part
			CurrentActionMsg = _U('helicopter_prompt')
			CurrentActionData = {hospital = hospital, partNum = partNum}
		end
	end
end)

AddEventHandler('esx_ambulancejob:hasExitedMarker', function(hospital, part, partNum)
	if not isInShopMenu then
		ESX.UI.Menu.CloseAll()
	end

	CurrentAction = nil
end)

-- Key Controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if CurrentAction then
			ESX.ShowHelpNotification(CurrentActionMsg)

			if IsControlJustReleased(0, Keys['E']) then

				if CurrentAction == 'AmbulanceActions' then
					OpenAmbulanceActionsMenu()
				elseif CurrentAction == 'Pharmacy' then
					OpenPharmacyMenu()
				elseif CurrentAction == 'Vehicles' then
					OpenVehicleSpawnerMenu(CurrentActionData.hospital, CurrentActionData.partNum)
				elseif CurrentAction == 'Helicopters' then
					OpenHelicopterSpawnerMenu(CurrentActionData.hospital, CurrentActionData.partNum)
				end

				CurrentAction = nil

			end

		elseif ESX.PlayerData.job ~= nil and ESX.PlayerData.job.name == 'ambulance' and not IsDead then
			if IsControlJustReleased(0, Keys['F6']) then
				OpenMobileAmbulanceActionsMenu()
			end
		else
			Citizen.Wait(500)
		end
	end
end)

RegisterNetEvent('esx_ambulancejob:putInVehicle')
AddEventHandler('esx_ambulancejob:putInVehicle', function()
	local playerPed = PlayerPedId()
	local coords    = GetEntityCoords(playerPed)

	if IsAnyVehicleNearPoint(coords, 5.0) then
		local vehicle = GetClosestVehicle(coords, 5.0, 0, 71)

		if DoesEntityExist(vehicle) then
			local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(vehicle)

			for i=maxSeats - 1, 0, -1 do
				if IsVehicleSeatFree(vehicle, i) then
					freeSeat = i
					break
				end
			end

			if freeSeat then
				TaskWarpPedIntoVehicle(playerPed, vehicle, freeSeat)
			end
		end
	end
end)

function OpenCloakroomMenu()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'cloakroom', {
		title    = _U('cloakroom'),
		align    = 'top-left',
		elements = {
			{label = _U('ems_clothes_civil'), value = 'citizen_wear'},
			{label = _U('ems_clothes_ems'), value = 'ambulance_wear'},
		}
	}, function(data, menu)
		if data.current.value == 'citizen_wear' then
			menu.close()
			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
				menu.close()
				local playerPed = PlayerPedId()
				exports['progressBars']:startUI(8000, "Převlékáš se do civilu")
				FreezeEntityPosition(playerPed, true)	
				Citizen.Wait(8000)
				FreezeEntityPosition(playerPed, false)
				exports["rp-radio"]:RemovePlayerAccessToFrequency(3)
				exports["rp-radio"]:RemovePlayerAccessToFrequency(4)
				exports["rp-radio"]:RemovePlayerAccessToFrequency(5)
				Radio:Toggle(not Radio.Open)
				TriggerEvent('skinchanger:loadSkin', skin)
			end)
		elseif data.current.value == 'ambulance_wear' then
			menu.close()
			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
				if skin.sex == 0 then
					menu.close()
					local playerPed = PlayerPedId()
					exports['progressBars']:startUI(8000, "Převlékáš se do uniformy")
					FreezeEntityPosition(playerPed, true)	
					Citizen.Wait(8000)
					FreezeEntityPosition(playerPed, false)
					exports["rp-radio"]:GivePlayerAccessToFrequency(3)
					exports["rp-radio"]:GivePlayerAccessToFrequency(4)
					exports["rp-radio"]:GivePlayerAccessToFrequency(5)	
					TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_male)
				else
					local playerPed = PlayerPedId()
					exports['progressBars']:startUI(8000, "Převlékáš se do uniformy")
					FreezeEntityPosition(playerPed, true)	
					Citizen.Wait(8000)
					FreezeEntityPosition(playerPed, false)
					exports["rp-radio"]:GivePlayerAccessToFrequency(3)
					exports["rp-radio"]:GivePlayerAccessToFrequency(4)
					exports["rp-radio"]:GivePlayerAccessToFrequency(5)	
					TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_female)
				end
			end)
		end

		menu.close()
	end, function(data, menu)
		menu.close()
	end)
end

function OpenVehicleSpawnerMenu(hospital, partNum)
	local playerCoords = GetEntityCoords(PlayerPedId())
	local elements = {
		{label = _U('garage_storeditem'), action = 'garage'},
		{label = _U('garage_storeitem'), action = 'store_garage'},
		{label = _U('garage_buyitem'), action = 'buy_vehicle'}
	}

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle', {
		title    = _U('garage_title'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)

		if data.current.action == 'buy_vehicle' then
			local shopCoords = Config.Hospitals[hospital].Vehicles[partNum].InsideShop
			local shopElements = {}

			local authorizedVehicles = Config.AuthorizedVehicles[ESX.PlayerData.job.grade_name]

			if #authorizedVehicles > 0 then
				for k,vehicle in ipairs(authorizedVehicles) do
					table.insert(shopElements, {
						label = ('%s - <span style="color:green;">%s</span>'):format(vehicle.label, _U('shop_item', ESX.Math.GroupDigits(vehicle.price))),
						name  = vehicle.label,
						model = vehicle.model,
						price = vehicle.price,
						type  = 'car'
					})
				end
			else
				return
			end

			OpenShopMenu(shopElements, playerCoords, shopCoords)
		elseif data.current.action == 'garage' then
			local garage = {}

			ESX.TriggerServerCallback('esx_vehicleshop:retrieveJobVehicles', function(jobVehicles)
				if #jobVehicles > 0 then
					for k,v in ipairs(jobVehicles) do
						local props = json.decode(v.vehicle)
						local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(props.model))
						local label = ('%s - <span style="color:darkgoldenrod;">%s</span>: '):format(vehicleName, props.plate)

						if v.stored then
							label = label .. ('<span style="color:green;">%s</span>'):format(_U('garage_stored'))
						else
							label = label .. ('<span style="color:darkred;">%s</span>'):format(_U('garage_notstored'))
						end

						table.insert(garage, {
							label = label,
							stored = v.stored,
							model = props.model,
							vehicleProps = props
						})
					end

					ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_garage', {
						title    = _U('garage_title'),
						align    = 'top-left',
						elements = garage
					}, function(data2, menu2)
						if data2.current.stored then
							local foundSpawn, spawnPoint = GetAvailableVehicleSpawnPoint(hospital, 'Vehicles', partNum)

							if foundSpawn then
								menu2.close()

								ESX.Game.SpawnVehicle(data2.current.model, spawnPoint.coords, spawnPoint.heading, function(vehicle)
									ESX.Game.SetVehicleProperties(vehicle, data2.current.vehicleProps)

									TriggerServerEvent('esx_vehicleshop:setJobVehicleState', data2.current.vehicleProps.plate, false)
									exports['dopeNotify']:Alert("EMS", "Tvé vozidlo bylo vyloženoi", 5000, 'success')
									--exports['mythic_notify']:SendAlert('true', 'Tvé vozidlo bylo vyloženoi')
								end)
							end
						else
							exports['dopeNotify']:Alert("EMS", "Tvé vozidlo není v garáži", 5000, 'error')
							--exports['mythic_notify']:SendAlert('false', 'Tvé vozidlo není v garáži')
						end
					end, function(data2, menu2)
						menu2.close()
					end)

				else
					exports['dopeNotify']:Alert("EMS", "Žádná vozidla v garáži", 5000, 'info')
    --exports['mythic_notify']:SendAlert('false', 'Žádná vozidla v garáži')
				end
			end, 'car')

		elseif data.current.action == 'store_garage' then
			StoreNearbyVehicle(playerCoords)
		end

	end, function(data, menu)
		menu.close()
	end)

end

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job

	Citizen.Wait(5000)
	TriggerServerEvent('esx_ambulancejob:forceBlip')
	
end)


function StoreNearbyVehicle(playerCoords)
	local vehicles, vehiclePlates = ESX.Game.GetVehiclesInArea(playerCoords, 30.0), {}

	if #vehicles > 0 then
		for k,v in ipairs(vehicles) do

			-- Make sure the vehicle we're saving is empty, or else it wont be deleted
			if GetVehicleNumberOfPassengers(v) == 0 and IsVehicleSeatFree(v, -1) then
				table.insert(vehiclePlates, {
					vehicle = v,
					plate = ESX.Math.Trim(GetVehicleNumberPlateText(v))
				})
			end
		end
	else
		exports['dopeNotify']:Alert("EMS", "V blízkosti nejsou žádná vozidla", 5000, 'error')
		--exports['mythic_notify']:SendAlert('false', 'V blízkosti nejsou žádná vozidla')
		return
	end

	ESX.TriggerServerCallback('esx_ambulancejob:storeNearbyVehicle', function(storeSuccess, foundNum)
		if storeSuccess then
			local vehicleId = vehiclePlates[foundNum]
			local attempts = 0
			ESX.Game.DeleteVehicle(vehicleId.vehicle)
			IsBusy = true

			Citizen.CreateThread(function()
				while IsBusy do
					Citizen.Wait(0)
					drawLoadingText(_U('garage_storing'), 255, 255, 255, 255)
				end
			end)

			-- Workaround for vehicle not deleting when other players are near it.
			while DoesEntityExist(vehicleId.vehicle) do
				Citizen.Wait(500)
				attempts = attempts + 1

				-- Give up
				if attempts > 30 then
					break
				end

				vehicles = ESX.Game.GetVehiclesInArea(playerCoords, 30.0)
				if #vehicles > 0 then
					for k,v in ipairs(vehicles) do
						if ESX.Math.Trim(GetVehicleNumberPlateText(v)) == vehicleId.plate then
							ESX.Game.DeleteVehicle(v)
							break
						end
					end
				end
			end

			IsBusy = false
			exports['dopeNotify']:Alert("EMS", "Vozidlo bylo uloženo do garáže", 5000, 'success')
			--exports['mythic_notify']:SendAlert('true', 'Vozidlo bylo uloženo do garáže')
		else
			exports['dopeNotify']:Alert("EMS", "V blízkosti nejsou žádná vozidla", 5000, 'info')
				--exports['mythic_notify']:SendAlert('false', 'V blízkosti nejsou žádná vozidla')
		end
	end, vehiclePlates)
end

function GetAvailableVehicleSpawnPoint(hospital, part, partNum)
	local spawnPoints = Config.Hospitals[hospital][part][partNum].SpawnPoints
	local found, foundSpawnPoint = false, nil

	for i=1, #spawnPoints, 1 do
		if ESX.Game.IsSpawnPointClear(spawnPoints[i].coords, spawnPoints[i].radius) then
			found, foundSpawnPoint = true, spawnPoints[i]
			break
		end
	end

	if found then
		return true, foundSpawnPoint
	else
		exports['dopeNotify']:Alert("EMS", "Garáž je blokována", 5000, 'error')
		--exports['mythic_notify']:SendAlert('false', 'Garáž je blokována')
		return false
	end
end

function OpenHelicopterSpawnerMenu(hospital, partNum)
	local playerCoords = GetEntityCoords(PlayerPedId())
	ESX.PlayerData = ESX.GetPlayerData()
	local elements = {
		{label = _U('helicopter_garage'), action = 'garage'},
		{label = _U('helicopter_store'), action = 'store_garage'},
		{label = _U('helicopter_buy'), action = 'buy_helicopter'}
	}

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'helicopter_spawner', {
		title    = _U('helicopter_title'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)

		if data.current.action == 'buy_helicopter' then
			local shopCoords = Config.Hospitals[hospital].Helicopters[partNum].InsideShop
			local shopElements = {}

			local authorizedHelicopters = Config.AuthorizedHelicopters[ESX.PlayerData.job.grade_name]

			if #authorizedHelicopters > 0 then
				for k,helicopter in ipairs(authorizedHelicopters) do
					table.insert(shopElements, {
						label = ('%s - <span style="color:green;">%s</span>'):format(helicopter.label, _U('shop_item', ESX.Math.GroupDigits(helicopter.price))),
						name  = helicopter.label,
						model = helicopter.model,
						price = helicopter.price,
						type  = 'helicopter'
					})
				end
			else
				exports['dopeNotify']:Alert("EMS", "Nemůžeš kupovat helikoptéry", 5000, 'error')
				--exports['mythic_notify']:SendAlert('false', 'Nemůžeš kupovat helikoptéry')
				return
			end

			OpenShopMenu(shopElements, playerCoords, shopCoords)
		elseif data.current.action == 'garage' then
			local garage = {}

			ESX.TriggerServerCallback('esx_vehicleshop:retrieveJobVehicles', function(jobVehicles)
				if #jobVehicles > 0 then
					for k,v in ipairs(jobVehicles) do
						local props = json.decode(v.vehicle)
						local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(props.model))
						local label = ('%s - <span style="color:darkgoldenrod;">%s</span>: '):format(vehicleName, props.plate)

						if v.stored then
							label = label .. ('<span style="color:green;">%s</span>'):format(_U('garage_stored'))
						else
							label = label .. ('<span style="color:darkred;">%s</span>'):format(_U('garage_notstored'))
						end

						table.insert(garage, {
							label = label,
							stored = v.stored,
							model = props.model,
							vehicleProps = props
						})
					end

					ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'helicopter_garage', {
						title    = _U('helicopter_garage_title'),
						align    = 'top-left',
						elements = garage
					}, function(data2, menu2)
						if data2.current.stored then
							local foundSpawn, spawnPoint = GetAvailableVehicleSpawnPoint(hospital, 'Helicopters', partNum)

							if foundSpawn then
								menu2.close()

								ESX.Game.SpawnVehicle(data2.current.model, spawnPoint.coords, spawnPoint.heading, function(vehicle)
									ESX.Game.SetVehicleProperties(vehicle, data2.current.vehicleProps)

									TriggerServerEvent('esx_vehicleshop:setJobVehicleState', data2.current.vehicleProps.plate, false)
									exports['dopeNotify']:Alert("EMS", "Tvá helikoptéra byla vyložena", 5000, 'success')
									--exports['mythic_notify']:SendAlert('true', 'Tvá helikoptéra byla vyložena')
								end)
							end
						else
							exports['dopeNotify']:Alert("EMS", "Tvá helikoptéra není v hangara", 5000, 'info')
							--exports['mythic_notify']:SendAlert('true', 'Tvá helikoptéra není v hangar')
						end
					end, function(data2, menu2)
						menu2.close()
					end)

				else
					exports['dopeNotify']:Alert("EMS", "Hangar je prázdný", 5000, 'info')
					--exports['mythic_notify']:SendAlert('false', 'Hangar je prázdný')
				end
			end, 'helicopter')

		elseif data.current.action == 'store_garage' then
			StoreNearbyVehicle(playerCoords)
		end

	end, function(data, menu)
		menu.close()
	end)

end

function OpenShopMenu(elements, restoreCoords, shopCoords)
	local playerPed = PlayerPedId()
	isInShopMenu = true

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_shop', {
		title    = _U('vehicleshop_title'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_shop_confirm', {
			title    = _U('vehicleshop_confirm', data.current.name, data.current.price),
			align    = 'top-left',
			elements = {
				{ label = _U('confirm_no'), value = 'no' },
				{ label = _U('confirm_yes'), value = 'yes' }
			}
		}, function(data2, menu2)

			if data2.current.value == 'yes' then
				local newPlate = exports['esx_vehicleshop']:GeneratePlate()
				local vehicle  = GetVehiclePedIsIn(playerPed, false)
				local props    = ESX.Game.GetVehicleProperties(vehicle)
				props.plate    = newPlate

				ESX.TriggerServerCallback('esx_ambulancejob:buyJobVehicle', function (bought)
					if bought then
						exports['dopeNotify']:Alert("EMS", "Zakoupil jsi vozidlo", 5000, 'info')
						--exports['mythic_notify']:SendAlert('true', 'Zakoupil jsi vozidlo')

						isInShopMenu = false
						ESX.UI.Menu.CloseAll()
				
						DeleteSpawnedVehicles()
						FreezeEntityPosition(playerPed, false)
						SetEntityVisible(playerPed, true)
				
						ESX.Game.Teleport(playerPed, restoreCoords)
					else
						exports['dopeNotify']:Alert("EMS", "Toto vozidlo si nemůžeš dovolit", 5000, 'error')
						--exports['mythic_notify']:SendAlert('false', 'Toto vozidlo si nemůžeš dovolit')
						menu2.close()
					end
				end, props, data.current.type)
			else
				menu2.close()
			end

		end, function(data2, menu2)
			menu2.close()
		end)

		end, function(data, menu)
		isInShopMenu = false
		ESX.UI.Menu.CloseAll()

		DeleteSpawnedVehicles()
		FreezeEntityPosition(playerPed, false)
		SetEntityVisible(playerPed, true)

		ESX.Game.Teleport(playerPed, restoreCoords)
	end, function(data, menu)
		DeleteSpawnedVehicles()

		WaitForVehicleToLoad(data.current.model)
		ESX.Game.SpawnLocalVehicle(data.current.model, shopCoords, 0.0, function(vehicle)
			table.insert(spawnedVehicles, vehicle)
			TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
			FreezeEntityPosition(vehicle, true)
		end)
	end)

	WaitForVehicleToLoad(elements[1].model)
	ESX.Game.SpawnLocalVehicle(elements[1].model, shopCoords, 0.0, function(vehicle)
		table.insert(spawnedVehicles, vehicle)
		TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
		FreezeEntityPosition(vehicle, true)
	end)
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if isInShopMenu then
			DisableControlAction(0, 75, true)  -- Disable exit vehicle
			DisableControlAction(27, 75, true) -- Disable exit vehicle
		else
			Citizen.Wait(500)
		end
	end
end)

function DeleteSpawnedVehicles()
	while #spawnedVehicles > 0 do
		local vehicle = spawnedVehicles[1]
		ESX.Game.DeleteVehicle(vehicle)
		table.remove(spawnedVehicles, 1)
	end
end

function WaitForVehicleToLoad(modelHash)
	modelHash = (type(modelHash) == 'number' and modelHash or GetHashKey(modelHash))

	if not HasModelLoaded(modelHash) then
		RequestModel(modelHash)

		while not HasModelLoaded(modelHash) do
			Citizen.Wait(0)

			DisableControlAction(0, Keys['TOP'], true)
			DisableControlAction(0, Keys['DOWN'], true)
			DisableControlAction(0, Keys['LEFT'], true)
			DisableControlAction(0, Keys['RIGHT'], true)
			DisableControlAction(0, 176, true) -- ENTER key
			DisableControlAction(0, Keys['BACKSPACE'], true)

			drawLoadingText(_U('vehicleshop_awaiting_model'), 255, 255, 255, 255)
		end
	end
end

function drawLoadingText(text, red, green, blue, alpha)
	SetTextFont(4)
	SetTextScale(0.0, 0.5)
	SetTextColour(red, green, blue, alpha)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextCentre(true)

	BeginTextCommandDisplayText("STRING")
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(0.5, 0.5)
end

function OpenPharmacyMenu()
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'pharmacy', {
		title    = _U('pharmacy_menu_title'),
		align    = 'top-left',
		elements = {
			{label = _U('pharmacy_take', _U('medikit')), value = 'medikit'},
			{label = _U('pharmacy_take', _U('bandage')), value = 'bandage'}
		}
	}, function(data, menu)
		if data.current.value == 'medikit' then
			menu.close()
			local playerPed = PlayerPedId()
			exports['progressBars']:startUI(3000, "Bereš si medikity")
			FreezeEntityPosition(playerPed, true)	
			Citizen.Wait(3000)
			FreezeEntityPosition(playerPed, false)
			TriggerServerEvent('esx_ambulancejob:giveItem', data.current.value)
		elseif data.current.value == 'bandage' then
			menu.close()
			local playerPed = PlayerPedId()
			exports['progressBars']:startUI(3000, "Bereš si obvazy")
			FreezeEntityPosition(playerPed, true)	
			Citizen.Wait(3000)
			FreezeEntityPosition(playerPed, false)
			TriggerServerEvent('esx_ambulancejob:giveItem', data.current.value)
		end
	end, function(data, menu)
		menu.close()
	end)
end

-- Create blip for colleagues
function createBlip(id)
	local ped = GetPlayerPed(id)
	local blip = GetBlipFromEntity(ped)

	if not DoesBlipExist(blip) then -- Add blip and create head display on player
		blip = AddBlipForEntity(ped)
		SetBlipSprite(blip, 61)
		ShowHeadingIndicatorOnBlip(blip, true) -- Player Blip indicator
		SetBlipRotation(blip, math.ceil(GetEntityHeading(ped))) -- update rotation
		SetBlipNameToPlayerName(blip, id) -- update blip name
		SetBlipScale(blip, 0.7) -- set scale
		SetBlipAsShortRange(blip, true)
		SetBlipColour(blip, 2)

		table.insert(blipsCops, blip) -- add blip to array so we can remove it later
	end
end

RegisterNetEvent('esx_ambulancejob:updateBlip')
AddEventHandler('esx_ambulancejob:updateBlip', function()

	-- Refresh all blips
	for k, existingBlip in pairs(blipsCops) do
		RemoveBlip(existingBlip)
	end

	-- Clean the blip table
	blipsCops = {}

	-- Is the player a cop? In that case show all the blips for other cops
	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
		ESX.TriggerServerCallback('esx_society:getOnlinePlayers', function(players)
			for i=1, #players, 1 do
				if players[i].job.name == 'ambulance' then
					local id = GetPlayerFromServerId(players[i].source)
					if NetworkIsPlayerActive(id) and GetPlayerPed(id) ~= PlayerPedId() then
						createBlip(id)
					end
				end
			end
		end)
	end

end)

function WarpPedInClosestVehicle(ped)
	local coords = GetEntityCoords(ped)

	local vehicle, distance = ESX.Game.GetClosestVehicle(coords)

	if distance ~= -1 and distance <= 5.0 then
		local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(vehicle)

		for i=maxSeats - 1, 0, -1 do
			if IsVehicleSeatFree(vehicle, i) then
				freeSeat = i
				break
			end
		end

		if freeSeat then
			TaskWarpPedIntoVehicle(ped, vehicle, freeSeat)
		end
	else
		exports['dopeNotify']:Alert("EMS", "Žádná vozidla v okolí", 5000, 'info')
		--exports['mythic_notify']:SendAlert('false', 'Žádná vozidla v okolí')
	end
end

RegisterNetEvent('esx_ambulancejob:heal')
AddEventHandler('esx_ambulancejob:heal', function(healType, quiet)
	local playerPed = PlayerPedId()
	local maxHealth = GetEntityMaxHealth(playerPed)

	if healType == 'big' then
		SetEntityHealth(playerPed, maxHealth)
	end

	if not quiet then
		exports['dopeNotify']:Alert("EMS", "Byl jsi vyléčen", 5000, 'info')
		--exports['mythic_notify']:SendAlert('msg', 'Byl jsi vyléčen')
	end
end)

function OpenFineMenu(player)
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'fine', {
		title    = ('📋Faktura📋'),
		align    = 'top-left',
		elements = {
			{label = ('🚑 | Výjezdy'), value = 0},
			{label = ('❤️ | Lékařská Pomoc'),   value = 1},
			{label = ('🖤 | Doktorská Pomoc'), value = 2},
			{label = ('📜 | Pojištění'), value = 3},
			{label = ('📋 | Pokuty'), value = 4}
	}}, function(data, menu)
		OpenFineCategoryMenu(player, data.current.value)
	end, function(data, menu)
		menu.close()
	end)
end

function OpenFineCategoryMenu(player, category)
	ESX.TriggerServerCallback('esx_ambulancejob:getFineList', function(fines)
		local elements = {}

		for k,fine in ipairs(fines) do
			table.insert(elements, {
				label     = ('%s <span style="color:green;">%s</span>'):format(fine.label, _U('armory_item', ESX.Math.GroupDigits(fine.amount))),
				value     = fine.id,
				amount    = fine.amount,
				fineLabel = fine.label
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'fine_category', {
			title    = _U('fine_1'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			menu.close()

			if Config.EnablePlayerManagement then
				TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(player), 'society_ambulance', _U('fine_total', data.current.fineLabel), data.current.amount)
			else
				TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(player), 'society_ambulance', _U('fine_total', data.current.fineLabel), data.current.amount)
			end

			ESX.SetTimeout(300, function()
				OpenFineCategoryMenu(player, category)
			end)
		end, function(data, menu)
			menu.close()
		end)
	end, category)
end