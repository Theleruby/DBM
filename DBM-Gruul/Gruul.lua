local mod	= DBM:NewMod("Gruul", "DBM-Gruul")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(19044)

mod:SetModelID(19044)
mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 33525 33654",
	"SPELL_CAST_SUCCESS 36297",
	"SPELL_AURA_APPLIED 36300 36240",
	"SPELL_AURA_APPLIED_DOSE 36300"
)

local warnGrowth		= mod:NewStackAnnounce(36300, 2)
local warnGroundSlam	= mod:NewSpellAnnounce(33525, 3)
local warnShatter		= mod:NewSpellAnnounce(33654, 4)
local warnSilence		= mod:NewSpellAnnounce(36297, 4)

local specWarnCaveIn	= mod:NewSpecialWarningGTFO(36240, nil, nil, nil, 1, 6)
local specWarnShatter	= mod:NewSpecialWarningMoveAway(33654, nil, nil, nil, 1, 6)

local timerGrowthCD		= mod:NewNextTimer(30+0.3, 36300, nil, nil, nil, 6)
local timerGroundSlamCD	= mod:NewCDTimer(74-14, 33525, nil, nil, nil, 2)--74-80 second variation,and this is just from 2 pulls.
local timerShatterCD	= mod:NewNextTimer(10-0.3, 33654, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 4)--10 seconds after ground slam
local timerSilenceCD	= mod:NewCDTimer(32+7.9, 36297, nil, nil, nil, 5, nil, DBM_COMMON_L.HEALER_ICON)--Also showing a HUGE variation of 32-130 seconds.

mod:AddRangeFrameOption(mod.Options.RangeDistance == "Smaller" and 11+2 or 18+2, 33654)
mod:AddDropdownOption("RangeDistance", {"Smaller", "Safe"}, "Safe", "misc")

do
	function mod:OnCombatStart(delay)
		timerGrowthCD:Start(-delay)
		timerGroundSlamCD:Start(40-5-delay)
		timerSilenceCD:Start(-delay)
		if self.Options.RangeFrame then
			DBM.RangeCheck:Show(self.Options.RangeDistance == "Smaller" and 11 or 18)
		end
	end

	function mod:OnCombatEnd()
		if self.Options.RangeFrame then
			DBM.RangeCheck:Hide()
		end
	end

	local GroundSlam, Shatter = DBM:GetSpellInfo(33525), DBM:GetSpellInfo(33654)

	function mod:SPELL_CAST_START(args)
		local spellName = args.spellName
		if spellName == GroundSlam then
		--if args.spellId == 33525 then--Ground Slam
			warnGroundSlam:Show()
			timerShatterCD:Start() 
			timerGroundSlamCD:Start(74-14)
			specWarnShatter:Schedule(3)
			specWarnShatter:ScheduleVoice(3, "scatter")

			timerGrowthCD:AddTime(9.7)
			timerSilenceCD:AddTime(9.7)
		elseif spellName == Shatter then
		--elseif args.spellId == 33654 then--Shatter
			warnShatter:Show()
		end
	end

	local Reverberation = DBM:GetSpellInfo(36297)

	function mod:SPELL_CAST_SUCCESS(args)
		local spellName = args.spellName
		if spellName == Reverberation then
		--if args.spellId == 36297 then--Reverberation (Silence)
			warnSilence:Show()
			timerSilenceCD:Start()
		end
	end

	local Growth, CaveIn = DBM:GetSpellInfo(36300), DBM:GetSpellInfo(36240)

	function mod:SPELL_AURA_APPLIED(args)
		local spellName = args.spellName
		if spellName == Growth then
		--if args.spellId == 36300 then--Growth
			local amount = args.amount or 1
			warnGrowth:Show(spellName, amount)
			timerGrowthCD:Start()
		elseif spellName == CaveIn and args:IsPlayer() then
		--elseif args.spellId == 36240 and args:IsPlayer() and not self:IsTrivial() then--Cave In
			specWarnCaveIn:Show(spellName)
			specWarnCaveIn:Play("watchfeet")
		end
	end
	mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

end