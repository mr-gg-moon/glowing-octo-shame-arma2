#define __A2OA__
/*
 * TODO: Рефакторинг.
 */
private ["_str","_n","_arr","_arr0","_player","_side"];

// playerSide не меняется самостоятельно.
if (isMultiplayer) then {
_side = side player;
while {sleep 0.01; _side == sideUnknown} do {
	_side = side player;
};
gosa_playerSide = _side;
}else{
	waitUntil {!isNil "gosa_friendlyside"};
	gosa_playerside = gosa_friendlyside select 0;
};

// Ошибки настроек.
[] execVM "dir\client\init_gameMode.sqf";

// Маркеры возрождения должны присутствовать до начала миссии.
[] execVM "dir\client\while_markers.sqf";

#ifdef __ARMA3__
	if (gosa_playerSide == sideLogic) then {
		[] spawn gosa_fnc_spectator_init;
	};
#endif

_arr = [];

// Для совместимости.
if (isNil "gosa_SquadRole") then {
	gosa_SquadRole = -2;
};

if (isNil "gosa_playerStartingClass") then {
	_str = typeOf player;
	while {sleep 0.01; _str == ""} do {
		_str = typeOf player;
	};
	_arr set [0,_str];
	_n = 0;
	if (_str in gosa_pilotL) then {
		_n = 1;
	};
	_arr set [1,_n];
	gosa_playerStartingClass = _n;
	diag_log format ["Log: [init_client] player typeOf %2, Class %3", nil, _str, _n];
};

gosa_squadOn = [];
gosa_squadOff = [];
gosa_squadOnW = [];
gosa_squadOffW = [506,600,605];
#ifdef __ARMA3__
if (difficultyOption "thirdPersonView" <= 0) then {
	gosa_squadOffW set [count gosa_squadOffW, 500];
};
#endif
gosa_MapPlayer = [];
availableVehiclesBuyMenu = [[],[],[]];

//--- Окружение-погружение.
if(worldName == "namalsk")then{
	enableEnvironment false;
};
gosa_GroupIconsVisible = if (gosa_loglevel > 0) then {[true, true]}else{[true, false]};

#ifndef __ARMA3__
	waitUntil{!isNil "bis_fnc_init"};
#endif
waitUntil{!isNil "gosa_fnc_init"};

/*
[] spawn {
	// BIS_Effects_AirDestructionStage2
	waitUntil {!isNil "BIS_Effects_Secondaries"};
	if (ACE_Avail) then {waitUntil {!isNil "WARFX_Effects_Init"}};
	BIS_Effects_AirDestructionStage2 = compile preprocessFileLineNumbers "dir\Client\AirDestructionStage2.sqf";
};
*/

_str = getPlayerUID player;
if (isMultiplayer) then {
while {sleep 0.01; _str == ""} do {
	_str = getPlayerUID player;
};
};
gosa_playerOwner = _str;
gosa_owner = _str;
_arr set [2, _str];
diag_log format ["Log: [init_client] Player UI %1", _str];

#ifndef __ARMA3__
// В файле беспорядок, поэтому сюда поместил временно.
diag_log format ["Log: [init_client] waitUntil gosa_MapPlayers", nil];
waitUntil{!isNil "gosa_MapPlayers"};
diag_log format ["Log: [init_client] post waitUntil gosa_MapPlayers", nil];
#endif

// TODO: Компилировать все execVM заранее.
[] execVM "dir\client\while_debug_notice.sqf";
[] execVM "dir\client\while_respawnRandom.sqf";
[] execVM "dir\common\while_reinforcement_v2.sqf";
if !(isServer) then {
	// FIXME: Сервер не может считать obj assignedVehicle для не серверных ИИ?
	[] execVM "dir\client\while_groups_other.sqf";
};
if (gosa_playerSide == sideLogic) exitWith {
	diag_log format ["Log: [init_client] %1, %2, exitWith", time, sideLogic];
};
[] execVM "dir\client\while_sp_rating.sqf";
[] execVM "dir\client\clientMenu.sqf";
[] execVM "dir\client\while_localGroup.sqf";
[] execVM "dir\client\while_act_BuyMenu.sqf";
[] execVM ("dir\client\while_aa_hidden.sqf");
[] execVM ("dir\client\while_keyEH_smoke.sqf");
[] execVM ("dir\client\while_assignedVehicle.sqf");
[] execVM ("dir\ban\while_ban.sqf");
[] execVM "dir\testing\while_act_laserBomb.sqf";
[] execVM "dir\functions\fnc_SSM_updateMenu.sqf";
[] execVM "dir\client\while_survival.sqf";

