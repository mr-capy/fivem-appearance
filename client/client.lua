-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

local savedOutfits = {}
local LastZone, CurrentAction, hasAlreadyEnteredMarker, currentZone = nil, nil, false, nil

ESX = exports["es_extended"]:getSharedObject()

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
	ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:onPlayerLogout')
AddEventHandler('esx:onPlayerLogout', function()
    ESX.PlayerLoaded = false
    ESX.PlayerData = {}
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

AddEventHandler('esx:onPlayerDeath', function(data)
    closeMenu()
end)

closeMenu = function()
    RenderScriptCams(false, false, 0, true, true)
    DestroyAllCams(true)
    DisplayRadar(true)
    SetNuiFocus(false, false)
    SetEntityInvincible(PlayerPedId(), false)

    SetNuiFocus(false, false)
    SendNUIMessage{
        type = 'appearance_hide',
        payload = {}
    }
end

-- Blips

CreateBlip = function(coords, sprite, colour, text, scale)
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, colour)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, scale)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(text)
    EndTextCommandSetBlipName(blip)
end

CreateThread(function()
    for i=1, #Config.ClothingShops do
        if Config.ClothingShops[i].blip then
            CreateBlip(Config.ClothingShops[i].coords, Config.ClothingShops[i].type, Config.ClothingShops[i].color, Config.Translation.Blip.clothingShop, Config.ClothingShops[i].scale)
        end
    end
    for i=1, #Config.BarberShops do
        if Config.BarberShops[i].blip then
            CreateBlip(Config.BarberShops[i].coords, Config.BarberShops[i].type, Config.BarberShops[i].color, Config.Translation.Blip.barberShop, Config.BarberShops[i].scale)
        end
    end
    for i=1, #Config.TattooShops do
        if Config.TattooShops[i].blip then
            CreateBlip(Config.TattooShops[i].coords, Config.TattooShops[i].type, Config.TattooShops[i].color, Config.Translation.Blip.tattooShop, Config.TattooShops[i].scale)
        end
    end
end)

function isPlayerAllowed(Shops)
    local playerjob = ESX.PlayerData.job.name
    local isallowed = false
        if type(Shops.jobs) == 'table' then
            for k,v in ipairs(Shops.jobs) do
                if playerjob == v or not v then
                    isallowed = true
                end
                Wait(500)
            end
        else
            isallowed = true
        end
        return isallowed
end

CreateThread(function()
    while true do
        local sleep = 1500
        local playerCoords, inClothingShop, inBarberShop, inTattooShop, currentZone = GetEntityCoords(PlayerPedId()), false, false, false, nil

        for i=1, #Config.ClothingShops do
            local dist = #(playerCoords - Config.ClothingShops[i].coords)
            if dist <= Config.Distance then
                sleep = 0
                if dist <= Config.ClothingShops[i].distance and isPlayerAllowed(Config.ClothingShops[i]) then
                    inClothingShop, currentZone = true, i
                end
            end
        end

        for i=1, #Config.BarberShops do
            local dist = #(playerCoords - Config.BarberShops[i].coords)
            if dist <= Config.Distance then
                sleep = 0
                if dist <= Config.BarberShops[i].distance then
                    inBarberShop, currentZone = true, i
                end
            end
        end

        for i=1, #Config.TattooShops do
            local dist = #(playerCoords - Config.TattooShops[i].coords)
            if dist <= Config.Distance then
                sleep = 0
                if dist <= Config.TattooShops[i].distance then
                    inTattooShop, currentZone = true, i
                end
            end
        end

        if (inClothingShop and not hasAlreadyEnteredMarker) or (inClothingShop and LastZone ~= currentZone) then
            hasAlreadyEnteredMarker, LastZone = true, currentZone
            CurrentAction = 'clothingMenu'
            lib.showTextUI(Config.Translation.Menu.clothingMenu)
        end

        if (inBarberShop and not hasAlreadyEnteredMarker) or (inBarberShop and LastZone ~= currentZone) then
            hasAlreadyEnteredMarker, LastZone = true, currentZone
            CurrentAction = 'barberMenu'
            lib.showTextUI(Config.Translation.Menu.barberMenu)
        end

        if (inTattooShop and not hasAlreadyEnteredMarker) or (inTattooShop and LastZone ~= currentZone) then
            hasAlreadyEnteredMarker, LastZone = true, currentZone
            CurrentAction = 'tattooMenu'
            lib.showTextUI(Config.Translation.Menu.tattooMenu)
        end

        if not inClothingShop and not inBarberShop and not inTattooShop and hasAlreadyEnteredMarker then
            hasAlreadyEnteredMarker = false
            sleep = 1000
            CurrentAction = nil
            lib.hideTextUI()
        end
        Wait(sleep)
    end
end)


