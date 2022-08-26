QBCore = exports['qb-core']:GetCoreObject() -- Used Globally
inJail = false
jailTime = 0
currentJob = nil --"electrician" old code
CellsBlip = nil
TimeBlip = nil
ShopBlip = nil
WorkBlip = nil
PlayerJob = {}

local canteenTarget = false
local prisontimeTarget = false
local slushyTarget = false
local sodaTarget = false
local coffeeTarget = false
local prisoncraftingTarget = false

local inRange = false

local function GetJailTime()
	if Config.QB_PrisonJobs then
		return jailTime
	end
end
exports('GetJailTime', GetJailTime)

local function CreateCellsBlip()
	if CellsBlip ~= nil then
		RemoveBlip(CellsBlip)
	end

	CellsBlip = AddBlipForCoord(Config.Locations["yard"].coords.x, Config.Locations["yard"].coords.y, Config.Locations["yard"].coords.z)

	SetBlipSprite (CellsBlip, 238)
	SetBlipDisplay(CellsBlip, 4)
	SetBlipScale  (CellsBlip, 0.8)
	SetBlipAsShortRange(CellsBlip, true)
	SetBlipColour(CellsBlip, 4)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentSubstringPlayerName("Cells")
	EndTextCommandSetBlipName(CellsBlip)

	if TimeBlip ~= nil then
		RemoveBlip(TimeBlip)
	end
	TimeBlip = AddBlipForCoord(Config.Locations["freedom"].coords.x, Config.Locations["freedom"].coords.y, Config.Locations["freedom"].coords.z)

	SetBlipSprite (TimeBlip, 466)
	SetBlipDisplay(TimeBlip, 4)
	SetBlipScale  (TimeBlip, 0.8)
	SetBlipAsShortRange(TimeBlip, true)
	SetBlipColour(TimeBlip, 4)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentSubstringPlayerName("Time check")
	EndTextCommandSetBlipName(TimeBlip)

	if ShopBlip ~= nil then
		RemoveBlip(ShopBlip)
	end
	ShopBlip = AddBlipForCoord(Config.Locations["shop"].coords.x, Config.Locations["shop"].coords.y, Config.Locations["shop"].coords.z)

	SetBlipSprite (ShopBlip, 52)
	SetBlipDisplay(ShopBlip, 4)
	SetBlipScale  (ShopBlip, 0.5)
	SetBlipAsShortRange(ShopBlip, true)
	SetBlipColour(ShopBlip, 0)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentSubstringPlayerName("Canteen")
	EndTextCommandSetBlipName(ShopBlip)

	if WorkBlip ~= nil then
		RemoveBlip(WorkBlip)
	end
	WorkBlip = AddBlipForCoord(Config.Locations["work"].coords.x, Config.Locations["work"].coords.y, Config.Locations["work"].coords.z)

	SetBlipSprite (WorkBlip, 440)
	SetBlipDisplay(WorkBlip, 4)
	SetBlipScale  (WorkBlip, 0.5)
	SetBlipAsShortRange(WorkBlip, true)
	SetBlipColour(WorkBlip, 0)

	BeginTextCommandSetBlipName("STRING")
	AddTextComponentSubstringPlayerName("Prison Work")
	EndTextCommandSetBlipName(WorkBlip)
end

--------------------------------
-- CREATE / DESTROY ALL ZONES --
--------------------------------

local function CreateAllTargets()
	if not canteenTarget and not prisontimeTarget and not slushyTarget and not coffeeTarget and not sodaTarget then
    	TriggerEvent('qb-prison:PrisonTimeTarget')
    	TriggerEvent('qb-prison:CanteenTarget')
    	TriggerEvent('qb-prison:SlushyTarget')
		TriggerEvent('qb-prison:SodaTarget')
		TriggerEvent('qb-prison:CoffeeTarget')
		if Config.Crafting then
			TriggerEvent('qb-prison:PrisonCraftingTarget')
		end
	end

    if Config.Debug then
        print('All Zones Created')
    end
end

local function DestroyAllTargets()
	if canteenTarget and prisontimeTarget and slushyTarget and sodaTarget and coffeeTarget then
    	exports['qb-target']:RemoveZone("prisontime")
    	exports['qb-target']:RemoveZone("prisoncanteen")
    	exports['qb-target']:RemoveZone("prisonslushy")
		exports['qb-target']:RemoveZone("prisoncoffee")
		exports['qb-target']:RemoveZone("prisonsoda")
		if Config.Crafting then
			exports['qb-target']:RemoveZone("prisoncrafting")
		end

		canteenTarget = false
		prisontimeTarget = false
		slushyTarget = false
		sodaTarget = false
		coffeeTarget = false
	end

    if Config.Debug then
        print('All Zones Destroyed')
    end
end

