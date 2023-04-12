-- Created by Xsticcy --
-- Version: 2022 | 12 April --
--!strict
local NatureStore = {}

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local DataStore = DataStoreService:GetDataStore("NatureStore")
local WidesDataStore = DataStoreService:GetDataStore("NatureStore_Wide")
local BackupDataStore = DataStoreService:GetDataStore("NatureStore_Backups")
local OrderedPlayersDataStore = DataStoreService:GetOrderedDataStore("NatureStore_OrderedPlayers")

if RunService:IsServer() then
	NatureStore.SUCCESS = "NS_SUCCESS"
	NatureStore.ERROR = "NS_ERROR"

	local playerData = {}
	local wideTemplate = {}
	local Template = {}

	local saveOnLeave = true
	local OnBindToClose = false

	game:BindToClose(function()
		OnBindToClose = true
		task.spawn(function()
			while (OnBindToClose) do
				task.wait(1)
			end
		end)
		self:ApplyAll()
	end)

	Players.PlayerRemoving:Connect(function(plr)
		if not saveOnLeave then
			return
		end
		self:ApplyPlayerData(plr.UserId)
	end)

	function NatureStore:DisableSaveOnLeave()
		saveOnLeave = false
	end

	function NatureStore:EnableSaveOnLeave()
		saveOnLeave = true
	end

	function NatureStore:SetTemplate(Data: table)
		assert(typeof(Data) == "table", string.format("Data argument must be a table", typeof(Data)))
		Template = Data
	end

	function NatureStore:SetPlayerData(plr: number, Data: table)
		if not playerData[plr] then
			playerData[plr] = Template
		end
		local newData = Template
		for k, v in pairs(Data) do
			if not newData[k] then
				warn("[NatureStore Error] Attempt to save a key that doesn't exist in the template!")
				return self.ERROR
			end
			newData[k] = Data[k]
		end
		playerData[plr] = newData
		return self.SUCCESS
	end

	function NatureStore:SetPlayerDataKey(plr: number, key: string, value: any)
		if not value then
			return self.ERROR
		end
		if not playerData[plr] then
			playerData[plr] = Template
		end
		local newData = playerData[plr]
		newData[key] = value

		playerData[plr] = newData
		return self.SUCCESS
	end

	function NatureStore:IncrementData(plr: number, Key: string, Value: number)
		if Key == "" or typeof(Key) ~= "string" then
			print(string.format("[IncrementData]: Value argument must be a number got %s", typeof(Key)))
			return self.ERROR
		end
		if not playerData[plr] then
			self:Get(plr)
		end
		if playerData[plr][Key] then
			playerData[plr][Key] += Value
		end
	end

	function NatureStore:ApplyAll()
		for _, plr: number in pairs(Players:GetPlayers()) do
			task.spawn(function()
				self:ApplyPlayerData(plr.UserId)
			end)
		end
		if OnBindToClose then
			OnBindToClose = false
		end
	end

	function NatureStore:ApplyPlayerData(plr: number): string
		if not typeof(plr) == "number" then
			return self.ERROR
		end
		local s, e = pcall(function()
			DataStore:SetAsync(plr, playerData[plr])
			BackupDataStore:SetAsync(plr, 1)
		end)
		if s then
			OrderedPlayersDataStore:SetAsync(plr, 1)
			return self.SUCCESS
		end
		warn("[NatureStore Error] Can't save data due to an issue!")
		return self.ERROR
	end

	function NatureStore:DoAutosave(Time: number): never
		if typeof(Time) ~= "number" or tonumber(Time) < 7 then
			Time = 7
		end
		task.spawn(function()
			while true do
				self:ApplyAll()
				task.wait(Time)
			end
		end)
	end

	function NatureStore:Get(plr: number): { any }
		if playerData[plr] == nil then
			playerData[plr] = Template
		end
		local s, vb = pcall(function()
			return DataStore:GetAsync(plr)
		end)
		if not s then
			local s, vb = pcall(function()
				return BackupDataStore:GetAsync(plr)
			end)
			if not s then
				return {
					Message = self.ERROR,
					Value = Template,
				}
			end
			return {
				Message = self.SUCCESS,
				Value = vb,
			}
		end
		if not s then
			return {
				Message = self.ERROR,
				Value = Template,
			}
		end
		playerData[plr] = v
		return {
			Message = self.SUCCESS,
			Value = v,
		}
	end

	function NatureStore:GetLocalData(plr: number): { any }
		return playerData[plr] or Template
	end

	function NatureStore:GetAllLocalData()
		return playerData
	end

	function NatureStore:GetAllPlayersWithSavedData()
		local data = {}
		local success, pages = pcall(function()
			return OrderedPlayersDataStore:GetSortedAsync(false, 3)
		end)
		if success and pages then
			while true do
				local entries = pages:GetCurrentPage()
				for _, entry in pairs(entries) do
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

	function NatureStore:RemoveData(plr: number)
		if playerData[plr] then
			playerData[plr] = nil
		end
	end

	function NatureStore:LeaderboardData(plr: Player)
		if plr and playerData[plr.UserId] then
			local ls
			if not plr:FindFirstChild("leaderstats") then
				ls = Instance.new("Folder", plr)
				ls.Name = "leaderstats"
			else
				ls = plr.leaderstats
			end
			for k, val in pairs(playerData[plr.UserId]) do
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
	end

	function NatureStore:GetAll(): { [any]: any }
		local data = {}
		for _, plr in pairs(Players:GetPlayers()) do
			table.insert(data, self:Get(plr.UserId))
		end
		return data
	end

	function NatureStore:AutoLeaderboard(freq: number)
		if typeof(freq) ~= "number" or tonumber(freq) < 1 then
			freq = 1
		end
		task.spawn(function()
			while true do
				for _, plr in pairs(Players:GetPlayers()) do
					if not playerData[plr.UserId] then
						continue
					end
					local ls
					if not plr:FindFirstChild("leaderstats") then
						ls = Instance.new("Folder", plr)
						ls.Name = "leaderstats"
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

	function NatureStore:SetWideTemplate(Key: string, template: table)
		wideTemplate[Key] = template
	end

	function NatureStore:SetWideData(Key: string, Data: table): string
		local newData = wideTemplate[Key]
		for k, v in pairs(Data) do
			if not newData[k] then
				warn("[NatureStore Error] Attempt to save a key that doesn't exist in the template!")
				return self.ERROR
			end
			newData[k] = Data[k]
		end
		wideTemplate[Key] = newData
		return self.SUCCESS
	end

	function NatureStore:GetWideData(Key: string): { any }
		local s, e = pcall(function()
			return WidesDataStore:GetAsync(Key)
		end)
		if not s then
			v = wideTemplate[Key]
			print(string.format("Failed to get key:%s data", Key))
		end
		wideTemplate[Key] = v
		return {
			Value = v,
			Message = e,
		}
	end

	function NatureStore:ApplyWide(Key: string)
		WidesDataStore:SetAsync(Key, wideTemplate[Key])
	end
end

function NatureStore:ConvertVec3ToTable(vec3: Vector3)
	return { X = vec3.X, Y = vec3.Y, Z = vec3.Z }
end
function NatureStore:ConvertTableToVec3(tabl: table)
	return Vector3.new(tabl.X, tabl.Y, tabl.Z)
end

function NatureStore:ConvertClr3ToTable(clr3: Color3)
	return { R = clr3.R, G = clr3.G, B = clr3.B }
end
function NatureStore:ConvertTableToClr3(tabl: table)
	return Color3.new(tabl.R, tabl.G, tabl.B)
end

return table.freeze(NatureStore)
