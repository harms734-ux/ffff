-- Tony's Weapon Trader - Enhanced Script v2.1
-- Filters: no icons, underslung weapons, duplicate weapons (named variants)

-- ============================
-- GLOBALE VARIABLEN
-- ============================
g_TonyCurrentInventory = {}
g_TonyLastWeek = 0
-- use the player's real money value; fall back to 0 safely at load time
g_TonyPlayerMoney = g_Player_Cash_Amount or 0

-- ============================
-- KATEGORIE-DEFINITIONEN
-- ============================

local TonyCategoryDefinitions = {
	{name = "Assault Rifles", priority = 1, check = function(item) 
		return (item.WeaponType and item.WeaponType == "AssaultRifle") or IsKindOf(item, "AssaultRifle")
	end},
	{name = "Sniper Rifles", priority = 2, check = function(item) 
		return (item.WeaponType and item.WeaponType == "SniperRifle") or IsKindOf(item, "SniperRifle")
	end},
	{name = "Submachine Guns", priority = 3, check = function(item) 
		return (item.WeaponType and item.WeaponType == "SubmachineGun") or IsKindOf(item, "SubmachineGun")
	end},
	{name = "Machine Guns", priority = 4, check = function(item) 
		return (item.WeaponType and item.WeaponType == "MachineGun") or IsKindOf(item, "MachineGun")
	end},
	{name = "Shotguns", priority = 5, check = function(item) 
		return (item.WeaponType and item.WeaponType == "Shotgun") or IsKindOf(item, "Shotgun")
	end},
	{name = "Pistols & Revolvers", priority = 6, check = function(item) 
		return (item.WeaponType and (item.WeaponType == "Pistol" or item.WeaponType == "Revolver")) or
		       IsKindOf(item, "Pistol") or IsKindOf(item, "Revolver")
	end},
	{name = "Heavy Weapons", priority = 7, check = function(item) 
		return (item.WeaponType and item.WeaponType == "HeavyWeapon") or
		       IsKindOf(item, "HeavyWeapon") or IsKindOf(item, "FlareGun")
	end},
	{name = "Body Armor", priority = 8, check = function(item) 
		return IsKindOf(item, "Armor") or IsKindOf(item, "BodyArmor")
	end},
	{name = "Helmets", priority = 9, check = function(item) 
		return IsKindOf(item, "Head") or IsKindOf(item, "Helmet")
	end},
	{name = "Grenades", priority = 10, check = function(item) 
		return IsKindOf(item, "Grenade") or IsKindOf(item, "ThrowableTrapItem")
	end},
	{name = "Ammo - 7.62mm", priority = 11, check = function(item) 
		return IsKindOf(item, "Ammo") and item.Caliber and (item.Caliber == "762NATO" or item.Caliber == "762WP")
	end},
	{name = "Ammo - 5.56mm", priority = 12, check = function(item) 
		return IsKindOf(item, "Ammo") and item.Caliber and item.Caliber == "556"
	end},
	{name = "Ammo - 9mm", priority = 13, check = function(item) 
		return IsKindOf(item, "Ammo") and item.Caliber and item.Caliber == "9mm"
	end},
	{name = "Ammo - .45 ACP", priority = 14, check = function(item) 
		return IsKindOf(item, "Ammo") and item.Caliber and item.Caliber == "45ACP"
	end},
	{name = "Ammo - .44 CAL", priority = 15, check = function(item) 
		return IsKindOf(item, "Ammo") and item.Caliber and item.Caliber == "44CAL"
	end},
	{name = "Ammo - 12 Gauge", priority = 16, check = function(item) 
		return IsKindOf(item, "Ammo") and item.Caliber and item.Caliber == "12gauge"
	end},
	{name = "Ammo - .50 BMG", priority = 17, check = function(item) 
		return IsKindOf(item, "Ammo") and item.Caliber and item.Caliber == "50BMG"
	end},
	{name = "Ammo - 30-06", priority = 18, check = function(item) 
		return IsKindOf(item, "Ammo") and item.Caliber and item.Caliber == "3006"
	end},
	{name = "Ammo - Other", priority = 19, check = function(item) 
		return IsKindOf(item, "Ammo")
	end},
	{name = "Ordnance", priority = 20, check = function(item) 
		return IsKindOf(item, "Ordnance")
	end},
	{name = "Medicine", priority = 21, check = function(item) 
		return IsKindOf(item, "Medicine")
	end},
	{name = "Tool Kits", priority = 22, check = function(item) 
		return IsKindOf(item, "RepairKit") or IsKindOf(item, "ExplosivesKit")
	end},
	{name = "Misc Items", priority = 99, check = function(item) 
		return true
	end},
}

