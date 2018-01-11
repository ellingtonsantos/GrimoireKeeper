GrimoireKeeper = AceLibrary('AceAddon-2.0'):new('AceEvent-2.0', 'AceHook-2.1')

function GrimoireKeeper:OnInitialize()
	local _, class = UnitClass('player')
	if class ~= 'WARLOCK' then return end
	
	GrimoireTable = {
		-- [spell name] = {grimoire id by ranks}
		-- Imp
		['Firebolt'] 			= {nil,     '16302', '16316', '16317', '16318', '16319', '16320'},
		['Blood Pact'] 			= {'16321', '16322', '16323', '16324', '16325'},
		['Fire Shield'] 		= {'16326', '16327', '16328', '16329', '16330'},
		['Phase Shift'] 		= {'16331'},
		-- Voidwalker
		['Torment'] 			= {nil,     '16346', '16347', '16348', '16349', '16350'},
		['Sacrifice'] 			= {'16351', '16352', '16353', '16354', '16355', '16356'},
		['Consume Shadows'] 	= {'16357', '16358', '16359', '16360', '16361', '16362'},
		['Suffering'] 			= {'16363', '16364', '16365', '16366'},
		-- Succubus
		['Lash of Pain'] 		= {nil,     '16368', '16371', '16372', '16373', '16374'},
		['Soothing Kiss'] 		= {'16375', '16376', '16377', '16378'},
		['Seduction'] 			= {'16379'},
		['Lesser Invisibility'] = {'16380'},
		-- Felhunter
		['Devour Magic'] 		= {nil,     '16381', '16382', '16383'},
		['Tainted Blood'] 		= {'16384', '16385', '16386', '16387'},
		['Spell Lock'] 			= {'16388', '16389'},
		['Paranoia'] 			= {'16390'}
	}
	self:RegisterEvent('PET_BAR_UPDATE')
	self:SecureHook('MerchantFrame_UpdateMerchantInfo')
end

function GrimoireKeeper:PET_BAR_UPDATE()	
	GrimoireKeeperData = {}
	
	for i=1, SPELLS_PER_PAGE do
		local name, rank = GetSpellName(i, BOOKTYPE_PET)
		if not name then break end
		_, _, rank = string.find(rank, '(%d)')
		if not rank then rank = 1 end
		if GetLocale() ~= 'enUS' then
			name = AceLibrary('Babble-Spell-2.2'):GetReverseTranslation(name)
		end
		for i=1, tonumber(rank) do
			local GrimoireID = GrimoireTable[name][i]
			if GrimoireID then
				table.insert(GrimoireKeeperData, GrimoireID)
			end
		end
	end
end

function GrimoireKeeper:MerchantFrame_UpdateMerchantInfo()
	if not PetActionBarFrame:IsShown() then return end
	for i=1, MERCHANT_ITEMS_PER_PAGE do
		local index = (MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE + i
		if index <= GetMerchantNumItems() then
			local link = GetMerchantItemLink(index)
			if not link then return end
			local _, _, itemID = string.find(link, 'item:(%d+):%d+:%d+:%d+')
			for k in pairs(GrimoireKeeperData) do
				if itemID == GrimoireKeeperData[k] then
					local itemButton = getglobal('MerchantItem'..i..'ItemButton')
					local merchantButton = getglobal('MerchantItem'..i)
					SetItemButtonNameFrameVertexColor(merchantButton, 0, 0.75, 0.75)
					SetItemButtonSlotVertexColor(merchantButton, 0, 0.75, 0.75)
					SetItemButtonTextureVertexColor(itemButton, 0, 0.65, 0.65)
					SetItemButtonNormalTextureVertexColor(itemButton, 0, 0.65, 0.65)
				end
			end
		end
	end
end