/*
// TODO: Нужна функция.
if ([[player], Officers] call gosa_fnc_CheckIsKindOfArray) then {
	waitUntil{!isNil "gosa_HC_logic"};
	[] call compile preprocessFileLineNumbers "dir\client\gosa_hc.sqf";
	[] execVM "dir\client\while_hc.sqf";
	[player] execVM ("\ca\modules\hc\data\scripts\HC_GUI.sqf");
	[] execVM "dir\client\gosa_hc_gui_wp_attack.sqf";
};
*/

// [] call compile preprocessFileLineNumbers  "dir\Client\coin.sqf";

/* _player = (createVehicle [typeOf player, position player, [], 0, "FORM"]);
selectPlayer _player;
 */

// TODO: Нужна функция.
"respawn" spawn gosa_fnc_RespawnWeaponsAdd;

// TODO: Нужна функция.
player addEventHandler ["killed", {
	skipAddAction = true;
	// _this select 0 setVariable ["BIS_IS_Dead", true, true];
	_this spawn {
		waitUntil{alive player};
		player setCaptive false;
		skipAddAction = nil;
	};
}];

// TODO: Нужна функция для addEventHandler-ов.
if (isMultiplayer) then {
	player addEventHandler ["Respawn", {call gosa_fnc_eh_playerRespawn}];
	// player addEventHandler ["killed", {_this spawn gosa_fnc_killcam}];
	// player addEventHandler ["respawn", {player spawn gosa_fnc_RespawnWeaponsAdd}];
	player addEventHandler ["killed", {"respawn" spawn gosa_fnc_RespawnWeaponsAdd}];
	player addEventHandler ["killed", {_this spawn gosa_fnc_resetActions}];
	// player addEventHandler ["killed", {_this select 0 call {_this setVariable ["BIS_lifestate","ALIVE",true]}}];
	if(missionNamespace getVariable "respawn" != 1)then{
		player addEventHandler ["killed", {call gosa_fnc_eh_playerKilled}];
		waitUntil{!isNil "gosa_MPF_InitDone"};
		#ifdef __ARMA3__
			[nil, player, _arr select 2] remoteExec ["rgosa_setMapPlayerscode", 2];
		#else
			[nil, player, rgosa_setMapPlayers, _arr select 2] call RE;
		#endif
	};
}else{
	#ifdef __ARMA3__
		addMissionEventHandler ["TeamSwitch", {
			//params ["_previousUnit", "_newUnit"];
			[_this select 1, objNull] spawn gosa_fnc_eh_playerSelected;
			_this select 0 enableAI "TeamSwitch";
		}];
	#else
	onTeamSwitch {
			40 CutRsc["OptionsAvailable","PLAIN",0];
			[_to, objNull] spawn gosa_fnc_eh_playerSelected;
			_from enableAI "TeamSwitch";
	};
	#endif

	_arr0 = units group player;
	for "_i" from 0 to (count _arr0 -1) do {
		_str = _arr0 select _i getVariable "type";
		// TODO: Не перезаписывать изменения инвентаря пользователем.
		if !(isNil "_str") then {
			[_arr0 select _i, _str] call gosa_fnc_unit_loadout;
		};
	};

	_arr = [];
	{
		if (side _x in [sideLogic]) then {
			_arr set [count _arr, _x];
		}else{
			diag_log format ["Log: [init_client] delete switchableUnit %1", _x];
			deleteVehicle _x;
		};
	} forEach switchableUnits - _arr0;
	// Один слот остаётся для совместимости.
	for "_i" from 0 to (count _arr -2) do {
		diag_log format ["Log: [init_client] delete switchableUnit %1", _arr select _i];
		deleteVehicle (_arr select _i);
	};
	EnableTeamSwitch true;
	gosa_switchableUnits_removed = true;

	#ifdef __ARMA3__
		[nil, "menu"] call BIS_fnc_addCommMenuItem;
	#endif
};

// радио 0-0, чтоб разные скрипты тестировать
[] call compile preprocessFileLineNumbers  "dir\Client\radio\init.sqf";

if (gosa_loglevel > 0) then {	//diag_log
	// Военные обозначения, показ всех, чтобы видеть как и где создаются боты.	//diag_log
	_arr = ([] call BIS_fnc_getFactions);	//diag_log
	// player setVariable ["MARTA_showRules", ["USMC", 1, "CDF", 0]];	//diag_log
	if (typeName (_arr select 0) == typeName (_arr select 1)) then {//diag_log
	for "_i" from (count _arr * 2 -1) to 1 step -2 do {	//diag_log
		_arr set [_i, 1];	//diag_log
	};	//diag_log
	for "_i" from (count _arr * 2 -2) to 0 step -2 do {	//diag_log
		_arr set [_i, _arr select _i];	//diag_log
	};	//diag_log
	gosa_MARTA_showRules = _arr;	//diag_log
	};//diag_log
};  //diag_log

diag_log format ["Log: [init_client] Done %1", time];