----------------------------------
-- RESOURCE START / PLAYER LOAD --
----------------------------------

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
	QBCore.Functions.GetPlayerData(function(PlayerData)
		if PlayerData.metadata["injail"] > 0 then
			TriggerEvent("prison:client:Enter", PlayerData.metadata["injail"])
		end
	end)

	QBCore.Functions.TriggerCallback('prison:server:IsAlarmActive', function(active)
		if active then
			TriggerEvent('prison:client:JailAlarm', true)
		end
	end)

	PlayerJob = QBCore.Functions.GetPlayerData().job
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
	Wait(100)
	if LocalPlayer.state['isLoggedIn'] then
		QBCore.Functions.GetPlayerData(function(PlayerData)
			if PlayerData.metadata["injail"] > 0 then
				TriggerEvent("prison:client:Enter", PlayerData.metadata["injail"])
			end
		end)
	end

	QBCore.Functions.TriggerCallback('prison:server:IsAlarmActive', function(active)
		if not active then return end
		TriggerEvent('prison:client:JailAlarm', true)
	end)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

-----------------------------------
-- RESOURCE STOP / PLAYER UNLOAD --
-----------------------------------

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
	inJail = false
	currentJob = nil
	RemoveBlip(currentBlip)
	DestroyAllTargets()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
		DestroyAllTargets()
    end
end)

