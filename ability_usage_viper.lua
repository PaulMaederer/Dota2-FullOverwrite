-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_usage_viper", package.seeall )

require( GetScriptDirectory().."/constants" )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local Abilities ={
    "viper_poison_attack",
    "viper_nethertoxin",
    "viper_corrosive_skin",
    "viper_viper_strike"
}

local DoTdpsQ = 0
local DoTdpsUlt = 0

function AbilityUsageThink(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return false end

    local bot = GetBot()
    if not bot:IsAlive() then return false end

    -- Check if we're already using an ability
    if bot:IsUsingAbility() or bot:IsChanneling() then return false end

    local target = getHeroVar("Target")
    if not utils.ValidTarget(target) then
        target, _ = utils.GetWeakestHero(bot, bot:GetAttackRange()+200)
        if target ~= nil then
            local totalDmgPerSec = (CalcRightClickDmg(bot, target) + DoTdpsUlt + DoTdpsQ)/bot:GetSecondsPerAttack()
            if totalDmgPerSec*5.1 > target:GetHealth() and HasUlt(bot) then
                setHeroVar("Target", {Obj=target, Id=target:GetPlayerID()})
            end
        end
    end

    if UseUlt(bot) or UseQ(bot) then return true end
    
    return false
end

function UseQ(bot)
    local ability = bot:GetAbilityByName(Abilities[1])

    if (ability == nil) or (not ability:IsFullyCastable()) then
        return false
    end
    
    -- set our local var
    DoTdpsQ = ability:GetSpecialValueInt("damage")
    
    local target = getHeroVar("Target")

    -- if we don't have a valid target, return
    if not utils.ValidTarget(target) then return false end

    -- if target is magic immune or invulnerable, return
    if target.Obj:IsMagicImmune() or target.Obj:IsInvulnerable() then return false end

    DoTdpsQ = target.Obj:GetActualIncomingDamage(DoTdpsQ, DAMAGE_TYPE_MAGICAL)

    if GetUnitToUnitDistance(bot, target.Obj) < (ability:GetCastRange() + 100) then
        utils.TreadCycle(bot, constants.INTELLIGENCE)
        bot:Action_UseAbilityOnEntity(ability, target.Obj)
        return true
    end

    -- harassment code when in lane
    -- DON'T DO THIS HERE - IT'S HANDLED in laning_generic.lua UseOrbEffect()
    return false
end

function HasUlt(bot)
    local ability = bot:GetAbilityByName(Abilities[4])
    if ability == nil or not ability:IsFullyCastable() then
        return false
    end
    
    return true
end

function UseUlt(bot)
    if not HasUlt(bot) then return false end

    local target = getHeroVar("Target")

    -- if we don't have a valid target, return
    if not utils.ValidTarget(target) then return false end

    -- if target is magic immune or invulnerable, return
    if target.Obj:IsMagicImmune() or target.Obj:IsInvulnerable() then return false end

    local ability = bot:GetAbilityByName(Abilities[4])
    
    -- set our local var
    DoTdpsUlt = ability:GetSpecialValueInt("damage")

    if bot:GetLevel() >= 25 then
        local unique2 = bot:GetAbilityByName("special_bonus_unique_viper_2")
        if unique2 and unique2:GetLevel() >= 1 then
            DoTdpsUlt = DoTdpsUlt + 80
        end
    end
    
    DoTdpsUlt = target.Obj:GetActualIncomingDamage(DoTdpsUlt, DAMAGE_TYPE_MAGICAL)
    
    if GetUnitToUnitDistance(target.Obj, bot) < (ability:GetCastRange() + 100) then
        utils.TreadCycle(bot, constants.INTELLIGENCE)
        bot:Action_UseAbilityOnEntity(ability, target.Obj)
        return true
    end

    return false
end

function CalcRightClickDmg(bot, target)
    local toxin = bot:GetAbilityByName(Abilities[2])
    local bonusDmg = 0
    if toxin ~= nil and toxin:GetLevel() > 0 then
        bonusDmg = toxin:GetSpecialValueFloat("bonus_damage")
        local tgtHealthPrct = target:GetHealth()/target:GetMaxHealth()
        local healthRank = math.ceil(tgtHealthPrct/20)
        bonusDmg = bonusDmg * math.pow(2, 5-healthRank)
    end

    local rightClickDmg = bot:GetAttackDamage() + bonusDmg
    local actualDmg = target:GetActualIncomingDamage(rightClickDmg, DAMAGE_TYPE_PHYSICAL)
    return actualDmg
end

for k,v in pairs( ability_usage_viper ) do _G._savedEnv[k] = v end
