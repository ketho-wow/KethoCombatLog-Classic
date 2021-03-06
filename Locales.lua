local _, S = ...

local L = {
	enUS = {
		EVENT_JUKE = "Juke",
		EVENT_CROWDCONTROL = "Crowd Control",
		
		MSG_TAUNT = "<SRC><SPELL> taunted <DEST>",
		
		MSG_INTERRUPT = "<SRC><SPELL> "..ACTION_SPELL_INTERRUPT.." <DEST><XSPELL>",
		MSG_JUKE = "<SRC> juked <SPELL> on <DEST>",
		
		MSG_DISPEL = "<SRC><SPELL> "..ACTION_SPELL_DISPEL_BUFF.." <DEST><XSPELL>",
		MSG_CLEANSE = "<SRC><SPELL> "..ACTION_SPELL_DISPEL_DEBUFF.." <DEST><XSPELL>",
		MSG_SPELLSTEAL = "<SRC><SPELL> "..ACTION_SPELL_STOLEN.." <DEST><XSPELL>",
		
		MSG_REFLECT = "<DEST> "..ACTION_SPELL_MISSED_REFLECT.." <SRC><SPELL>",
		MSG_MISS = "<SRC><SPELL> on <DEST> "..ACTION_SPELL_CAST_FAILED.." (<TYPE>)",
		
		MSG_CROWDCONTROL = "<SRC><SPELL> CC'ed <DEST>",
		-- this particular spell and extraspell order is extra confusing :x
		MSG_BREAK_SPELL = "<SRC><XSPELL> "..ACTION_SPELL_AURA_BROKEN.." <DEST><SPELL>",
		MSG_BREAK = "<SRC> "..ACTION_SPELL_AURA_BROKEN.." <DEST><SPELL>",
		MSG_BREAK_NOSOURCE = "<SPELL> on <DEST> "..ACTION_SPELL_AURA_BROKEN,
		
		MSG_DEATH = "<DEST> "..ACTION_UNIT_DIED.." <SRC><SPELL> <AMOUNT> <SCHOOL>",
		MSG_DEATH_MELEE = "<DEST> "..ACTION_UNIT_DIED.." <SRC> <AMOUNT> "..ACTION_SWING,
		MSG_DEATH_ENVIRONMENTAL = "<DEST> "..ACTION_UNIT_DIED.." <AMOUNT> <TYPE>",
		MSG_DEATH_INSTAKILL = "<SRC><SPELL> "..ACTION_SPELL_INSTAKILL.." <DEST>",
		
		MSG_SAVE = "<SRC><SPELL> saved <DEST> <AMOUNT> <SCHOOL>",
		MSG_RESURRECT = "<SRC><SPELL> "..ACTION_SPELL_RESURRECT.." <DEST>",
		-- source and dest are switched
		MSG_SELFRES_SOULSTONE = "<SRC> used <DEST><SPELL>",
		MSG_SELFRES_REINCARNATION = "<SRC> "..ACTION_SPELL_CAST_SUCCESS.." <SPELL>",
		
		LOCAL = "Local",
		SELF = "Self",
		ENEMY_PLAYERS_CLASS_COLORS = "Color enemy players by class",
		ABBREVIATE_LARGE_NUMBERS = "Abbreviate Large Numbers",
		
		USE_CLASS_COLORS = "Please use the |cff71D5FFClass Colors|r AddOn",
		BROKER_CLICK = "|cffFFFFFFClick|r to open the options menu",
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-click|r to toggle this AddOn",
	},
	deDE = {
		ABBREVIATE_LARGE_NUMBERS = "Lange Zahlen k??rzen",
		ENEMY_PLAYERS_CLASS_COLORS = "Gegnerische Spieler nach deren Klasse f??rben",
		EVENT_CROWDCONTROL = "Massenkontrolle",
		EVENT_JUKE = "Verschwendung", -- Needs review
		-- LOCAL = "",
		MSG_BREAK = "<SRC> brach <DEST><SPELL>",
		MSG_BREAK_NOSOURCE = "<SPELL> auf <DEST> brach",
		MSG_BREAK_SPELL = "<SRC><XSPELL> brach <DEST><SPELL>",
		MSG_CLEANSE = "<SRC><SPELL> reinigte <DEST><XSPELL>", -- Needs review
		MSG_CROWDCONTROL = "<SRC><SPELL> CC'ed <DEST>", -- Needs review
		MSG_DEATH = "<DEST> starb <SRC><SPELL> <AMOUNT> <SCHOOL>",
		MSG_DEATH_ENVIRONMENTAL = "<DEST> starb <AMOUNT> <TYPE>",
		MSG_DEATH_INSTAKILL = "<SRC><SPELL> t??tete <DEST>",
		MSG_DEATH_MELEE = "<DEST> starb <SRC> <AMOUNT> Nahkampf",
		MSG_DISPEL = "<SRC><SPELL> bannte <DEST><XSPELL>",
		MSG_INTERRUPT = "<SRC><SPELL> unterbrach <DEST><XSPELL>",
		MSG_JUKE = "<SRC> verschwendete <SPELL> auf <DEST>", -- Needs review
		MSG_MISS = "<SRC><SPELL> verfehlte <DEST> (<TYPE>)", -- Needs review
		MSG_REFLECT = "<DEST> reflektierte <SRC><SPELL>",
		MSG_RESURRECT = "<SRC><SPELL> belebte <DEST> wieder",
		MSG_SAVE = "<SRC><SPELL> rettete <DEST> <AMOUNT> <SCHOOL>",
		MSG_SELFRES_REINCARNATION = "<SRC> wirkt <SPELL>",
		MSG_SELFRES_SOULSTONE = "<SRC> benutzte <DEST><SPELL>",
		MSG_SPELLSTEAL = "<SRC><SPELL> stahl <DEST><XSPELL>",
		MSG_TAUNT = "<SRC><SPELL> verspottete <DEST>",
		SELF = "Selbst",
		
		USE_CLASS_COLORS = "Bitte ben??tzt daf??r das |cff71D5FFClass Colors|r AddOn",
		BROKER_CLICK = "|cffFFFFFFKlickt|r, um das Optionsmen?? zu ??ffnen",
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-klickt|r, um dieses AddOn ein-/auszuschalten",
	},
	esES = {
		BROKER_CLICK = "|cffffffffHaz clic|r para ver opciones",
		BROKER_SHIFT_CLICK = "|cffffffffMay??s-clic|r para activar/desactivar",
	},
	--esMX = {},
	frFR = {
		SELF = "Soi-m??me",
	},
	itIT = {
		SELF = "Stesso", -- google translate
	},
	koKR = {
		ABBREVIATE_LARGE_NUMBERS = "??? ?????? ?????? ????????? ??????",
		ENEMY_PLAYERS_CLASS_COLORS = "????????? ?????? ?????? ?????? ??????",
		EVENT_CROWDCONTROL = "????????????",
		EVENT_JUKE = "??????",
		LOCAL = "??????",
		MSG_BREAK = "<SRC> ?????? <DEST><SPELL>",
		MSG_BREAK_NOSOURCE = "<SPELL> on <DEST> ??????",
		MSG_BREAK_SPELL = "<SRC><XSPELL> ?????? <DEST><SPELL>",
		MSG_CLEANSE = "<SRC><SPELL> ????????? <DEST><XSPELL>",
		MSG_CROWDCONTROL = "<SRC><SPELL> ???????????? <DEST>",
		MSG_DEATH = "<DEST> ?????? <SRC><SPELL> <AMOUNT> <SCHOOL>",
		MSG_DEATH_ENVIRONMENTAL = "<DEST> ?????? <AMOUNT> <TYPE>",
		MSG_DEATH_INSTAKILL = "<SRC><SPELL> ?????? <DEST>",
		MSG_DEATH_MELEE = " <DEST> ?????? <SRC> <AMOUNT> ??????",
		MSG_DISPEL = "<SRC><SPELL> ?????? <DEST><XSPELL>",
		MSG_INTERRUPT = "<SRC><SPELL> ?????? <DEST><XSPELL>",
		MSG_JUKE = "<SRC> ?????? <SPELL> on <DEST>",
		MSG_MISS = " <SRC><SPELL> on <DEST> ?????? (<TYPE>)",
		MSG_REFLECT = "<DEST> ?????? <SRC><SPELL>",
		MSG_RESURRECT = "<SRC><SPELL> ?????? <DEST>",
		MSG_SAVE = "<SRC><SPELL> ????????? ?????? <DEST> <AMOUNT> <SCHOOL>",
		MSG_SELFRES_REINCARNATION = "<SRC> ?????? <SPELL>",
		MSG_SELFRES_SOULSTONE = "<SRC> ?????? <DEST><SPELL>",
		MSG_SPELLSTEAL = "<SRC><SPELL> ?????? <DEST><XSPELL>",
		MSG_TAUNT = "<SRC><SPELL> ?????? <DEST>",
		SELF = "???",
	},
	ptBR = {
		SELF = "Maga", -- google translate
	},
	ruRU = {
		SELF = "????????????????",
	},
	zhCN = {
		SELF = "??????",
		
		USE_CLASS_COLORS = "????????? |cff71D5FFClassColors|r ??????", -- Needs review
		BROKER_CLICK = "|cffFFFFFF??????|r??????????????????",
		BROKER_SHIFT_CLICK = "|cffFFFFFFrShift-??????|r ?????????????????????",
	},
	zhTW = {
		SELF = "??????",
		USE_CLASS_COLORS = "????????? |cff71D5FFClassColors|r ??????", -- Needs review
		BROKER_CLICK = "|cffFFFFFF??????|r??????????????????",
		BROKER_SHIFT_CLICK = "|cffFFFFFFrShift-??????|r ?????????????????????",
	},
}

L.esMX = L.esES

S.L = setmetatable(L[GetLocale()] or L.enUS, {__index = function(t, k)
	local v = rawget(L.enUS, k) or k
	rawset(t, k, v)
	return v
end})
