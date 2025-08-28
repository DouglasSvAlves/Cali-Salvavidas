----------------------------------------------------------------------------------------
--VARIABLES
----------------------------------------------------------------------------------------
local step = 0
local car = false
local working = false
local point = 0
local blips = false
local blipssv = false
local has_npc = false
local npcSafe = nil
local npc
local roupa = {}
local Object = nil
local npcThread = nil

local startTarget
local finishTarget
----------------------------------------------------------------------------------------
--PRINCIPAL THREAD
----------------------------------------------------------------------------------------
Citizen.CreateThread(function ()
    blipsv()
    while true do
        local idle = 1000
        local ped = PlayerPedId()
        local player_cds = GetEntityCoords(ped)
        local drowning_ped_cds = GetEntityCoords(npc)
        local distance_player_safe = #(player_cds - config.blip)
        local distance_player_drowning_ped = #(player_cds - drowning_ped_cds)

        if distance_player_safe <= 50 then
            if not has_npc then
                createNpcSafeguard()
                has_npc = true
            end
        else
            if has_npc then
                Citizen.Wait(500)
                DeleteEntity(npcSafe)
                -- interact.removeById(startTarget)
                exports['qb-target']:RemoveZone('safeguardStart')
                
                -- interact.removeById(finishTarget)
                exports['qb-target']:RemoveZone('safeguardFinish')
                has_npc = false
            end
        end

        if working then
            local chance_incident = math.random(1, 100)

            if step == 1 then
                TriggerServerEvent('Safeguard:setPlayerObserve')
                point = math.random(#config.locs)
                blipmapa()
                step = 2
            elseif step == 2 then
                local dist = #(player_cds - vec3(config.locs[point][1], config.locs[point][2], config.locs[point][3]))
                local ultimoveh = GetEntityModel(GetPlayersLastVehicle())
                
                if dist <= 7 then
                    idle = 0
                    DrawText3D(config.locs[point][1], config.locs[point][2], config.locs[point][3], "Pressione ~r~E~w~ para observar!")
                    DrawTextEmoji(config.locs[point][1], config.locs[point][2], config.locs[point][3]+0.2,'🛟')
                    if dist <= 2 then
                        if IsControlJustPressed(0, 38) and ultimoveh == -48031959 then
		                    createObjects("amb@world_human_binoculars@male@enter" ,"enter" ,"prop_binoc_01",50,28422)

                            SetEntityHeading(ped, config.locs[point][4])
                            Citizen.Wait(5000)
                            ClearPedTasks(ped)
                            FreezeEntityPosition(ped, false)
                            DeleteEntity(Object)
                            Object = nil
                            if chance_incident <= config.incident_chance then

                                exports['okokNotify']:Alert('Salva-Vidas', "Vitima se afogando!!!", 5000, 'safeguardS')
                                
                                createNpcDrowning()
                                RemoveBlip(blips)
                                blipIncident(npc)
                                TriggerServerEvent('Safeguard:setPlayerIncident')

                                step = 4                           

                            else
                                TriggerServerEvent('Safeguard:pointObserved')
                                exports['okokNotify']:Alert('Salva-Vidas', "Nenhum incidente.", 5000, 'safeguardS')
                                step = 3
                            end
                        elseif IsControlJustPressed(0, 38) then
                            exports['okokNotify']:Alert('Salva-Vidas', "Você precisa estar com uma veiculo de trabalho!", 5000, 'safeguardN')
                        end
                    end
                end

            elseif step == 3 then
                Citizen.Wait(0)
                RemoveBlip(blips)
                Citizen.Wait(2000)
                exports['okokNotify']:Alert('Salva-Vidas', "Novo local marcado em seu GPS.", 5000, 'safeguardS')

                step = 1

            elseif step == 4 then
                idle = 0
                if distance_player_drowning_ped <= 4.0 then
                    DrawText3D(drowning_ped_cds[1], drowning_ped_cds[2], drowning_ped_cds[3]+0.3, "Pressione ~r~E~w~ para salvar a vítima!")
                elseif not IsEntityInWater(ped) then
                    DrawTextEmoji(drowning_ped_cds[1], drowning_ped_cds[2], drowning_ped_cds[3]+0.5,'🖐️')
                end

                if distance_player_drowning_ped <= 4.0 and IsControlJustPressed(0, 38) then
                    SetEntityAsMissionEntity(npc, true,true)
                    ClearPedTasksImmediately(npc)

                    AttachEntityToEntity(npc, ped, 0,0.20,0.12,0.63,0.5,0.5,0.0, 180, false, false, false, false, 2, false)

                    loadAnim("nm")
                    TaskPlayAnim(npc, 'nm', 'firemans_carry', 8.0, -8.0, 100000, 46, 0, false, false, false)
                    step = 5
                end
                
            elseif step == 5 then
                idle = 0
                if IsEntityInWater(ped) then
                    DrawText3D(player_cds.x,player_cds.y,player_cds.z+1.0, "Saia da água para salvar a vítima!")
                else
                    DrawText3D(player_cds.x,player_cds.y,player_cds.z+1.0, "Pressione ~r~E~w~ para reanimá-la!")                                       
                end
                if GetIsTaskActive(npc,222) then
                    TaskWanderInArea(npc,config.drownings[point][1], config.drownings[point][2], config.drownings[point][3],2.0,2,10)
                end
                
                if not IsPedSwimming(ped) and not IsEntityPlayingAnim(ped,'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman',3) then
                    loadAnim("missfinale_c2mcs_1")
                    TaskPlayAnim(ped, 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 8.0, -8.0, 100000, 49, 0, false, false, false)
                end
                
                if not IsEntityInWater(ped) and IsControlJustPressed(0, 38) then
                    DoScreenFadeOut(700)
                    FreezeEntityPosition(ped, true)
                    Citizen.Wait(1000)
                    
                    DetachEntity(npc,true,true)
                    ClearPedTasksImmediately(ped)
                    ClearPedTasksImmediately(npc)
                    loadAnim("mini@cpr@char_a@cpr_str")
                    loadAnim("switch@trevor@annoys_sunbathers")
                    
                    SetEntityHeading(npc, GetEntityHeading(ped)+90.0)
                    SetEntityHeading(ped, GetEntityHeading(ped)+180.0)
                    SetEntityCoords(npc, player_cds.x-0.75, player_cds.y, player_cds.z)
                    TaskPlayAnim(ped, "mini@cpr@char_a@cpr_str","cpr_pumpchest", 8.0, -8.0, 10000, 15, 0.0, false, false, false)
                    TaskPlayAnim(npc, "switch@trevor@annoys_sunbathers","trev_annoys_sunbathers_loop_guy", 8.0, -8.0, 10000, 15, 0.0, false, false, false)
                    Citizen.Wait(1000)
                    DoScreenFadeIn(500)
                    Citizen.Wait(5000)
                
                    DoScreenFadeOut(700)
                    Citizen.Wait(1000)
                    FreezeEntityPosition(ped, false)
                    
		            ClearPedTasksImmediately(ped)
		            ClearPedTasksImmediately(npc)
                    
                    TaskWanderStandard(npc,10.0,10)
                    RemoveBlip(blips)
                    Citizen.Wait(1000)
                    TriggerServerEvent('Safeguard:pointObserved')
                    DoScreenFadeIn(500)
                    TriggerServerEvent('Safeguard:incidents')

                    exports['okokNotify']:Alert('Salva-Vidas', "Novo local marcado em seu GPS.", 5000, 'safeguardS')


                    step = 1
                end

            end
        end
        Citizen.Wait(idle)
    end
end)
----------------------------------------------------------------------------------------
--TEXT FUNCTIONS
----------------------------------------------------------------------------------------

function DrawText3D(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.20, 0.20)
    SetTextFont(8)
    SetTextOutline()
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
end

function DrawTextEmoji(x,y,z,text)
    local onScreen,_x,_y = World3dToScreen2d(x,y,z)

    SetTextFont(4)
    SetTextScale(0.65,0.65)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
end

----------------------------------------------------------------------------------------
--NPC FUNCTIONS
----------------------------------------------------------------------------------------

function createNpcSafeguard()
    local npc_safeguard = "s_f_y_baywatch_01"
    RequestModel(npc_safeguard)
    while not HasModelLoaded(npc_safeguard) do
        Citizen.Wait(100)
    end
    npcSafe = CreatePed(1, npc_safeguard, -1482.82, -1029.91, 6.14-1.0, 231.68, false, true)
    FreezeEntityPosition(npcSafe, true)
    SetEntityInvincible(npcSafe, true)
    SetBlockingOfNonTemporaryEvents(npcSafe, true)
    RequestAnimDict("anim@heists@heist_corona@single_team")
    RequestAnimSet("single_team_loop_boss")
    TaskPlayAnim(npcSafe, "anim@heists@heist_corona@single_team", "single_team_loop_boss", 8.0, 8.0, -1, 1, 0.0, false, false, false)


    if not working then

        -- startTarget = interact.addLocalEntity({
        --     id = "safeguardStart",
        --     entity = npcSafe,  -- Example entity handle
        --     offset = vec3(0.0,0.0,0.35),
        --     options = {
        --         {
        --             text = "Iniciar trabalho",
        --             icon = "life-ring",  -- Example simple FA icon name
        --             event = "safe:startJob",
        --             canInteract = function(entity, distance, coords, id)
        --                 return distance < 2.0
        --             end
        --         }
        --     },
        --     renderDistance = 2.5,
        --     activeDistance = 2.0,
        --     cooldown = 1500
        -- })

        exports['qb-target']:AddBoxZone("safeguardStart", vector3(-1482.82, -1029.91, 6.14), 0.5, 0.7, {
            name="safeguardStart",
            heading=318,
            debugPoly=false,
        }, {
            options = {
                {
                    event = "safe:startJob",
                    icon = "far fa-clipboard",
                    label = "Iniciar trabalho",
                },
            },
            distance = 1.5
        })
    else

        -- finishTarget = interact.addLocalEntity({
        --     id = "safeguardFinish",
        --     entity = npcSafe,  -- Example entity handle
        --     offset = vec3(0.0,0.0,0.35),
        --     options = {
        --         {
        --             text = "Finalizar trabalho",
        --             icon = "life-ring",  -- Example simple FA icon name
        --             event = "safe:cancel",
        --             canInteract = function(entity, distance, coords, id)
        --                 return distance < 2.0
        --             end
        --         }
        --     },
        --     renderDistance = 2.5,
        --     activeDistance = 2.0,
        --     cooldown = 1500
        -- })

        exports['qb-target']:AddBoxZone("safeguardFinish", vector3(-1482.82, -1029.91, 6.14), 0.5, 0.7, {
            name = "safeguardFinish",
            heading=318,
            debugPoly=false,
        }, {
            options = {
                {
                    event = "safe:cancel",
                    icon = "far fa-clipboard",
                    label = "Finalizar trabalho",
                },
            },
            distance = 1.5
        })
    end
end

function hello()
    loadAnim('gestures@f@standing@casual')
	TaskPlayAnim(npcSafe, "gestures@f@standing@casual", "gesture_bye_soft", 8.0, 8.0, -1, 0, 10, 0, 0, 0)
end

function createNpcDrowning()
    local npc_drowning = {"a_f_m_beach_01", "a_f_m_bodybuild_01", "a_f_m_fatcult_01", "a_f_y_beach_01", "a_f_y_topless_01", "a_m_m_beach_02", "a_m_y_beach_03", "a_m_y_jetski_01"}
    repeat
        local random_ped = math.random(1, #npc_drowning)
        npc = CreatePed(1, npc_drowning[random_ped] ,-1664.94, -1081.23, 1.69, 231.68, true,true)
        Wait(100)
    until npc ~= 0 and npc ~= nil
    
    
    if npc then
        Wait(100)
        SetEntityCanBeDamaged(npc, false)
        SetBlockingOfNonTemporaryEvents(npc, true)
        SetEntityInvincible(npc, true)
        SetPedDiesInWater(npc,false)
        
        TaskWanderInArea(npc,config.drownings[point][1], config.drownings[point][2], config.drownings[point][3],2.0,2,10)
        
        Wait(100)
        SetEntityCoords(npc,config.drownings[point][1], config.drownings[point][2], config.drownings[point][3])
    end
end

----------------------------------------------------------------------------------------
--BLIP FUNCTIONS
----------------------------------------------------------------------------------------

function blipmapa()
	blips = AddBlipForCoord(config.locs[point][1],config.locs[point][2],config.locs[point][3])
	SetBlipSprite(blips,472)
	SetBlipColour(blips,1)
	SetBlipScale(blips,0.8)
	SetBlipAsShortRange(blips,false)
	SetBlipRoute(blips,true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Base")
	EndTextCommandSetBlipName(blips)
end

function blipIncident(npc)
    local x,y,z = table.unpack(GetEntityCoords(npc))
	blips = AddBlipForCoord(x,y,z)
	SetBlipSprite(blips,280)
	SetBlipColour(blips,1)
	SetBlipScale(blips,0.8)
	SetBlipAsShortRange(blips,false)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Ocorrência!")
	EndTextCommandSetBlipName(blips)
end

function blipsv()
	blipssv = AddBlipForCoord(-1483.0, -1029.8, 6.14)
	SetBlipSprite(blipssv,512)
	SetBlipColour(blipssv,1)
	SetBlipScale(blipssv,0.65)
	SetBlipAsShortRange(blipssv,true)
	SetBlipRoute(blipssv,false)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Salva Vidas")
	EndTextCommandSetBlipName(blipssv)
end
----------------------------------------------------------------------------------------
--VEHICLE FUNCTIONS
----------------------------------------------------------------------------------------

function createVehicle(name,x,y,z,h)
	local mhash = GetHashKey(name)
	while not HasModelLoaded(mhash) do
		RequestModel(mhash)
		Citizen.Wait(10)
	end 
	
	if HasModelLoaded(mhash) then
		local checkPos = GetClosestVehicle(x,y,z,h,0,71)
		if DoesEntityExist(checkPos) and checkPos ~= nil then
            exports['okokNotify']:Alert('Salva-Vidas', "Todas as vagas estão ocupadas no momento.", 5000, 'safeguardN')

			return false
		else	
			local nveh = CreateVehicle(mhash,x,y,z,229.9898223877,true,true)

            TriggerEvent('vehiclekeys:client:givekeyclient', GetVehicleNumberPlateText(nveh),name)
            SetVehicleFuelLevel(nveh, 100.0)
			return nveh
		end
	end
end
----------------------------------------------------------------------------------------
--NUI NPC EVENTS
----------------------------------------------------------------------------------------

RegisterNetEvent("safe:startJob", function()
    hello()
	SetTimeout(1500, function()
		TaskPlayAnim(npc, "anim@heists@heist_corona@single_team", "single_team_loop_boss", 8.0, 8.0, -1, 1, 10, 0, 0, 0)
	end)


    car = createVehicle('blazer2',-1480.03, -1033.39, 5.99,2.502)
    working = true
    step = 1

    exports['qb-target']:RemoveZone('safeguardStart')
    -- interact.removeById(startTarget)

    -- finishTarget = interact.addLocalEntity({
    --     id = "safeguardFinish",
    --     entity = npcSafe,  -- Example entity handle
    --     offset = vec3(0.0,0.0,0.35),
    --     options = {
    --         {
    --             text = "Finalizar trabalho",
    --             icon = "life-ring",  -- Example simple FA icon name
    --             event = "safe:cancel",
    --             canInteract = function(entity, distance, coords, id)
    --                 return distance < 2.0
    --             end
    --         }
    --     },
    --     renderDistance = 2.5,
    --     activeDistance = 2.0,
    --     cooldown = 1500
    -- })

    exports['qb-target']:AddBoxZone("safeguardFinish", vector3(-1482.82, -1029.91, 6.14), 0.5, 0.7, {
        name = "safeguardFinish",
        heading=318,
        debugPoly=false,
    }, {
        options = {
            {
                event = "safe:cancel",
                icon = "far fa-clipboard",
                label = "Finalizar trabalho",
            },
        },
        distance = 1.5
    })
end)

RegisterNetEvent("safe:cancel", function()
    TriggerServerEvent('Safeguard:payment')
	working = false
	RemoveBlip(blips)
    exports['okokNotify']:Alert('Salva-Vidas', "Serviço finalizado.", 5000, 'safeguardN')

	hello()
	SetTimeout(1500, function()
		TaskPlayAnim(npc, "anim@heists@heist_corona@single_team", "single_team_loop_boss", 8.0, 8.0, -1, 1, 10, 0, 0, 0)
	end)

    if DoesEntityExist(car) then
        local model = GetDisplayNameFromVehicleModel(GetEntityModel(car))
        local plate = GetVehicleNumberPlateText(car)
        DeleteVehicle(car)
        exports['qs-vehiclekeys']:RemoveKeys(plate, model)
    end


    -- interact.removeById(finishTarget)
    exports['qb-target']:RemoveZone('safeguardFinish')

    -- startTarget = interact.addLocalEntity({
    --     id = "safeguardStart",
    --     entity = npcSafe,  -- Example entity handle
    --     offset = vec3(0.0,0.0,0.35),
    --     options = {
    --         {
    --             text = "Iniciar trabalho",
    --             icon = "life-ring",  -- Example simple FA icon name
    --             event = "safe:startJob",
    --             canInteract = function(entity, distance, coords, id)
    --                 return distance < 2.0
    --             end
    --         }
    --     },
    --     renderDistance = 2.5,
    --     activeDistance = 2.0,
    --     cooldown = 1500
    -- })

    exports['qb-target']:AddBoxZone("safeguardStart", vector3(-1482.82, -1029.91, 6.14), 0.5, 0.7, {
        name="safeguardStart",
        heading=318,
        debugPoly=false,
    }, {
        options = {
            {
                event = "safe:startJob",
                icon = "far fa-clipboard",
                label = "Iniciar trabalho",
            },
        },
        distance = 1.5
    })
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then

        if DoesEntityExist(car) then
            local model = GetDisplayNameFromVehicleModel(GetEntityModel(car))
            local plate = GetVehicleNumberPlateText(car)
            DeleteVehicle(car)
            exports['qs-vehiclekeys']:RemoveKeys(plate, model)
        end
        
        ClearPedTasksImmediately(npc)
        DetachEntity(npc,true,true)
        TaskWanderStandard(npc,10.0,10)
        exports['qb-target']:RemoveZone('safeguardStart')
        exports['qb-target']:RemoveZone('safeguardFinish')
        -- interact.removeById(startTarget)
        -- interact.removeById(finishTarget)
    end
end)

local AnimVars = { nil,nil,false,49 }

function createObjects(Dict,Anim,Prop,Flag,Hands,Height,Pos1,Pos2,Pos3,Pos4,Pos5)
	local Ped = PlayerPedId()
	if DoesEntityExist(Object) then
        DeleteEntity(Object)
		Object = nil
	end

	if Anim ~= "" then
        loadAnim(Dict) 
        TaskPlayAnim(Ped,Dict,Anim,8.0,8.0,-1,Flag,0,0,0,0)

		AnimVars[4] = Flag
		AnimVars[3] = true
		AnimVars[1] = Dict
		AnimVars[2] = Anim
	end

	if not IsPedInAnyVehicle(Ped) then
		local Coords = GetEntityCoords(Ped)
        local spawnObjects = 0
        local hash = GetHashKey(Prop)
        Object = CreateObject(hash, Coords["x"],Coords["y"],Coords["z"], true, true, false)

        while not DoesEntityExist(Object) and spawnObjects <= 1000 do
            spawnObjects = spawnObjects + 1
            Wait(1)
        end

		if Height then
			AttachEntityToEntity(Object,Ped,GetPedBoneIndex(Ped,Hands),Height,Pos1,Pos2,Pos3,Pos4,Pos5,true,true,false,true,1,true)
		else
			AttachEntityToEntity(Object,Ped,GetPedBoneIndex(Ped,Hands),0.0,0.0,0.0,0.0,0.0,0.0,false,false,false,false,2,true)
		end
		SetModelAsNoLongerNeeded(Prop)
	end
end

function loadAnim(dict) 
    RequestAnimDict(dict)

    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(100)
    end
end