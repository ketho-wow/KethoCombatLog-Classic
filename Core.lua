local NAME, S = ...
local KCL = KethoCombatLog

local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local L = S.L
local options = S.options

local profile, char
local color, spell

local player = S.Player

local _G = _G
local tonumber = tonumber
local unpack = unpack
local time = time
local strsub, strmatch, format = strsub, strmatch, format
local wipe = wipe
local bit_band = bit.band

local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local GetSpellInfo, GetSpellLink = GetSpellInfo, GetSpellLink

local COMBATLOG_OBJECT_RAIDTARGET_MASK = COMBATLOG_OBJECT_RAIDTARGET_MASK
local COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE

local TEXT_MODE_A_TIMESTAMP = TEXT_MODE_A_TIMESTAMP
local TEXT_MODE_A_STRING_SOURCE_UNIT = TEXT_MODE_A_STRING_SOURCE_UNIT
local TEXT_MODE_A_STRING_DEST_UNIT = TEXT_MODE_A_STRING_DEST_UNIT
local TEXT_MODE_A_STRING_SPELL = TEXT_MODE_A_STRING_SPELL
local TEXT_MODE_A_STRING_RESULT_OVERKILLING = TEXT_MODE_A_STRING_RESULT_OVERKILLING
local TEXT_MODE_A_STRING_RESULT_CRITICAL = TEXT_MODE_A_STRING_RESULT_CRITICAL
local TEXT_MODE_A_STRING_RESULT_GLANCING = TEXT_MODE_A_STRING_RESULT_GLANCING
local TEXT_MODE_A_STRING_RESULT_CRUSHING = TEXT_MODE_A_STRING_RESULT_CRUSHING

local args = {}
local braces = "[%[%]]"
local chatType

-- bit flaky naming
local death = {
	unit = {}, -- unit guids from the UNIT_DIED event; timestamp
	overkill = {}, -- unit guids that supposedly died from overkill; saved cleu event
	damage = {}, -- unit guids with their last known dmg event; saved cleu event
}

local overkillcd = {} -- separate cooldown between every overkill event; time of last overkill event
local ttl = 2 -- time to live/die -- required time for last known dmg event to be counted as death

	------------
	--- Ace3 ---
	------------

local appKey = {
	"KethoCombatLog_Main",
	"KethoCombatLog_Advanced",
	"KethoCombatLog_Profiles",
}

local appValue = {
	KethoCombatLog_Main = options.args.Main,
	KethoCombatLog_Advanced = options.args.Advanced,
}

function KCL:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("KethoCombatLogDB", S.defaults, true)
	
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshDB")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshDB")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshDB")
	self:RefreshDB()
	
	self.db.global.version = S.VERSION
	self.db.global.build = S.BUILD
	
	-- parent options table
	local NAME2 = "Ketho CombatLog"
	ACR:RegisterOptionsTable("KethoCombatLog_Parent", options)
	ACD:AddToBlizOptions("KethoCombatLog_Parent", NAME2)
	
	-- profiles
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	local profiles = options.args.profiles
	appValue.KethoCombatLog_Profiles = profiles
	profiles.order = 6
	profiles.name = "|TInterface\\Icons\\INV_Misc_Note_01:16:16:0:-1"..S.crop.."|t  "..profiles.name
	
	for _, v in ipairs(appKey) do
		ACR:RegisterOptionsTable(v, appValue[v])
		ACD:AddToBlizOptions(v, appValue[v].name, NAME2)
	end
	
	ACD:SetDefaultSize("KethoCombatLog_Parent", 700, 600)
	
	-- slash command
	for _, v in ipairs({"kcl", "ket", "ketho", "kethocombat", "kethocombatlog"}) do
		self:RegisterChatCommand(v, "SlashCommand")
	end
	
	-- v1.11: changed toggle widget to select widget without renaming ..
	if profile.Timestamp == true then
		profile.Timestamp = 1
	end
end

function KCL:OnEnable()
	-- controls COMBAT_LOG_EVENT_UNFILTERED
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:ZONE_CHANGED_NEW_AREA()
	
	-- controls chatType
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:GROUP_ROSTER_UPDATE()
	
	if not profile.BlizzardCombatLog then
		if COMBATLOG then
			COMBATLOG:UnregisterEvent("COMBAT_LOG_EVENT")
		else
			self:RegisterEvent("ADDON_LOADED") -- Check for Blizzard CombatLog
		end
	end
	
	-- support [Class Colors] by Phanx
	if CUSTOM_CLASS_COLORS then
		CUSTOM_CLASS_COLORS:RegisterCallback("WipeCache", self)
	end
