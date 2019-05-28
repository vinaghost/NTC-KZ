#include <amxmodx>
#include <hamsandwich>
#include <engine>

#define PLUGIN_NAME "KZ: Te khong mat mau"
#define PLUGIN_AUTHOR "VINAGHOST"
#define PLUGIN_VERSION "1.0"

public plugin_init() {

    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
    RegisterHam(Ham_TakeDamage, "player", "Ham_PlayerTakeDamage")
}

public Ham_PlayerTakeDamage(id, iInflictor, iAttacker, Float:flDamage, iBits) {
    if( !is_user_alive(id) ) return HAM_IGNORED;

    if(iBits == DMG_FALL) {
        SetHamParamFloat(4, 0.0);
        return HAM_HANDLED
    }

    return HAM_IGNORED
}
