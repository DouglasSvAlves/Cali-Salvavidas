QBCore = nil
local QBCore = exports['qb-core']:GetCoreObject()

local points = {}
local points_incident = {}

function getPlayerIdentifier(src)
    local player = QBCore.Functions.GetPlayer(source)
    local identifier = player.PlayerData.citizenid
    return identifier
end

RegisterNetEvent('Safeguard:setPlayerObserve',function()
	local source = source
    local identifier = getPlayerIdentifier(source)
	if points[identifier] == nil then
		points[identifier] = 0
	end
end)

RegisterNetEvent('Safeguard:setPlayerIncident',function()
	local source = source
    local identifier = getPlayerIdentifier(source)
	if points_incident[identifier] == nil then
		points_incident[identifier] = 0
	end
end)

RegisterNetEvent('Safeguard:pointObserved',function()
	local source = source
    local identifier = getPlayerIdentifier(source)
	points[identifier] = points[identifier] + 1
end)

RegisterNetEvent('Safeguard:incidents',function()
	local source = source
    local identifier = getPlayerIdentifier(source)
	points_incident[identifier] = points_incident[identifier] + 1
end)

RegisterNetEvent('Safeguard:payment',function()
	local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    local identifier = Player.PlayerData.citizenid
    if points[identifier] <= 0 then
        return
    end
    local payment = math.random(config.payment[1],config.payment[2])*points[identifier]
    local payment2 = 0
    if points_incident[identifier] ~= nil then
        payment2 = math.random(config.payment_incident[1],config.payment_incident[2])*points_incident[identifier]
    end
    local total = payment + payment2
    total = getValueReward(total,0.05,false,source)
    if identifier then
		if points[identifier] ~= 0 then
            Player.Functions.AddMoney('cash', total)

            if points_incident[identifier] ~= 0 and points_incident[identifier] ~= nil then
                TriggerClientEvent('okokNotify:Alert', source,"Salva-Vidas", "| <b>Pagamento Efetuado!</b> |<br> Pontos observados: <b>"..points[identifier].."</b>,<br>Ocorrências realizadas: <b>"..points_incident[identifier].."</b>, <br>Ganhos: <b>R$"..total.."</b>.",5000,'safeguardS') 
            else
                TriggerClientEvent('okokNotify:Alert', source,"Salva-Vidas", "| <b>Pagamento Efetuado!</b> |<br> Pontos observados: <b>"..points[identifier].."</b>, Ganhos: <b>R$"..total.."</b>.",5000,'safeguardS')
            end
            points[identifier] = nil
            points_incident[identifier] = nil
		end
	end
end)

----------
-- BUFF --
----------
function getValueReward(value,percent,extras,source)
    local QBCore = exports['qb-core']:GetCoreObject()
    if not  IsDuplicityVersion() then
        local promise = promise.new()
        QBCore.Functions.TriggerCallback('Cali-Vips:Server:CheckVips', function(result)
            if result == true then
                if type(value) ~= 'table' then
                    price = value + (value * percent)
                else
                    price = {}
                    for i = 1, #value do
                        price[i] = value[i] + (value[i] * percent)
                    end
                end
            else
                if type(value) ~= 'table' then
                    price = value + (value * percent)
                else
                    price = {}
                    for i = 1, #value do
                        price[i] = value[i]
                    end
                end
            end

            if extras then
                extras(price)
            end
            promise:resolve(price)
        end)
        return Citizen.Await(promise)
    else
        if source then
            local promise = promise.new()
            QBCore.Functions.TriggerCallback('Cali-Vips:Server:CheckVips', source,function(result)
                if result == true then
                    if type(value) ~= 'table' then
                        price = value + (value * percent)
                    else
                        price = {}
                        for i = 1, #value do
                            price[i] = value[i] + (value[i] * percent)
                        end
                    end
                else
                    if type(value) ~= 'table' then
                        price = value + (value * percent)
                    else
                        price = {}
                        for i = 1, #value do
                            price[i] = value[i]
                        end
                    end
                end
    
                if extras then
                    extras(price)
                end
                promise:resolve(price)
            end)
            return Citizen.Await(promise)
        else
            if type(value) ~= 'table' then
                price = value
            else
                price = {}
                for i = 1, #value do
                    price[i] = value[i]
                end
            end
            return price
        end
    end
end