local _, class = UnitClass('player')
if class ~= 'WARLOCK' then return end

local GrimoireKeeper = CreateFrame('Frame')
local DemonSpellTable = {} -- table of learned demon spells
local GrimoireDB = {} -- table of learned grimoires
local demonType, isDemonVendor
local GrimoireTable = {
	-- [spell texture] = {grimoire id by ranks}
	['Imp'] = {
		['Spell_Fire_FireBolt']							= {nil,     '16302', '16316', '16317', '16318', '16319', '16320'}, -- Firebolt
		['Spell_Shadow_BloodBoil']					= {'16321', '16322', '16323', '16324', '16325'}, -- Blood Pact
		['Spell_Fire_FireArmor']						= {'16326', '16327', '16328', '16329', '16330'}, -- Fire Shield
		['Spell_Shadow_ImpPhaseShift']			= {'16331'} -- Phase Shift
	},
	['Voidwalker'] = {
		['Spell_Shadow_GatherShadows']			= {nil,     '16346', '16347', '16348', '16349', '16350'}, -- Torment
		['Spell_Shadow_SacrificialShield']	= {'16351', '16352', '16353', '16354', '16355', '16356'}, -- Sacrifice
		['Spell_Shadow_AntiShadow']					= {'16357', '16358', '16359', '16360', '16361', '16362'}, -- Consume Shadows
		['Spell_Shadow_BlackPlague']				= {'16363', '16364', '16365', '16366'} -- Suffering
	},
	['Succubus'] = {
		['Spell_Shadow_Curse']							= {nil,     '16368', '16371', '16372', '16373', '16374'}, -- Lash of Pain
		['Spell_Shadow_SoothingKiss']				= {'16375', '16376', '16377', '16378'}, -- Soothing Kiss
		['Spell_Shadow_MindSteal']					= {'16379'}, -- Seduction
		['Spell_Magic_LesserInvisibilty']		= {'16380'} -- Lesser Invisibility
	},
	['Felhunter'] = {
		['Spell_Nature_Purge']							= {nil,     '16381', '16382', '16383'}, -- Devour Magic
		['Spell_Shadow_LifeDrain']					= {'16384', '16385', '16386', '16387'}, -- Tainted Blood
		['Spell_Shadow_MindRot']						= {'16388', '16389'}, -- Spell Lock
		['Spell_Shadow_AuraOfDarkness']			= {'16390'} -- Paranoia
	}
}

GrimoireKeeper:RegisterEvent('MERCHANT_SHOW')
GrimoireKeeper:RegisterEvent('PET_BAR_UPDATE')
GrimoireKeeper:SetScript('OnEvent', function()
	if event == 'MERCHANT_SHOW' then
		isDemonVendor = nil
		local _, texture = GetMerchantItemInfo(1)
		if texture == 'Interface\\Icons\\INV_Misc_Book_06' then isDemonVendor = true end
		if not (isDemonVendor or HasPetUI()) then return end
	end
	-- The code below works for all registered events.
	demonType = this:GetDemonFamily()
	if not demonType then return end

	this:UpdateGrimoireData()
	MerchantFrame_UpdateMerchantInfo()
end)

function GrimoireKeeper:isValidGrimoire(itemID)
	for _, GrimoireIDs in pairs(GrimoireTable[demonType]) do
		for _, GrimoireID in pairs(GrimoireIDs) do
			if itemID == GrimoireID then return true end
		end
	end
	return
end

function GrimoireKeeper:GetDemonFamily()
	self:ScanDemonSpells()
	
	for demonFamily, textures in pairs(GrimoireTable) do
		for texture in pairs(textures) do
			if DemonSpellTable[texture] then return demonFamily end
		end
	end
	return
end

function GrimoireKeeper:ScanDemonSpells()
	DemonSpellTable = {}
	local spellTexture, rank
	for spellIndex = 1, SPELLS_PER_PAGE do
		spellTexture = GetSpellTexture(spellIndex, BOOKTYPE_PET)		
		if not spellTexture then break end
		
		spellTexture = string.gsub(spellTexture, 'Interface\\Icons\\', '')
		_, rank = GetSpellName(spellIndex, BOOKTYPE_PET)
		_, _, rank = string.find(rank, '(%d)')
		if not rank then rank = 1 end
		DemonSpellTable[spellTexture] = tonumber(rank)
	end
end

function GrimoireKeeper:UpdateGrimoireData()
	GrimoireDB = {}
	local GrimoireID
	for spellTexture, spellRank in pairs(DemonSpellTable) do
		for i=1, spellRank do
			GrimoireID = GrimoireTable[demonType][spellTexture][i]
			if GrimoireID then
				GrimoireDB[GrimoireID] = true
			end
		end
	end
end

local oldMerchantFrame_UpdateMerchantInfo = MerchantFrame_UpdateMerchantInfo
function MerchantFrame_UpdateMerchantInfo()
	oldMerchantFrame_UpdateMerchantInfo()
	if not (HasPetUI() and demonType and isDemonVendor) then return end
	
	local index, itemButton, merchantButton, isUsable, link, itemID
	local ir, ig, ib -- color for itemButton
	local mr, mg, mb -- color for merchantButton
	for i=1, MERCHANT_ITEMS_PER_PAGE do
		index = (MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE + i
		itemButton = getglobal('MerchantItem'..i..'ItemButton')
		merchantButton = getglobal('MerchantItem'..i)
		itemButton:SetScript("OnClick", function() MerchantItemButton_OnClick(this) end) -- return the possibility of buying the items (when changing the page MerchantFrame)
		if index > GetMerchantNumItems() then return end
		_, _, _, _, _, isUsable = GetMerchantItemInfo(index)
		link = GetMerchantItemLink(index)
		if not link then return end
		_, _, itemID = string.find(link, 'item:(%d+):')
		
		if not GrimoireKeeper:isValidGrimoire(itemID) then -- if grimoire is not suitable for the current demon
			mr, mg, mb, ir, ig, ib = .5, 0, 0 -- red color
			itemButton:SetScript("OnClick", function() end) -- disabling item buying
		elseif not isUsable then -- if the level is small
			mr, mg, mb, ir, ig, ib = .5, .5, 0 -- yellow color
		elseif GrimoireDB[itemID] then -- if grimoire is known
			mr, mg, mb, ir, ig, ib = 0, .5, .5 -- green color
			itemButton:SetScript("OnClick", function() end) -- disabling item buying
		else -- available for buying
			mr, mg, mb, ir, ig, ib = .5, .5, .5, 1, 1, 1 -- white color
		end
		GrimoireKeeper:ColorButton(merchantButton, itemButton, mr, mg, mb, ir, ig, ib)
	end
end

function GrimoireKeeper:ColorButton(merchantButton, itemButton, mr, mg, mb, ir, ig, ib)
	if not (ir or ig or ib) then ir, ig, ib = mr, mg, mb end
	SetItemButtonNameFrameVertexColor(merchantButton, mr, mg, mb)
	SetItemButtonSlotVertexColor(merchantButton, mr, mg, mb)
	SetItemButtonTextureVertexColor(itemButton, ir, ig, ib)
	SetItemButtonNormalTextureVertexColor(itemButton, ir, ig, ib)
end