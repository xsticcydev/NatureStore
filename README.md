# NatureStore
### Datastores made easy!
_________
Hello developers! I would like to introduce NatureStore.
NatureStore is a datastore module for Roblox. It's mainly made for intermediate developers, not specifically for beginners.

Example code (please read the comments too!):

```lua
local NatureStore = require(game.ServerStorage.NatureStore) -- Require NatureStore, I suggest to put it in ServerStorage

NatureStore:SetTemplate({
	Coins = 0;
	Time = 0;
	Rank = "Noob";
}) -- We *must* create a template. These are the things we want to save for every player. In that case, it's Coins, Time and Rank
--[[ You can set default values in the template. If the player doesn't have saved data yet, those values are automatically
     going to be applied (in this case, it's zero for both)]]

NatureStore:AutoLeaderboard() -- Automatically displayes loaded data on a leaderboard

game.Players.PlayerAdded:Connect(function(plr)
	
	NatureStore:Get(plr.UserId) -- Load the player's data (you must use UserId!)
	
	plr.Chatted:Connect(function(msg)
		if msg == "yes" then -- If a player says "yes" we give them five coins
			NatureStore:IncrementData(plr.UserId, "Coins", 5) -- Here we increment the Coins of our player by 5
		end
	end)
	
	spawn(function()
		while wait(1) do
			NatureStore:IncrementData(plr.UserId, "Time", 1) -- Here we increment the Time of our player by 1
		end
	end)
	
	--NatureStore automatically saves data when the player leaves, but you can save data of a player manually
	--using the following function:
	NatureStore:ApplyPlayerData(plr.UserId)
	
	--or you can save every player's data, like this:
	NatureStore:ApplyAll()
	
	--If you want to disable autosave just call this function:
	NatureStore:DisableSaveOnLeave()
	
end)
```

_________
# API:
```lua
NatureStore:DisableSaveOnLeave()
```
Disables the autosave feature.
____
```lua 
NatureStore:EnableSaveOnLeave()
```
Enables the autosave feature.
____
```lua
NatureStore:SetTemplate(Data:table)
```
Use this to set a template. Call it only once!
____
```lua
NatureStore:SetPlayerData(UserId:number, Data:table)
```
Change data of a player locally. If you don't have autosave on, make sure you apply the value!
____
```lua
NatureStore:SetPlayerDataKey(UserId:number, Key:string, Value:any)
```
Change only one key in the player's data locally.
____
```lua
NatureStore:IncrementData(UserId:number, Key:string, Value:any)
```
Increment a key's value by a number in the player's data locally. (you can use negative value to decrease)
____
```lua
NatureStore:ApplyAll()
```
Applies every player's data who are in the server.
____
```lua
NatureStore:ApplyPlayerData(UserId:number)
```
Applies a given player's data.
____
```lua
NatureStore:DoAutosave(Time:number)
```
Calls ```NatureStoreApplyAll()``` every ```x``` seconds. The minimum time is 7 seconds.
____
```lua
NatureStore:Get(UserId:number)
```
Loads, and returns the data of a player and a message.
Example:
```lua
local data = NatureStore:Get(player.UserId)
local value = data.Value
local message = data.Message
local coins = value.Coins

print(coins, message)
```
____
```lua
NatureStore:GetAll()
```
Loads, and returns the data of every player on the server and a message.
____
```lua
NatureStore:GetLocalData(UserId:number)
```
Same as ```NatureStore:Get```, but it returns the local data, not from the datastore.
____
```lua
NatureStore:GetAllLocalData()
```
Returns every player's local data, who are in the server.
____
```lua
NatureStore:GetAllPlayersWithSavedData()
```
**This function can return very long tables, use it at your own risk!**
Returns every player's UserId, who has a saved data.
____
```lua
NatureStore:RemoveData(UserId:number)
```
Removes a player's data locally. Make sure to apply using ```NatureStore:ApplyPlayerData``` or ```NatureStore:ApplyAll```!
____
```lua
NatureStore:LeaderboardData(UserId:number)
```
Displays a specific player's data on the leaderboard. It's made for debugging, but you can use it in any situation.
____
```lua
NatureStore:AutoLeaderboard(Time:number)
```
Displays a every player's data on the leaderboard. It also updates the leaderboard every ```x``` seconds. Default update rate it 1 second.
____
```lua
NatureStore:SetWideTemplate(Key:string, template:table)
```
Sets a template for a 'wide' value. Wide values are values, that aren't attached to a player.
The 'Key' parameter is the name of the wide value.
____
```lua
NatureStore:SetWideData(Key:string, Data:table)
```
Changes the value of a wide value locally. You need to apply it to be saved.
____
```lua
NatureStore:GetWideData(Key:string)
```
Works the same as ```NatureStore:Get```, but for wide values.
____
```lua
NatureStore:ApplyWide(Key:string)
```
Works the same as ```NatureStore:ApplyPlayerData```, but for wide values.
____
```lua
NatureStore:ConvertVec3ToTable(vec3:Vector3)
```
Converts a Vector3 to a table. (Example: Vector3.new(1,2,3) -> {X=1,Y=2,Z=3})
You can use this if you want to save Vector3 values.
____
```lua
NatureStore:ConvertTableToVec3(table:table)
```
Converts a table to Vector3. (Example: {X=1,Y=2,Z=3} -> Vector3.new(1,2,3))
You can use this if you have a Vector3 data saved with ```NatureStore:ConvertVec3ToTable(vec3:Vector3)```.
____
```lua
NatureStore:ConvertClr3ToTable(clr3:Color3)
```
The same as ```NatureStore:ConvertVec3ToTable(vec3:Vector3)```, but for Color3.
____
```lua
NatureStore:ConvertTableToClr3(table:table)
```
The same as ```NatureStore:ConvertTableToVec3(table:table)```, but for Color3.
