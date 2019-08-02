#include <amxmodx>
#include <cstrike>
#include <colorchat>
#include <fun>
#include <fakemeta>
#include <hamsandwich>

#define USE_SQL

#if defined USE_SQL
 #include <sqlx>
 #include <geoip>
#endif

#define KZ_LEVEL ADMIN_KICK
#define MSG MSG_ONE_UNRELIABLE
#define MAX_ENTITYS 900+15*32
#define IsOnLadder(%1) (pev(%1, pev_movetype) == MOVETYPE_FLY)
#define VERSION "2.31"

#define SCOREATTRIB_NONE    0
#define SCOREATTRIB_DEAD    ( 1 << 0 )
#define SCOREATTRIB_BOMB    ( 1 << 1 )
#define SCOREATTRIB_VIP  ( 1 << 2 )


new g_iPlayers[32], g_iNum, g_iPlayer
new const g_szAliveFlags[] = "a"
#define RefreshPlayersList()    get_players(g_iPlayers, g_iNum, g_szAliveFlags)

new const FL_ONGROUND2 = ( FL_ONGROUND | FL_PARTIALGROUND | FL_INWATER |  FL_CONVEYOR | FL_FLOAT )
new const KZ_STARTFILE[] = "start.ini"
new const KZ_STARTFILE_TEMP[] = "temp_start.ini"

#if defined USE_SQL
new Handle:g_SqlTuple
new Handle:SqlConnection
new g_Error[512]
/*new kz_sql_host
new kz_sql_user
new kz_sql_pass
new kz_sql_db*/
new kz_sql_name
new kz_sql_files
#else
new Float:Pro_Times[24]
new Pro_AuthIDS[24][32]
new Pro_Names[24][32]
new Pro_Date[24][32]
new Float:Noob_Tiempos[24]
new Noob_AuthIDS[24][32]
new Noob_Names[24][32]
new Noob_Date[24][32]
new Noob_CheckPoints[24]
new Noob_GoChecks[24]
new Noob_Weapon[24][32]
#endif

new Float:Checkpoints[33][2][3]
new Float:timer_time[33]
new Float:g_pausetime[33]
new Float:antihookcheat[33]
new Float:SpecLoc[33][3]
new Float:NoclipPos[33][3]
new Float:PauseOrigin[33][3]
new Float:SavedStart[33][3]
new hookorigin[33][3]
new Float:DefaultStartPos[3]

new Float:SavedTime[33]
new SavedChecks[33]
new SavedGoChecks[33]
new SavedScout[33]
new SavedOrigins[33][3]

new bool:g_bCpAlternate[33]
new bool:timer_started[33]
new bool:IsPaused[33]
new bool:WasPaused[33]
new bool:firstspawn[33]
new bool:canusehook[33]
new bool:ishooked[33]
new bool:user_has_scout[33]
new bool:NightVisionUse[33]
new bool:HealsOnMap
new bool:gViewInvisible[33]
new bool:gMarkedInvisible[33] = { true, ...};
new bool:gWaterInvisible[33]
new bool:gWaterEntity[MAX_ENTITYS]
new bool:gWaterFound
new bool:DefaultStart
new bool:AutoStart[33]

new Trie:g_tStarts
new Trie:g_tStops;

new checknumbers[33]
new gochecknumbers[33]
new chatorhud[33]
new ShowTime[33]
new MapName[64]
new Kzdir[128]
new SavePosDir[128]
new prefix[33]
#if !defined USE_SQL
new Topdir[128]
#endif

new kz_checkpoints
new kz_cheatdetect
new kz_spawn_mainmenu
new kz_show_timer
new kz_chatorhud
new kz_hud_color
new kz_chat_prefix
new hud_message
new kz_other_weapons
new kz_maxspeedmsg
new kz_drop_weapons
new kz_remove_drops
new kz_pick_weapons
new kz_reload_weapons
new kz_use_radio
new kz_hook_prize
new kz_hook_sound
new kz_hook_speed
new kz_pause
new kz_noclip_pause
new kz_nvg
new kz_nvg_colors
new kz_vip
new kz_respawn_ct
new kz_save_pos
new kz_save_pos_gochecks
new kz_semiclip
new kz_semiclip_transparency
new kz_spec_saves
new kz_save_autostart
new kz_top15_authid
new Sbeam = 0

new const other_weapons[8] =
{
	CSW_SCOUT, CSW_P90, CSW_FAMAS, CSW_SG552,
	CSW_M4A1, CSW_M249, CSW_AK47, CSW_AWP
}

new const other_weapons_name[8][] =
{
	"weapon_scout", "weapon_p90", "weapon_famas", "weapon_sg552",
	"weapon_m4a1", "weapon_m249", "weapon_ak47", "weapon_awp"
}

new const g_weaponsnames[][] =
{
	"", // NULL
	"p228", "shield", "scout", "hegrenade", "xm1014", "c4",
	"mac10", "aug", "smokegrenade", "elite", "fiveseven",
	"ump45", "sg550", "galil", "famas", "usp", "glock18",
	"awp", "mp5navy", "m249", "m3", "m4a1", "tmp", "g3sg1",
	"flashbang", "deagle", "sg552", "ak47", "knife", "p90",
	"glock",  "elites", "fn57", "mp5", "vest", "vesthelm",
	"flash", "hegren", "sgren", "defuser", "nvgs", "primammo",
	"secammo", "km45", "9x19mm", "nighthawk", "228compact",
	"12gauge", "autoshotgun", "mp", "c90", "cv47", "defender",
	"clarion", "krieg552", "bullpup", "magnum", "d3au1",
	"krieg550"
}

new const g_block_commands[][]=
{
	"buy", "buyammo1", "buyammo2", "buyequip",
	"cl_autobuy", "cl_rebuy", "cl_setautobuy", "cl_setrebuy"

}

#if defined USE_SQL
enum
{
	PRO_TOP,
	NUB_TOP,
	PLAYERS_RANKING_PRO,
	PLAYERS_RANKING_NUB
}
#endif

// =================================================================================================

public plugin_init()
{
	register_plugin("ProKreedz", VERSION, "nucLeaR & p4ddY")

	kz_checkpoints = register_cvar("kz_checkpoints","1")
	kz_cheatdetect = register_cvar("kz_cheatdetect","1")
	kz_spawn_mainmenu = register_cvar("kz_spawn_mainmenu", "1")
	kz_show_timer = register_cvar("kz_show_timer", "1")
	kz_chatorhud = register_cvar("kz_chatorhud", "2")
	kz_chat_prefix = register_cvar("kz_chat_prefix", "[KZ]")
	kz_hud_color = register_cvar("kz_hud_color", "12 122 221")
	kz_other_weapons = register_cvar("kz_other_weapons","1")
	kz_drop_weapons = register_cvar("kz_drop_weapons", "0")
	kz_remove_drops = register_cvar("kz_remove_drops", "1")
	kz_pick_weapons = register_cvar("kz_pick_weapons", "0")
	kz_reload_weapons = register_cvar("kz_reload_weapons", "0")
	kz_maxspeedmsg = register_cvar("kz_maxspeedmsg","1")
	kz_hook_prize = register_cvar("kz_hook_prize","1")
	kz_hook_sound = register_cvar("kz_hook_sound","1")
	kz_hook_speed = register_cvar("kz_hook_speed", "300.0")
	kz_use_radio = register_cvar("kz_use_radio", "0")
	kz_pause = register_cvar("kz_pause", "1")
	kz_noclip_pause = register_cvar("kz_noclip_pause", "1")
	kz_nvg = register_cvar("kz_nvg","1")
	kz_nvg_colors = register_cvar("kz_nvg_colors","5 0 255")
	kz_vip = register_cvar("kz_vip","1")
	kz_respawn_ct = register_cvar("kz_respawn_ct", "1")
	kz_semiclip = register_cvar("kz_semiclip", "1")
	kz_semiclip_transparency = register_cvar ("kz_semiclip_transparency", "85")
	kz_spec_saves = register_cvar("kz_spec_saves", "1")
	kz_save_autostart = register_cvar("kz_save_autostart", "1")
	kz_top15_authid = register_cvar("kz_top15_authid", "1")
	kz_save_pos = register_cvar("kz_save_pos", "1")
	kz_save_pos_gochecks = register_cvar("kz_save_pos_gochecks", "1")

	#if defined USE_SQL
	/*kz_sql_host = register_cvar("kz_sql_host", "") // Host of DB
	kz_sql_user = register_cvar("kz_sql_user", "") // Username of DB
	kz_sql_pass = register_cvar("kz_sql_pass", "", FCVAR_PROTECTED) // Password for DB user
	kz_sql_db = register_cvar("kz_sql_db", "") // DB Name for the top 15*/
	kz_sql_name = register_cvar("kz_sql_server", "") // Name of server
	kz_sql_files = register_cvar("kz_sql_files", "") // Path of the PHP files
	#endif

	register_clcmd("/cp","CheckPoint")
	register_clcmd("drop", "BlockDrop")
	register_clcmd("/gc", "GoCheck")
	register_clcmd("+hook","hook_on",KZ_LEVEL)
	register_clcmd("-hook","hook_off",KZ_LEVEL)
	register_concmd("kz_hook","give_hook", KZ_LEVEL, "<name|#userid|steamid|@ALL> <on/off>")
	register_concmd("nightvision","ToggleNVG")
	register_clcmd("radio1", "BlockRadio")
	register_clcmd("radio2", "BlockRadio")
	register_clcmd("radio3", "BlockRadio")
	register_clcmd("/tp","GoCheck")

	kz_register_saycmd("cp","CheckPoint",0)
	kz_register_saycmd("chatorhud", "ChatHud", 0)
	kz_register_saycmd("ct","ct",0)
	kz_register_saycmd("gc", "GoCheck",0)
	kz_register_saycmd("gocheck", "GoCheck",0)
	kz_register_saycmd("god", "GodMode",0)
	kz_register_saycmd("godmode", "GodMode", 0)
	kz_register_saycmd("invis", "InvisMenu", 0)
	kz_register_saycmd("kz", "kz_menu", 0)
	kz_register_saycmd("menu","kz_menu", 0)
	kz_register_saycmd("nc", "noclip", 0)
	kz_register_saycmd("noclip", "noclip", 0)
	/*kz_register_saycmd("noob10", "NoobTop_show", 0)
	kz_register_saycmd("noob15", "NoobTop_show", 0)
	kz_register_saycmd("nub10", "NoobTop_show", 0)
	kz_register_saycmd("nub15", "NoobTop_show", 0)*/
	kz_register_saycmd("pause", "Pause", 0)
	kz_register_saycmd("pinvis", "cmdInvisible", 0)
	/*kz_register_saycmd("pro10", "ProTop_show", 0)
	kz_register_saycmd("pro15", "ProTop_show", 0)*/
	kz_register_saycmd("reset", "reset_checkpoints", 0)
	kz_register_saycmd("respawn", "goStart", 0)
	kz_register_saycmd("savepos", "SavePos", 0)
	kz_register_saycmd("scout", "cmdScout", 0)
	kz_register_saycmd("setstart", "setStart", KZ_LEVEL)
	kz_register_saycmd("showtimer", "ShowTimer_Menu", 0)
	kz_register_saycmd("spec", "ct", 0)
	kz_register_saycmd("start", "goStart", 0)
	kz_register_saycmd("stuck", "Stuck", 0)
	kz_register_saycmd("teleport", "GoCheck", 0)
	kz_register_saycmd("timer", "ShowTimer_Menu", 0)
	kz_register_saycmd("top15", "top15menu",0)
	kz_register_saycmd("top10", "top15menu",0)
	kz_register_saycmd("tp", "GoCheck",0)
	kz_register_saycmd("usp", "cmdUsp", 0)
	kz_register_saycmd("weapons", "weapons", 0)
	kz_register_saycmd("guns", "weapons", 0)
	kz_register_saycmd("winvis", "cmdWaterInvisible", 0)

	#if defined USE_SQL
	kz_register_saycmd("prorecords", "ProRecs_show", 0)
	kz_register_saycmd("prorecs", "ProRecs_show", 0)
	#endif

	register_event("CurWeapon", "curweapon", "be", "1=1")
	register_event( "StatusValue", "EventStatusValue", "b", "1>0", "2>0" );

	register_forward(FM_AddToFullPack, "FM_client_AddToFullPack_Post", 1)

	RegisterHam( Ham_Player_PreThink, "player", "Ham_CBasePlayer_PreThink_Post", 1)
	RegisterHam( Ham_Use, "func_button", "fwdUse", 0)
	RegisterHam( Ham_Killed, "player", "Ham_CBasePlayer_Killed_Post", 1)
	RegisterHam( Ham_Touch, "weaponbox", "FwdSpawnWeaponbox" )
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn", 1 )
	RegisterHam( Ham_Touch, "weaponbox", "GroundWeapon_Touch")

	register_message( get_user_msgid( "ScoreAttrib" ), "MessageScoreAttrib" )
	register_dictionary("prokreedz.txt")
	get_pcvar_string(kz_chat_prefix, prefix, 31)
	get_mapname(MapName, 63)
	set_msg_block(get_user_msgid("ClCorpse"), BLOCK_SET)
	set_task(0.5,"timer_task",2000,"",0,"ab")
	#if defined USE_SQL
	set_task(0.2, "plugin_sql")
	#endif

	new kreedz_cfg[128], ConfigDir[64]
	get_configsdir( ConfigDir, 64)
	formatex(Kzdir,128, "%s/kz", ConfigDir)
	if( !dir_exists(Kzdir) )
		mkdir(Kzdir)

	#if !defined USE_SQL
	formatex(Topdir,128, "%s/top15", Kzdir)
	if( !dir_exists(Topdir) )
		mkdir(Topdir)
	#endif

	formatex(SavePosDir, 128, "%s/savepos", Kzdir)
	if( !dir_exists(SavePosDir) )
		mkdir(SavePosDir)

	formatex(kreedz_cfg,128,"%s/kreedz.cfg", Kzdir)

	if( file_exists( kreedz_cfg ) )
	{
		server_exec()
		server_cmd("exec %s",kreedz_cfg)
	}

	for(new i = 0; i < sizeof(g_block_commands) ; i++)
		register_clcmd(g_block_commands[i], "BlockBuy")

	g_tStarts = TrieCreate( )
	g_tStops  = TrieCreate( )

	new const szStarts[ ][ ] =
	{
		"counter_start", "clockstartbutton", "firsttimerelay", "but_start", "counter_start_button",
		"multi_start", "timer_startbutton", "start_timer_emi", "gogogo"
	}

	new const szStops[ ][ ]  =
	{
		"counter_off", "clockstopbutton", "clockstop", "but_stop", "counter_stop_button",
		"multi_stop", "stop_counter", "m_counter_end_emi"
	}

	for( new i = 0; i < sizeof szStarts; i++ )
		TrieSetCell( g_tStarts, szStarts[ i ], 1 )

	for( new i = 0; i < sizeof szStops; i++ )
		TrieSetCell( g_tStops, szStops[ i ], 1 )
}

