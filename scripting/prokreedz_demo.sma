#include <amxmodx>
#include <colorchat>

#define KZ_LEVEL ADMIN_KICK
new const KZ_DIR[] = "addons/amxmodx/configs/kz"

new bool:Safe

public plugin_init()
{
	register_plugin("ProKreedz Safe-Demo","1.0","nucLeaR")

	register_clcmd("say /demo", "Demo_CVars", KZ_LEVEL, "")
	register_clcmd("say /record", "Demo_CVars", KZ_LEVEL, "")
	register_clcmd("say /public", "Public_CVars", KZ_LEVEL, "")
	register_clcmd("say /pub", "Public_CVars", KZ_LEVEL, "")
}

public Demo_CVars(id)
{
	if (!(  get_user_flags( id ) & KZ_LEVEL ))
	{
		ColorChat(id, GREEN, "[XJ]^x01 You have no acces to that command.")
		return PLUGIN_HANDLED
	}

	set_cvar_num("kz_respawn_ct", 0)
	set_cvar_num("kz_drop_weapons",  1)
	set_cvar_num("kz_show_timer", 0)
	set_cvar_num("kz_remove_drops",  0)
	set_cvar_num("kz_drop_weapons",  1)
	set_cvar_num("kz_other_weapons",  1)
	set_cvar_num("kz_pick_weapons", 1)
	set_cvar_num("kz_use_radio",  1)
	set_cvar_num("kz_pause",  0)
	set_cvar_num("kz_semiclip",  0)
	set_cvar_num("kz_save_autostart", 0)

	Safe = true
	ColorChat(0, GREEN, "[XJ]^x01 Plugin is now^x03 safe^x01 for recording.")
	return PLUGIN_HANDLED
}

public Public_CVars(id)
{
	if (! (get_user_flags( id ) & KZ_LEVEL) )
	{
		ColorChat(id, GREEN, "[XJ]^x01 You have no acces to that command.")

		return PLUGIN_HANDLED
	}

	new kreedz_cfg[128]
	formatex(kreedz_cfg,128,"%s/kreedz.cfg",KZ_DIR)

	if( file_exists( kreedz_cfg ) )
	{
		server_cmd("exec %s",kreedz_cfg)
		Safe = false
	}
	else
	{
		set_cvar_num("kz_respawn_ct", 0)
		set_cvar_num("kz_drop_weapons",  0)
		set_cvar_num("kz_show_timer", 1)
		set_cvar_num("kz_remove_drops",  1)
		set_cvar_num("kz_drop_weapons",  0)
		set_cvar_num("kz_use_radio",  0)
		set_cvar_num("kz_pause",  1)
		set_cvar_num("kz_semiclip",  1)
		set_cvar_num("kz_save_autostart", 1)
		Safe = false
	}

	if (!Safe)
	ColorChat(0, GREEN, "[XJ]^x01 Plugin is now^x03 not safe^x01 for recording.")

	return PLUGIN_HANDLED
}
