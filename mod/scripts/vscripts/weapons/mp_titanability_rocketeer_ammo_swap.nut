global function OnWeaponPrimaryAttack_rocketeer_ammo_swap
global function MpTitanAbilityRocketeerAmmoSwap_Init

#if SERVER
global function OnWeaponNpcPrimaryAttack_rocketeer_ammo_swap
#endif

void function MpTitanAbilityRocketeerAmmoSwap_Init()
{
	RegisterSignal( "SwapRocketAmmo" )
}

var function OnWeaponPrimaryAttack_rocketeer_ammo_swap( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	entity weaponOwner = weapon.GetWeaponOwner()
	array<entity> weapons = GetPrimaryWeapons( weaponOwner )
	entity primaryWeapon = weapons[0]

	if ( !IsValid( primaryWeapon ) )
		return false
	else if ( weaponOwner.ContextAction_IsActive() )
		return false
	else if ( primaryWeapon.GetWeaponClassName() != "mp_titanweapon_rocketeer_rocketstream" )
		return false
	else if ( primaryWeapon.HasMod( "burn_mod_titan_rocket_launcher" ) )
		return false

	weaponOwner.e.ammoSwapPlaying = true

	#if SERVER
	thread SwapRocketAmmo( weaponOwner, weapon)
	#endif

	if ( weaponOwner.IsPlayer() )
		PlayerUsedOffhand( weaponOwner, weapon )

	return 1
}

#if SERVER
var function OnWeaponNpcPrimaryAttack_rocketeer_ammo_swap( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	printt( "npc trying to swap ammo" )
	OnWeaponPrimaryAttack_rocketeer_ammo_swap( weapon, attackParams )
}

void function SwapRocketAmmo( entity weaponOwner, entity offhand )
{
	weaponOwner.Signal( "SwapRocketAmmo" )
	weaponOwner.EndSignal( "SwapRocketAmmo" )
	weaponOwner.EndSignal( "OnDestroy" )
	weaponOwner.EndSignal( "OnDeath" )
	weaponOwner.EndSignal( "InventoryChanged" )
	weaponOwner.EndSignal( "DisembarkingTitan" )
	weaponOwner.EndSignal( "TitanEjectionStarted" )

	table e = {}
	e.deployWeapon <- false

	EmitSoundOnEntity( weaponOwner, "Coop_AmmoBox_AmmoRefill" )
	printt("used ammo swap")

	if ( weaponOwner.IsPlayer() )
	{
		weaponOwner.HolsterWeapon()

		entity defensive = weaponOwner.GetOffhandWeapon( OFFHAND_LEFT )
		if( IsValid( defensive ) )
			if( defensive.GetWeaponInfoFileKeyField( "fire_mode" ) == "offhand_instant" )         
				defensive.AllowUse( true )
			else
				defensive.AllowUse( false )

		entity ordnance = weaponOwner.GetOffhandWeapon( OFFHAND_RIGHT )
		if ( IsValid( ordnance ) )
			ordnance.AllowUse( false )

		e.deployWeapon = true

		OnThreadEnd(
		function() : ( weaponOwner, e )
			{
				if ( e.deployWeapon )
				{
					if ( IsValid( weaponOwner ) )
					{
						if ( weaponOwner.IsPlayer() )
						{
							weaponOwner.DeployWeapon()
							entity defensive = weaponOwner.GetOffhandWeapon( OFFHAND_LEFT )
							if( IsValid( defensive ) ) 
								defensive.AllowUse( true )

							entity ordnance = weaponOwner.GetOffhandWeapon( OFFHAND_RIGHT )
							if ( IsValid( ordnance ) )
								ordnance.AllowUse( true )
						}
					}
				}
			}
		)

		wait 0.75
	}
	else if ( weaponOwner.IsNPC() && HasAnim( weaponOwner, "at_reload_quick" ) )
	{
		weaponOwner.Anim_ScriptedPlay( "at_reload_quick" )
	}

	entity weapon = weaponOwner.GetMainWeapons()[0]
	array<string> mods = weapon.GetMods()
	if ( !mods.contains( "burn_mod_titan_rocket_launcher" ) )
	{
		mods.append( "burn_mod_titan_rocket_launcher" )
		weapon.SetMods( mods )
	}

	weapon.SetWeaponPrimaryClipCount( weapon.GetWeaponPrimaryClipCountMax() )

	OnThreadEnd(
	function() : ( weaponOwner, weapon, offhand)
		{
			if ( IsValid( weapon ) )
			{
				array<string> mods = weapon.GetMods()
				if ( mods.contains( "burn_mod_titan_rocket_launcher" ) )
				{
					mods.fastremovebyvalue( "burn_mod_titan_rocket_launcher" )
					weapon.SetMods( mods )
					offhand.SetWeaponPrimaryClipCount(1)
				}
			}
		}
	)

	if ( weaponOwner.IsPlayer() )
	{
		weaponOwner.DeployWeapon()
		entity defensive = weaponOwner.GetOffhandWeapon( OFFHAND_LEFT )
		if( IsValid( defensive ) ) 
			defensive.AllowUse( true )

		entity ordnance = weaponOwner.GetOffhandWeapon( OFFHAND_RIGHT )
		if ( IsValid( ordnance ) )
			ordnance.AllowUse( true )
			
		e.deployWeapon = false
		while( IsValid( weapon ) && !weapon.IsReloading() && weapon.GetWeaponPrimaryClipCount() > 0 )
			wait 0.1
	}
	else
	{
		wait 10.0
	}
}
#endif