#if defined USE_SQL
public plugin_sql()
{

	g_SqlTuple = SQL_MakeStdTuple();


	new ErrorCode
	SqlConnection = SQL_Connect(g_SqlTuple,ErrorCode,g_Error,511)

	if(!SqlConnection)
	{
		server_print("[KZ] TOP15 SQL: Could not connect to SQL database.!")
		log_amx("[KZ] TOP15 SQL: Could not connect to SQL database.")
		return pause("a")
	}

	new createinto[1001]
	formatex(createinto, 1000, "CREATE TABLE IF NOT EXISTS `kz_pro15` (`mapname` varchar(64) NOT NULL, `authid` varchar(64) NOT NULL, `country` varchar(6) NOT NULL, `name` varchar(64) NOT NULL, `time` decimal(65,2)   NOT NULL, `date` datetime NOT NULL, `weapon` varchar(64) NOT NULL, `server` varchar(64) NOT NULL)")
	SQL_ThreadQuery(g_SqlTuple,"QueryHandle", createinto)
	formatex(createinto, 1000, "CREATE TABLE IF NOT EXISTS `kz_nub15` (`mapname` varchar(64) NOT NULL, `authid` varchar(64) NOT NULL, `country` varchar(6) NOT NULL, `name` varchar(64) NOT NULL, `time`decimal(65,2)  NOT NULL, `date` datetime NOT NULL, `weapon` varchar(64) NOT NULL, `server` varchar(64) NOT NULL, `checkpoints` real NOT NULL, `gocheck` real NOT NULL)")
	SQL_ThreadQuery(g_SqlTuple,"QueryHandle", createinto)

	return PLUGIN_CONTINUE
}

public QueryHandle(iFailState, Handle:hQuery, szError[], iErrnum, cData[], iSize, Float:fQueueTime)
{
	if( iFailState != TQUERY_SUCCESS )
	{
		log_amx("[KZ] TOP15 SQL: SQL Error #%d - %s", iErrnum, szError)
		ColorChat(0, GREEN,  "[KZ]^x01: Warning the SQL Tops can not be saved.")
	}

	server_print("[KZ] Server Sending Info to SQL Server")

	return PLUGIN_CONTINUE
}
#endif

public plugin_precache()
{
	hud_message = CreateHudSyncObj()
	RegisterHam( Ham_Spawn, "func_door", "FwdHamDoorSpawn", 1 )
	precache_sound("weapons/xbow_hit2.wav")
	Sbeam = precache_model("sprites/laserbeam.spr")
}