local function TonyCalculateItemPrice(item, itemClass)
	local basePrice = 500
	
	if item.Cost then
		basePrice = item.Cost * 1.5
	end
	
	if IsKindOf(item, "AssaultRifle") then
		basePrice = math.max(basePrice, 1500)
	elseif IsKindOf(item, "SniperRifle") then
		basePrice = math.max(basePrice, 3000)
	elseif IsKindOf(item, "MachineGun") then
		basePrice = math.max(basePrice, 3000)
	elseif IsKindOf(item, "Shotgun") then
		basePrice = math.max(basePrice, 1000)
	elseif IsKindOf(item, "SubmachineGun") then
		basePrice = math.max(basePrice, 1200)
	elseif IsKindOf(item, "Pistol") or IsKindOf(item, "Revolver") then
		basePrice = math.max(basePrice, 400)
	elseif IsKindOf(item, "HeavyWeapon") then
		basePrice = math.max(basePrice, 4000)
	elseif IsKindOf(item, "Armor") or IsKindOf(item, "BodyArmor") then
		basePrice = math.max(basePrice, 800)
	elseif IsKindOf(item, "Head") or IsKindOf(item, "Helmet") then
		basePrice = math.max(basePrice, 600)
	elseif IsKindOf(item, "Grenade") then
		basePrice = math.max(basePrice, 100)
	elseif IsKindOf(item, "Ammo") then
		basePrice = math.max(basePrice, 30)
		if item.MaxStacks and item.MaxStacks > 1 then
			basePrice = basePrice / 2
		end
	elseif IsKindOf(item, "Ordnance") then
		basePrice = math.max(basePrice, 150)
	elseif IsKindOf(item, "Medicine") then
		basePrice = math.max(basePrice, 200)
	elseif IsKindOf(item, "RepairKit") or IsKindOf(item, "ExplosivesKit") then
		basePrice = math.max(basePrice, 300)
	end
	
	return math.floor(basePrice)
end

