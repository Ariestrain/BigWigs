--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewBoss("Thorim", "Ulduar")
if not mod then return end
-- 32865 = thorim, 32882 = behemoth, 32872 = runic colossus, 33196 = Sif
mod:RegisterEnableMob(32865, 32882, 32872)
mod.toggleOptions = {{62042, "ICON"}, 62016, 62331, {62017, "FLASHSHAKE"}, 62338, {62526, "ICON", "SAY"}, 62279, 62130, "proximity", "hardmode", "phase", "bosskill"}

local CL = LibStub("AceLocale-3.0"):GetLocale("Big Wigs: Common")
mod.optionHeaders = {
	[62042] = CL.phase:format(2),
	[62279] = CL.phase:format(3),
	hardmode = "hard",
	phase = "general",
}

mod.proximityCheck = function(unit) return CheckInteractDistance(unit, 3) end
mod.proximitySilent = true

--------------------------------------------------------------------------------
-- Locals
--

local chargeCount = 1
local pName = UnitName("player")

local hardModeMessageID

--------------------------------------------------------------------------------
-- Localization
--

local L = LibStub("AceLocale-3.0"):NewLocale("Big Wigs: Thorim", "enUS", true)
if L then
	L["Runic Colossus"] = true -- For the runic barrier emote.

	L.phase = "Phases"
	L.phase_desc = "Warn for phase changes."
	L.phase1_message = "Phase 1"
	L.phase2_trigger = "Interlopers! You mortals who dare to interfere with my sport will pay.... Wait--you..."
	L.phase2_message = "Phase 2, berserk in 6:15!"
	L.phase3_trigger = "Impertinent whelps, you dare challenge me atop my pedestal? I will crush you myself!"
	L.phase3_message = "Phase 3 - %s engaged!"

	L.hardmode = "Hard mode timer"
	L.hardmode_desc = "Show timer for when you have to reach Thorim in order to enter hard mode in phase 3."
	L.hardmode_warning = "Hard mode expires"

	L.shock_message = "You're getting shocked!"
	L.barrier_message = "Barrier up!"

	L.detonation_say = "I'm a bomb!"

	L.charge_message = "Charged x%d!"
	L.charge_bar = "Charge %d"

	L.strike_bar = "Unbalancing Strike CD"

	L.end_trigger = "Stay your arms! I yield!"
end
L = LibStub("AceLocale-3.0"):GetLocale("Big Wigs: Thorim")
mod.locale = L

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Hammer", 62042)
	self:Log("SPELL_CAST_SUCCESS", "Charge", 62279)
	self:Log("SPELL_CAST_SUCCESS", "StrikeCooldown", 62130)
	self:Log("SPELL_MISSED", "StrikeCooldown", 62130)
	self:Log("SPELL_AURA_APPLIED", "Strike", 62130)
	self:Log("SPELL_AURA_APPLIED", "Detonation", 62526)
	self:Log("SPELL_AURA_APPLIED", "Orb", 62016)
	self:Log("SPELL_AURA_APPLIED", "Impale", 62331, 62418)
	self:Log("SPELL_AURA_APPLIED", "Barrier", 62338)
	self:Log("SPELL_DAMAGE", "Shock", 62017)
	self:Log("SPELL_MISSED", "Shock", 62017)

	self:Yell("PhaseTwo", L["phase2_trigger"])
	self:Yell("PhaseThree", L["phase3_trigger"])
	self:Yell("Win", L["end_trigger"])

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
end

function mod:VerifyEnable(unit)
	return (UnitIsEnemy(unit, "player") and UnitCanAttack(unit, "player")) and true or false
end

function mod:OnEngage()
	chargeCount = 1
	self:Message("phase", L["phase1_message"], "Attention")
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Barrier(_, spellId, _, _, spellName)
	self:Message(spellId, L["barrier_message"], "Urgent", spellId, "Alarm")
	self:Bar(spellId, spellName, 20, spellId)
end

function mod:Charge(_, spellId)
	self:Message(spellId, L["charge_message"]:format(chargeCount), "Attention", spellId)
	chargeCount = chargeCount + 1
	self:Bar(spellId, L["charge_bar"]:format(chargeCount), 15, spellId)
end

function mod:Hammer(player, spellId, _, _, spellName)
	self:TargetMessage(spellId, spellName, player, "Urgent", spellId)
	self:Bar(spellId, spellName, 16, spellId)
	self:PrimaryIcon(spellId, player)
end

function mod:Strike(player, spellId, _, _, spellName)
	self:TargetMessage(spellId, spellName, player, "Attention", spellId)
	self:Bar(spellId, spellName..": "..player, 15, spellId)
end

function mod:StrikeCooldown(player, spellId)
	self:Bar(spellId, L["strike_bar"], 25, spellId)
end

function mod:Orb(_, spellId, _, _, spellName)
	self:Message(spellId, spellName, "Urgent", spellId)
	self:Bar(spellId, spellName, 15, spellId)
end

local last = 0
function mod:Shock(player, spellId)
	local time = GetTime()
	if (time - last) > 5 then
		last = time
		if player == pName then
			self:LocalMessage(spellId, L["shock_message"], "Personal", spellId, "Info")
			self:FlashShake(spellId)
		end
	end
end

function mod:Impale(player, spellId, _, _, spellName)
	self:TargetMessage(spellId, spellName, player, "Important", spellId)
end

function mod:Detonation(player, spellId, _, _, spellName)
	if player == pName and bit.band(self.db.profile[(GetSpellInfo(spellId))], BigWigs.C.SAY) == BigWigs.C.SAY then
		SendChatMessage(L["detonation_say"], "SAY")
	else
		self:TargetMessage(spellId, spellName, player, "Important", spellId)
	end
	self:Bar(spellId, spellName..": "..player, 4, spellId)
	self:PrimaryIcon(spellId, player)
end

function mod:PhaseTwo()
	self:Message("phase", L["phase2_message"], "Attention")
	self:Bar("phase", CL["berserk"], 375, 20484)
	self:Bar("hardmode", L["hardmode"], 173, 6673)
	hardModeMessageID = self:DelayedMessage("hardmode", 173, L["hardmode_warning"], "Attention")
end

function mod:PhaseThree()
	self:CancelScheduledEvent(hardModeMessageID)
	self:SendMessage("BigWigs_StopBar", self, L["hardmode"])
	self:SendMessage("BigWigs_StopBar", self, CL["berserk"])
	self:Message("phase", L["phase3_message"]:format(unit), "Attention")
	self:OpenProximity(5)
end