public plugin_cfg()
{
	#if !defined USE_SQL
	for (new i = 0 ; i < 15; ++i)
	{
		Pro_Times[i] = 999999999.00000;
		Noob_Tiempos[i] = 999999999.00000;
	}

	read_pro15()
	read_Noob15()
	#endif

	new startcheck[100], data[256], map[64], x[13], y[13], z[13];
	formatex(startcheck, 99, "%s/%s", Kzdir, KZ_STARTFILE)
	new f = fopen(startcheck, "rt" )
	while( !feof( f ) )
	{
		fgets( f, data, sizeof data - 1 )
		parse( data, map, 63, x, 12, y, 12, z, 12)

		if( equali( map, MapName ) )
		{
			DefaultStartPos[0] = str_to_float(x)
			DefaultStartPos[1] = str_to_float(y)
			DefaultStartPos[2] = str_to_float(z)

			DefaultStart = true
			break;
		}
	}
	fclose(f)

	new ent = -1;
	while( ( ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_water") ) != 0 )
	{
		if( !gWaterFound )
		{
			gWaterFound = true;
		}

		gWaterEntity[ent] = true;
	}

	ent = -1;
	while( ( ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_illusionary") ) != 0 )
	{
		if( pev( ent, pev_skin ) ==  CONTENTS_WATER )
		{
			if( !gWaterFound )
			{
				gWaterFound = true;
			}

			gWaterEntity[ent] = true;
		}
	}

	ent = -1;
	while( ( ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_conveyor") ) != 0 )
	{
		if( pev( ent, pev_spawnflags ) == 3 )
		{
			if( !gWaterFound )
			{
				gWaterFound = true;
			}

			gWaterEntity[ent] = true;
		}
	}
}

public client_command(id)
{

	new sArg[13];
	if( read_argv(0, sArg, 12) > 11 )
	{
		return PLUGIN_CONTINUE;
	}

	for( new i = 0; i < sizeof(g_weaponsnames); i++ )
	{
		if( equali(g_weaponsnames[i], sArg, 0) )
		{
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

// =================================================================================================
// Global Functions
// =================================================================================================

public Pause(id)
{

	if (get_pcvar_num(kz_pause) == 0)
	{
		kz_chat(id, "%L", id, "KZ_PAUSE_DISABLED")

		return PLUGIN_HANDLED
	}

	if(! is_user_alive(id) )
	{
		kz_chat(id, "%L", id, "KZ_NOT_ALIVE")

		return PLUGIN_HANDLED
	}


	if(!IsPaused[id])
	{
		if(! timer_started[id])
		{
			kz_chat(id, "%L", id, "KZ_TIMER_NOT_STARTED")
			return PLUGIN_HANDLED
		}

		g_pausetime[id] = get_gametime() - timer_time[id]
		timer_time[id] = 0.0
		IsPaused[id] = true
		kz_chat(id, "%L", id, "KZ_PAUSE_ON")
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN)
		pev(id, pev_origin, PauseOrigin[id])

	}
	else
	{
			if(timer_started[id])
			{
				kz_chat(id, "%L", id, "KZ_PAUSE_OFF")
				if(get_user_noclip(id))
					noclip(id)
				timer_time[id] = get_gametime() - g_pausetime[id]
			}
			IsPaused[id] = false
			set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
	}

	return PLUGIN_HANDLED
}

public timer_task()
{
	if ( get_pcvar_num(kz_show_timer) > 0 )
	{
		new Alive[32], Dead[32], alivePlayers, deadPlayers;
		get_players(Alive, alivePlayers, "ach")
		get_players(Dead, deadPlayers, "bch")
		for(new i=0;i<alivePlayers;i++)
		{
			if( timer_started[Alive[i]])
			{
				new Float:kreedztime = get_gametime() - (IsPaused[Alive[i]] ? get_gametime() - g_pausetime[Alive[i]] : timer_time[Alive[i]])

				if( ShowTime[Alive[i]] == 1 )
				{
					new colors[12], r[4], g[4], b[4];
					new imin = floatround(kreedztime / 60.0,floatround_floor)
					new isec = floatround(kreedztime - imin * 60.0,floatround_floor)
					get_pcvar_string(kz_hud_color, colors, 11)
					parse(colors, r, 3, g, 3, b, 4)

					set_hudmessage(str_to_num(r), str_to_num(g), str_to_num(b), 0.40, 0.10, 0, 0.0, 1.0, 0.0, 0.0, 1)
					show_hudmessage(Alive[i], "Time: %02d:%02d  | CPs: %d | TPs: %d %s ",imin, isec,checknumbers[Alive[i]], gochecknumbers[Alive[i]], IsPaused[Alive[i]] ? "| *Paused*" : "")
				}
				else
				if( ShowTime[Alive[i]] == 2 )
				{
					kz_showtime_roundtime(Alive[i], floatround(kreedztime))
				}
			}

		}
		for(new i=0;i<deadPlayers;i++)
		{
			new specmode = pev(Dead[i], pev_iuser1)
			if(specmode == 2 || specmode == 4)
			{
				new target = pev(Dead[i], pev_iuser2)
				if(target != Dead[i])
					if(is_user_alive(target) && timer_started[target])
					{
						new name[32], colors[12], r[4], g[4], b[4];
						get_user_name (target, name, 31)

						new Float:kreedztime = get_gametime() - (IsPaused[target] ? get_gametime() - g_pausetime[target] : timer_time[target])
						new imin = floatround(kreedztime / 60.0,floatround_floor)
						new isec = floatround(kreedztime - imin * 60.0,floatround_floor)

						get_pcvar_string(kz_hud_color, colors, 11)
						parse(colors, r, 3, g, 3, b, 4)

						set_hudmessage(str_to_num(r), str_to_num(g), str_to_num(b), -1.0, 0.46, 0, 0.0, 1.0, 0.0, 0.0, 1)
						show_hudmessage(Dead[i], "Time: %02d:%02d  | CPs: %d | TPs: %d %s ",imin, isec, checknumbers[target], gochecknumbers[target], IsPaused[target] ? "| *Paused*" : "")
					}
			}
		}
	}
}

// ============================ Block Commands ================================


public BlockRadio(id)
{
	if (get_pcvar_num(kz_use_radio) == 1)
		return PLUGIN_CONTINUE
	return PLUGIN_HANDLED
}

public BlockDrop(id)
{
	if (get_pcvar_num(kz_drop_weapons) == 1)
		return PLUGIN_CONTINUE
	return PLUGIN_HANDLED
}

public BlockBuy(id)
{
	return PLUGIN_HANDLED
}

public CmdRespawn(id)
{
	if ( get_user_team(id) == 3 )
		return PLUGIN_HANDLED
	else
		ExecuteHamB(Ham_CS_RoundRespawn, id)

	return PLUGIN_HANDLED
}

public ChatHud(id)
{
	if(get_pcvar_num(kz_chatorhud) == 0)
	{
		ColorChat(id, GREEN,  "%s^x01 %L", id, "KZ_CHECKPOINT_OFF", prefix)
		return PLUGIN_HANDLED
	}
	if(chatorhud[id] == -1)
		++chatorhud[id];

	++chatorhud[id];

	if(chatorhud[id] == 3)
		chatorhud[id] = 0;
	else
		kz_chat(id, "%L", id, "KZ_CHATORHUD", chatorhud[id] == 1 ? "Chat" : "HUD")

	return PLUGIN_HANDLED
}

public ct(id)
{
	new CsTeams:team = cs_get_user_team(id)
	if (team == CS_TEAM_CT)
	{
		if( !( pev( id, pev_flags ) & FL_ONGROUND2 ) && timer_started[id] )
			return PLUGIN_HANDLED

		if (get_pcvar_num(kz_spec_saves) == 1)
		{
			pev(id, pev_origin, SpecLoc[id])

			if ( timer_started[id] )
			{
				if ( IsPaused[id] )
				{
					Pause(id)
					WasPaused[id]=true
				}

				g_pausetime[id] =   get_gametime() - timer_time[id]
				timer_time[id] = 0.0
				kz_chat(id, "%L", id, "KZ_PAUSE_ON")
			}
		}

		if(gViewInvisible[id])
			gViewInvisible[id] = false

		cs_set_user_team(id,CS_TEAM_SPECTATOR)
		set_pev(id, pev_solid, SOLID_NOT)
		set_pev(id, pev_movetype, MOVETYPE_FLY)
		set_pev(id, pev_effects, EF_NODRAW)
		set_pev(id, pev_deadflag, DEAD_DEAD)
	}
	else
	{
		cs_set_user_team(id,CS_TEAM_CT)
		set_pev(id, pev_effects, 0)
		set_pev(id, pev_movetype, MOVETYPE_WALK)
		set_pev(id, pev_deadflag, DEAD_NO)
		set_pev(id, pev_takedamage, DAMAGE_AIM)
		CmdRespawn(id)
		give_item(id,"weapon_knife")
		give_item(id,"weapon_usp")
		cs_set_user_bpammo(id, CSW_USP, 36)

		if (get_pcvar_num(kz_spec_saves) == 1)
		{
			set_pev(id, pev_origin, SpecLoc[id])
			if ( timer_started [id] )
				timer_time[id] = get_gametime() - g_pausetime[id] + timer_time[id]
			if( WasPaused[id] )
			{
				Pause(id)
				WasPaused[id]=false
			}
		}
	}
	return PLUGIN_HANDLED
}


//=================== Weapons ==============
public curweapon(id)
{
/*
	if(get_pcvar_num(kz_maxspeedmsg) == 1 && is_user_alive(id))
	{
		new clip, ammo, speed,
 		switch(get_user_weapon(id,clip,ammo))
		{
			case CSW_SCOUT: speed = 260
			case CSW_C4, CSW_P228, CSW_MAC10, CSW_MP5NAVY, CSW_USP, CSW_TMP, CSW_FLASHBANG, CSW_DEAGLE, CSW_GLOCK18, CSW_SMOKEGRENADE, CSW_ELITE, CSW_FIVESEVEN, CSW_UMP45, CSW_HEGRENADE, CSW_KNIFE:   speed = 250
			case CSW_P90:   speed = 245
			case CSW_XM1014, CSW_AUG, CSW_GALIL, CSW_FAMAS: speed = 240
			case CSW_SG552:  speed = 235
			case CSW_M3, CSW_M4A1:   speed= 230
			case CSW_AK47:   speed = 221
			case CSW_M249:   speed = 220
			case CSW_G3SG1, CSW_SG550, CSW_AWP: speed = 210
  		}
		kz_hud_message(id,"%L",id, "KZ_WEAPONS_SPEED",speed)
	}
 */
 	static last_weapon[33];
	static weapon_active, weapon_num
	weapon_active = read_data(1)
	weapon_num = read_data(2)

 	if( ( weapon_num != last_weapon[id] ) && weapon_active && get_pcvar_num(kz_maxspeedmsg) == 1)
	{
		last_weapon[id] = weapon_num;

		static Float:maxspeed;
		pev(id, pev_maxspeed, maxspeed );

		if( maxspeed < 0.0 )
			maxspeed = 250.0;

		kz_hud_message(id,"%L",id, "KZ_WEAPONS_SPEED",floatround( maxspeed, floatround_floor ));
	}
	return PLUGIN_HANDLED
}

public weapons(id)
{
	if(!is_user_alive(id))
	{
		kz_chat(id, "%L", id, "KZ_NOT_ALIVE")
		return PLUGIN_HANDLED
	}

	if(get_pcvar_num(kz_other_weapons) == 0)
	{
		kz_chat(id, "%L", id, "KZ_OTHER_WEAPONS_ZERO")
		return PLUGIN_HANDLED
	}

	if (timer_started[id])
	{
		kz_chat(id, "%L", id, "KZ_WEAPONS_IN_RUN")
		return PLUGIN_HANDLED
	}

	for(new i = 0; i < 8; i++)
		if( !user_has_weapon(id, other_weapons[i]) )
		{
			new item;
			item = give_item(id, other_weapons_name[i] );
			cs_set_weapon_ammo(item, 0);
		}

	if( !user_has_weapon(id, CSW_USP) )
		cmdUsp(id)

	return PLUGIN_HANDLED
}


// ========================= Scout =======================
public cmdScout(id)
{
	if (timer_started[id])
		user_has_scout[id] = true

	strip_user_weapons(id)
	give_item(id,"weapon_usp")
	give_item(id,"weapon_knife")
	if( !user_has_weapon(id, CSW_SCOUT))
		give_item(id,"weapon_scout")

	return PLUGIN_HANDLED
}

public cmdUsp(id)
{
	give_item(id,"weapon_usp")
	give_item(id,"weapon_knife")

	return PLUGIN_HANDLED
}

// ========================== Start location =================

public goStart(id)
{
	if( !is_user_alive( id ) )
	{
		kz_chat(id, "%L", id, "KZ_NOT_ALIVE")
		return PLUGIN_HANDLED
	}

	if (IsPaused[id])
	{
		kz_chat(id, "%L", id, "KZ_TELEPORT_PAUSE")
		return PLUGIN_HANDLED
	}

	if(get_pcvar_num(kz_save_autostart) == 1 && AutoStart [id] )
	{
		set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
		set_pev( id, pev_flags, pev(id, pev_flags) | FL_DUCKING )
		set_pev(id, pev_origin, SavedStart [id] )

		kz_chat(id, "%L", id, "KZ_START")
	}
	else if ( DefaultStart )
	{
		set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
		set_pev(id, pev_origin, DefaultStartPos)

		kz_chat(id, "%L", id, "KZ_START")
	}
	else
	{
		kz_chat(id, "%L", id, "KZ_NO_START")

		CmdRespawn(id)
    }

	return PLUGIN_HANDLED
}

public setStart(id)
{
	if (! (get_user_flags( id ) & KZ_LEVEL ))
	{
		kz_chat(id, "%L", id, "KZ_NO_ACCESS")
		return PLUGIN_HANDLED
	}

	new Float:origin[3]
	pev(id, pev_origin, origin)
	kz_set_start(MapName, origin)
	AutoStart[id] = false;
	ColorChat(id, GREEN, "%s^x01 %L.", prefix, id, "KZ_SET_START")

	return PLUGIN_HANDLED
}

// ========= Respawn CT if dies ========

public Ham_CBasePlayer_Killed_Post(id)
{
	if(get_pcvar_num(kz_respawn_ct) == 1)
	{
		if( cs_get_user_team(id) == CS_TEAM_CT )
		{
			set_pev(id, pev_deadflag, DEAD_RESPAWNABLE)
   			cs_set_user_deaths(id, 0)
			set_user_frags(id, 0)
		}
	}
}


// =============================  NightVision ================================================

public ToggleNVG(id)
{

	if( get_pcvar_num(kz_nvg) == 0 || !is_user_alive(id))
		return PLUGIN_CONTINUE;

	if ( NightVisionUse[id] )
		StopNVG(id)
	else
		StartNVG(id)

	return PLUGIN_HANDLED
}

public StartNVG(id)
{
	emit_sound(id,CHAN_ITEM,"items/nvg_on.wav",1.0,ATTN_NORM,0,PITCH_NORM)
	set_task(0.1,"RunNVG",id+111111,_,_,"b")
	NightVisionUse[id] = true;

	return PLUGIN_HANDLED
}

public StopNVG(id)
{
	emit_sound(id,CHAN_ITEM,"items/nvg_off.wav",1.0,ATTN_NORM,0,PITCH_NORM)
	remove_task(id+111111)
	NightVisionUse[id] = false;

	return PLUGIN_HANDLED
}


public RunNVG(taskid)
{
	new id = taskid - 111111

	if (!is_user_alive(id)) return

	new origin[3]
	get_user_origin(id,origin,3)

	new color[17];
	get_pcvar_string(kz_nvg_colors,color,16);

	new iRed[5], iGreen[7], iBlue[5]
	parse(color,iRed,4,iGreen ,6,iBlue,4)

	message_begin(MSG, SVC_TEMPENTITY, _, id)
	write_byte(TE_DLIGHT)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_byte(80)
	write_byte(str_to_num(iRed))
	write_byte(str_to_num(iGreen))
	write_byte(str_to_num(iBlue))
	write_byte(2)
	write_byte(0)
	message_end()
}

// ============================ Hook ==============================================================

public give_hook(id)
{
	if (!(  get_user_flags( id ) & KZ_LEVEL ))
		return PLUGIN_HANDLED

	new szarg1[32], szarg2[8], bool:mode
	read_argv(1,szarg1,32)
	read_argv(2,szarg2,32)
	if(equal(szarg2,"on"))
		mode = true

	if(equal(szarg1,"@ALL"))
	{
		new Alive[32], alivePlayers
		get_players(Alive, alivePlayers, "ach")
		for(new i;i<alivePlayers;i++)
		{
			canusehook[i] = mode
			if(mode)
				ColorChat(i, GREEN,  "%s^x01, %L.", prefix, i, "KZ_HOOK")
		}
	}
	else
	{
		new pid = find_player("bl",szarg1);
		if(pid > 0)
		{
			canusehook[pid] = mode
			if(mode)
			{
				ColorChat(pid, GREEN, "%s^x01 %L.", prefix, pid, "KZ_HOOK")
			}
		}
	}

	return PLUGIN_HANDLED
}

public hook_on(id)
{
	if( !canusehook[id] && !(  get_user_flags( id ) & KZ_LEVEL ) || !is_user_alive(id) )
		return PLUGIN_HANDLED

	if (IsPaused[id])
	{
		kz_chat(id, "%L", id, "KZ_HOOK_PAUSE")
		return PLUGIN_HANDLED
	}

	detect_cheat(id,"Hook")
	get_user_origin(id,hookorigin[id],3)
	ishooked[id] = true
	antihookcheat[id] = get_gametime()

	if (get_pcvar_num(kz_hook_sound) == 1)
	emit_sound(id,CHAN_STATIC,"weapons/xbow_hit2.wav",1.0,ATTN_NORM,0,PITCH_NORM)

	set_task(0.1,"hook_task",id,"",0,"ab")
	hook_task(id)

	return PLUGIN_HANDLED
}

public hook_off(id)
{
	remove_hook(id)

	return PLUGIN_HANDLED
}

public hook_task(id)
{
	if(!is_user_connected(id) || !is_user_alive(id))
		remove_hook(id)

	remove_beam(id)
	draw_hook(id)

	new origin[3], Float:velocity[3]
	get_user_origin(id,origin)
	new distance = get_distance(hookorigin[id],origin)
	velocity[0] = (hookorigin[id][0] - origin[0]) * (2.0 * get_pcvar_num(kz_hook_speed) / distance)
	velocity[1] = (hookorigin[id][1] - origin[1]) * (2.0 * get_pcvar_num(kz_hook_speed) / distance)
	velocity[2] = (hookorigin[id][2] - origin[2]) * (2.0 * get_pcvar_num(kz_hook_speed) / distance)

	set_pev(id,pev_velocity,velocity)
}

public draw_hook(id)
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(1)				// TE_BEAMENTPOINT
	write_short(id)				// entid
	write_coord(hookorigin[id][0])		// origin
	write_coord(hookorigin[id][1])		// origin
	write_coord(hookorigin[id][2])		// origin
	write_short(Sbeam)			// sprite index
	write_byte(0)				// start frame
	write_byte(0)				// framerate
	write_byte(random_num(1,100))		// life
	write_byte(random_num(1,20))		// width
	write_byte(random_num(1,0))		// noise
	write_byte(random_num(1,255))		// r
	write_byte(random_num(1,255))		// g
	write_byte(random_num(1,255))		// b
	write_byte(random_num(1,500))		// brightness
	write_byte(random_num(1,200))		// speed
	message_end()
}

public remove_hook(id)
{
	if(task_exists(id))
		remove_task(id)
	remove_beam(id)
	ishooked[id] = false
}

public remove_beam(id)
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(99) // TE_KILLBEAM
	write_short(id)
	message_end()
}


//============================ VIP In ScoreBoard =================================================

public MessageScoreAttrib( iMsgID, iDest, iReceiver )
{
	if( get_pcvar_num(kz_vip) )
	{
		new iPlayer = get_msg_arg_int( 1 )
		if( is_user_alive( iPlayer ) && ( get_user_flags( iPlayer ) & KZ_LEVEL ) )
		{
			set_msg_arg_int( 2, ARG_BYTE, SCOREATTRIB_VIP );
		}
	}
}

public EventStatusValue( const id )
{

	new szMessage[ 34 ], Target, aux
	get_user_aiming(id, Target, aux)
	if (is_user_alive(Target))
	{
		formatex( szMessage, 33, "1 %s: %%p2", get_user_flags( Target ) & KZ_LEVEL ? "VIP" : "Player" )
		message_begin( MSG, get_user_msgid( "StatusText" ) , _, id )
		write_byte( 0 )
		write_string( szMessage )
		message_end( )
	}
}

public detect_cheat(id,reason[])
{
	if(timer_started[id] && get_pcvar_num(kz_cheatdetect) == 1)
	{
		timer_started[id] = false
		if(IsPaused[id])
		{
			set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
			IsPaused[id] = false
		}
		if (get_pcvar_num(kz_show_timer) > 0 && ShowTime[id] == 2)
			kz_showtime_roundtime(id, 0)
		ColorChat(id, GREEN,  "%s^x01 %L", prefix, id, "KZ_CHEAT_DETECT", reason)
	}
}

// =================================================================================================
// Cmds
// =================================================================================================

public CheckPoint(id)
{

	if( !is_user_alive( id ) )
	{
		kz_chat(id, "%L", id, "KZ_NOT_ALIVE")
		return PLUGIN_HANDLED
	}

	if(get_pcvar_num(kz_checkpoints) == 0)
	{
		kz_chat(id, "%L", id, "KZ_CHECKPOINT_OFF")
		return PLUGIN_HANDLED
	}

	if( !( pev( id, pev_flags ) & FL_ONGROUND2 ) && !IsOnLadder(id))
	{
		kz_chat(id, "%L", id, "KZ_CHECKPOINT_AIR")
		return PLUGIN_HANDLED
	}

	if( IsPaused[id] )
	{
		kz_chat(id, "%L", id, "KZ_CHECKPOINT_PAUSE")
		return PLUGIN_HANDLED
	}

	pev(id, pev_origin, Checkpoints[id][g_bCpAlternate[id] ? 1 : 0])
	g_bCpAlternate[id] = !g_bCpAlternate[id]
	checknumbers[id]++

	kz_chat(id, "%L", id, "KZ_CHECKPOINT", checknumbers[id])

	return PLUGIN_HANDLED
}

public GoCheck(id)
{
	if( !is_user_alive( id ) )
	{
		kz_chat(id, "%L", id, "KZ_NOT_ALIVE")
		return PLUGIN_HANDLED
	}

	if( checknumbers[id] == 0  )
	{
		kz_chat(id, "%L", id, "KZ_NOT_ENOUGH_CHECKPOINTS")
		return PLUGIN_HANDLED
	}

	if( IsPaused[id] )
	{
		kz_chat(id, "%L", id, "KZ_TELEPORT_PAUSE")
		return PLUGIN_HANDLED
	}

	set_pev( id, pev_velocity, Float:{0.0, 0.0, 0.0} );
	set_pev( id, pev_view_ofs, Float:{  0.0,   0.0,  12.0 } );
	set_pev( id, pev_flags, pev(id, pev_flags) | FL_DUCKING );
	set_pev( id, pev_fuser2, 0.0 );
	engfunc( EngFunc_SetSize, id, {-16.0, -16.0, -18.0 }, { 16.0, 16.0, 32.0 } );
	set_pev(id, pev_origin, Checkpoints[ id ][ !g_bCpAlternate[id] ] )
	gochecknumbers[id]++

	kz_chat(id, "%L", id, "KZ_GOCHECK", gochecknumbers[id])

	return PLUGIN_HANDLED
}

public Stuck(id)
{
	if( !is_user_alive( id ) )
	{
		kz_chat(id, "%L", id, "KZ_NOT_ALIVE")
		return PLUGIN_HANDLED
	}

	if( checknumbers[id] < 2 )
	{
		kz_chat(id, "%L", id, "KZ_NOT_ENOUGH_CHECKPOINTS")
		return PLUGIN_HANDLED
	}

	set_pev( id, pev_velocity, Float:{0.0, 0.0, 0.0} )
	set_pev( id, pev_view_ofs, Float:{  0.0,   0.0,  12.0 })
	set_pev( id, pev_flags, pev(id, pev_flags) | FL_DUCKING )
	set_pev( id, pev_fuser2, 0.0 )
	engfunc( EngFunc_SetSize, id, {-16.0, -16.0, -18.0 }, { 16.0, 16.0, 32.0 } )
	set_pev(id, pev_origin, Checkpoints[id][g_bCpAlternate[id]] )
	g_bCpAlternate[id] = !g_bCpAlternate[id];
	gochecknumbers[id]++

	kz_chat(id, "%L", id, "KZ_GOCHECK", gochecknumbers[id])

	return PLUGIN_HANDLED;
}

// =================================================================================================

public reset_checkpoints(id)
{
	checknumbers[id] = 0
	gochecknumbers[id] = 0
	timer_started[id] = false
	timer_time[id] = 0.0
	user_has_scout[id] = false
	if(IsPaused[id])
	{
		set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
		IsPaused[id] = false
	}
	if (get_pcvar_num(kz_show_timer) > 0 && ShowTime[id] == 2)
		kz_showtime_roundtime(id, 0)

	return PLUGIN_HANDLED
}

//===== Invis =======

public cmdInvisible(id)
{

	gViewInvisible[id] = !gViewInvisible[id]
	if(gViewInvisible[id])
		kz_chat(id, "%L", id, "KZ_INVISIBLE_PLAYERS_ON")
	else
		kz_chat(id, "%L", id, "KZ_INVISIBLE_PLAYERS_OFF")

	return PLUGIN_HANDLED
}

public cmdWaterInvisible(id)
{
	if( !gWaterFound )
	{
		kz_chat(id, "%L", id, "KZ_INVISIBLE_NOWATER")
		return PLUGIN_HANDLED
	}

	gWaterInvisible[id] = !gWaterInvisible[id]
	if(gWaterInvisible[id])
		kz_chat(id, "%L", id, "KZ_INVISIBLE_WATER_ON")
	else
		kz_chat(id, "%L", id, "KZ_INVISIBLE_WATER_OFF")

	return PLUGIN_HANDLED
}

//======================Semiclip / Invis==========================

public FM_client_AddToFullPack_Post(es, e, ent, host, hostflags, player, pSet)
{
	if( player )
	{
		if (get_pcvar_num(kz_semiclip) == 1)
		{
			if ( host != ent && get_orig_retval() && is_user_alive(host) )
    			{
				set_es(es, ES_Solid, SOLID_NOT)
				set_es(es, ES_RenderMode, kRenderTransAlpha)
				set_es(es, ES_RenderAmt, get_pcvar_num(kz_semiclip_transparency))
			}
		}
		if(gMarkedInvisible[ent] && gViewInvisible[host])
		{
 		  	set_es(es, ES_RenderMode, kRenderTransTexture)
			set_es(es, ES_RenderAmt, 0)
			set_es(es, ES_Origin, { 999999999.0, 999999999.0, 999999999.0 } )
		}
	}
	else if( gWaterInvisible[host] && gWaterEntity[ent] )
	{
		set_es(es, ES_Effects, get_es( es, ES_Effects ) | EF_NODRAW )
	}

	return FMRES_IGNORED
}

public Ham_CBasePlayer_PreThink_Post(id)
{
	if( !is_user_alive(id) )
	{
		return
	}

	RefreshPlayersList()

	if (get_pcvar_num(kz_semiclip) == 1)
	{
		for(new i = 0; i<g_iNum; i++)
		{
			g_iPlayer = g_iPlayers[i]
			if( id != g_iPlayer )
			{
				set_pev(g_iPlayer, pev_solid, SOLID_NOT)
			}
		}
	}
}

public client_PostThink(id)
{
	if( !is_user_alive(id) )
		return

	RefreshPlayersList()

	if (get_pcvar_num(kz_semiclip) == 1)
		for(new i = 0; i<g_iNum; i++)
   		{
			g_iPlayer = g_iPlayers[i]
			if( g_iPlayer != id )
				set_pev(g_iPlayer, pev_solid, SOLID_SLIDEBOX)
   		}
}

public noclip(id)
{
	if(!is_user_alive(id))
	{
		kz_chat(id, "%L", id, "KZ_NOT_ALIVE")
		return PLUGIN_HANDLED
	}
	new noclip = !get_user_noclip(id)
	set_user_noclip(id, noclip)
	if(IsPaused[id] && (get_pcvar_num(kz_noclip_pause) == 1))
	{
		if(noclip)
		{
			pev(id, pev_origin, NoclipPos[id])
			set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
		}
		else
		{
			set_pev(id, pev_origin, NoclipPos[id])
			set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN)
		}
	}
	else if(noclip)
		detect_cheat(id,"Noclip")
	kz_chat(id, "%L", id, "KZ_NOCLIP" , noclip ? "ON" : "OFF")

	return PLUGIN_HANDLED
}

public GodMode(id)
{
	if(!is_user_alive(id))
	{
		kz_chat(id, "%L", id, "KZ_NOT_ALIVE")
		return PLUGIN_HANDLED
	}

	new godmode = !get_user_godmode(id)
	set_user_godmode(id, godmode)
	if(godmode)
		detect_cheat(id,"God Mode")
	kz_chat(id, "%L", id, "KZ_GODMODE" , godmode ? "ON" : "OFF")

	return PLUGIN_HANDLED
}

// =================================================================================================

stock kz_set_start(const map[], Float:origin[3])
{
	new realfile[128], tempfile[128], formatorigin[50]
	formatex(realfile, 127, "%s/%s", Kzdir, KZ_STARTFILE)
	formatex(tempfile, 127, "%s/%s", Kzdir, KZ_STARTFILE_TEMP)
	formatex(formatorigin, 49, "%f %f %f", origin[0], origin[1], origin[2])

	DefaultStartPos = origin
	DefaultStart = true

	new file = fopen(tempfile, "wt")
	new vault = fopen(realfile, "rt")

	new data[128], key[64]
	new bool:replaced = false

	while( !feof(vault) )
	{
		fgets(vault, data, 127)
		parse(data, key, 63)

		if( equal(key, map) && !replaced )
		{
			fprintf(file, "%s %s^n", map, formatorigin)

			replaced = true
		}
		else
		{
			fputs(file, data)
		}
	}

	if( !replaced )
	{
		fprintf(file, "%s %s^n", map, formatorigin)
	}

	fclose(file)
	fclose(vault)

	delete_file(realfile)
	while( !rename_file(tempfile, realfile, 1) ) {}
}

stock kz_showtime_roundtime(id, time)
{
	if( is_user_connected(id) )
	{
		message_begin(MSG, get_user_msgid( "RoundTime" ), _, id);
		write_short(time + 1);
		message_end();
	}
}

stock kz_chat(id, const message[], {Float,Sql,Result,_}:...)
{
	new cvar = get_pcvar_num(kz_chatorhud)
	if(cvar == 0)
		return PLUGIN_HANDLED

	new msg[180], final[192]
	if (cvar == 1 && chatorhud[id] == -1 || chatorhud[id] == 1)
	{
		vformat(msg, 179, message, 3)
		formatex(final, 191, "%s^x01 %s", prefix, msg)
		kz_remplace_colors(final, 191)
		ColorChat(id, GREEN, "%s", final)
	}
	else if( cvar ==  2 && chatorhud[id] == -1 || chatorhud[id] == 2)
	{
			vformat(msg, 179, message, 3)
			replace_all(msg, 191, "^x01", "")
			replace_all(msg, 191, "^x03", "")
			replace_all(msg, 191, "^x04", "")
			replace_all(msg, 191, ".", "")
			kz_hud_message(id, "%s", msg)
	}

	return 1
}

stock kz_print_config(id, const msg[])
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, id);
	write_byte(id);
	write_string(msg);
	message_end();
}

stock kz_remplace_colors(message[], len)
{
	replace_all(message, len, "!g", "^x04")
	replace_all(message, len, "!t", "^x03")
	replace_all(message, len, "!y", "^x01")
}

stock kz_hud_message(id, const message[], {Float,Sql,Result,_}:...)
{
	static msg[192], colors[12], r[4], g[4], b[4];
	vformat(msg, 191, message, 3);

	get_pcvar_string(kz_hud_color, colors, 11)
	parse(colors, r, 3, g, 3, b, 4)

	set_hudmessage(str_to_num(r), str_to_num(g), str_to_num(b), -1.0, 0.90, 0, 0.0, 2.0, 0.0, 1.0, -1);
	ShowSyncHudMsg(id, hud_message, msg);
}

stock kz_register_saycmd(const saycommand[], const function[], flags)
{
	new temp[64]
	formatex(temp, 63, "say /%s", saycommand)
	register_clcmd(temp, function, flags)
	formatex(temp, 63, "say .%s", saycommand)
	register_clcmd(temp, function, flags)
	formatex(temp, 63, "say_team /%s", saycommand)
	register_clcmd(temp, function, flags)
	formatex(temp, 63, "say_team .%s", saycommand)
	register_clcmd(temp, function, flags)
}

stock get_configsdir(name[],len)
{
	return get_localinfo("amxx_configsdir",name,len);
}

#if defined USE_SQL
stock GetNewRank(id, type)
{
	new createinto[1001]

	new cData[2]
	cData[0] = id
	cData[1] = type

	formatex(createinto, 1000, "SELECT authid FROM `%s` WHERE mapname='%s' ORDER BY time LIMIT 15", type == PRO_TOP ? "kz_pro15" : "kz_nub15", MapName)
	SQL_ThreadQuery(g_SqlTuple, "GetNewRank_QueryHandler", createinto, cData, 2)
}

stock kz_update_plrname(id)
{
	new createinto[1001], authid[32], name[32]
	get_user_authid(id, authid, 31)
	get_user_name(id, name, 31)

	replace_all(name, 31, "\", "")
	replace_all(name, 31, "`", "")
	replace_all(name, 31, "'", "")

	if(equal(authid, "VALVE_ID_LAN") || equal(authid, "STEAM_ID_LAN") || strlen(authid) > 18)
		return 0;
	else
	{
		formatex(createinto, 1000, "UPDATE `kz_pro15` SET name='%s' WHERE authid='%s'", name, authid)
		SQL_ThreadQuery(g_SqlTuple, "QueryHandle", createinto)
		formatex(createinto, 1000, "UPDATE `kz_nub15` SET name='%s' WHERE authid='%s'", name, authid)
		SQL_ThreadQuery(g_SqlTuple, "QueryHandle", createinto)
	}
	return 1
}
#endif

public FwdSpawnWeaponbox( iEntity )
{
	if(get_pcvar_num(kz_remove_drops) == 1)
	{
		set_pev( iEntity, pev_flags, FL_KILLME )
		dllfunc( DLLFunc_Think, iEntity )
	}

	return HAM_IGNORED
}

public FwdHamDoorSpawn( iEntity )
{
	static const szNull[ ] = "common/null.wav";

	new Float:flDamage;
	pev( iEntity, pev_dmg, flDamage );

	if( flDamage < -999.0 ) {
		set_pev( iEntity, pev_noise1, szNull );
		set_pev( iEntity, pev_noise2, szNull );
		set_pev( iEntity, pev_noise3, szNull );

		if( !HealsOnMap )
			HealsOnMap = true
	}
}

public FwdHamPlayerSpawn( id )
{

	if( !is_user_alive( id ) )
		return;

	if(firstspawn[id])
	{
		ColorChat(id, GREEN,  "%s^x01 Welcome to ^x03nucLeaR's Server ^x01", prefix)
		ColorChat(id, GREEN,  "%s^x01 Visit ^x03www.google.com ^x01", prefix)

		if(get_pcvar_num(kz_checkpoints) == 0)
			ColorChat(id, GREEN,  "%s^x01 %L", id, "KZ_CHECKPOINT_OFF", prefix)


		if(Verif(id,1) && get_pcvar_num(kz_save_pos) == 1)
			savepos_menu(id)
		else if(get_pcvar_num(kz_spawn_mainmenu) == 1)
			kz_menu (id)
	}
	firstspawn[id] = false


	if( !user_has_weapon(id,CSW_KNIFE) )
		give_item( id,"weapon_knife" )

	if( HealsOnMap )
		set_user_health(id, 50175)

	if( IsPaused[id] )
	{
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN)
		set_pev(id, pev_origin, PauseOrigin[id])
	}

	if(get_pcvar_num(kz_use_radio) == 0)
	{
		#define XO_PLAYER				5
		#define	m_iRadiosLeft			192
		set_pdata_int(id, m_iRadiosLeft, 0, XO_PLAYER)
	}
}

public GroundWeapon_Touch(iWeapon, id)
{
	if( is_user_alive(id) && timer_started[id] && get_pcvar_num(kz_pick_weapons) == 0 )
		return HAM_SUPERCEDE

	return HAM_IGNORED
}



// ==================================Save positions=================================================

public SavePos(id)
{

	new authid[33];
	get_user_authid(id, authid, 32)
	if(get_pcvar_num(kz_save_pos) == 0)
	{
		kz_chat(id, "%L", id, "KZ_SAVEPOS_DISABLED")
		return PLUGIN_HANDLED
	}

	if(equal(authid, "VALVE_ID_LAN") || equal(authid, "STEAM_ID_LAN") || strlen(authid) > 18)
	{
		ColorChat (id, GREEN, "%s^x01 %L", prefix, id, "KZ_NO_STEAM")

		return PLUGIN_HANDLED
	}

	if( !( pev( id, pev_flags ) & FL_ONGROUND2  ) )
	{
		kz_chat(id, "%L", id, "KZ_NOT_ON_GROUND")

		return PLUGIN_HANDLED
	}

	if(!timer_started[id])
	{
		kz_chat(id, "%L", id, "KZ_TIMER_NOT_STARTED")
		return PLUGIN_HANDLED
	}

	if(Verif(id,1))
	{
		ColorChat(id, GREEN,  "%s^x01 %L", prefix, id, "KZ_SAVEPOS_ALREADY")
		savepos_menu(id)
		return PLUGIN_HANDLED
	}

	if(get_user_noclip(id))
	{
		ColorChat(id, GREEN, "%s^x01 %L", prefix, id, "KZ_SAVEPOS_NOCLIP")
		return PLUGIN_HANDLED
	}

	new Float:origin[3], scout
	pev(id, pev_origin, origin)
	new Float:Time,check,gocheck
	if(IsPaused[id])
	{
		Time = g_pausetime[id]
		Pause(id)
	}
	else
		Time=get_gametime() - timer_time[id]
	check=checknumbers[id]
	gocheck=gochecknumbers[id]
	ColorChat(id, GREEN,  "%s^x01 %L", prefix, id, "KZ_SAVEPOS")
	if (user_has_scout[id])
		scout=1
	else
		scout=0
	kz_savepos(id, Time, check, gocheck, origin, scout)
	reset_checkpoints(id)

	return PLUGIN_HANDLED
}

public GoPos(id)
{
	remove_hook(id)
	set_user_godmode(id, 0)
	set_user_noclip(id, 0)
	if(Verif(id,0))
	{
		set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING )
		set_pev(id, pev_origin, SavedOrigins[id] )
	}

	checknumbers[id]=SavedChecks[id]
	gochecknumbers[id]=SavedGoChecks[id]+((get_pcvar_num(kz_save_pos_gochecks)>0) ? 1 : 0)
	CheckPoint(id)
	CheckPoint(id)
	strip_user_weapons(id)
	give_item(id,"weapon_usp")
	give_item(id,"weapon_knife")
	if(SavedScout[id])
	{
		give_item(id, "weapon_scout")
		user_has_scout[id] = true
	}
	timer_time[id]=get_gametime()-SavedTime[id]
	timer_started[id]=true
	Pause(id)

}

public Verif(id, action)
{
	new realfile[128], tempfile[128], authid[32], map[64]
	new bool:exist = false
	get_mapname(map, 63)
	get_user_authid(id, authid, 31)
	formatex(realfile, 127, "%s/%s.ini", SavePosDir, map)
	formatex(tempfile, 127, "%s/temp.ini", SavePosDir)

	if( !file_exists(realfile) )
		return 0

	new file = fopen(tempfile, "wt")
	new vault = fopen(realfile, "rt")
	new data[150], sid[32], time[25], checks[5], gochecks[5], x[25], y[25], z[25], scout[5]
	while( !feof(vault) )
	{
		fgets(vault, data, 149)
		parse(data, sid, 31, time, 24,  checks, 4, gochecks, 4, x, 24,  y, 24, z, 24, scout, 4)

		if( equal(sid, authid) && !exist) // ma aflu in fisier?
		{
			if(action == 1)
				fputs(file, data)
			exist= true
			SavedChecks[id] = str_to_num(checks)
			SavedGoChecks[id] = str_to_num(gochecks)
			SavedTime[id] = str_to_float(time)
			SavedOrigins[id][0]=str_to_num(x)
			SavedOrigins[id][1]=str_to_num(y)
			SavedOrigins[id][2]=str_to_num(z)
			SavedScout[id] = str_to_num(scout)
		}
		else
		{
			fputs(file, data)
		}
	}

	fclose(file)
	fclose(vault)

	delete_file(realfile)
	if(file_size(tempfile) == 0)
		delete_file(tempfile)
	else
		while( !rename_file(tempfile, realfile, 1) ) {}


	if(!exist)
		return 0

	return 1
}
public kz_savepos (id, Float:time, checkpoints, gochecks, Float:origin[3], scout)
{
	new realfile[128], formatorigin[128], map[64], authid[32]
	get_mapname(map, 63)
	get_user_authid(id, authid, 31)
	formatex(realfile, 127, "%s/%s.ini", SavePosDir, map)
	formatex(formatorigin, 127, "%s %f %d %d %d %d %d %d", authid, time, checkpoints, gochecks, origin[0], origin[1], origin[2], scout)

	new vault = fopen(realfile, "rt+")
	write_file(realfile, formatorigin) // La sfarsit adaug datele mele

	fclose(vault)

}

// =================================================================================================
// Events / Forwards
// =================================================================================================

//=================================================================================================

public client_disconnect(id)
{
	checknumbers[id] = 0
	gochecknumbers[id] = 0
	antihookcheat[id] = 0.0
	chatorhud[id] = -1
	timer_started[id] = false
	ShowTime[id] = get_pcvar_num(kz_show_timer)
	firstspawn[id] = true
	NightVisionUse[id] = false
	IsPaused[id] = false
	WasPaused[id] = false
	user_has_scout[id] = false
	remove_hook(id)
}

public client_putinserver(id)
{
	checknumbers[id] = 0
	gochecknumbers[id] = 0
	antihookcheat[id] = 0.0
	chatorhud[id] = -1
	timer_started[id] = false
	ShowTime[id] = get_pcvar_num(kz_show_timer)
	firstspawn[id] = true
	NightVisionUse[id] = false
	IsPaused[id] = false
	WasPaused[id] = false
	user_has_scout[id] = false
	remove_hook(id)
}

// =================================================================================================
// Menu
// =================================================================================================


public kz_menu(id)
{
	new title[64];
	formatex(title, 63, "\yProKreedz %s Menu\w", VERSION)
	new menu = menu_create(title, "MenuHandler")

	new msgcheck[64], msggocheck[64], msgpause[64]
	formatex(msgcheck, 63, "Checkpoint - \y#%i", checknumbers[id])
	formatex(msggocheck, 63, "Gocheck - \y#%i",  gochecknumbers[id])
	formatex(msgpause, 63, "Pause - %s^n", IsPaused[id] ? "\yON" : "\rOFF" )

	menu_additem( menu, msgcheck, "1" )
	menu_additem( menu, msggocheck, "2" )
	menu_additem( menu, "Top 15^n", "3")
	menu_additem( menu, "Start", "4")
	menu_additem( menu, "Timer Menu", "5" )
	menu_additem( menu, msgpause, "6" )
	menu_additem( menu, "Invisible Menu", "7" )
	menu_additem( menu, "Spectator/CT", "8" )
	menu_additem( menu, "Reset Time^n", "9")
	menu_additem( menu, "Exit", "MENU_EXIT" )

	menu_setprop(menu, MPROP_PERPAGE, 0)
	menu_display(id, menu, 0)
	return PLUGIN_HANDLED
}

public MenuHandler(id , menu, item)
{
	if( item == MENU_EXIT ) {
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}


	switch(item) {
		case 0:{
			CheckPoint(id)
			kz_menu(id)
		}
		case 1:{
			GoCheck(id)
			kz_menu(id)
		}
		case 2:{
			top15menu(id)
		}
		case 3:{
			goStart(id)
			kz_menu(id)
		}
		case 4:{
			ShowTimer_Menu(id)
		}
		case 5:{
			Pause(id)
			kz_menu(id)
		}
		case 6:{
			InvisMenu(id)
		}
		case 7:{
			ct(id)
		}
		case 8:{
			reset_checkpoints(id)
			kz_menu(id)
		}
	}

	return PLUGIN_HANDLED
}

public InvisMenu(id)
{
	new menu = menu_create("\yInvis Menu\w", "InvisMenuHandler")
	new msginvis[64], msgwaterinvis[64]

	formatex(msginvis, 63, "Players - %s",  gViewInvisible[id] ? "\yON" : "\rOFF" )
	formatex(msgwaterinvis, 63, "Water - %s^n^n", gWaterInvisible[id] ? "\yON" : "\rOFF" )

	menu_additem( menu, msginvis, "1" )
	menu_additem( menu, msgwaterinvis, "2" )
	menu_additem( menu, "Main Menu", "3" )

	menu_display(id, menu, 0)
	return PLUGIN_HANDLED
}

public InvisMenuHandler (id, menu, item)
{
	if( item == MENU_EXIT )
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	switch(item)
	{
		case 0:
		{
			cmdInvisible(id)
			InvisMenu(id)
		}
		case 1:
		{
			cmdWaterInvisible(id)
			InvisMenu(id)
		}
		case 2:
		{
			kz_menu(id)
		}
	}
	return PLUGIN_HANDLED
}

public ShowTimer_Menu(id)
{
	if (get_pcvar_num(kz_show_timer) == 0 )
	{
		kz_chat(id, "%L", id, "KZ_TIMER_DISABLED")
		return PLUGIN_HANDLED
	}
	else
	{
		new menu = menu_create("\yTimer Menu\w", "TimerHandler")

		new roundtimer[64], hudtimer[64], notimer[64];

		formatex(roundtimer, 63, "Round Timer %s", ShowTime[id] == 2 ? "\y x" : "" )
		formatex(hudtimer, 63, "HUD Timer %s", ShowTime[id] == 1 ? "\y x" : "" )
		formatex(notimer, 63, "No Timer %s^n", ShowTime[id] == 0 ? "\y x" : "" )

		menu_additem( menu, roundtimer, "1" )
		menu_additem( menu, hudtimer, "2" )
		menu_additem( menu, notimer, "3" )
		menu_additem( menu, "Main Menu", "4" )

		menu_display(id, menu, 0)
		return PLUGIN_HANDLED
	}

	return PLUGIN_HANDLED
}

public TimerHandler (id, menu, item)
{
	if( item == MENU_EXIT )
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	switch(item)
	{

		case 0:
		{
			ShowTime[id]= 2
			ShowTimer_Menu(id)
		}
		case 1:
		{
			ShowTime[id]= 1
			ShowTimer_Menu(id)
			if (timer_started[id])
				kz_showtime_roundtime(id, 0)
		}
		case 2:
		{
			ShowTime[id]= 0
			ShowTimer_Menu(id)
			if (timer_started[id])
				kz_showtime_roundtime(id, 0)
		}
		case 3:
		{
			kz_menu(id)
		}
	}
	return PLUGIN_HANDLED
}

public savepos_menu(id)
{
	new menu = menu_create("SavePos Menu", "SavePosHandler")

	menu_additem( menu, "Reload previous run", "1" )
	menu_additem( menu, "Start a new run", "2" )

	menu_display(id, menu, 0)
	return PLUGIN_HANDLED
}

public SavePosHandler(id, menu, item)
{

	switch(item)
	{
		case 0:
		{
			GoPos(id)
		}
		case 1:
		{
			Verif(id,0)
		}
	}
	return PLUGIN_HANDLED
}

public top15menu(id)
{
	new menu = menu_create("\rProKreedz \yTop15 \w", "top15handler")
	menu_additem(menu, "\wPro 15", "1", 0)
	menu_additem(menu, "\wNoob 15^n^n", "2", 0)
	#if defined USE_SQL
	menu_additem(menu, "Players Rankings Pro","3")
	menu_additem(menu, "Players Rankings Noob","4")
	menu_additem(menu, "Main Menu", "5")
	#else
	menu_additem(menu, "\wMain Menu", "6", 0)
	#endif

	menu_display(id, menu, 0);

	return PLUGIN_HANDLED;
}

public top15handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	#if defined USE_SQL
	switch(item)
	{
		case 0:
		{
			kz_showhtml_motd(id, PRO_TOP, MapName)
		}
		case 1:
		{
			kz_showhtml_motd(id, NUB_TOP, MapName)
		}
		case 2:
		{
			kz_showhtml_motd(id, PLAYERS_RANKING_PRO, MapName)
		}
		case 3:
		{
			kz_showhtml_motd(id, PLAYERS_RANKING_PRO, MapName)
		}
		case 4:
		{
			kz_menu(id)
		}
	}
	#else
	switch(item)
	{
		case 0:
		{
			ProTop_show(id)
		}
		case 1:
		{
			NoobTop_show(id)
		}
		case 2:
		{
			kz_menu(id)
		}
	}
	#endif

	return PLUGIN_HANDLED;
}

// =================================================================================================

//
// Timersystem
// =================================================================================================
public fwdUse(ent, id)
{
	if( !ent || id > 32 )
	{
		return HAM_IGNORED;
	}

	if( !is_user_alive(id) )
	{
		return HAM_IGNORED;
	}


	new name[32]
	get_user_name(id, name, 31)

	new szTarget[ 32 ];
	pev(ent, pev_target, szTarget, 31);

	if( TrieKeyExists( g_tStarts, szTarget ) )
	{

		if ( get_gametime() - antihookcheat[id] < 3.0 )
		{
			kz_hud_message( id, "%L", id, "KZ_HOOK_PROTECTION" );
			return PLUGIN_HANDLED
		}

		if(Verif(id,1))
		{
			ColorChat(id, GREEN,  "%s^x01 %L", prefix, id, "KZ_SAVEPOS_SAVED")
			savepos_menu(id)
			return HAM_IGNORED
		}

		if ( reset_checkpoints(id) && !timer_started[id]  )
		{
			start_climb(id)
			new wpn=get_user_weapon(id)
			for(new i = 0; i < 8; i++)
				if( user_has_weapon(id, other_weapons[i])  )
				{
					strip_user_weapons(id)
					give_item(id,"weapon_knife")
					give_item(id,"weapon_usp")
					set_pdata_int(id, 382, 24, 5)
					if(wpn==CSW_SCOUT)
					{
						user_has_scout[id]=true
						give_item(id,"weapon_scout")
					}
					else
						user_has_scout[id]=false
				}

			if( get_user_health(id) < 100 )
				set_user_health(id, 100)

			pev(id, pev_origin, SavedStart[id])
			if(get_pcvar_num(kz_save_autostart) == 1)
				AutoStart[id] = true;

			if( !DefaultStart )
			{
				kz_set_start(MapName, SavedStart[id])
				ColorChat(id, GREEN,  "%s^x01 %L", prefix, id, "KZ_SET_START")
			}

			remove_hook(id)
		}

	}

	if( TrieKeyExists( g_tStops, szTarget ) )
	{
		if( timer_started[id] )
		{
			if(get_user_noclip(id))
				return PLUGIN_HANDLED

			finish_climb(id)

			if(get_pcvar_num(kz_hook_prize) == 1 && !canusehook[id])
			{
				canusehook[id] = true
				ColorChat(id, GREEN,  "%s^x01 %L.", prefix, id, "KZ_HOOK")
			}
		}
		else
			kz_hud_message(id, "%L", id, "KZ_TIMER_NOT_STARTED")

		}
	return HAM_IGNORED
}

public start_climb(id)
{
	kz_chat(id, "%L", id, "KZ_START_CLIMB")

	if (get_pcvar_num(kz_reload_weapons) == 1)
	{
		strip_user_weapons(id)
		give_item(id,"weapon_knife")
		give_item(id,"weapon_usp")
	}

	if (ShowTime[id] == 2)
		kz_showtime_roundtime(id, 0)
	set_pev(id, pev_gravity, 1.0);
	set_pev(id, pev_movetype, MOVETYPE_WALK)
	set_user_godmode(id, 0)
	reset_checkpoints(id)
	IsPaused[id] = false
	timer_started[id] = true
	timer_time[id] = get_gametime()
}

public finish_climb(id)
{
	if (!is_user_alive (id))
	{
		return;
	}

	if ( (get_pcvar_num(kz_top15_authid) > 1) || (get_pcvar_num(kz_top15_authid) < 0) )
	{
		ColorChat(id, GREEN,  "%s^x01 %L.", prefix, id, "KZ_TOP15_DISABLED")
		return;
	}

	#if defined USE_SQL
	new Float: time, wpn
	time = get_gametime() - timer_time[id]
	show_finish_message(id, time)
	timer_started[id] = false
	if (get_pcvar_num(kz_show_timer) > 0 && ShowTime[id] == 2)
		kz_showtime_roundtime(id, 0)
	new checkpoints=checknumbers[id]
	new gocheck=gochecknumbers[id]
	if(user_has_scout[id])
		wpn=CSW_SCOUT
	else
		wpn=get_user_weapon( id )

	new steam[32], name[32]
	get_user_name(id, name, 31)
	get_user_authid(id, steam, 31 )
	client_cmd(0, "spk buttons/bell1")
	new createinto[1001]

	new cData[192]
	cData[0] = id
	formatex(cData[2], charsmax(cData)-2, "^"%f^" ^"%d^" ^"%d^" ^"%d^"", time, wpn, checkpoints ,gocheck)


	if(equal(steam, "VALVE_ID_LAN") || equal(steam, "STEAM_ID_LAN") || strlen(steam) > 18)
	{
		if (gochecknumbers[id] == 0 &&  !user_has_scout[id] )
		{
			cData[1] = PRO_TOP
			formatex(createinto, sizeof createinto - 1, "SELECT time FROM `kz_pro15` WHERE mapname='%s' AND name='%s'", MapName, name)
			SQL_ThreadQuery(g_SqlTuple, "Set_QueryHandler", createinto, cData, strlen(cData[2])+1)
		}
		if (gochecknumbers[id] > 0 || user_has_scout[id] )
		{
			cData[1] = NUB_TOP
			formatex(createinto, sizeof createinto - 1, "SELECT time FROM `kz_nub15` WHERE mapname='%s' AND name='%s'", MapName, name)
			SQL_ThreadQuery(g_SqlTuple, "Set_QueryHandler", createinto, cData, strlen(cData[2])+1)
		}
	} else
	{

		if (gochecknumbers[id] == 0 &&  !user_has_scout[id] )
		{
			cData[1] = PRO_TOP
			formatex(createinto, sizeof createinto - 1, "SELECT time FROM `kz_pro15` WHERE mapname='%s' AND authid='%s'", MapName, steam)
			SQL_ThreadQuery(g_SqlTuple, "Set_QueryHandler", createinto, cData, strlen(cData[2])+1)
		}
		if (gochecknumbers[id] > 0 || user_has_scout[id] )
		{
			cData[1] = NUB_TOP
			formatex(createinto, sizeof createinto - 1, "SELECT time FROM `kz_nub15` WHERE mapname='%s' AND authid='%s'", MapName, steam)
			SQL_ThreadQuery(g_SqlTuple, "Set_QueryHandler", createinto, cData, strlen(cData[2])+1)
		}
	}
	#else
	new Float: time, authid[32]
	time = get_gametime() - timer_time[id]
	get_user_authid(id, authid, 31)
	show_finish_message(id, time)
	timer_started[id] = false
	if (get_pcvar_num(kz_show_timer) > 0 && ShowTime[id] == 2)
		kz_showtime_roundtime(id, 0)

	if (gochecknumbers[id] == 0 &&  !user_has_scout[id] )
		ProTop_update(id, time)
	if (gochecknumbers[id] > 0 || user_has_scout[id] )
		NoobTop_update(id, time, checknumbers[id], gochecknumbers[id])
	#endif
	user_has_scout[id] = false

}

public show_finish_message(id, Float:kreedztime)
{
	new name[32]
	new imin,isec,ims, wpn
	if(user_has_scout[id])
		wpn=CSW_SCOUT
	else
		wpn=get_user_weapon( id )
	get_user_name(id, name, 31)
	imin = floatround(kreedztime / 60.0, floatround_floor)
	isec = floatround(kreedztime - imin * 60.0,floatround_floor)
	ims = floatround( ( kreedztime - ( imin * 60.0 + isec ) ) * 100.0, floatround_floor )

	ColorChat(0, GREEN,  "%s^x01^x03 %s^x01 %L^x04 %02i:%02i.%02i ^x03(^x01 CPs: ^x04%d^x03 | ^x01 TPs: ^x04%d^x03 | ^x01 %L: ^x04%s^x03) ^x01 !", prefix, name, LANG_PLAYER, "KZ_FINISH_MSG", imin, isec, ims, checknumbers[id], gochecknumbers[id], LANG_PLAYER, "KZ_WEAPON", g_weaponsnames[wpn])
}

//==========================================================
#if defined USE_SQL
public Set_QueryHandler(iFailState, Handle:hQuery, szError[], iErrnum, cData[], iSize, Float:fQueueTime)
{
	new id = cData[0]
	new style = cData[1]
	if( iFailState != TQUERY_SUCCESS )
	{
		log_amx("[KZ] TOP15 SQL: SQL Error #%d - %s", iErrnum, szError)
		ColorChat(0, GREEN,  "%s^x01 %F", prefix, LANG_PLAYER, "KZ_TOP15_SQL_ERROR")
	}

	server_print("[KZ] Server Geting Info of SQL Server")

	new createinto[1001]
	new x1[16], x2[4], x3[5], x4[5]
	parse(cData[2], x1, 15, x2, 3, x3, 4, x4, 4)

	new dia[64], steam[32], name[32], ip[15], country[3], checkpoints[32], gochecks[32]
	new Float:newtime = str_to_float(x1)
	new iMin, iSec, iMs, server[64]
	get_pcvar_string(kz_sql_name, server, 63)
	get_time("%Y%m%d%H%M%S", dia, sizeof dia - 1)
	get_user_authid(id, steam, 31)
	get_user_name(id, name, sizeof name - 1)
	get_user_ip (id, ip, sizeof ip - 1, 1)
	geoip_code2_ex( ip, country)

	replace_all(name, 31, "\", "")
	replace_all(name, 31, "`", "")
	replace_all(name, 31, "'", "")


	if( SQL_NumResults(hQuery) == 0 )
	{
		formatex(checkpoints, 31, ", '%d'", str_to_num(x3))
		formatex(gochecks, 31, ", '%d'", str_to_num(x4))
		formatex( createinto, sizeof createinto - 1, "INSERT INTO `%s` VALUES('%s', '%s','%s','%s','%f','%s','%s','%s'%s%s)", style == PRO_TOP ? "kz_pro15" : "kz_nub15", MapName, steam, country, name, newtime, dia, g_weaponsnames[str_to_num(x2)], server, style == PRO_TOP ? "" : checkpoints, style == PRO_TOP ? "" : gochecks)
		SQL_ThreadQuery(g_SqlTuple, "QueryHandle", createinto)
		GetNewRank(id, style)
	}
	else
	{
		new Float:oldtime, Float:thetime
		SQL_ReadResult(hQuery, 0, oldtime)

		if(newtime < oldtime)
		{
			thetime = oldtime - newtime
			iMin = floatround(thetime / 60.0, floatround_floor)
			iSec = floatround(thetime - iMin * 60.0,floatround_floor)
			iMs = floatround( ( thetime - ( iMin * 60.0 + iSec ) ) * 100.0, floatround_floor )
			ColorChat(id, GREEN,  "[KZ]^x01 %L^x03 %02i:%02i.%02i^x01 in ^x03%s", id, "KZ_IMPROVE", iMin, iSec, iMs, style == PRO_TOP ? "Pro 15" : "Noob 15")
			formatex(checkpoints, 31, ", checkpoints='%d'", str_to_num(x3))
			formatex(gochecks, 31, ", gocheck='%d'", str_to_num(x4))
			if(equal(steam, "VALVE_ID_LAN") || equal(steam, "STEAM_ID_LAN") || strlen(steam) > 18)
				formatex(createinto, sizeof createinto - 1, "UPDATE `%s` SET time='%f', weapon='%s', date='%s', server='%s'%s%s WHERE name='%s' AND mapname='%s'", style == PRO_TOP ? "kz_pro15" : "kz_nub15", newtime, g_weaponsnames[str_to_num(x2)],  dia, server, style == PRO_TOP ? "" : gochecks, style == PRO_TOP ? "" : checkpoints, name, MapName)
			else
				formatex(createinto, sizeof createinto - 1, "UPDATE `%s` SET time='%f', weapon='%s', date='%s', server='%s'%s%s WHERE authid='%s' AND mapname='%s'", style == PRO_TOP ? "kz_pro15" : "kz_nub15", newtime, g_weaponsnames[str_to_num(x2)],  dia, server, style == PRO_TOP ? "" : gochecks, style == PRO_TOP ? "" : checkpoints, steam, MapName)

			SQL_ThreadQuery(g_SqlTuple, "QueryHandle", createinto )
			GetNewRank(id, style)
		}
		else
		{
			thetime = newtime - oldtime
			iMin = floatround(thetime / 60.0, floatround_floor)
			iSec = floatround(thetime - iMin * 60.0,floatround_floor)
			iMs = floatround( ( thetime - ( iMin * 60.0 + iSec ) ) * 100.0, floatround_floor )
			ColorChat(id, GREEN,  "[KZ]^x01 %L^x03 %02i:%02i.%02i ^x01in ^x03%s", id, "KZ_SLOWER", iMin, iSec, iMs, style == PRO_TOP ? "Pro 15" : "Noob 15")
		}
	}

	return PLUGIN_CONTINUE

}

public GetNewRank_QueryHandler(iFailState, Handle:hQuery, szError[], iErrnum, cData[], iSize, Float:fQueueTime)
{
	new id = cData[0]
	if( iFailState != TQUERY_SUCCESS )
	{
		return log_amx("TOP15 SQL: SQL Error #%d - %s", iErrnum, szError)
	}

	new steam[32], authid[32], namez[32], name[32], i = 0
	get_user_authid(id, steam, 31)
	get_user_name(id, namez, 31)

	while( SQL_MoreResults(hQuery) )
	{
		i++
		if(equal(steam, "VALVE_ID_LAN") || equal(steam, "STEAM_ID_LAN") || strlen(steam) > 18)
		{
			SQL_ReadResult(hQuery, 0, name, 31)
			if( equal(name, namez) )
			{
				ColorChat(0, GREEN,  "%s^x03 %s^x01 %L ^x03%d^x01 in^x03 %s^x01",prefix, namez, LANG_PLAYER, "KZ_PLACE", i, cData[1] == PRO_TOP ? "Pro 15" : "Noob 15");
				break;
			}
		}
		else
		{
			SQL_ReadResult(hQuery, 0, authid, 31)
			if( equal(authid, steam) )
			{
				ColorChat(0, GREEN,  "%s^x03 %s^x01 %L ^x03%d^x01 in^x03 %s^x01",prefix, namez, LANG_PLAYER, "KZ_PLACE", i, cData[1] == PRO_TOP ? "Pro 15" : "Noob 15");
				break;
			}
		}
		SQL_NextRow(hQuery)
	}

	return PLUGIN_CONTINUE
}
/*
public ProTop_show(id)
{
	kz_showhtml_motd(id, PRO_TOP, MapName)

	return PLUGIN_HANDLED
}

public NoobTop_show(id)
{

	kz_showhtml_motd(id, NUB_TOP, MapName)

	return PLUGIN_HANDLED
}

public ProRecs_show(id)
{
	new authid[32]
	get_user_authid(id, authid, 31)

	if(equal(authid, "VALVE_ID_LAN") || equal(authid, "STEAM_ID_LAN") || strlen(authid) > 18)
	{
		ColorChat (id, GREEN, "%s^x01 %L", prefix, id, "KZ_NO_STEAM")
		return PLUGIN_HANDLED
	}

	kz_showhtml_motd(id, PRO_RECORDS, MapName)

	return PLUGIN_HANDLED
}*/

stock kz_showhtml_motd(id, type, const map[])
{
	new buffer[125], filepath[96]
	get_pcvar_string(kz_sql_files, filepath, 95)
	new authid[32]
	get_user_name(id, authid, 31)

	switch( type )
	{
		case PRO_TOP:
		{
			formatex(buffer, 124,"http://%s/index.php?map=%s&type=pro", filepath, map)

		}
		case NUB_TOP:
		{
			formatex(buffer, 124,"http://%s/index.php?map=%s&type=nub", filepath, map)
		}
		case PLAYERS_RANKING_PRO:
		{
			formatex(buffer, 124,"http://%s/index.php?name=%s&type=pro", filepath, authid)
		}
		case PLAYERS_RANKING_NUB:
		{
			formatex(buffer, 124,"http://%s/index.php?name=%s&type=nub", filepath, authid)
		}
	}

	show_motd(id, buffer)
}
#else
public ProTop_update(id, Float:time)
{
	new authid[32], name[32], thetime[32], Float: slower, Float: faster, Float:protiempo
	get_user_name(id, name, 31);
	get_user_authid(id, authid, 31);
	get_time(" %d/%m/%Y ", thetime, 31);
	new bool:Is_in_pro15
	Is_in_pro15 = false

	for(new i = 0; i < 15; i++)
	{
		if( (equali(Pro_Names[i], name) && (get_pcvar_num(kz_top15_authid) == 0)) || (equali(Pro_AuthIDS[i], authid) && (get_pcvar_num(kz_top15_authid) == 1)) )
		{
			Is_in_pro15 = true
			slower = time - Pro_Times[i]
			faster = Pro_Times[i] - time
			protiempo = Pro_Times[i]
		}
	}

	for (new i = 0; i < 15; i++)
	{
		if( time < Pro_Times[i])
		{
			new pos = i
			if ( get_pcvar_num(kz_top15_authid) == 0 )
				while( !equal(Pro_Names[pos], name) && pos < 15 )
				{
					pos++;
				}
			else if ( get_pcvar_num(kz_top15_authid) == 1)
				while( !equal(Pro_AuthIDS[pos], authid) && pos < 15 )
				{
					pos++;
				}

			for (new j = pos; j > i; j--)
			{
				formatex(Pro_AuthIDS[j], 31, Pro_AuthIDS[j-1]);
				formatex(Pro_Names[j], 31, Pro_Names[j-1]);
				formatex(Pro_Date[j], 31, Pro_Date[j-1])
				Pro_Times[j] = Pro_Times[j-1];
			}

			formatex(Pro_AuthIDS[i], 31, authid);
			formatex(Pro_Names[i], 31, name);
			formatex(Pro_Date[i], 31, thetime)
			Pro_Times[i] = time

			save_pro15()

			if( Is_in_pro15 )
			{

				if( time < protiempo )
				{
					new min, Float:sec;
					min = floatround(faster, floatround_floor)/60;
					sec = faster - (60*min);
					ColorChat(id, GREEN,  "%s^x01 %L ^x03%02d:%s%.2f^x01", prefix, id, "KZ_IMPROVE", min, sec < 10 ? "0" : "", sec);

					if( (i + 1) == 1)
					{
						client_cmd(0, "spk woop");
						ColorChat(0, GREEN,  "%s^x01^x03 %s^x01 %L^x03 1^x01 in ^x04Pro 15^x01", prefix, name, LANG_PLAYER, "KZ_PLACE");
					}
					else
					{
						client_cmd(0, "spk buttons/bell1");
						ColorChat(0, GREEN,  "%s^x01^x03 %s^x01 %L^x03 %d^x01 in ^x04Pro 15^x01", prefix, name, LANG_PLAYER, "KZ_PLACE", (i+1));
					}
				}
			}
			else
			{
				if( (i + 1) == 1)
				{
					client_cmd(0, "spk woop");
					ColorChat(0, GREEN,  "%s^x01^x03 %s^x01 %L^x03 1^x01 in ^x04Pro 15^x01", prefix, name, LANG_PLAYER, "KZ_PLACE");
				}
				else
				{
					client_cmd(0, "spk buttons/bell1");
					ColorChat(0, GREEN,  "%s^x01^x03 %s^x01 %L^x03 %d^x01 in ^x04Pro 15^x01", prefix, name, LANG_PLAYER, "KZ_PLACE", (i+1));
				}
			}

			return;
		}

		if( (equali(Pro_Names[i], name) && (get_pcvar_num(kz_top15_authid) == 0)) || (equali(Pro_AuthIDS[i], authid) && (get_pcvar_num(kz_top15_authid) == 1)) )
		{
			if( time > protiempo )
			{
				new min, Float:sec;
				min = floatround(slower, floatround_floor)/60;
				sec = slower - (60*min);
				ColorChat(id, GREEN,  "%s^x01 %L ^x03%02d:%s%.2f^x01", prefix, id, "KZ_SLOWER", min, sec < 10 ? "0" : "", sec);
				return;
			}
		}

	}
}

public save_pro15()
{
	new profile[128]
	formatex(profile, 127, "%s/pro_%s.cfg", Topdir, MapName)

	if( file_exists(profile) )
	{
		delete_file(profile)
	}

	new Data[256];
	new f = fopen(profile, "at")

	for(new i = 0; i < 15; i++)
	{
		formatex(Data, 255, "^"%.2f^"   ^"%s^"   ^"%s^"   ^"%s^"^n", Pro_Times[i], Pro_AuthIDS[i], Pro_Names[i], Pro_Date[i])
		fputs(f, Data)
	}
	fclose(f);
}

public read_pro15()
{
	new profile[128], prodata[256]
	formatex(profile, 127, "%s/pro_%s.cfg", Topdir, MapName)

	new f = fopen(profile, "rt" )
	new i = 0
	while( !feof(f) && i < 16)
	{
		fgets(f, prodata, 255)
		new totime[25]
		parse(prodata, totime, 24, Pro_AuthIDS[i], 31, Pro_Names[i], 31, Pro_Date[i], 31)
		Pro_Times[i] = str_to_float(totime)
		i++;
	}
	fclose(f)
}

//==================================================================================================

public NoobTop_update(id, Float:time, checkpoints, gochecks)
{
	new authid[32], name[32], thetime[32], wpn, Float: slower, Float: faster, Float:noobtiempo
	get_user_name(id, name, 31);
	get_user_authid(id, authid, 31);
	get_time(" %d/%m/%Y ", thetime, 31);
	new bool:Is_in_noob15
	Is_in_noob15 = false
	if(user_has_scout[id])
		wpn=CSW_SCOUT
	else
		wpn=get_user_weapon(id)

	for(new i = 0; i < 15; i++)
	{
		if( (equali(Noob_Names[i], name) && (get_pcvar_num(kz_top15_authid) == 0)) || (equali(Noob_AuthIDS[i], authid) && (get_pcvar_num(kz_top15_authid) == 1)) )
		{
			Is_in_noob15 = true
			slower = time - Noob_Tiempos[i];
			faster = Noob_Tiempos[i] - time;
			noobtiempo = Noob_Tiempos[i]
		}
	}

	for (new i = 0; i < 15; i++)
	{
		if( time < Noob_Tiempos[i])
		{
			new pos = i

			if ( get_pcvar_num(kz_top15_authid) == 0 )
				while( !equal(Noob_Names[pos], name) && pos < 15 )
				{
					pos++;
				}
			else if ( get_pcvar_num(kz_top15_authid) == 1)
				while( !equal(Noob_AuthIDS[pos], authid) && pos < 15 )
				{
					pos++;
				}

			for (new j = pos; j > i; j--)
			{
				formatex(Noob_AuthIDS[j], 31, Noob_AuthIDS[j-1])
				formatex(Noob_Names[j], 31, Noob_Names[j-1])
				formatex(Noob_Date[j], 31, Noob_Date[j-1])
				formatex(Noob_Weapon[j], 31, Noob_Weapon[j-1])
				Noob_Tiempos[j] = Noob_Tiempos[j-1]
				Noob_CheckPoints[j] = Noob_CheckPoints[j-1]
				Noob_GoChecks[j] = Noob_GoChecks[j-1]
			}

			formatex(Noob_AuthIDS[i], 31, authid);
			formatex(Noob_Names[i], 31, name);
			formatex(Noob_Date[i], 31, thetime)
			formatex(Noob_Weapon[i], 31, g_weaponsnames[wpn])
			Noob_Tiempos[i] = time
			Noob_CheckPoints[i] = checkpoints
			Noob_GoChecks[i] = gochecks

			save_Noob15()

			if( Is_in_noob15 )
			{

				if( time < noobtiempo )
				{
					new min, Float:sec;
					min = floatround(faster, floatround_floor)/60;
					sec = faster - (60*min);
					ColorChat(id, GREEN,  "%s^x01 %L ^x03%02d:%s%.2f^x01", prefix, id, "KZ_IMPROVE", min, sec < 10 ? "0" : "", sec);

					if( (i + 1) == 1)
					{
						client_cmd(0, "spk woop");
						ColorChat(0, GREEN,  "%s^x01^x03 %s^x01 %L^x03 1^x01 in ^x04Noob 15^x01", prefix, name, LANG_PLAYER, "KZ_PLACE");
					}
					else
					{
						client_cmd(0, "spk buttons/bell1");
						ColorChat(0, GREEN,  "%s^x01^x03 %s^x01 %L^x03 %d^x01 in ^x04Noob 15^x01", prefix, name, LANG_PLAYER, "KZ_PLACE", (i+1));
					}
				}
			}
			else
			{
				if( (i + 1) == 1)
				{
					client_cmd(0, "spk woop");
					ColorChat(0, GREEN,  "%s^x01^x03 %s^x01 %L^x03 1^x01 in ^x04Noob 15^x01", prefix, name, LANG_PLAYER, "KZ_PLACE");
				}
				else
				{
					client_cmd(0, "spk buttons/bell1");
					ColorChat(0, GREEN,  "%s^x01^x03 %s^x01 %L^x03 %d^x01 in ^x04Noob 15^x01", prefix, name, LANG_PLAYER, "KZ_PLACE", (i+1));
				}
			}
			return;
		}

		if( (equali(Noob_Names[i], name) && (get_pcvar_num(kz_top15_authid) == 0)) || (equali(Noob_AuthIDS[i], authid) && (get_pcvar_num(kz_top15_authid) == 1)) )
		{
			if( time > noobtiempo )
			{

				new min, Float:sec;
				min = floatround(slower, floatround_floor)/60;
				sec = slower - (60*min);
				ColorChat(id, GREEN,  "%s^x01 %L ^x03%02d:%s%.2f^x01", prefix, id, "KZ_SLOWER", min, sec < 10 ? "0" : "", sec);
				return;
			}
		}

	}
}

public save_Noob15()
{
	new profile[128]
	formatex(profile, 127, "%s/Noob_%s.cfg", Topdir, MapName)

	if( file_exists(profile) )
	{
		delete_file(profile)
	}

	new Data[256];
	new f = fopen(profile, "at")

	for(new i = 0; i < 15; i++)
	{
		formatex(Data, 255, "^"%.2f^"   ^"%s^"   ^"%s^"   ^"%i^"   ^"%i^"   ^"%s^"  ^"%s^" ^n", Noob_Tiempos[i], Noob_AuthIDS[i], Noob_Names[i], Noob_CheckPoints[i], Noob_GoChecks[i],Noob_Date[i],Noob_Weapon[i])
		fputs(f, Data)
	}
	fclose(f);
}

public read_Noob15()
{
	new profile[128], prodata[256]
	formatex(profile, 127, "%s/Noob_%s.cfg", Topdir, MapName)

	new f = fopen(profile, "rt" )
	new i = 0
	while( !feof(f) && i < 16)
	{
		fgets(f, prodata, 255)
		new totime[25], checks[5], gochecks[5]
		parse(prodata, totime, 24, Noob_AuthIDS[i], 31, Noob_Names[i], 31,  checks, 4, gochecks, 4, Noob_Date[i], 31, Noob_Weapon[i], 31)
		Noob_Tiempos[i] = str_to_float(totime)
		Noob_CheckPoints[i] = str_to_num(checks)
		Noob_GoChecks[i] = str_to_num(gochecks)
		i++;
	}
	fclose(f)
}

public ProTop_show(id)
{
	new  buffer[2048], len, name[32]

	len = formatex(buffer, 2047, "<body bgcolor=#3399FF><table width=100%% cellpadding=2 cellspacing=0 border=0>")
	len += formatex(buffer[len], 2047-len, "<tr  align=center bgcolor=#0052FF><th width=5%%> # <th width=45%% align=center> Player <th  width=30%%> Time <th width=20%%> Date ")

	for (new i = 0; i < 10; i++)
	{
		name = Pro_Names[i]

		if( Pro_Times[i] > 9999999.0 )
		{
			len += formatex(buffer[len], 2047-len, "<tr align=center%s><td> %d <td align=center> %s <td> %s <td> %s", ((i%2)==0) ? " bgcolor=#5DA5FF" : " bgcolor=#3399FF", (i+1), "", "", "")
		}

		else
		{
			new minutos, Float:segundos
			minutos = floatround(Pro_Times[i], floatround_floor)/60
			segundos = Pro_Times[i] - (60*minutos)

			len += formatex(buffer[len], 2047-len, "<tr align=center%s><td> %d <td align=center> %s <td> <b>%02d:%s%.2f <td> %s", ((i%2)==0) ? " bgcolor=#5DA5FF" : " bgcolor=#3399FF", (i+1), Pro_Names[i], minutos, segundos < 10 ? "0" : "", segundos, Pro_Date[i])

		}
	}

	len += formatex(buffer[len], 2047-len, "</table></body>")
	len += formatex(buffer[len], 2047-len, "<tr><Center><b><BR>Plugin created by nucLeaR")

	show_motd(id, buffer, "Pro10 Climbers")

	return PLUGIN_HANDLED
}

public NoobTop_show(id)
{
	new buffer[2048], name[32], len

	len = formatex(buffer, 2047, "<body bgcolor=#3399FF><table width=100%% cellpadding=2 cellspacing=0 border=0>")
	len += formatex(buffer[len], 2047-len, "<tr  align=center bgcolor=#0052FF><th width=5%%> # <th width=35%% align=center> Player <th  width=20%%> Time  <th width=10%%> CPs <th width=10%%> TPs <th width=10%%> Date")

	for (new i = 0; i < 10; i++)
	{
		if( Noob_Tiempos[i] > 9999999.0 )
		{
			len += formatex(buffer[len], 2047-len, "<tr align=center%s><td> %d <td align=center> %s <td> %s <td> %s <td> %s <td> %s", ((i%2)==0) ? " bgcolor=#5DA5FF" : " bgcolor=#3399FF", (i+1), "", "", "", "", "")
		}

		else
		{
			name = Noob_Names[i]
			new minutos, Float:segundos
			minutos = floatround(Noob_Tiempos[i], floatround_floor)/60
			segundos = Noob_Tiempos[i] - (60*minutos)

			len += formatex(buffer[len], 2047-len, "<tr align=center%s><td> %d <td align=center> %s%s <td> <b>%02d:%s%.2f <td> %d <td> %d <td> %s", ((i%2)==0) ? " bgcolor=#5DA5FF" : " bgcolor=#3399FF", (i+1), Noob_Names[i], equal(Noob_Weapon[i],"scout") ? "(scout)" : "", minutos, segundos < 10 ? "0" : "", segundos, Noob_CheckPoints[i], Noob_GoChecks[i], Noob_Date[i], Noob_Weapon[i])
		}
	}

	len += formatex(buffer[len], 2047-len, "</table></body>")
	len += formatex(buffer[len], 2047-len, "<tr><Center><b><BR>Plugin created by nucLeaR")

	show_motd(id, buffer, "Noob10 Climbers")

	return PLUGIN_HANDLED
}
#endif

// You reached the end of file
// The original plugin was made by p4ddY
// This plugin was edited by nucLeaR
// Version 2.31