end

function KCL:OnDisable()
	-- maybe superfluous
	self:UnregisterAllEvents()
	self:CancelAllTimers()
	
	if CUSTOM_CLASS_COLORS then
		CUSTOM_CLASS_COLORS:UnregisterCallback("WipeCache", self)
	end
end

function KCL:RefreshDB()
	-- table shortcuts
	profile, char = self.db.profile, self.db.char
	color = profile.color
	
	for i = 1, 2 do -- refresh db in other files
		self["RefreshDB"..i](self)
	end
	self:WipeCache() -- wipe metatables
	self:SetSinkStorage(profile) -- LibSink
	
	-- other
	S.crop = profile.IconCropped and ":64:64:4:60:4:60" or ""
	if profile.ChatWindow > 1 then
		S.ChatFrame = _G["ChatFrame"..profile.ChatWindow-1]
	end
end

	---------------------
	--- Slash Command ---
	---------------------

local enable = {
	["1"] = true,
	on = true,
	enable = true,
	load = true,
}

local disable = {
	["0"] = true,
	off = true,
	disable = true,
	unload = true,
}

function KCL:SlashCommand(input)
	if enable[input] then
		self:Enable()
		self:Print("|cffADFF2F"..VIDEO_OPTIONS_ENABLED.."|r")
	elseif disable[input] then
		self:Disable()
		self:Print("|cffFF2424"..VIDEO_OPTIONS_DISABLED.."|r")
	elseif input == "toggle" then
		self:SlashCommand(self:IsEnabled() and "0" or "1")
	else
		ACD:Open("KethoCombatLog_Parent")
	end
end

-- Blizzard CombatLog is Load-on-Demand
function KCL:ADDON_LOADED(event, addon)
	if addon == "Blizzard_CombatLog" and not profile.BlizzardCombatLog then
		COMBATLOG:UnregisterEvent("COMBAT_LOG_EVENT")
		self:UnregisterEvent(addon)
	end
end

function KCL:ZONE_CHANGED_NEW_AREA(event)
	local instanceType = select(2, IsInInstance())
	
	local pve = profile.PvE and S.PvE[instanceType]
	local pvp = profile.PvP and S.PvP[instanceType]
	local world = profile.World and instanceType == "none"
	S.isBattleground = instanceType == "pvp"
	
	self[(pve or pvp or world) and "RegisterEvent" or "UnregisterEvent"](self, "COMBAT_LOG_EVENT_UNFILTERED")
end

function KCL:GROUP_ROSTER_UPDATE(event)
	local p = profile.ChatChannel
	
	if p == 2 then
		chatType = "SAY"
	elseif p == 3 then
		chatType = "YELL"
	elseif p == 4 then
		local isInstance = IsInRaid(LE_PARTY_CATEGORY_INSTANCE) or IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
		chatType = isInstance and "INSTANCE_CHAT" or IsInRaid() and "RAID" or IsInGroup() and "PARTY"
	elseif p >= 5 then
		chatType = "CHANNEL"
	end
end

	----------------
	--- Reaction ---
	----------------

