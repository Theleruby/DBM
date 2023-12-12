local mod	= DBM:NewMod("Magtheridon", "DBM-Magtheridon")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(17257)

mod:SetModelID(18527)
mod:RegisterCombat("emote", L.DBM_MAG_EMOTE_PULL)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 30528 30616",
	"SPELL_CAST_SUCCESS 30511 30657",
	"SPELL_AURA_APPLIED 30757",
	"SPELL_AURA_REFRESH 30757",
	"CHAT_MSG_MONSTER_YELL",
	"CHAT_MSG_MONSTER_EMOTE"
)

local warningHeal			= mod:NewSpellAnnounce(30528, 3)
local warningInfernal		= mod:NewSpellAnnounce(30511, 2)
local warnPhase2			= mod:NewPhaseAnnounce(2)
local warnPhase3			= mod:NewPhaseAnnounce(3)

local specWarnBlastNova		= mod:NewSpecialWarningInterrupt(30616, nil, nil, nil, 3, 2)
local specWarnHeal			= mod:NewSpecialWarningInterrupt(30528, "HasInterrupt", nil, nil, 1, 2)

local timerHeal				= mod:NewCastTimer(2, 30528, nil, nil, nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON)
local timerPhase2			= mod:NewTimer(120+3, "timerP2", "135566", nil, nil, 6)
local timerBlastNovaCD		= mod:NewCDCountTimer(54+0.35, 30616, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON)
local timerDebris			= mod:NewNextTimer(15, 36449, nil, nil, nil, 2, nil, DBM_COMMON_L.HEALER_ICON..DBM_COMMON_L.TANK_ICON)--Only happens once per fight, after the phase 3 yell.
-- quake cannot be detected properly yet
local timerQuake			= mod:NewCastTimer(7, 30657, nil, nil, nil)
local timerQuakeCD			= mod:NewCDTimer(53+2.65, 30657, nil, nil, nil, 2)
local specWarnGTFO			= mod:NewSpecialWarningGTFO(30757, nil, nil, nil, 1, 8)

mod.vb.blastNovaCounter = 1

function mod:OnCombatStart(delay)
	self:SetStage(1)
	self.vb.blastNovaCounter = 1
	timerPhase2:Start(-delay)
end

do
	local Heal, BlastNova, Infernal, Quake = DBM:GetSpellInfo(30528), DBM:GetSpellInfo(30616), DBM:GetSpellInfo(30511), DBM:GetSpellInfo(30657)

	function mod:SPELL_CAST_START(args)
		local spellName = args.spellName
		if spellName ==	Heal then
		--if args.spellId == 30528 then
			if self:CheckInterruptFilter(args.sourceGUID) then
				specWarnHeal:Show(args.sourceName)
				specWarnHeal:Play("kickcast")
				timerHeal:Start()
			else
				warningHeal:Show()
			end
		elseif spellName == BlastNova then
		--elseif args.spellId == 30616 then
			self.vb.blastNovaCounter = self.vb.blastNovaCounter + 1
			specWarnBlastNova:Show(L.name)
			specWarnBlastNova:Play("kickcast")
			--timerQuakeCD:AddTime(10)
			--timerBlastNovaCD:Start(nil, self.vb.blastNovaCounter)
			-- added 7 seconds time from quake manually because quake still isnt detected
			timerBlastNovaCD:Start(54+0.35+7, self.vb.blastNovaCounter)
		end
	end

	function mod:SPELL_CAST_SUCCESS(args)
		local spellName = args.spellName
		if spellName == Infernal and self:AntiSpam(3, 1) then
		--if args.spellId == 30511 and self:AntiSpam(3, 1) then
			warningInfernal:Show()
		elseif spellName == Quake and self:AntiSpam(15, 2) then
			timerQuake:Start()
			timerQuakeCD:Start()
			-- disabled this in case Chromie fixes stuff
			--timerBlastNovaCD:AddTime(7, self.vb.blastNovaCounter)
		end
	end

	local Conflagration = DBM:GetSpellInfo(30757)

	function mod:SPELL_AURA_APPLIED(args)
		local spellName = args.spellName
		if spellName == Conflagration and args:IsPlayer() and self:AntiSpam(3, 3) then
			specWarnGTFO:Show(spellName)
			specWarnGTFO:Play("watchfeet")
		end
	end

	function mod:SPELL_AURA_REFRESH(args)
		local spellName = args.spellName
		if spellName == Conflagration and args:IsPlayer() and self:AntiSpam(3, 3) then
			specWarnGTFO:Show(spellName)
			specWarnGTFO:Play("watchfeet")
		end
	end


	function mod:CHAT_MSG_MONSTER_YELL(msg)
		if msg == L.DBM_MAG_YELL_PHASE2 or msg:find(L.DBM_MAG_YELL_PHASE2) then
			self:SetStage(2)
			warnPhase2:Show()
			timerQuakeCD:Start(28.3+3)
			-- added 7 seconds time from quake manually because quake still isnt detected
			timerBlastNovaCD:Start(55.65+3, self.vb.blastNovaCounter)
			timerPhase2:Cancel()
		elseif msg == L.DBM_MAG_YELL_PHASE3 or msg:find(L.DBM_MAG_YELL_PHASE3) then
			self:SetStage(3)
			warnPhase3:Show()
			timerBlastNovaCD:AddTime(18, self.vb.blastNovaCounter)
			timerQuakeCD:AddTime(18)
			timerDebris:Start(15)
		end
	end

end