CreateThread(function()
    while true do
        local sleep = 1500
        if CurrentAction ~= nil then
            sleep = 0
            if IsControlPressed(1, 38) then
                --get current model before modification so we can revert if plyaer doesnot have money
                local playerPed = PlayerPedId()
		        local currentPedModel = exports['fivem-appearance']:getPedModel(playerPed)
                local currentappearance = exports['fivem-appearance']:getPedAppearance(playerPed)

                Wait(500)
                if CurrentAction == 'clothingMenu' then
                    TriggerEvent('fivem-appearance:clothingShop')
                elseif CurrentAction == 'barberMenu' then
                    local config = {
                        ped = false,
                        headBlend = true,
                        faceFeatures = true,
                        headOverlays = true,
                        components = false,
                        props = false,
                        tattoos = false
                    }
                    exports['fivem-appearance']:startPlayerCustomization(function (appearance)
						if (appearance) then
                            --price check and detect using callback                          
                            ESX.TriggerServerCallback('fivem-appearance:payfee', function(success)
                                if success then
                                    TriggerServerEvent('fivem-appearance:save', appearance)
                                    TriggerEvent('esx:restoreLoadout')
							        ESX.SetPlayerData('ped', PlayerPedId())
                                else
                                    --revert character which we already save before modification                                 
                                    exports['fivem-appearance']:setPlayerAppearance(currentappearance)
                                    TriggerServerEvent('fivem-appearance:save',currentappearance)
                                    TriggerEvent('esx:restoreLoadout')
							        ESX.SetPlayerData('ped', PlayerPedId())
                                end
                            end, "BarberShops",currentZone)
						else
                            TriggerEvent('esx:restoreLoadout')
							ESX.SetPlayerData('ped', PlayerPedId())
						end
					end, config)
                elseif CurrentAction == 'tattooMenu' then
                    local config = {
						ped = false,
						headBlend = false,
						faceFeatures = false,
						headOverlays = false,
						components = false,
						props = false,
						tattoos = true
					}
                    exports['fivem-appearance']:startPlayerCustomization(function (appearance)
						if (appearance) then
                            ESX.TriggerServerCallback('fivem-appearance:payfee', function(success)
                                if success then
                                    TriggerServerEvent('fivem-appearance:save', appearance)
                                    TriggerEvent('esx:restoreLoadout')
							        --ESX.SetPlayerData('ped', PlayerPedId())
                                else
                                    exports['fivem-appearance']:setPlayerAppearance(currentappearance)
                                    TriggerServerEvent('fivem-appearance:save',currentappearance)
                                    TriggerEvent('esx:restoreLoadout')
							        --ESX.SetPlayerData('ped', PlayerPedId())
                                end
                            end, "TattooShops",currentZone)
						else
							ESX.SetPlayerData('ped', PlayerPedId())
                            TriggerEvent('esx:restoreLoadout')
						end
					end, config)
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('fivem-appearance:notify', function(title, desc, style, icon)
    if icon then
        lib.notify({
            title = title,
            description = desc,
            duration = 3500,
            icon = icon,
            type = style
        })
    else
        lib.notify({
            title = title,
            description = desc,
            duration = 3500,
            type = style
        })
    end
end)

RegisterNetEvent('fivem-appearance:clothingShop', function()
	lib.registerContext({
		id = 'clothing_menu',
		title = Config.Translation.Shop.masterTitle,
		options = {
			{
				title = Config.Translation.Shop.clothingMenuTitle,
				description = Config.Translation.Shop.clothingMenuDesc,
				arrow = false,
				event = 'fivem-appearance:clothingMenu',
			},
			{
				title = Config.Translation.Shop.pickNewOutfitTitle,
				description = Config.Translation.Shop.pickNewOutfitDesc,
				arrow = false,
				event = 'fivem-appearance:pickNewOutfit'
			},
			{
				title = Config.Translation.Shop.saveOutfitTitle,
				description = Config.Translation.Shop.saveOutfitDesc,
				arrow = false,
				event = 'fivem-appearance:saveOutfit'
			},
			{
				title = Config.Translation.Shop.deleteOutfitMenuTitle,
				description = Config.Translation.Shop.deleteOutfitMenuDesc,
				arrow = false,
				event = 'fivem-appearance:deleteOutfitMenu'
			},
		}
	})
	lib.showContext('clothing_menu')
end)
RegisterNetEvent('fivem-appearance:clothingMenu', function()
    local playerPed = PlayerPedId()
    local currentPedModel = exports['fivem-appearance']:getPedModel(playerPed)
    local currentappearance = exports['fivem-appearance']:getPedAppearance(playerPed)


	local config = {
		ped = false,
		headBlend = false,
		faceFeatures = false,
		headOverlays = false,
		components = true,
		props = true
	}
	exports['fivem-appearance']:startPlayerCustomization(function (appearance)
		if (appearance) then
			ESX.TriggerServerCallback('fivem-appearance:payfee', function(success)
                if success then
                    TriggerServerEvent('fivem-appearance:save', appearance)
                    TriggerEvent('esx:restoreLoadout')
                    ESX.SetPlayerData('ped', PlayerPedId())
                else
                
                    exports['fivem-appearance']:setPlayerAppearance(currentappearance)
                    TriggerServerEvent('fivem-appearance:save',currentappearance)
                    TriggerEvent('esx:restoreLoadout')
                    ESX.SetPlayerData('ped', PlayerPedId())
                end   
            end, "ClothingShops",currentZone)
        else
			ESX.SetPlayerData('ped', PlayerPedId()) -- Fix for esx legacy
            TriggerEvent('esx:restoreLoadout')
		end
	end, config)
end)

openWardrobe = function()
    ESX.TriggerServerCallback('fivem-appearance:getOutfits', function(cb)
        local Options = {}
        if cb then
            Options = {}
            for i=1, #cb do
                table.insert(Options, {
                    title = cb[i].name,
                    event = 'fivem-appearance:setOutfit',
                    args = {
                        ped = cb[i].ped,
						components = cb[i].components,
						props = cb[i].props
                    }
                })
            end
        else
            Options = {
                {
                    title = Config.Translation.Wardrobe.menuTitle,
                    description = Config.Translation.Wardrobe.menuDesc,
                    event = ''
                }
            }
        end
        lib.registerContext({
            id = 'wardrobe_menu',
            title = Config.Translation.Wardrobe.masterTitle,
            options = Options
        })
        lib.showContext('wardrobe_menu')
    end)
end

exports('openWardrobe', openWardrobe)

RegisterNetEvent('fivem-appearance:pickNewOutfit', function()
    ESX.TriggerServerCallback('fivem-appearance:getOutfits', function(cb)
        local Options = {}
        if cb then
            Options = {
                {
                    title = Config.Translation.NewOutfit.title,
                    event = 'fivem-appearance:clothingShop'
                }
            }
            for i=1, #cb do
                table.insert(Options, {
                    title = cb[i].name,
                    event = 'fivem-appearance:setOutfit',
                    args = {
                        ped = cb[i].ped, 
						components = cb[i].components,
						props = cb[i].props
                    }
                })
            end
        else
            Options = {
                {
                    title = Config.Translation.NewOutfit.title,
                    description = Config.Translation.NewOutfit.desc,
                    event = 'fivem-appearance:clothingShop'
                }
            }
        end
        lib.registerContext({
            id = 'outfit_menu',
            title = Config.Translation.NewOutfit.masterTitle,
            options = Options
        })
        lib.showContext('outfit_menu')
    end)
end)

RegisterNetEvent('fivem-appearance:setOutfit')
AddEventHandler('fivem-appearance:setOutfit', function(data)
	local pedModel = data.ped
	local pedComponents = data.components
	local pedProps = data.props
	local playerPed = PlayerPedId()
	local currentPedModel = exports['fivem-appearance']:getPedModel(playerPed)
	if currentPedModel ~= pedModel then
    	exports['fivem-appearance']:setPlayerModel(pedModel)
		Wait(500)
		playerPed = PlayerPedId()
		exports['fivem-appearance']:setPedComponents(playerPed, pedComponents)
		exports['fivem-appearance']:setPedProps(playerPed, pedProps)
		local appearance = exports['fivem-appearance']:getPedAppearance(playerPed)
		TriggerServerEvent('fivem-appearance:save', appearance)
		ESX.SetPlayerData('ped', PlayerPedId())
	else
		exports['fivem-appearance']:setPedComponents(playerPed, pedComponents)
		exports['fivem-appearance']:setPedProps(playerPed, pedProps)
		local appearance = exports['fivem-appearance']:getPedAppearance(playerPed)
		TriggerServerEvent('fivem-appearance:save', appearance)
		ESX.SetPlayerData('ped', PlayerPedId())
	end
end)

RegisterNetEvent('fivem-appearance:saveOutfit', function()
    local input = lib.inputDialog('Save Outfit', {'Outfit Name'})
    if input then
        local name = input[1]
        local playerPed = PlayerPedId()
        local pedModel = exports['fivem-appearance']:getPedModel(playerPed)
        local pedComponents = exports['fivem-appearance']:getPedComponents(playerPed)
        local pedProps = exports['fivem-appearance']:getPedProps(playerPed)
        TriggerServerEvent('fivem-appearance:saveOutfit', name, pedModel, pedComponents, pedProps)
    end
end)

RegisterNetEvent('fivem-appearance:deleteOutfitMenu', function()
    ESX.TriggerServerCallback('fivem-appearance:getOutfits', function(cb)
        local Options = {}
        if cb then
            Options = {
                {
                    title = Config.Translation.DeleteOutfit.title,
                    event = 'fivem-appearance:clothingShop'
                }
            }
            for i=1, #cb do
                table.insert(Options, {
                    title = cb[i].name,
                    serverEvent = 'fivem-appearance:deleteOutfit',
                    args = cb[i].id
                })
            end
        else
            Options = {
                {
                    title = Config.Translation.DeleteOutfit.title,
                    description = Config.Translation.DeleteOutfit.desc,
                    event = 'fivem-appearance:clothingShop'
                }
            }
        end
        lib.registerContext({
            id = 'outfit_delete_menu',
            title = Config.Translation.DeleteOutfit.masterTitle,
            options = Options
        })
        lib.showContext('outfit_delete_menu')
    end)
end)

RegisterNetEvent('fivem-appearance:skinCommand')
AddEventHandler('fivem-appearance:skinCommand', function()
	local config = {
		ped = true,
		headBlend = true,
		faceFeatures = true,
		headOverlays = true,
		components = true,
		props = true
	}
	exports['fivem-appearance']:startPlayerCustomization(function (appearance)
		if (appearance) then
			TriggerServerEvent('fivem-appearance:save', appearance)
			ESX.SetPlayerData('ped', PlayerPedId())
			TriggerEvent('esx:restoreLoadout')
		else
			ESX.SetPlayerData('ped', PlayerPedId())
			TriggerEvent('esx:restoreLoadout')
		end
	end, config)
end)

RegisterCommand('propfix', function()
    for k, v in pairs(GetGamePool('CObject')) do
        if IsEntityAttachedToEntity(PlayerPedId(), v) then
            SetEntityAsMissionEntity(v, true, true)
            DeleteObject(v)
            DeleteEntity(v)
        end
    end
end)

-- cd_multicharacter compatibility
RegisterNetEvent('skinchanger:loadSkin2')
AddEventHandler('skinchanger:loadSkin2', function(ped, skin)
    if not skin.model then skin.model = 'mp_m_freemode_01' end
    	exports['fivem-appearance']:setPedAppearance(ped, skin)
    if cb ~= nil then
        cb()
    end
end)

-- esx_skin and skinchanger compatibility

AddEventHandler('skinchanger:getSkin', function(cb)
    while not ESX.PlayerLoaded do
        Wait(1000)
    end

    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(appearance)
        cb(appearance)
    end)
end)