local function UnitReaction(unitflags)
	if bit_band(unitflags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 then
		return "Friendly"
	elseif bit_band(unitflags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then
		return "Hostile"
	else
		return "Unknown"
	end
end

	-------------------
	--- Raid Target ---
	-------------------

local function UnitIcon(unitFlags, reaction)
	local raidTarget = bit_band(unitFlags, COMBATLOG_OBJECT_RAIDTARGET_MASK)
	if raidTarget == 0 then return "", "" end
	
	local i = S.COMBATLOG_OBJECT_RAIDTARGET[raidTarget]
	local icon = _G["COMBATLOG_ICON_RAIDTARGET"..i]
	local iconString = format(S.STRING_REACTION_ICON[reaction], raidTarget, icon)
	local chat = "{"..strlower(_G["RAID_TARGET_"..i]).."}"
	return iconString, chat
end

	-------------
	--- Spell ---
	-------------

local GetSpellSchool = setmetatable({}, {__index = function(t, k)
	local str = S.SpellSchoolString[k] or STRING_SCHOOL_UNKNOWN
	local color = S.SpellSchoolColor[k]
	local v = {"|cff"..color..str.."|r", str, color}
	rawset(t, k, v)
	return v
end})

local GetSpellIcon = setmetatable({}, {__index = function(t, k)
	local v = select(3, GetSpellInfo(k))
	rawset(t, k, v)
	return v
end})

local _GetSpellLink = setmetatable({}, {__index = function(t, k)
	local v = GetSpellLink(k)
	rawset(t, k, v)
	return v
end})

local function _GetSpellInfo(spellID, spellName, spellSchool)
	local schoolNameLocal, schoolNameChat, schoolColor = unpack(GetSpellSchool[spellSchool])
	local iconSize = profile.IconSize
	local spellIcon = iconSize>1 and format("|T%s:%s:%s:0:0%s|t", GetSpellIcon[spellID], iconSize, iconSize, S.crop) or ""
	local spellLinkLocal = format("|cff%s"..TEXT_MODE_A_STRING_SPELL.."|r", schoolColor, spellID, "", "["..spellName.."]")
	return schoolNameLocal, schoolNameChat, spellLinkLocal..spellIcon, _GetSpellLink[spellID]
end

	--------------
	--- Result ---
	--------------

local function GetResultString(overkill, critical, glancing, crushing)
	local str = ""

	if overkill and profile.OverkillFormat then
		str = str.." "..format(TEXT_MODE_A_STRING_RESULT_OVERKILLING, overkill)
	end
	if critical and profile.CriticalFormat then
		str = str.." "..TEXT_MODE_A_STRING_RESULT_CRITICAL
	end
	if glancing and profile.GlancingFormat then
		str = str.." "..TEXT_MODE_A_STRING_RESULT_GLANCING 
	end
	if crushing and profile.CrushingFormat then
		str = str.." "..TEXT_MODE_A_STRING_RESULT_CRUSHING 
	end
	
	return str
end

	--------------
	--- Filter ---
	--------------

local function IsOption(event)
	return profile["Local"..event] or profile["Chat"..event]
end

local function IsLocalEvent(event)
	return profile["Local"..event]
end

local function IsChatEvent(event)
	return profile[(profile.ChatFilter and "Chat" or "Local")..event]
end

local function TankFilter(event, unit)
	local isTank = (UnitGroupRolesAssigned(unit) == "TANK")
	return not isTank or profile["Tank"..event]
end

	------------
	--- Args ---
	------------

local function SetMessage(msgtype)
	args.msg = profile.message[msgtype]
	local group = S.EventGroup[msgtype] or msgtype -- fallback
	args.color = color[group]
	args.loc = IsLocalEvent(group)
	args.chat = IsChatEvent(group) -- whether to output to chat
end

-- only append x for these chatargs
local ChatArgs = {
	src = true,
	dest = true,
	spell = true,
	xspell = true,
	school = true,
	xschool = true,
}

local function ReplaceArgs(args, isChat)
	local msg = args.msg
	for k in gmatch(msg, "%b<>") do
		-- remove <>, make case insensitive
		local s = strlower(gsub(k, "[<>]", ""))
		-- escape special characters
		s = gsub(args[isChat and ChatArgs[s] and s.."x" or s] or "", "(%p)", "%%%1")
		k = gsub(k, "(%p)", "%%%1")
		msg = msg:gsub(k, s)
	end
	return msg
end

	------------
	--- CLEU ---
	------------

function KCL:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	
	local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...
	
	wipe(args)
	
	local sourceType = tonumber(strsub(sourceGUID, 5, 5))
	local destType = tonumber(strsub(destGUID, 5, 5))
	
	local sourcePlayer = sourceType and bit_band(sourceType, 0x7) == 0
	local destPlayer = destType and bit_band(destType, 0x7) == 0
	local destNPC = destType and S.NPCID[bit_band(destType, 0x7)]
	
	-- exceptions to the filter
	local isMissEvent = (subevent == "SPELL_MISSED" and S.MissEvent[select(15, ...)])
	local isReverseEvent = S.DamageEvent[subevent] or isMissEvent or subevent == "UNIT_DIED"
	local isPetTaunt = S.PetTaunt[select(12, ...)]
	
	--------------
	--- Filter ---
	--------------
	
	if sourceName == player.name or destName == player.name then
		if not profile.FilterSelf then return end
	else
		if not profile.FilterOther then return end
	end
	
	-- the other way round for for death/reflect events
	if (isReverseEvent and destPlayer) or (not isReverseEvent and sourcePlayer) or isPetTaunt then
		if not profile.FilterPlayers then return end
	else
		if not profile.FilterMonsters then return end
	end
	
	------------
	--- Unit ---
	------------
	
	-- reaction also used in SPELL_DISPEL
	local sourceReaction = UnitReaction(sourceFlags)
	local destReaction = UnitReaction(destFlags)
	
	if sourceName then
		-- trim out (CRZ) realm name; only do this for players, to avoid false positives for certain npcs
		local name = (profile.TrimRealm and sourcePlayer) and strmatch(sourceName, "([^%-]+)%-?.*") or sourceName
		local fname = (sourceName == player.name) and UNIT_YOU_SOURCE or name
		local sourceIconLocal, sourceIconChat = UnitIcon(sourceRaidFlags, 1)
		local color = S.GeneralColor[sourceReaction]
		
		if sourcePlayer and (profile.ColorEnemy or not profile.ColorEnemy and sourceReaction == "Friendly") then
			local class = select(2,GetPlayerInfoByGUID(sourceGUID))
			color = class and S.ClassColor[class] or color
		end
		
		args.src = format("|cff%s"..TEXT_MODE_A_STRING_SOURCE_UNIT.."|r", color, sourceIconLocal, sourceGUID, sourceName, "["..fname.."]")
		args.srcx = format("%s[%s]", sourceIconChat, name)
	end
	
	if destName then
		local name = (profile.TrimRealm and destPlayer) and strmatch(destName, "([^%-]+)%-?.*") or destName
		local fname = (destName == player.name) and UNIT_YOU_DEST or (destName == sourceName) and L.SELF or name
		local destIconLocal, destIconChat = UnitIcon(destRaidFlags, 2)
		local color = S.GeneralColor[destReaction]
		
		if destPlayer and (profile.ColorEnemy or not profile.ColorEnemy and destReaction == "Friendly") then
			local class = select(2,GetPlayerInfoByGUID(destGUID))
			color = class and S.ClassColor[class] or color
		end
		
		args.dest = format("|cff%s"..TEXT_MODE_A_STRING_DEST_UNIT.."|r", color, destIconLocal, destGUID, destName, "["..fname.."]")
		args.destx = format("%s[%s]", destIconChat, name)
	end
	
	--------------
	--- Suffix ---
	--------------
	
	local spellID, spellName, spellSchool
	local SuffixParam1, SuffixParam2, SuffixParam3, SuffixParam4, SuffixParam5, SuffixParam6, SuffixParam7, SuffixParam8, SuffixParam9
	
	local prefix = strsub(subevent, 1, 5)
	if prefix == "SWING" then
		SuffixParam1, SuffixParam2, SuffixParam3, SuffixParam4, SuffixParam5, SuffixParam6, SuffixParam7, SuffixParam8, SuffixParam9 = select(12, ...)
		args.amount = SuffixParam1
	elseif prefix == "SPELL" or prefix == "RANGE" or prefix == "DAMAG" then
		spellID, spellName, spellSchool, SuffixParam1, SuffixParam2, SuffixParam3, SuffixParam4, SuffixParam5, SuffixParam6, SuffixParam7, SuffixParam8, SuffixParam9 = select(12, ...)
		args.amount = SuffixParam1
		
	-------------
	--- Spell ---
	-------------
		
		args.school, args.schoolx, args.spell, args.spellx = _GetSpellInfo(spellID, spellName, spellSchool)
		
		if S.ExtraSpellEvent[subevent] then
			args.xschool, args.xschoolx, args.xspell, args.xspellx = _GetSpellInfo(SuffixParam1, SuffixParam2, SuffixParam3)
		end
	end
	
	-------------
	--- Event ---
	-------------
	
	-- only announce death after UNIT_DIED fired, since the overkill parameter isn't always accurate
	-- prioritize any overkill events over the last non overkill event stored, all within a 2 seconds time frame
	if S.DamageEvent[subevent] then
		if not IsOption("Death") then return end
		
		-- check for confirmation of the guid his death, then announce
		if death.unit[destGUID] and death.unit[destGUID]-timestamp < ttl then
			if subevent == "ENVIRONMENTAL_DAMAGE" then
				local environmentalType, amount = select(12, ...)
				if not destName then return end -- sometimes destName is nil
				args.amount = amount
				args.type = S.EnvironmentalDamageType[environmentalType] or environmentalType
				SetMessage("Death_Environmental")
			else
				SetMessage(subevent == "SWING_DAMAGE" and "Death_Melee" or "Death")
			end
		end
		
		-- store last dmg event. generates a crapload of garbage
		death.damage[destGUID] = {event, ...}
		-- store last overkill event
		if SuffixParam2 and SuffixParam2 > 0 and time() > (overkillcd[destGUID] or 0) then
			overkillcd[destGUID] = time() + ttl -- throttle overkill events
			death.overkill[destGUID] = {event, ...}
			self:ScheduleTimer(function()
				-- discard overkill event, in case it was a false positive, and for future deaths
				death.overkill[destGUID] = nil
			end, 2)
		end
		death.unit[destGUID] = nil -- reset death flag
	elseif subevent == "UNIT_DIED" then
		local events = death.overkill[destGUID] or death.damage[destGUID]
		if IsOption("Death") and events and not UnitBuff(destName, 5384) then -- Hunter 5384 [Feign Death] fix
			death.unit[destGUID] = timestamp -- set death flag and also store current timestamp for comparing with the fatal event
			self:COMBAT_LOG_EVENT_UNFILTERED(unpack(events)) -- fire the fatal event again
			return -- avoid double messages
		end
	elseif subevent == "SPELL_CAST_SUCCESS" then
		if S.Interrupt[spellID] and IsOption("Juke") then
			self:Juke(...)
		end
	elseif subevent == "SPELL_AURA_APPLIED" then
		if S.Taunt[spellID] or (S.PetTaunt[spellID] and profile.PetTaunt) and destNPC and IsOption("Taunt") and TankFilter("Taunt", sourceName) then
			SetMessage("Taunt")
		elseif S.CrowdControl[spellID] and IsOption("CrowdControl") then
			if not (destGUID == sourceGUID and S.CrowdControlDouble[spellID]) then
				SetMessage("CrowdControl")
			end
		-- Priest 27827 [Spirit of Redemption] fix
		-- sometimes applied just before receiving the fatal dmg event
		elseif spellID == 27827 and IsOption("Death") then
			self:ScheduleTimer(function()
				-- prioritize overkill over common dmg events
				local events = death.overkill[destGUID] or death.damage[destGUID]
				if events then
					death.unit[destGUID] = timestamp
					self:COMBAT_LOG_EVENT_UNFILTERED(unpack(events))
					return
				end
			end, .5)
		end
	elseif subevent == "SPELL_INTERRUPT" then
		if IsOption("Interrupt") then
			SetMessage("Interrupt")
		end
		if IsOption("Juke") then
			self:Juke(...)
		end
	elseif subevent == "SPELL_JUKE" then
		-- not needed to check event options
		SetMessage("Juke")
	elseif subevent == "SPELL_DISPEL" then
		if IsOption("Dispel") then
			local friendly = (sourceReaction == "Friendly" and destReaction == sourceReaction)
			local hostile = (sourceReaction == "Hostile" and destReaction == sourceReaction)
			-- cleanses between two (friendly/hostile) units
			-- bug: its not possible to see whether 2 friendly units are hostile to each other, ie dueling
			if friendly or hostile then
				if profile.FriendlyDispel then
					SetMessage("Cleanse")
				end
			else
				if profile.HostileDispel then
					SetMessage("Dispel")
				end
			end
		end
	elseif subevent == "SPELL_STOLEN" then
		if IsOption("Dispel") and profile.Spellsteal then
			SetMessage("Spellsteal")
		end
	elseif subevent == "SPELL_MISSED" then
		-- holy priest fatal spell absorb bug
		if SuffixParam1 == "ABSORB" then
			if not IsOption("Death") then return end
			if death.unit[destGUID] and death.unit[destGUID]-timestamp < ttl then
				args.amount = SuffixParam3
				SetMessage("Death")
			end
			death.damage[destGUID] = {event, ...}
			death.unit[destGUID] = nil
		elseif SuffixParam1 == "REFLECT" then
			if IsOption("Reflect") then
				SetMessage("Reflect")
			end
		else
			local taunt = S.Taunt[spellID] and IsOption("Taunt")
			local interrupt = S.Interrupt[spellID] and IsOption("Interrupt")
			local crowdcontrol = S.CrowdControl[spellID] and IsOption("CrowdControl")
			if (profile.MissAll or taunt or interrupt or crowdcontrol) and not S.Blacklist[spellID] then
				args.type = S.MissType[SuffixParam1] or SuffixParam1
				SetMessage("Miss")
			end
			-- check if the interrupt failed, instead of being wasted
			if S.Interrupt[spellID] and IsOption("Juke") then
				self:Juke(...)
			end
		end
	elseif subevent == "SPELL_AURA_BROKEN" then
		if IsOption("Break") then
			SetMessage(sourceName and "Break_NoSource" or "Break")
		end
	elseif subevent == "SPELL_AURA_BROKEN_SPELL" then
		if IsOption("Break") then
			SetMessage("Break_Spell")
		end
	elseif subevent == "SPELL_INSTAKILL" then
		if IsOption("Death") and not S.Blacklist[spellID] then
			SetMessage("Death_Instakill")
			-- untested; pray there will be no dmg events between SPELL_INSTAKILL and UNIT_DIED
			death.unit[destGUID] = nil
			death.overkill[destGUID] = nil
			death.damage[destGUID] = nil
		end
	elseif subevent == "SPELL_HEAL" then
		if S.Save[spellID] and IsOption("Save") then
			SetMessage("Save")
		end
	elseif subevent == "SPELL_RESURRECT" then
		-- To Do: add better check, this is kinda lazy
		if IsOption("Resurrect") and not profile.BattleRez or (profile.BattleRez and UnitAffectingCombat("player")) then
			SetMessage("Resurrect")
		end
	end
	
	---------------
	--- Message ---
	---------------
	
	-- check if there is any message
	if args.msg then
		
		-- timestamp; possibility to also use as an arg
		args.time, args.timex = S.GetTimestamp()
		
		local resultString = ""
		if S.DamageEvent[subevent] or S.HealEvent[subevent] then
			resultString = GetResultString(SuffixParam2, SuffixParam7, SuffixParam8, SuffixParam9)
		end
		
		-- remove braces again; except timestamp
		if not profile.UnitBracesLocal then
			-- src and dest args can be nil in rare cases
			args.src = args.src and args.src:gsub(braces, "")
			args.dest = args.dest and args.dest:gsub(braces, "")
			-- spell strings can be nil
			args.spell = args.spell and args.spell:gsub(braces, " ")
			args.xspell = args.xspell and args.xspell:gsub(braces, " ")
		end
		if not profile.UnitBracesChat then
			args.srcx = args.srcx and args.srcx:gsub(braces, "")
			args.destx = args.destx and args.destx:gsub(braces, "")
		end
		
		-- abbreviate numbers
		if args.amount and type(args.amount) == "number" and profile.AbbreviateNumbers then
			args.amount = AbbreviateLargeNumbers(args.amount)
		end
		
		local textLocal = args.time..ReplaceArgs(args)..resultString
		local textChat = args.timex..ReplaceArgs(args, true)..resultString
		
	--------------
	--- Output ---
	--------------
		
		if args.loc and profile.ChatWindow > 1 then
			S.ChatFrame:AddMessage(textLocal, unpack(args.color))
		end
		
		-- don't default to "SAY" if chatType is nil
		if args.chat and profile.ChatChannel > 1 and chatType then
			-- avoid ERR_CHAT_WHILE_DEAD
			local DeadTalk = (UnitIsDead("player") or UnitIsGhost("player")) and S.Talk[chatType]
			-- dont ever spam the battleground group
			if not (DeadTalk or S.isBattleground) then
				SendChatMessage(textChat, chatType, nil, profile.ChatChannel-4)
			end
		end
		
		-- LibSink; use local event group
		if args.loc then
			self:Pour(profile.sink20OutputSink == "Channel" and textChat or textLocal, unpack(args.color))
		end
	end
end

	------------
	--- Juke ---
	------------

local Interrupt = {}

function KCL:Juke(timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool)
	if subevent == "SPELL_CAST_SUCCESS" then -- casted
		Interrupt[sourceGUID] = true
		self:ScheduleTimer(function() -- wait for SPELL_INTERRUPT delay/lag
			self:Juke(timestamp, "CHECK_JUKE", hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool)
		end, .5)
	
	elseif subevent == "SPELL_INTERRUPT" or subevent == "SPELL_MISSED" then -- succesful or failed
		Interrupt[sourceGUID] = false
	
	elseif subevent == "CHECK_JUKE" then
		if Interrupt[sourceGUID] then -- wasted
			self:COMBAT_LOG_EVENT_UNFILTERED(_, timestamp, "SPELL_JUKE", hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool)
		end
		Interrupt[sourceGUID] = false
	end
end
