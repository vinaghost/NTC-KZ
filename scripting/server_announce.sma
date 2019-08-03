#include <amxmodx>
#include <sqlx>


#define PLUGIN_NAME "Server Announce"
#define PLUGIN_VERSION  "1.0"
#define PLUGIN_AUTHOR   "VINAGHOST"

new Array:g_message;
new num, pos;

new Handle:g_SqlX
new Handle:g_SqlConnection
new g_error[128]

new const sql_table[] = "server_announce";

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

	register_clcmd("update_message", "update_message");
	set_task(30.0, "show_message", 113, _, _, "b");
	pos = 0;

	set_task(2.0, "sql")

}
public plugin_cfg() {
	g_message = ArrayCreate(128);
}
public sql() {
	new errorcode;

	g_SqlX = SQL_MakeStdTuple()
	g_SqlConnection = SQL_Connect(g_SqlX, errorcode, g_error, charsmax(g_error));

	if (!g_SqlConnection) {
		console_print(0,"[Server Announce] Could not connect to SQL database.!")
		return log_amx("[Server Announce] Could not connect to SQL database.")
	}

	new query[128];
	formatex(query,charsmax(query),"CREATE TABLE IF NOT EXISTS %s (message varchar(512) CHARACTER SET utf8 COLLATE utf8_bin))", sql_table);

	SQL_ThreadQuery(g_SqlX, "QuerySetData", query);

	console_print(0,"[Server Announce] SQL Connected!")

	update_message()
	return PLUGIN_CONTINUE
}
public update_message() {
	new query[128];
	formatex(query,charsmax(query),"SELECT * FROM %s", sql_table);

	SQL_ThreadQuery(g_SqlX, "QueryGetData", query);

}
public QuerySetData(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return log_amx("[Server Announce] Could not connect to SQL database.")

	else if(FailState == TQUERY_QUERY_FAILED)
		return log_amx("[Server Announce] Query failed:  %s",Error)

	if(Errcode)
		return log_amx("[Server Announce] Error on query: %s",Error)

	return PLUGIN_CONTINUE
}
public QueryGetData(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return log_amx("[Server Announce] Could not connect to SQL database.")

	else if(FailState == TQUERY_QUERY_FAILED)
		return log_amx("[Server Announce] Query failed:  %s",Error)

	if(Errcode)
		return log_amx("[Server Announce] Error on query: %s",Error)

	new message[128]
	num = SQL_NumResults(Query);

	while(SQL_MoreResults(Query))
	{
		SQL_ReadResult(Query, 0, message, charsmax(message));
		ArrayPushString(g_message, message);

		SQL_NextRow(Query)
	}
	return PLUGIN_CONTINUE
}
// ^4 green
// ^3 team
// ^1 yellow
public show_message() {

	if ( pos >= num || pos < 0) {
		pos = 0;
	}

	new message[124];
	ArrayGetString(g_message, pos, message, charsmax(message));
	client_print_color(0, print_team_red, "^4[NTC]^1 %s", message);

	pos++;
}

public plugin_end() {
	remove_task(113);
	SQL_FreeHandle(g_SqlX);
	SQL_FreeHandle(g_SqlConnection);
}
