#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <sqlx>


#define PLUGINNAME	"Chat Logger SQL"
#define VERSION		"0.8b"
#define AUTHOR		"naputtaja"



#define table           "chatlog_kz"

// SQL Settings
new Handle:g_SqlX
new Handle:g_SqlConnection
new g_error[512]

new const TEAMNAME[_:CsTeams][] = {"*DEAD*", "(Terrorist)", "(Counter-Terrorist)", "*SPEC*"}


public plugin_init()
{
	register_plugin(PLUGINNAME, VERSION, AUTHOR)
	register_cvar("amx_chat_logger",VERSION,FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY)
	
	set_task(0.1, "check_sql")
	return PLUGIN_CONTINUE 
}
public plugin_natives()
{
	register_native("chat_log_sql", "chat_log_sql")
}

public check_sql()
{
	new errorcode;
	
	g_SqlX = SQL_MakeStdTuple()
	g_SqlConnection = SQL_Connect(g_SqlX,errorcode,g_error,511);
	
	if (!g_SqlConnection) {
		console_print(0,"Chat log SQL: Could not connect to SQL database.!")
		return log_amx("Chat log SQL: Could not connect to SQL database.")
	}
	
	console_print(0,"[Chat Logger] SQL Connected!")
	return PLUGIN_CONTINUE 
}

public chat_log_sql() 
{   
	static datestr[11]
	new authid[32],name[32], name2[32],ip[16],timestr[9]
	
	new id = get_param(1);
	new tag[32]
	get_string(2, tag, charsmax(tag));
	
	new team_chat = get_param(3);
	
	new msg[100], msg2[100];
	get_string(4, msg, charsmax(msg));
	MakeStringSQLSafe(msg, msg2, charsmax(msg2))
	
	new CsTeams:team = cs_get_user_team(id)
	get_user_authid(id,authid,32)  
	
	get_user_name(id,name,31)
	MakeStringSQLSafe(name, name2, charsmax(name2))
	
	get_user_ip(id, ip, 15, 1)
	
	get_time("%Y.%m.%d", datestr, 12)
	get_time("%H:%M:%S", timestr, 8)
	
	//server_print("'%s','%s','%s','%s','%s', '%d', '%d', '%s','%s','%s'", name,authid,ip,tag, TEAMNAME[_:team], team_chat, is_user_alive(id),datestr,timestr,msg)
	new query[512]
	formatex(query,charsmax(query),"INSERT into %s (name,authid,ip,tag,team,team_chat,alive,date_chat,time_chat,message) values ('%s','%s','%s','%s','%s', '%d', '%d', '%s','%s','%s')",table, name2,authid,ip,tag, TEAMNAME[_:team], team_chat, is_user_alive(id),datestr,timestr,msg2)
	
	SQL_ThreadQuery(g_SqlX,"QueryHandle",query)
} 


public QueryHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return log_amx("Chat log SQL: Could not connect to SQL database.")
	
	else if(FailState == TQUERY_QUERY_FAILED)
		return log_amx("Chat log SQL: Query failed:  %s",Error)
	
	if(Errcode)
		return log_amx("Chat log SQL: Error on query: %s",Error)
	
	new DataNum
	while(SQL_MoreResults(Query))
	{
		DataNum = SQL_ReadResult(Query,0)
		server_print("zomg, some data: %s",DataNum)
		SQL_NextRow(Query)
	}
	return PLUGIN_CONTINUE
}
MakeStringSQLSafe(const input[], output[], len)
{
	copy(output, len, input);
	replace_all(output, len, "'", "*");
	replace_all(output, len, "^"", "*");
	replace_all(output, len, "`", "*");
}