RegisterNetEvent('prison:client:Enter', function(time)
	QBCore.Functions.Notify( Lang:t("error.injail", {Time = time}), "error")

	TriggerEvent("chatMessage", "SYSTEM", "warning", "Your property has been seized, you'll get everything back when your time is up..")
	DoScreenFadeOut(500)
	while not IsScreenFadedOut() do
		Wait(10)
	end
	local RandomStartPosition = Config.Locations.spawns[math.random(1, #Config.Locations.spawns)]
	SetEntityCoords(PlayerPedId(), RandomStartPosition.coords.x, RandomStartPosition.coords.y, RandomStartPosition.coords.z - 0.9, 0, 0, 0, false)
	SetEntityHeading(PlayerPedId(), RandomStartPosition.coords.w)
	Wait(500)
	TriggerEvent('animations:client:EmoteCommandStart', {RandomStartPosition.animation})

	inJail = true
	jailTime = time

	-- Code to Select Random Job
	local randomJobIndex = math.random(1, #Config.PrisonJobs) -- Chooses Random Job
   	local RandomJobSelection = Config.PrisonJobs[randomJobIndex].name
	currentJob = RandomJobSelection -- "electrician" old code

	TriggerServerEvent("prison:server:SetJailStatus", jailTime)
	TriggerServerEvent("prison:server:SaveJailItems", jailTime)
	TriggerServerEvent("InteractSound_SV:PlayOnSource", "jail", 0.5)
	GetJailTime()
	CreateCellsBlip()
	CreateAllTargets()
	Wait(2000)
	DoScreenFadeIn(1000)
	QBCore.Functions.Notify( Lang:t("error.do_some_work", {currentjob = Config.PrisonJobs[randomJobIndex].label}), "error")
end)

RegisterNetEvent('prison:client:Leave', function()
	if jailTime > 0 then
		QBCore.Functions.Notify( Lang:t("info.timeleft", {JAILTIME = jailTime}))
	else
		jailTime = 0
		TriggerServerEvent("prison:server:SetJailStatus", 0)
		TriggerServerEvent("prison:server:GiveJailItems")
		TriggerEvent("chatMessage", "SYSTEM", "warning", "you've received your property back..")
		inJail = false
		RemoveBlip(currentBlip)
		RemoveBlip(CellsBlip)
		CellsBlip = nil
		RemoveBlip(TimeBlip)
		TimeBlip = nil
		RemoveBlip(ShopBlip)
		ShopBlip = nil
		RemoveBlip(WorkBlip)
		WorkBlip = nil
		currentJob = nil --"electrician" old code
		QBCore.Functions.Notify(Lang:t("success.free_"))
		DoScreenFadeOut(500)
		while not IsScreenFadedOut() do
			Wait(10)
		end
		SetEntityCoords(PlayerPedId(), Config.Locations["outside"].coords.x, Config.Locations["outside"].coords.y, Config.Locations["outside"].coords.z, 0, 0, 0, false)
		SetEntityHeading(PlayerPedId(), Config.Locations["outside"].coords.w)
		DestroyAllTargets()

		Wait(500)

		DoScreenFadeIn(1000)
	end
end)

RegisterNetEvent('prison:client:UnjailPerson', function()
	if jailTime > 0 then
		TriggerServerEvent("prison:server:SetJailStatus", 0)
		TriggerServerEvent("prison:server:GiveJailItems")
		TriggerEvent("chatMessage", "SYSTEM", "warning", "You got your property back..")
		inJail = false
		RemoveBlip(currentBlip)
		RemoveBlip(CellsBlip)
		CellsBlip = nil
		RemoveBlip(TimeBlip)
		TimeBlip = nil
		RemoveBlip(ShopBlip)
		ShopBlip = nil
		RemoveBlip(WorkBlip)
		WorkBlip = nil
		QBCore.Functions.Notify(Lang:t("success.free_"))
		DoScreenFadeOut(500)
		while not IsScreenFadedOut() do
			Wait(10)
		end
		SetEntityCoords(PlayerPedId(), Config.Locations["outside"].coords.x, Config.Locations["outside"].coords.y, Config.Locations["outside"].coords.z, 0, 0, 0, false)
		SetEntityHeading(PlayerPedId(), Config.Locations["outside"].coords.w)
		Wait(500)
		DoScreenFadeIn(1000)
	end
end)

---------------------------------------------------
-- 		   PRISON JOBS 			 --
-- Fix Electrical, Cook, or Sweep to Reduce Time --
---------------------------------------------------

-- Job Menu
RegisterNetEvent('qb-prison:client:jobMenu', function()
    if inJail then

		pjobMenu = {
			{
				isHeader = true,
				header = 'Prison Work'
			},
			{
				header = "Electrician",
				txt = "Fix Electrical Boxes",
				params = {
					isServer = false,
					event = "qb-prison:jobapplyElectrician",
				}
			},
			{
				header = "Cook",
				txt = "Cook Food",
				params = {
					isServer = false,
					event = "qb-prison:jobapplyCook",
				}
			},
			{
				header = "Janitor",
				txt = "Clean Common Area",
				params = {
					isServer = false,
					event = "qb-prison:jobapplyJanitor",
				}
			},
			{
				header = "Close Menu",
				txt = "Close Menu",
				params = {
					isServer = false,
					event = exports['qb-menu']:closeMenu(),
				}
			},
		}

        exports['qb-menu']:openMenu(pjobMenu)

		if Config.Debug then
        	print("Job Menu: Opened")
		end

    else
        QBCore.Functions.Notify("You are not an Inmate", "error", 3500)
    end
end)

----------------
-- JOB EVENTS --
----------------

RegisterNetEvent('qb-prison:jobapplyElectrician', function(args)
	local pos = GetEntityCoords(PlayerPedId())
	inRange = false

	local dist = #(pos - vector3(Config.CheckTimeLocation.x, Config.CheckTimeLocation.y, Config.CheckTimeLocation.z))

    if dist < 2 then
		inRange = true
        if inJail then
			if currentJob ~= "electrician" then
				currentJob = "electrician" --"electrician" old code
				CreatePrisonBlip()
				QBCore.Functions.Notify('New Job: Electrician')

				if Config.Debug then
					print("Job: Electrician")
				end
			else
				QBCore.Functions.Notify('You already have the electrician job!')
			end
		else
			QBCore.Functions.Notify('Job Not Available')
			TriggerEvent('qb-prison:client:jobMenu')
		end
	else
		QBCore.Functions.Notify('Not Close Enough To Pay Phone')
	end

	if not inRange then
		Wait(1000)
	end
end)

RegisterNetEvent('qb-prison:jobapplyCook', function(args)
	local pos = GetEntityCoords(PlayerPedId())
	inRange = false

	local dist = #(pos - vector3(Config.CheckTimeLocation.x, Config.CheckTimeLocation.y, Config.CheckTimeLocation.z))

    if dist < 2 then
		inRange = true
        if inJail then
			if currentJob ~= "cook" then
				currentJob = "cook" --"electrician" old code
				CreatePrisonBlip()
				QBCore.Functions.Notify('New Job: Cook')

				if Config.Debug then
					print("Job: Cook")
				end
			else
				QBCore.Functions.Notify('You already have the cooking job!')
			end
		else
			QBCore.Functions.Notify('Job Not Available')
			TriggerEvent('qb-prison:client:jobMenu')
		end
	else
		QBCore.Functions.Notify('Not Close Enough To Pay Phone')
	end

	if not inRange then
		Wait(1000)
	end
end)

RegisterNetEvent('qb-prison:jobapplyJanitor', function(args)
	local pos = GetEntityCoords(PlayerPedId())
	inRange = false

	local dist = #(pos - vector3(Config.CheckTimeLocation.x, Config.CheckTimeLocation.y, Config.CheckTimeLocation.z))

    if dist < 2 then
		inRange = true
        if inJail then
			if currentJob ~= "janitor" then
				currentJob = "janitor" --"electrician" old code
				CreatePrisonBlip()
				QBCore.Functions.Notify('New Job: Janitor')

				if Config.Debug then
					print("Job: Janitor")
				end
			else
				QBCore.Functions.Notify('You already have the janitor job!')
			end
		else
			QBCore.Functions.Notify('Job Not Available')
			TriggerEvent('qb-prison:client:jobMenu')
		end
	else
		QBCore.Functions.Notify('Not Close Enough To Pay Phone')
	end

	if not inRange then
		Wait(1000)
	end
end)

-------------------
-- OTHER EVENTS --
-------------------

-- Check Time
RegisterNetEvent('qb-prison:client:checkTime', function()
	if LocalPlayer.state.isLoggedIn then
		if inJail then
			local pos = GetEntityCoords(PlayerPedId())
			if #(pos - vector3(Config.Locations["freedom"].coords.x, Config.Locations["freedom"].coords.y, Config.Locations["freedom"].coords.z)) < 1.5 then
				TriggerEvent("prison:client:Leave")
			end
		end
	end
end)

-- Use Canteen
RegisterNetEvent('qb-prison:client:useCanteen', function()
	if LocalPlayer.state.isLoggedIn then
		if inJail then
			local ShopItems = {}
			ShopItems.label = "Prison Canteen"
			ShopItems.items = Config.CanteenItems
			ShopItems.slots = #Config.CanteenItems
			TriggerServerEvent("inventory:server:OpenInventory", "shop", "Canteenshop_"..math.random(1, 99), ShopItems)
		else
			QBCore.Functions.Notify("You are not in Jail..", "error")
		end
	else
		Wait(5000)
	end
end)

-- Slushy Machine
RegisterNetEvent('qb-prison:client:slushy', function()
	if LocalPlayer.state.isLoggedIn then
		if inJail then
			Wait(1000)
			local ped = PlayerPedId()
			if Config.SlushyMiniGame.PSThermite.enabled then
				exports['ps-ui']:Thermite(function(success)
					if success then
						TriggerServerEvent("InteractSound_SV:PlayOnSource", "pour-drink", 0.1)
						TaskStartScenarioInPlace(ped, "WORLD_HUMAN_HANG_OUT_STREET", 0, true)
						QBCore.Functions.Progressbar("prison_slushy", "Making a Good Slushy...", 10000, false, true, {
							disableMovement = false,
							disableCarMovement = true,
							disableMouse = false,
							disableCombat = true,
						}, {}, {}, {}, function() -- Done
							SlushyTime(success)
							ClearPedTasks(PlayerPedId())
						end, function() -- Cancel
							QBCore.Functions.Notify("Canceled...", "error")
							ClearPedTasks(PlayerPedId())
						end, "slushy")
					else
						QBCore.Functions.Notify("You Failed making a Slushy..", "error")
						ClearPedTasks(PlayerPedId())
					end
				end, Config.SlushyMiniGame.PSThermite.time, Config.SlushyMiniGame.PSThermite.grid, Config.SlushyMiniGame.PSThermite.incorrect)
			elseif Config.SlushyMiniGame.PSCircle.enabled then
				exports['ps-ui']:Circle(function(success)
					if success then
						TriggerServerEvent("InteractSound_SV:PlayOnSource", "pour-drink", 0.1)
						TaskStartScenarioInPlace(ped, "WORLD_HUMAN_HANG_OUT_STREET", 0, true)
						QBCore.Functions.Progressbar("prison_slushy", "Making a Good Slushy...", 10000, false, true, {
							disableMovement = false,
							disableCarMovement = true,
							disableMouse = false,
							disableCombat = true,
						}, {}, {}, {}, function() -- Done
							SlushyTime(success)
							ClearPedTasks(PlayerPedId())
						end, function() -- Cancel
							QBCore.Functions.Notify("Canceled...", "error")
							ClearPedTasks(PlayerPedId())
						end, "slushy")
					else
						QBCore.Functions.Notify("You Failed making a Slushy..", "error")
						ClearPedTasks(PlayerPedId())
					end
				end, Config.SlushyMiniGame.PSCircle.circles, Config.SlushyMiniGame.PSCircle.time) -- NumberOfCircles, MS
			elseif Config.SlushyMiniGame.QBSkillbar.enabled then
				local Skillbar = exports['qb-skillbar']:GetSkillbarObject()
				Skillbar.Start({
					duration = Config.SlushyMiniGame.QBSkillbar.duration, -- how long the skillbar runs for
					pos = Config.SlushyMiniGame.QBSkillbar.pos, -- how far to the right the static box is
					width = Config.SlushyMiniGame.QBSkillbar.width, -- how wide the static box is
				}, function()
					TriggerServerEvent("InteractSound_SV:PlayOnSource", "pour-drink", 0.1)
					TaskStartScenarioInPlace(ped, "WORLD_HUMAN_HANG_OUT_STREET", 0, true)
					QBCore.Functions.Progressbar("prison_slushy", "Making a Good Slushy...", 10000, false, true, {
						disableMovement = false,
						disableCarMovement = true,
						disableMouse = false,
						disableCombat = true,
					}, {}, {}, {}, function() -- Done
						SlushyTime(Skillbar)
						ClearPedTasks(PlayerPedId())
					end, function() -- Cancel
						QBCore.Functions.Notify("Canceled...", "error")
						ClearPedTasks(PlayerPedId())
					end, "slushy")
				end, function()
					QBCore.Functions.Notify("You Failed making a Slushy..", "error")
					ClearPedTasks(PlayerPedId())
				end)
			elseif Config.SlushyMiniGame.QBLock.enabled then
				local success = exports['qb-lock']:StartLockPickCircle(Config.SlushyMiniGame.QBLock.circles, Config.SlushyMiniGame.QBLock.time, success)
				if success then
					TriggerServerEvent("InteractSound_SV:PlayOnSource", "pour-drink", 0.1)
					TaskStartScenarioInPlace(ped, "WORLD_HUMAN_HANG_OUT_STREET", 0, true)
					QBCore.Functions.Progressbar("prison_slushy", "Making a Good Slushy...", 10000, false, true, {
						disableMovement = false,
						disableCarMovement = true,
						disableMouse = false,
						disableCombat = true,
					}, {}, {}, {}, function() -- Done
						SlushyTime(success)
						ClearPedTasks(PlayerPedId())
					end, function() -- Cancel
						QBCore.Functions.Notify("Canceled...", "error")
						ClearPedTasks(PlayerPedId())
					end, "slushy")
				else
					QBCore.Functions.Notify("You Failed making a Slushy..", "error")
					ClearPedTasks(PlayerPedId())
				end
			end
		else
			QBCore.Functions.Notify("You are not in Jail..", "error")
		end
	else
		Wait(5000)
	end
end)

-- Slushy Success / Fail
function SlushyTime(success)
	if success then
		local SlushyItems = {}
			SlushyItems.label = "Prison Slushy"
			SlushyItems.items = Config.SlushyItems
			SlushyItems.slots = #Config.SlushyItems
		TriggerServerEvent("inventory:server:OpenInventory", "shop", "Slushyshop_"..math.random(1, 99), SlushyItems)
	else
		QBCore.Functions.Notify("Slushy Machine is Broken", "error")
	end

end

-- Soda Machine
RegisterNetEvent('qb-prison:client:soda', function()
	if LocalPlayer.state.isLoggedIn then
		if inJail then
			Wait(1000)
			local ped = PlayerPedId()
			if Config.SodaMiniGame.PSThermite.enabled then
				exports['ps-ui']:Thermite(function(success)
					if success then
						TriggerServerEvent("InteractSound_SV:PlayOnSource", "pour-drink", 0.1)
						TaskStartScenarioInPlace(ped, "WORLD_HUMAN_HANG_OUT_STREET", 0, true)
						QBCore.Functions.Progressbar("prison_soda", "Making a Cup Of Soda...", 10000, false, true, {
							disableMovement = false,
							disableCarMovement = true,
							disableMouse = false,
							disableCombat = true,
						}, {}, {}, {}, function() -- Done
							SodaTime(success)
							ClearPedTasks(PlayerPedId())
						end, function() -- Cancel
							QBCore.Functions.Notify("Canceled...", "error")
							ClearPedTasks(PlayerPedId())
						end, "bscoke")
					else
						QBCore.Functions.Notify("You failed making a Soda..", "error")
						ClearPedTasks(PlayerPedId())
					end
				end, Config.SodaMiniGame.PSThermite.time, Config.SodaMiniGame.PSThermite.grid, Config.SodaMiniGame.PSThermite.incorrect)
			elseif Config.SodaMiniGame.PSCircle.enabled then
				exports['ps-ui']:Circle(function(success)
					if success then
						TriggerServerEvent("InteractSound_SV:PlayOnSource", "pour-drink", 0.1)
						TaskStartScenarioInPlace(ped, "WORLD_HUMAN_HANG_OUT_STREET", 0, true)
						QBCore.Functions.Progressbar("prison_soda", "Making a Cup Of Soda...", 10000, false, true, {
							disableMovement = false,
							disableCarMovement = true,
							disableMouse = false,
							disableCombat = true,
						}, {}, {}, {}, function() -- Done
							SodaTime(success)
							ClearPedTasks(PlayerPedId())
						end, function() -- Cancel
							QBCore.Functions.Notify("Canceled...", "error")
							ClearPedTasks(PlayerPedId())
						end, "bscoke")
					else
						QBCore.Functions.Notify("You failed making a Soda..", "error")
						ClearPedTasks(PlayerPedId())
					end
				end, Config.SodaMiniGame.PSCircle.circles, Config.SodaMiniGame.PSCircle.time) -- NumberOfCircles, MS
			elseif Config.SodaMiniGame.QBSkillbar.enabled then
				local Skillbar = exports['qb-skillbar']:GetSkillbarObject()
				Skillbar.Start({
					duration = Config.SodaMiniGame.QBSkillbar.duration, -- how long the skillbar runs for
					pos = Config.SodaMiniGame.QBSkillbar.pos, -- how far to the right the static box is
					width = Config.SodaMiniGame.QBSkillbar.width, -- how wide the static box is
				}, function()
					TriggerServerEvent("InteractSound_SV:PlayOnSource", "pour-drink", 0.1)
					TaskStartScenarioInPlace(ped, "WORLD_HUMAN_HANG_OUT_STREET", 0, true)
					QBCore.Functions.Progressbar("prison_soda", "Making a Cup Of Soda...", 10000, false, true, {
						disableMovement = false,
						disableCarMovement = true,
						disableMouse = false,
						disableCombat = true,
					}, {}, {}, {}, function() -- Done
						SodaTime(Skillbar)
						ClearPedTasks(PlayerPedId())
					end, function() -- Cancel
						QBCore.Functions.Notify("Canceled...", "error")
						ClearPedTasks(PlayerPedId())
					end, "bscoke")
				end, function()
					QBCore.Functions.Notify("You failed making a Soda..", "error")
					ClearPedTasks(PlayerPedId())
				end)
			elseif Config.SodaMiniGame.QBLock.enabled then
				local success = exports['qb-lock']:StartLockPickCircle(Config.SodaMiniGame.QBLock.circles, Config.SodaMiniGame.QBLock.time, success)
				if success then
					TriggerServerEvent("InteractSound_SV:PlayOnSource", "pour-drink", 0.1)
					TaskStartScenarioInPlace(ped, "WORLD_HUMAN_HANG_OUT_STREET", 0, true)
					QBCore.Functions.Progressbar("prison_soda", "Making a Cup Of Soda...", 10000, false, true, {
						disableMovement = false,
						disableCarMovement = true,
						disableMouse = false,
						disableCombat = true,
					}, {}, {}, {}, function() -- Done
						SodaTime(success)
						ClearPedTasks(PlayerPedId())
					end, function() -- Cancel
						QBCore.Functions.Notify("Canceled...", "error")
						ClearPedTasks(PlayerPedId())
					end, "bscoke")
				else
					QBCore.Functions.Notify("You failed making a Soda..", "error")
					ClearPedTasks(PlayerPedId())
				end
			end
		else
			QBCore.Functions.Notify("You are not in Jail..", "error")
		end
	else
		Wait(5000)
	end
end)

-- Soda Success / Fail
function SodaTime(success)
	if success then
		local SodaItems = {}
			SodaItems.label = "Prison Soda"
			SodaItems.items = Config.SodaItems
			SodaItems.slots = #Config.SodaItems
		TriggerServerEvent("inventory:server:OpenInventory", "shop", "Sodashop_"..math.random(1, 99), SodaItems)
	else
		QBCore.Functions.Notify("Soda Machine is Broken", "error")
	end
end

RegisterNetEvent('qb-prison:client:coffee', function()
	if LocalPlayer.state.isLoggedIn then
		if inJail then
			local CoffeeItems = {}
			CoffeeItems.label = "Prison Coffee"
			CoffeeItems.items = Config.CoffeeItems
			CoffeeItems.slots = #Config.CoffeeItems
			TriggerServerEvent("inventory:server:OpenInventory", "shop", "Coffeeshop_"..math.random(1, 99), CoffeeItems)
		else
			QBCore.Functions.Notify("You are not in Jail..", "error")
		end
	else
		Wait(5000)
	end
end)

---------------------------------------------
-- CUP RELATED FUNCTIONS SLUSHY SODA (WIP) --
---------------------------------------------

-- Cup Stack

-- Slushy Machine
--[[RegisterNetEvent('qb-prison:client:slushy', function(HasItem)
	if LocalPlayer.state.isLoggedIn then
		if inJail then
			Citizen.Wait(1000)
			if HasItem then
				local ped = PlayerPedId()
				local seconds = math.random(7,10)
				local circles = math.random(5,10)
				local success = exports['qb-lock']:StartLockPickCircle(circles, seconds, success)
				if success then
					TriggerServerEvent("InteractSound_SV:PlayOnSource", "pour-drink", 0.1)
					TaskStartScenarioInPlace(ped, "WORLD_HUMAN_HANG_OUT_STREET", 0, true)
					QBCore.Functions.Progressbar("hospital_waiting", "Making a Good Slushy...", 10000, false, true, {
						disableMovement = false,
						disableCarMovement = true,
						disableMouse = false,
						disableCombat = true,
					}, {}, {}, {}, function() -- Done
						SlushyTime(success)
						ClearPedTasks(PlayerPedId())
					end, function() -- Cancel
						QBCore.Functions.Notify("Failed...", "error")
						ClearPedTasks(PlayerPedId())
					end, "slushy")
				else
					QBCore.Functions.Notify("You Failed making a Slushy..", "error")
					ClearPedTasks(PlayerPedId())
				end
			else
				QBCore.Functions.Notify("You are missing a cup..", "error")
			end
		else
			QBCore.Functions.Notify("You are not in Jail..", "error")
		end
	else
		Wait(5000)
	end
end)

-- Slushy Success / Fail
function SlushyTime(success)
	if success then
		local SlushyItems = {}
			SlushyItems.label = "Prison Slushy"
			SlushyItems.items = Config.SlushyItems
			SlushyItems.slots = #Config.SlushyItems
		TriggerServerEvent("inventory:server:OpenInventory", "shop", "Slushyshop_"..math.random(1, 99), SlushyItems)
	else
		QBCore.Functions.Notify("Slushy Machine is Broken", "error")
	end
end

-- Soda Machine
RegisterNetEvent('qb-prison:client:soda', function()
	if LocalPlayer.state.isLoggedIn then
		if inJail then
			Citizen.Wait(1000)
			local ped = PlayerPedId()
			local seconds = math.random(7,10)
			local circles = math.random(5,10)
			local success = exports['qb-lock']:StartLockPickCircle(circles, seconds, success)
			if success then
				TriggerServerEvent("InteractSound_SV:PlayOnSource", "pour-drink", 0.1)
				TaskStartScenarioInPlace(ped, "WORLD_HUMAN_HANG_OUT_STREET", 0, true)
				QBCore.Functions.Progressbar("hospital_waiting", "Making a Cup Of Soda...", 10000, false, true, {
					disableMovement = false,
					disableCarMovement = true,
					disableMouse = false,
					disableCombat = true,
				}, {}, {}, {}, function() -- Done
					SodaTime(success)
					ClearPedTasks(PlayerPedId())
				end, function() -- Cancel
					QBCore.Functions.Notify("Failed...", "error")
					ClearPedTasks(PlayerPedId())
				end, "bsoke")
			else
				QBCore.Functions.Notify("You failed making a Soda..", "error")
				ClearPedTasks(PlayerPedId())
			end
		else
			QBCore.Functions.Notify("You are not in Jail..", "error")
		end
	else
		Wait(5000)
	end
end)

-- Soda Success / Fail
function SodaTime(success)
	if success then
		local SodaItems = {}
			SodaItems.label = "Prison Soda"
			SodaItems.items = Config.SodaItems
			SodaItems.slots = #Config.SodaItems
		TriggerServerEvent("inventory:server:OpenInventory", "shop", "Sodashop_"..math.random(1, 99), SodaItems)
	else
		QBCore.Functions.Notify("Soda Machine is Broken", "error")
	end
end]]--

-------------------------------
-- CRAFTING MENU AND EVENTS --
-------------------------------

RegisterNetEvent('qb-prison:CraftingMenu', function()

	local craftingheader = {
	  {
		header = "Prison Crafting",
		isMenuHeader = true,
	  },
	}

	for k, v in pairs(Config.CraftingItems) do
	  print(k, v)
	  local item = {}
	  local text = ""

	  item.header = k
	  for k, v in pairs(v.materials) do
		text = text .. "- " .. QBCore.Shared.Items[v.item].label .. ": " .. v.amount .. "x <br>"
	  end
	  item.text = text
	  item.params = {
		event = 'qb-prison:CraftItem',
		args = {
		  item = k
		}
	  }

	  table.insert(craftingheader, item)
	end

	exports['qb-menu']:openMenu(craftingheader)
end)

local function CraftItem(item)

	if Config.Debug then
	  print(item, Config.CraftingItems[item].receive)
	end

	QBCore.Functions.Progressbar('crafting_item', 'Crafting '..item, 5000, false, false, {
		disableMovement = true,
		disableCarMovement = true,
		disableMouse = false,
		disableCombat = true,
	}, {
		animDict = "mini@repair",
		anim = "fixing_a_ped",
		}, {}, {}, function() -- Success
		QBCore.Functions.Notify("Crafted "..item, 'success')
		TriggerServerEvent('qb-prison:server:GetCraftedItem', Config.CraftingItems[item].receive)
		for k, v in pairs(Config.CraftingItems[item].materials) do
		  TriggerServerEvent('QBCore:Server:RemoveItem', v.item, v.amount)
		  TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items[v.item], "remove")
		end
		TriggerEvent('animations:client:EmoteCommandStart', {"c"})
		ClearPedTasks(PlayerPedId())
	end, function() -- Cancel
		ClearPedTasks(PlayerPedId())
		QBCore.Functions.Notify('You have cancelled the crafting process', 'error')
	end)
end

-- Uses Callback to Check for Materials
RegisterNetEvent('qb-prison:CraftItem', function(data)

	if Config.Debug then
		print(data.item)
	end

	QBCore.Functions.TriggerCallback("qb-prison:server:CraftingMaterials", function(hasMaterials)
		if (hasMaterials) then
			CraftItem(data.item)
		else
			QBCore.Functions.Notify("You do not have the correct items", "error")
			return
		end
	end, Config.CraftingItems[data.item].materials)
end)

RegisterNetEvent('qb-prison:client:GetCraftingItems', function(job)
	if job == 'janitor' then
		local JanitorItem = math.random(1, #Config.JanitorItems)
		TriggerServerEvent('qb-prison:server:GetCraftingItems', Config.JanitorItems[JanitorItem].item, Config.JanitorItems[JanitorItem].amount)

		if Config.Debug then
			print("Received "..Config.JanitorItems[JanitorItem].amount.."x "..Config.JanitorItems[JanitorItem].item.." from cleaning")
		end

	elseif job == 'cook' then
		local CookItem = math.random(1, #Config.CookItems)
		TriggerServerEvent('qb-prison:server:GetCraftingItems', Config.CookItems[CookItem].item, Config.CookItems[CookItem].amount)

		if Config.Debug then
			print("Received "..Config.CookItems[CookItem].amount.."x "..Config.CookItems[CookItem].item.." from cooking")
		end

	elseif job == 'electrician' then
		local ElectricianItem = math.random(1, #Config.ElectricianItems)

		TriggerServerEvent('qb-prison:server:GetCraftingItems', Config.ElectricianItems[ElectricianItem].item, Config.ElectricianItems[ElectricianItem].amount)

		if Config.Debug then
			print("Received "..Config.ElectricianItems[ElectricianItem].amount.."x "..Config.ElectricianItems[ElectricianItem].item.." from fixing electrical")
		end

	end
end)

-----------------------
-- TARGET FUNCTIONS --
-----------------------

-- PRISON TIME TARGET
RegisterNetEvent('qb-prison:PrisonTimeTarget', function()
    exports['qb-target']:AddBoxZone("prisontime", vector3(1827.3, 2587.72, 46.01), 0.4, 0.55, {
        name = "prisontime",
        heading = 0,
        debugPoly = Config.DebugPoly,
		minZ = 46.11,
		maxZ = 47.01,
        }, {
            options = {
            {
                type = "client",
                event = "qb-prison:client:checkTime",
                icon = "fas fa-clock",
                label = "Check Jail Time",
            },
            {
                type = "client",
                event = "qb-prison:client:jobMenu",
                icon = "fas fa-cash-register",
                label = "Choose Another Job",
            },
        },
        distance = 2,
    })

    prisontimeTarget = true

    if Config.Debug then
        print('Prison Time Target Created')
    end
end)

-- CANTEEN TARGET
RegisterNetEvent('qb-prison:CanteenTarget', function()
    exports['qb-target']:AddBoxZone("prisoncanteen", vector3(1780.95, 2560.05, 45.67), 3.8, 0.5, {
        name = "prisoncanteen",
        heading = 90,
        debugPoly = Config.DebugPoly,
		minZ = 45.40,
		maxZ = 45.85,
        }, {
            options = {
            {
                type = "client",
                event = "qb-prison:client:useCanteen",
                icon = "fas fa-utensils",
                label = "Open Canteen",
            },
        },
        distance = 2,
    })

    canteenTarget = true

    if Config.Debug then
        print('Canteen Target Created')
    end
end)


-- SLUSHY TARGET
RegisterNetEvent('qb-prison:SlushyTarget', function()
    exports['qb-target']:AddBoxZone("prisonslushy", vector3(1777.64, 2559.97, 45.67), 0.5, 0.7, {
        name = "prisonslushy",
        heading = 0,
        debugPoly = Config.DebugPoly,
		minZ = 45.50,
		maxZ = 46.75,
        }, {
            options = {
            {
                type = "client",
                event = "qb-prison:client:slushy",
                icon = "fas fa-wine-bottle",
                label = "Make Slushy",
            },
        },
        distance = 2,
    })

    slushyTarget = true

    if Config.Debug then
        print('Slushy Target Created')
    end
end)

-- COFFEE TARGET
RegisterNetEvent('qb-prison:CoffeeTarget', function()
    exports['qb-target']:AddBoxZone("prisoncoffee", vector3(1778.83, 2560.04, 45.67), 0.5, 0.3, {
        name = "prisoncoffee",
        heading = 0,
        debugPoly = Config.DebugPoly,
		minZ = 45.50,
		maxZ = 46.75,
        }, {
            options = {
            {
                type = "client",
                event = "qb-prison:client:coffee",
                icon = "fas fa-mug-hot",
                label = "Make Coffee",
            },
        },
        distance = 2,
    })

    coffeeTarget = true

    if Config.Debug then
        print('Coffee Target Created')
    end
end)

-- SODA TARGET
RegisterNetEvent('qb-prison:SodaTarget', function()
    exports['qb-target']:AddBoxZone("prisonsoda", vector3(1778.26, 2560.02, 45.67), 0.6, 0.55, {
        name = "prisonsoda",
        heading = 0,
        debugPoly = Config.DebugPoly,
		minZ = 45.50,
		maxZ = 46.75,
        }, {
            options = {
            {
                type = "client",
                event = "qb-prison:client:soda",
                icon = "fas fa-cash-register",
                label = "Make Soda",
            },
        },
        distance = 2,
    })

    sodaTarget = true

    if Config.Debug then
        print('Soda Target Created')
    end
end)

-- PRISON CRAFTING TARGET - POLYZONE IS ON A DOOR
RegisterNetEvent('qb-prison:PrisonCraftingTarget', function()
    exports['qb-target']:AddBoxZone("prisoncrafting", vector3(Config.CraftingLocation.x, Config.CraftingLocation.y, Config.CraftingLocation.z), 1.4, 0.5, {
        name = "prisoncrafting",
        heading = Config.CraftingLocation.w,
        debugPoly = Config.DebugPoly,
		minZ = Config.CraftingLocation.z - 1,
		maxZ = Config.CraftingLocation.z + 1,
        }, {
            options = {
            {
                type = "client",
                event = "qb-prison:CraftingMenu",
                icon = "fas fa-toolbox",
                label = "Prison Crafting",
            },
        },
        distance = 2,
    })

    prisoncraftingTarget = true

    if Config.Debug then
        print('Prison Crafting Target Created')
    end
end)

----------------------------------
-- JAIL ALARM -- PRISON BREAK --
----------------------------------

CreateThread(function()
    TriggerEvent('prison:client:JailAlarm', false)
	while true do
		local sleep = 1000
		if jailTime ~= nil and jailTime > 0 and inJail then
			Wait(1000 * 60)
			sleep = 0
			if jailTime > 0 and inJail then
				jailTime -= 1
				if jailTime <= 0 then
					jailTime = 0
					QBCore.Functions.Notify(Lang:t("success.timesup"), "success", 10000)
				end
				TriggerServerEvent("prison:server:SetJailStatus", jailTime)

				GetJailTime()

			end
		else
			Wait(sleep)
		end
	end
end)
