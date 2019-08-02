#include <amxmodx>


#define PLUGIN_NAME "Server Info"
#define PLUGIN_VERSION  "1.0"
#define PLUGIN_AUTHOR   "VINAGHOST"

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

	register_clcmd("say /server", "server")
}

public server(id) {

	show_motd(id, "http://103.48.193.60/server.html");
}