RegisterNetEvent('skinchanger:loadSkin')
AddEventHandler('skinchanger:loadSkin', function(skin, cb)
	if not skin.model then skin.model = 'mp_m_freemode_01' end
	exports['fivem-appearance']:setPlayerAppearance(skin)
	TriggerEvent('esx:restoreLoadout')
	if cb ~= nil then
		cb()
	end
end)

convertClothes = function(outfit)
    local data = {
        Components = {
            { drawable = outfit.mask_1 or 0, texture = outfit.mask_2 or 0, component_id = 1 },
            { drawable = outfit.arms or 0, texture = outfit.arms_2 or 0, component_id = 3 },
            { drawable = outfit.pants_1 or 0, texture = outfit.pants_2 or 0, component_id = 4 },
            { drawable = outfit.shoes_1 or 0, texture = outfit.shoes_2 or 0, component_id = 6 },
            { drawable = outfit.chain_1 or 0, texture = outfit.chain_2 or 0, component_id = 7 },
            { drawable = outfit.tshirt_1 or 0, texture = outfit.tshirt_2 or 0, component_id = 8 },
            { drawable = outfit.bproof_1 or 0, texture = outfit.bproof_2 or 0, component_id = 9 },
            { drawable = outfit.decals_1 or 0, texture = outfit.decals_2 or 0, component_id = 10 },
            { drawable = outfit.torso_1 or 0, texture = outfit.torso_2 or 0, component_id = 11 },
        },
        Props = {
            { drawable = outfit.helmet_1 or -1, texture = outfit.helmet_2 or 0, prop_id = 0 },
            { drawable = outfit.glasses_1 or -1, texture = outfit.glasses_2 or 0, prop_id = 1 },
            { drawable = outfit.ears_1 or -1, texture = outfit.ears_2 or 0, prop_id = 2 },
            { drawable = outfit.watches_1 or -1, texture = outfit.watches_2 or 0, prop_id = 6 },
            { drawable = outfit.bracelets_1 or -1, texture = outfit.bracelets_2 or 0, prop_id = 7 },
        }
    }
    return data
end

RegisterNetEvent('skinchanger:loadClothes')
AddEventHandler('skinchanger:loadClothes', function(skin, clothes)
    local playerPed = PlayerPedId()
    local outfit = convertClothes(clothes)
    exports['fivem-appearance']:setPedComponents(playerPed, outfit.Components)
    exports['fivem-appearance']:setPedProps(playerPed, outfit.Props)
end)

RegisterNetEvent('esx_skin:openSaveableMenu')
AddEventHandler('esx_skin:openSaveableMenu', function(submitCb, cancelCb)
	local config = {
		ped = true,
		headBlend = true,
		faceFeatures = true,
		headOverlays = true,
		components = true,
		props = true
	}
	exports['fivem-appearance']:startPlayerCustomization(function (appearance)
		if (appearance) then
			TriggerServerEvent('fivem-appearance:save', appearance)
			ESX.SetPlayerData('ped', PlayerPedId())
			TriggerEvent('esx:restoreLoadout')
			if submitCb then submitCb() end
		else
			if cancelCb then cancelCb() end
			ESX.SetPlayerData('ped', PlayerPedId())
			TriggerEvent('esx:restoreLoadout')
		end
	end, config)
end)
