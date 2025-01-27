untyped

global function MpTitanAbilityBrute4DomeShield_Init

global function OnWeaponPrimaryAttack_dome_shield

#if SERVER
global function OnWeaponNpcPrimaryAttack_dome_shield
#endif // #if SERVER

global const BRUTE4_DOME_SHIELD_HEALTH = 2500
const PAS_DOME_SHIELD_HEALTH = 3000
global const BRUTE4_DOME_SHIELD_MELEE_MOD = 2.5


function MpTitanAbilityBrute4DomeShield_Init()
{
	RegisterSignal( "KillBruteShield" )
	PrecacheWeapon( "mp_titanability_brute4_bubble_shield" )
}

var function OnWeaponPrimaryAttack_dome_shield( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	entity weaponOwner = weapon.GetWeaponOwner()
	
	#if SERVER
	entity soul = weaponOwner.GetTitanSoul()

	if( weaponOwner.IsPlayer() && IsValid( soul )  && IsValid( soul.soul.bubbleShield ))
		return 0
	#endif //SERVER
	
	if ( weaponOwner.IsPlayer() )
		PlayerUsedOffhand( weaponOwner, weapon )
		
	float duration = weapon.GetWeaponSettingFloat( eWeaponVar.fire_duration )
	thread Brute4GiveShortDomeShield( weapon, weaponOwner, duration )
	
	return weapon.GetWeaponInfoFileKeyField( "ammo_per_shot" )
}

#if SERVER
var function OnWeaponNpcPrimaryAttack_dome_shield( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	entity weaponOwner = weapon.GetWeaponOwner()
	entity soul = weaponOwner.GetTitanSoul()
	if ( IsValid( soul ) && IsValid( soul.soul.bubbleShield ))
		return 0

	float duration = weapon.GetWeaponSettingFloat( eWeaponVar.fire_duration )
	thread Brute4GiveShortDomeShield( weapon, weaponOwner, duration )
	
	return weapon.GetWeaponInfoFileKeyField( "ammo_per_shot" )
}
#endif // #if SERVER

void function Brute4GiveShortDomeShield( entity weapon, entity player, float duration = 6.0 )
{
	#if SERVER
	player.EndSignal( "OnDeath" )

	entity soul = GetSoulFromPlayer( player )
	if ( soul == null )
		return

	soul.EndSignal( "OnTitanDeath" )
	soul.EndSignal( "OnDestroy" )

	// Prevents the player from sprinting
	int slowID = StatusEffect_AddTimed( player, eStatusEffect.move_slow, 0.5, duration, 0 )
	int speedID = StatusEffect_AddTimed( player, eStatusEffect.speed_boost, 0.5, duration, 0 )

	CreateParentedBrute4BubbleShield( player, player.GetOrigin(), player.GetAngles(), duration )

	OnThreadEnd(
	function() : ( player, soul, slowID, speedID )
		{
			if ( IsValid( soul ) )
			{
				if ( IsValid( player ) )
				{
					StatusEffect_Stop( player, slowID )
					StatusEffect_Stop( player, speedID )
				}
			}
		}
	)

	soul.EndSignal( "TitanBrokeBubbleShield" )
	soul.soul.bubbleShield.EndSignal( "OnDestroy" )

	Brute4LetTitanPlayerShootThroughBubbleShield( player, weapon )
	
	wait duration
	#endif
}