
-- Created by Xsticcy --
-- Version: 2021 | 15 Dec --

local DataStoreService = game:GetService("DataStoreService")
local DataStore = DataStoreService:GetDataStore("NatureStore")
local Players = game.Players
local Template = {}
local WidesDataStore = DataStoreService:GetDataStore("NatureStore_Wide")
local BackupDataStore = DataStoreService:GetDataStore("NatureStore_Backups")
local OrderedPlayersDataStore = DataStoreService:GetOrderedDataStore("NatureStore_OrderedPlayers")

local saveOnLeave = true

local NatureStore = {}

NatureStore.SUCCESS = "NS_SUCCESS"
NatureStore.ERROR = "NS_ERROR"

local playerData = {}
local wideTemplate = {}

game:BindToClose(function()
	wait(1)
end)

game.Players.PlayerRemoving:Connect(function(plr)
	if not saveOnLeave then return end
	NatureStore:ApplyPlayerData(plr.UserId)
end)

function NatureStore:DisableSaveOnLeave()
	saveOnLeave = false
end

function NatureStore:EnableSaveOnLeave()
	saveOnLeave = true
end

function NatureStore:SetTemplate(Data : table)
	Template = Data
end

function NatureStore:SetPlayerData(plr, Data : table)
	if playerData[plr] == nil then
		playerData[plr] = Template
	end
	local newData = Template
	for k, v in pairs(Data) do
		if newData[k] == nil then
			warn("[NatureStore Error] Attempt to save a key that doesn't exist in the template!")
			return NatureStore.ERROR
		end
		newData[k] = Data[k]
	end
	playerData[plr] = newData
	return NatureStore.SUCCESS
end

function NatureStore:SetPlayerDataKey(plr,key,value)
	if playerData[plr] == nil then
		playerData[plr] = Template
	end
	local newData = playerData[plr]
	newData[key] = value
	
	playerData[plr] = newData
	return NatureStore.SUCCESS
end

function NatureStore:IncrementData(plr, Key, Value)
	if Value == nil then Value = 1 end
	if not playerData[plr] then
		NatureStore:Get(plr)
	end
	if Key == nil or Key == "" then return NatureStore.ERROR end
	playerData[plr][Key] = playerData[plr][Key] + Value
end

function NatureStore:ApplyAll()
	local msg = NatureStore.SUCCESS
	for _, plr : Player in pairs(Players:GetPlayers()) do
		msg = NatureStore:ApplyPlayerData(plr.UserId)
	end
	return msg
end

function NatureStore:ApplyPlayerData(plr)
	if not typeof(plr) == "number" then return NatureStore.ERROR end
	local s,e = pcall(function()
		DataStore:SetAsync(plr, playerData[plr])
		BackupDataStore:SetAsync(plr, 1)
	end)
	if not s then
		warn("[NatureStore Error] Can't save data due to an issue!")
		return e
	else
		OrderedPlayersDataStore:SetAsync(plr, 1)
	end
	return NatureStore.SUCCESS
end

function NatureStore:DoAutosave(Time)
	if not Time or Time < 7 then
		Time = 7
	end
	spawn(function()
		while true do
			NatureStore:ApplyAll()
			task.wait(Time)
		end
	end)
end

function NatureStore:Get(plr)
	if playerData[plr] == nil then
		playerData[plr] = Template
	end
	local v
	local s,_ = pcall(function()
		v = DataStore:GetAsync(plr)
	end)
	if v == nil then
		local vb
		local s,_ = pcall(function()
			vb = BackupDataStore:GetAsync(plr)
		end)
		if not s then
			return {
				Message = NatureStore.ERROR,
				Value = Template
			}
		end
		return {
			Message = NatureStore.SUCCESS,
			Value = vb
		}
	end
	if not s then
		return {
			Message = NatureStore.ERROR,
			Value = Template
		}
	end
	playerData[plr] = v
	return {
		Message = NatureStore.SUCCESS,
		Value = v
	}
end