local function TonyScanAllGameItems()
	print("[Tony Trader] === SCANNE ALLE SPIEL-ITEMS ===")
	
	local discoveredItems = {}
	local itemCount = 0
	local errorCount = 0
	local skippedNoIcon = 0
	local skippedUnderslung = 0
	local skippedDuplicate = 0
	
	local seenIcons = {}

	-- Explicit blacklist of item IDs that should never appear in Tony's shop
	local bannedItems = {
		SteroidPunchGrenade = true,
		IvanUshanka        = true,
		TexRevolver        = true,
		BrowningM2HMG      = true,
		LionRoar           = true,
		GoldenGun            = true,
		CrocodileHide      = true,
		CorocdileJaws      = true, -- if the actual ID is spelled differently, adjust here
		NailsLeatherVest   = true,
		PostApoHelmet      = true,
		ShapedCharge       = true,
	}
	
	for className, classDef in pairs(g_Classes) do
		if IsKindOf(classDef, "InventoryItem") then

			-- ============================
			-- EARLY EXCLUDES (NO SPAWN)
			-- ============================

			-- 1) exclude anything whose class name contains "_"
			if string.find(className, "_") then
				goto continue
			end

			-- 2) exclude all TransmutedArmor object classes
			if classDef.object_class == "TransmutedArmor" then
				goto continue
			end

			-- 3) exclude specific hardcoded item IDs
			if bannedItems[className] then
				goto continue
			end
			
			-- Now actually spawn the item
			local success, tempItem = pcall(PlaceInventoryItem, className)
			
			if success and tempItem then
				local shouldInclude = false
				
				-- Filter underslung
				if tempItem.SubWeapon or (tempItem.class and string.find(tempItem.class:lower(), "underslung")) then
					skippedUnderslung = skippedUnderslung + 1
					DoneObject(tempItem)
					goto continue
				end

				-- Filter no icon
				if not tempItem.Icon or tempItem.Icon == "" then
					skippedNoIcon = skippedNoIcon + 1
					DoneObject(tempItem)
					goto continue
				end
				
				-- Filter duplicate icons (named weapons)
				if IsKindOf(tempItem, "Firearm") then
					local iconPath = tempItem.Icon
					if seenIcons[iconPath] then
						skippedDuplicate = skippedDuplicate + 1
						DoneObject(tempItem)
						goto continue
					end
					seenIcons[iconPath] = true
				end
				
				-- Include filters
				if IsKindOf(tempItem, "Firearm") and not tempItem.quest_item then
					shouldInclude = true
				end
				
				if IsKindOf(tempItem, "Armor") or IsKindOf(tempItem, "BodyArmor") or 
				   IsKindOf(tempItem, "Head") or IsKindOf(tempItem, "Helmet") then
					shouldInclude = true
				end
				
				if IsKindOf(tempItem, "Ammo") and IsKindOf(tempItem, "InventoryStack") then
					shouldInclude = true
				end
				
				if IsKindOf(tempItem, "Grenade") or IsKindOf(tempItem, "ThrowableTrapItem") then
					shouldInclude = true
				end
				
				if IsKindOf(tempItem, "Ordnance") then
					shouldInclude = true
				end
				
				if IsKindOf(tempItem, "Medicine") then
					shouldInclude = true
				end
				
				if IsKindOf(tempItem, "RepairKit") or IsKindOf(tempItem, "ExplosivesKit") then
					shouldInclude = true
				end
				
				if shouldInclude then
					local category = "Misc Items"
					for _, catDef in ipairs(TonyCategoryDefinitions) do
						if catDef.check(tempItem) then
							category = catDef.name
							break
						end
					end
					
					-- Fixed stack sizes
					local stackSize = nil
					if IsKindOf(tempItem, "InventoryStack") then
						if tempItem.Caliber then
							if tempItem.Caliber == "9mm" then
								stackSize = 30
							elseif tempItem.Caliber == "556" then
								stackSize = 30
							elseif tempItem.Caliber == "762NATO" or tempItem.Caliber == "762WP" then
								stackSize = 30
							elseif tempItem.Caliber == "50BMG" then
								stackSize = 10
							elseif tempItem.Caliber == "12gauge" then
								stackSize = 12
							elseif tempItem.Caliber == "45ACP" then
								stackSize = 30
							elseif tempItem.Caliber == "44CAL" then
								stackSize = 30
							else
								stackSize = 30
							end
						else
							stackSize = 1
						end
					elseif IsKindOf(tempItem, "Ordnance") or IsKindOf(tempItem, "Grenade") or 
					       IsKindOf(tempItem, "Medicine") or IsKindOf(tempItem, "RepairKit") then
						stackSize = 1
					end
					
					-- Display name
					local displayName = tempItem.DisplayName or tempItem.class
					
					if type(displayName) ~= "string" then
						displayName = tostring(displayName)
					end
					
					if tempItem.DisplayName and type(tempItem.DisplayName) == "userdata" then
						local success2, englishText = pcall(TDevModeGetEnglishText, tempItem.DisplayName)
						if success2 and englishText and englishText ~= "" then
							displayName = englishText
						end
					end
					
					if not displayName or displayName == "" then
						displayName = tempItem.class
					end
					
					table.insert(discoveredItems, {
						id = className,
						name = displayName,
						price = TonyCalculateItemPrice(tempItem, className),
						category = category,
						stack = stackSize,
						sortKey = tostring(displayName):lower(),
						isSpacer = false,
					})
					
					itemCount = itemCount + 1
				end
				
				DoneObject(tempItem)
			else
				errorCount = errorCount + 1
			end
		end
		::continue::
	end
	
	print(string.format("[Tony Trader] %d Items gefunden, %d Fehler", itemCount, errorCount))
	print(string.format("[Tony Trader] Gefiltert: %d ohne Icon, %d underslung, %d Duplikate", 
		skippedNoIcon, skippedUnderslung, skippedDuplicate))
	
	-- Sort by category priority then name
	table.sort(discoveredItems, function(a, b)
		local priorityA = 999
		local priorityB = 999
		
		for _, catDef in ipairs(TonyCategoryDefinitions) do
			if catDef.name == a.category then
				priorityA = catDef.priority
			end
			if catDef.name == b.category then
				priorityB = catDef.priority
			end
		end
		
		if priorityA ~= priorityB then
			return priorityA < priorityB
		end
		
		return a.sortKey < b.sortKey
	end)
	
	-- Insert spacers
	local itemsWithSpacers = {}
	local lastCategory = nil
	
	for _, item in ipairs(discoveredItems) do
		if lastCategory and lastCategory ~= item.category then
			table.insert(itemsWithSpacers, {
				id = "SPACER_" .. item.category,
				name = item.category,
				category = item.category,
				isSpacer = true,
			})
		end
		
		table.insert(itemsWithSpacers, item)
		lastCategory = item.category
	end
	
	print(string.format("[Tony Trader] %d EintrÃ¤ge im Inventar (mit Spacern)", #itemsWithSpacers))
	
	local catCounts = {}
	for _, item in ipairs(itemsWithSpacers) do
		if not item.isSpacer then
			catCounts[item.category] = (catCounts[item.category] or 0) + 1
		end
	end
	
	print("[Tony Trader] Kategorien:")
	for cat, count in pairs(catCounts) do
		print(string.format("  - %s: %d Items", cat, count))
	end
	
	return itemsWithSpacers
end



function TonyUpdateInventory()
	local currentWeek = math.floor(Game.CampaignTime / (7 * const.Scale.day))
	
	if g_TonyLastWeek ~= currentWeek or not g_TonyCurrentInventory or #g_TonyCurrentInventory == 0 then
		g_TonyLastWeek = currentWeek
		g_TonyCurrentInventory = TonyScanAllGameItems()
		print(string.format("[Tony Trader] Inventar aktualisiert fÃ¼r Woche %d", currentWeek))
	end
end

function TonyGetInventory()
	if not g_TonyCurrentInventory or #g_TonyCurrentInventory == 0 then
		TonyUpdateInventory()
	end
	return g_TonyCurrentInventory
end

function TonyGetItemIcon(itemId)
	if not itemId then
		return nil
	end
	
	local itemDef = g_Classes[itemId]
	
	if itemDef and itemDef.Icon then
		return itemDef.Icon
	end
	
	local tempItem = PlaceInventoryItem(itemId)
	if tempItem then
		local icon = tempItem.Icon
		DoneObject(tempItem)
		return icon
	end
	
	return nil
end

function OpenTonyTrader(unit)
	print("[Tony Trader] Oeffne Tony's Shop...")
	
	TonyUpdateInventory()
	
	local tradeUnit = unit
	if not tradeUnit then
		tradeUnit = GetInventoryUnit()
	end
	if not tradeUnit then
		tradeUnit = SelectedObj
	end
	
	if not tradeUnit then
		print("[Tony Trader] ERROR: Keine Unit gefunden!")
		CreateRealTimeThread(function()
			CreateMessageBox(
				terminal.desktop,
				T{"Fehler"},
				T{"Keine Unit ausgewÃ¤hlt!"},
				T{"OK"}
			)
		end)
		return
	end
	
	print(string.format("[Tony Trader] Oeffne Shop fÃ¼r Unit: %s", tradeUnit.Nick or tradeUnit.session_id))
	
	local context = {
		unit = tradeUnit
	}
	
	OpenDialog("TonyTraderDialog", nil, context)
end

function TonyBuyItem(itemData, silentMode)
	if not itemData then
		print("[Tony Trader] ERROR: Keine Item-Daten")
		return false
	end
	
	if itemData.isSpacer then
		return false
	end
	
	local price = itemData.price
	local itemId = itemData.id
	
	print("[Tony Trader] =============================")
	print(string.format("[Tony Trader] Starte Kauf: %s fÃ¼r $%d", itemData.name, price))
	
	-- always sync with the player's current money
	local currentMoney = g_Player_Cash_Amount or 0
	g_TonyPlayerMoney = currentMoney

	if currentMoney < price then
		print("[Tony Trader] Nicht genug Geld!")
		CreateRealTimeThread(function()
			CreateMessageBox(
				terminal.desktop,
				T{"Nicht genug Geld"},
				T{string.format("Du brauchst $%d, hast aber nur $%d", price, currentMoney)},
				T{"OK"}
			)
		end)
		return false
	end
	
	CreateRealTimeThread(function()
		local newItem = PlaceInventoryItem(itemId)
		
		if not newItem then
			print("[Tony Trader] ERROR: Item konnte nicht erstellt werden: " .. itemId)
			CreateMessageBox(
				terminal.desktop,
				T{"Fehler"},
				T{string.format("Item '%s' existiert nicht", itemId)},
				T{"OK"}
			)
			return
		end
		
		print("[Tony Trader] Item erstellt: " .. newItem.class)
		
		if itemData.stack and IsKindOf(newItem, "InventoryStack") then
			newItem.Amount = itemData.stack
			print(string.format("[Tony Trader] Stack Menge gesetzt: %d", itemData.stack))
		end
		
		local unit = nil
		local dlg = GetDialog("TonyTraderDialog")
		if dlg and dlg.selected_unit then
			unit = dlg.selected_unit
		end
		
		if not unit then
			unit = GetInventoryUnit()
		end
		
		if not unit then
			unit = SelectedObj
		end
		
		if not unit then
			for squad_id, squad in pairs(gv_Squads) do
				if squad.units and #squad.units > 0 then
					local merc_id = squad.units[1]
					unit = gv_UnitData[merc_id] or g_Units[merc_id]
					if unit then
						break
					end
				end
			end
		end
		
		if not unit then
			print("[Tony Trader] ERROR: Keine Unit gefunden!")
			DoneObject(newItem)
			CreateMessageBox(
				terminal.desktop,
				T{"Fehler"},
				T{"Keine Unit gefunden!"},
				T{"OK"}
			)
			return
		end
		
		print(string.format("[Tony Trader] Unit: %s", unit.Nick or unit.session_id))
		
		local success = false
		local addedTo = "unknown"
		
		local preferSquadBag = IsKindOf(newItem, "SquadBagItem") and not IsKindOf(newItem, "Firearm")
		
		if IsKindOf(newItem, "Armor") or IsKindOf(newItem, "BodyArmor") or IsKindOf(newItem, "Head") then
			preferSquadBag = true
		end
		
		if preferSquadBag and unit.Squad then
			local squad = gv_Squads[unit.Squad]
			if squad then
				local items_to_add = {newItem}
				AddItemsToSquadBag(squad.UniqueId, items_to_add)
				
				if #items_to_add == 0 then
					success = true
					addedTo = "squad bag"
				end
			end
		end
		
		if not success then
			local pos, reason = unit:AddItem("Inventory", newItem)
			if pos then
				success = true
				addedTo = "unit inventory"
			elseif not preferSquadBag and unit.Squad and IsKindOf(newItem, "SquadBagItem") then
				local squad = gv_Squads[unit.Squad]
				if squad then
					local items_to_add = {newItem}
					AddItemsToSquadBag(squad.UniqueId, items_to_add)
					
					if #items_to_add == 0 then
						success = true
						addedTo = "squad bag (fallback)"
					end
				end
			end
		end
		
		if not success then
			local sector_id = gv_CurrentSectorId
			if unit.Squad then
				local squad = gv_Squads[unit.Squad]
				if squad and squad.CurrentSector then
					sector_id = squad.CurrentSector
				end
			end
			
			if sector_id then
				local sectorInv = GetSectorInventory(sector_id)
				
				if sectorInv then
					local stash_pos, stash_reason = sectorInv:AddItem("Inventory", newItem)
					
					if stash_pos then
						success = true
						addedTo = "sector stash"
					end
				end
			end
		end
		
		if not success and not gv_SatelliteView and IsKindOf(unit, "Unit") then
			if unit.GetPos then
				local unit_pos = unit:GetPos()
				
				local drop = PlaceObject("ItemDropContainer")
				if drop then
					drop:SetPos(unit_pos)
					
					local drop_pos, drop_reason = drop:AddItem("Inventory", newItem)
					
					if drop_pos then
						success = true
						addedTo = "ground"
					end
				end
			end
		end
		
		if success then
			-- actually take the money from the player
			local newMoney = (g_Player_Cash_Amount or 0) - price
			if newMoney < 0 then newMoney = 0 end
			g_Player_Cash_Amount = newMoney
			g_TonyPlayerMoney = newMoney
			
			print("[Tony Trader] KAUF ERFOLGREICH!")
			print(string.format("[Tony Trader] Item: %s -> %s", itemData.name, addedTo))
			
			if not silentMode then
				CreateMessageBox(
					terminal.desktop,
					T{"Kauf erfolgreich!"},
					T{string.format("%s gekauft!\n\nHinzugefÃ¼gt zu: %s", itemData.name, addedTo)},
					T{"OK"}
				)
			end
			
			ObjModified(unit)
			if unit.Squad then
				ObjModified(gv_Squads[unit.Squad])
			end
			
			Msg("InventoryChange", unit)
			
			local dlg = GetDialog("TonyTraderDialog")
			if dlg then
				Sleep(400)
				dlg:UpdateMoneyDisplay()
				dlg:RefreshUI()
			end
		else
			DoneObject(newItem)
			print("[Tony Trader] KAUF FEHLGESCHLAGEN!")
			
			if not silentMode then
				CreateMessageBox(
					terminal.desktop,
					T{"Fehler"},
					T{"Item konnte nicht hinzugefÃ¼gt werden!"},
					T{"OK"}
				)
			end
		end
	end)
	
	return true
end

function TonyOpenShop(state)
	print("[Tony Trader] === TonyOpenShop aufgerufen ===")
	
	local unit = nil
	
	if state and state.speaker then
		unit = gv_UnitData[state.speaker] or g_Units[state.speaker]
	end
	
	if not unit and g_CurrentSquad then
		local squad = gv_Squads[g_CurrentSquad]
		if squad and squad.units and #squad.units > 0 then
			local merc_id = squad.units[1]
			unit = gv_UnitData[merc_id] or g_Units[merc_id]
		end
	end
	
	if not unit then
		unit = GetInventoryUnit() or SelectedObj
	end
	
	if not unit then
		for id, u in pairs(gv_UnitData) do
			if u.HireStatus == "Hired" then
				unit = u
				break
			end
		end
	end
	
	if not unit then
		print("[Tony Trader] ERROR: Keine Unit gefunden!")
		CreateRealTimeThread(function()
			CreateMessageBox(
				terminal.desktop,
				T{"Tony Trader Fehler"},
				T{"Keine aktive Unit gefunden!"},
				T{"OK"}
			)
		end)
		return
	end
	
	OpenTonyTrader(unit)
end

function TonyTrade()
	TonyOpenShop(nil)
end

function TonyTradeConversation(self, obj)
	TonyOpenShop(obj)
end

function TestTonyTrader()
	print("[Tony Trader] Test gestartet...")
	local unit = GetInventoryUnit() or SelectedObj
	if not unit then
		print("[Tony Trader] ERROR: Keine Unit zum Testen!")
		return
	end
	OpenTonyTrader(unit)
end

function TonyDebugInventory()
	TonyUpdateInventory()
	print("[Tony Trader] === AKTUELLES INVENTAR ===")
	local currentCat = nil
	for i, item in ipairs(g_TonyCurrentInventory) do
		if item.isSpacer then
			print(string.format("\n--- %s ---", item.name))
			currentCat = item.category
		else
			print(string.format("  %d. %s - $%d%s", 
				i, item.name, item.price, 
				item.stack and (" (x" .. item.stack .. ")") or ""))
		end
	end
	print(string.format("[Tony Trader] Total: %d EintrÃ¤ge", #g_TonyCurrentInventory))
end

print("=======================================")
print("[Tony Trader Mod] Erfolgreich geladen!")
print("[Tony Trader Mod] Version 2.1 - Dynamic + Filters")
print("=======================================")
print("[Tony Trader] VerfÃ¼gbare Funktionen:")
print("  - TonyOpenShop(state)     : FÃ¼r ExecuteCode")
print("  - TonyTrade()             : Einfachste Version")
print("  - OpenTonyTrader(unit)    : Ã–ffnet den Trader")
print("  - TestTonyTrader()        : Test in Console")
print("  - TonyDebugInventory()    : Zeigt Inventar")
print("=======================================")

CreateRealTimeThread(function()
	Sleep(2000)
	TonyUpdateInventory()
	print("[Tony Trader] Initiales Inventar geladen!")
end)