function NatureStore:GetLocalData(plr)
	return playerData[plr]
end

function NatureStore:GetAllLocalData()
	return playerData
end

function NatureStore:GetAllPlayersWithSavedData()
	local data = {}
	local success, pages = pcall(function()
		return OrderedPlayersDataStore:GetSortedAsync(false, 3)
	end)
	if success then
		while true do
			local entries = pages:GetCurrentPage()
			for _,entry in pairs(entries) do
				table.insert(data, entry.key)
			end
			if pages.IsFinished then
				break
			else
				pages:AdvanceToNextPageAsync()
			end
		end
	end
	return data
end

function NatureStore:RemoveData(plr)
	playerData[plr] = nil
end

function NatureStore:LeaderboardData(plr)
	local ls
	if not plr:FindFirstChild("leaderstats") then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = plr
	else
		ls = plr.leaderstats
	end
	for k, val in pairs(playerData[plr]) do
		local v
		if typeof(v) == "number" then
			v = Instance.new("NumberValue")
		end
		if typeof(v) == "boolean" then
			v = Instance.new("BoolValue")
		end
		if typeof(v) == "string" then
			v = Instance.new("StringValue")
		end
		if v then
			v.Value = val
			v.Parent = ls
		end
	end
end

function NatureStore:GetAll()
	local data = {}
	for _, plr in pairs(game.Players:GetPlayers()) do
		table.insert(data, NatureStore:Get(plr.UserId))
	end
	return data
end

function NatureStore:AutoLeaderboard(freq)
	if not freq then freq = 1 end
	spawn(function()
		while true do
			for _, plr in pairs(game.Players:GetPlayers()) do
				if not playerData[plr.UserId] then
					continue
				end
				local ls
				if not plr:FindFirstChild("leaderstats") then
					ls = Instance.new("Folder")
					ls.Name = "leaderstats"
					ls.Parent = plr
				else
					ls = plr.leaderstats
				end
				for k, val in pairs(playerData[plr.UserId]) do
					local v
					if not ls:FindFirstChild(k) then
						if typeof(val) == "number" then
							v = Instance.new("NumberValue")
						end
						if typeof(val) == "boolean" then
							v = Instance.new("BoolValue")
						end
						if typeof(val) == "string" then
							v = Instance.new("StringValue")
						end
					else
						v = ls[k]
					end
					if v then
						v.Value = val
						v.Name = k
						v.Parent = ls
					end
				end
			end
			task.wait(freq)
		end
	end)
end

function NatureStore:SetWideTemplate(Key, template)
	wideTemplate[Key] = template
end

function NatureStore:SetWideData(Key, Data)
	local newData = wideTemplate[Key]
	for k, v in pairs(Data) do
		if newData[k] == nil then
			warn("[NatureStore Error] Attempt to save a key that doesn't exist in the template!")
			return NatureStore.ERROR
		end
		newData[k] = Data[k]
	end
	wideTemplate[Key] = newData
	return NatureStore.SUCCESS
end

function NatureStore:GetWideData(Key)
	local v = nil
	local s, e = pcall(function()
		v = WidesDataStore:GetAsync(Key)
	end)
	if v == nil then
		v = wideTemplate[Key]
	end
	wideTemplate[Key] = v
	return {
		Value = v,
		Message = e
	}
end

function NatureStore:ApplyWide(Key)
	WidesDataStore:SetAsync(Key, wideTemplate[Key])
end

function NatureStore:ConvertVec3ToTable(vec3)
	return {X=vec3.X,Y=vec3.Y,Z=vec3.Z}
end
function NatureStore:ConvertTableToVec3(tabl)
	return Vector3.new(tabl.X,tabl.Y,tabl.Z)
end

function NatureStore:ConvertClr3ToTable(clr3)
	return {R=clr3.R,G=clr3.G,B=clr3.B}
end
function NatureStore:ConvertTableToClr3(tabl)
	return Color3.new(tabl.R,tabl.G,tabl.B)
end

return NatureStore
