#define __A2OA__
/*
 * TODO: Рефакторинг.
 * TODO: Совместмость с играми без заводов.
 * TODO: Подсветка и выделение приобретеных юнитов.
 * TODO: Использовать позицию под курсором.
 */
diag_log format ["Log: [fnc_Client_BuyUnit]: _this %1", _this];
private ["_type","_HQ","_fnc_1","_isUAV","_z","_player_dir","_obj","_timeOut",
	"_str","_type_Lower","_Objects","_veh","_num","_b","_asl",
	"_factory_obj","_buy_dist_max","_player_pos","_player_veh",
	"_factory_dir","_factory_pos","_name","_alive","_arr0","_obj0",
	"_cfgVeh","_entry","_crew","_sizeOf","_sizeAllowed","_box",
	"_side","_listHQ_str","_class","_fnc_factory_HQ","_factory_HQ",
	"_factory","_pos","_logic","_arr","_status","_vr"];

_cfgVeh = LIB_cfgVeh;
_crew = [];
_asl = false;
_timeOut = 30;
if (missionNamespace getVariable "gosa_gamemode_vr" > 0) then {_vr = true} else {_vr = false};

_type = _this Select 0;

#ifdef __ARMA3__
	_sizeAllowed = 27;
#else
	_sizeAllowed = 25;
#endif
_entry = _cfgVeh >> _type;
_side = gosa_playerSide;
_player_veh = vehicle player;
_player_dir = getDir _player_veh;
_player_pos = getPos _player_veh;
_pos = _player_pos;
_buy_dist_max = gosa_distanceCoinBase;
_name = getText (_entry >> "displayName");
if (_name == "") then {
	_name = _type;
};

_type_Lower = toLower _type;

//-- Завод передан через переменную.
// _factory = [_logic, _class, _status, [_obj,_obj,objNull], _side, _str]
if !(isNil "gosa_menu") then {
	_factory = gosa_menu;
	diag_log format ["Log: [fnc_Client_BuyUnit]: _factory %1", _factory];
	if (_factory select 1 in [0]) then {
		_logic = _factory select 0;
		_pos = getPos _logic;
		_player_dir = getDir _logic;

		_factory_obj = _logic;
	};
};

//-- Доставка на дом.
if (missionNamespace getVariable "gosa_shop" == 2) then {
	_factory_obj = _player_veh;
};

// FIXME: sizeOf не работает. At least one object of the given classname has to be present in the current mission otherwise zero will be returned.
// FIXME: Переназначение оригинальной позиции нельзя делать.

//-- Приобретение мобильного штаба.
if ([_type_Lower, 0] call gosa_fnc_isHQ) exitWith {
	_status = 2;
	_str = _type_Lower call gosa_fnc_fixType;
	_pos = ([_pos, 0, 1 max sizeOf _type, false, _timeOut] call gosa_fnc_getSafePos);
	if (count _pos > 0) then {
		_arr = [_pos, _type_Lower, _status, gosa_playerSide, player, _player_dir, _str];
		#ifdef __ARMA3__
			_arr remoteExec ["gosa_fnc_createHQ", 2];
		#else
			[nil, _arr, rgosa_fnc_createHQ] call RE;
		#endif
		[_pos, _name] call gosa_fnc_hint_layout_completed;
	}else{
		[_name] call gosa_fnc_hint_layout_timeOut;
	};
};

// Для совместимости.
_HQ = listMHQ + HQ;

//-- Беспилотники.
// TODO: Мовместимость с A3.
_isUAV=false;
if(_type isKindOf "UAV")then{
	_isUAV=true;
}else{
	if(getNumber (_entry >> "isUav") == 1)then{
		_isUAV=true;
	};
};

// TODO: Использовать одну переменную.
_fnc_1={
	//_veh = _this;

	if(_isUAV)then{
		#ifdef __ARMA3__
			_side createVehicleCrew _veh;
			_veh setAutonomous false;
		#else
			// Не работает с UAV или UGV в A3.
			_crew = ([_veh, createGroup _side, _side, _type, [], _entry, _pos] call gosa_fnc_spawnCrew);
		#endif
	}else{
		group player addVehicle _veh;
	};

	#ifdef __ARMA3__
		[_veh, "fnc_Client_BuyUnit"] remoteExec ["gosa_fnc_vehInit2"];
	#else
		[nil, _veh, rvehInit] call RE;
	#endif


	player reveal _veh;

	#ifdef __ARMA3__
		_veh setCollisionLight true;
	#else
		// Синхронизация.
		// TODO: Проверить с A3.
		if (isMultiplayer) then {
			_veh setPos getPos _veh;
		};

		// FIXME: В подталкивании нет необходимости,
		// если земля без наклона.
		_veh setVectorUp [0,0,1];

		[[_veh], true] call gosa_fnc_reweapon;
	#endif
};

if (true) then {
	//-- Мегаящик.
	if (_type == "gosa_megaAmmoBox") then {
		if (isNil "_factory_obj") then {
			_arr = nearestObjects [_player_pos, gosa_type_Barracks, _buy_dist_max];
			// Для совместимости.
			if (count _arr < 1) then {
				_arr = nearestObjects [_player_pos, _HQ+["WarfareBDepot","WarfareBCamp"], _buy_dist_max];
			};
			if (count _arr > 0) then {
				_factory_obj = _arr select 0;
			};
		};

		if !(isNil "_factory_obj") then {
				_pos = [_pos, 1.5, getDir _player_veh] call BIS_fnc_relPos;
				// TODO: A3 ящик слишком сильно нагружен, лучше использовать класический инвентарь как в миссиях других.
				_veh = (
					#ifdef __ARMA3__
						"Box_NATO_Ammo_F"
					#else
						"USBasicAmmunitionBox_EP1"
					#endif
					createVehicleLocal _pos);
				player reveal _veh;
				_veh setVariable ["gosa_megaAmmoBox",true];
				// TODO: Не нужно сообщать другим игрокам о локальных объектах.
				[_veh, _name] call gosa_fnc_hint_layout_completed;
		};
	};

	//-- Ящик с оружием.
	if ((_type isKindOf "ReammoBox")
		or (toLower getText(_entry >> "vehicleclass") in ["ammo","ace_ammunition"]))
	then
	{
		if (isNil "_factory_obj") then {
			_arr = nearestObjects [_player_pos, gosa_type_Barracks, _buy_dist_max];
			// Для совместимости.
			if (count _arr < 1) then {
				_arr = nearestObjects [_player_pos, _HQ+["WarfareBDepot","WarfareBCamp"], _buy_dist_max];
			};
			if (count _arr > 0) then {
				_factory_obj = _arr select 0;
			};
		};

		if !(isNil "_factory_obj") then {
				_pos = [_pos, 1.5, getDir _player_veh] call BIS_fnc_relPos;
				_veh = (_type createVehicle _pos);
				player reveal _veh;
				[_veh, _name] call gosa_fnc_hint_layout_completed;
		};
	};

	//-- Солдаты.
	if (_type isKindOf "Man") then {
		if (isNil "_factory_obj") then {
			_arr = nearestObjects [_player_pos, gosa_type_Barracks, _buy_dist_max];
			// Для совместимости.
			if (count _arr < 1) then {
				_arr = nearestObjects [_player_pos, _HQ+Airport+["WarfareBDepot","WarfareBCamp"], _buy_dist_max];
			};
			if (count _arr > 0) then {
				_factory_obj = _arr select 0;
				_pos = getPos _factory_obj;
			};
		};

		if !(isNil "_factory_obj") then {
			if ((count units player) < 10 or true)then{
				// _pos = ([_pos, (sizeOf typeOf (_Objects select 0)) / 2 + (sizeOf _type) / 2, random 360] call BIS_fnc_relPos);
					_veh = [group player, [_type, _pos, [], 0.2, "FORM"], _vr, [_side, _type]] call gosa_fnc_createUnit;

					if !(isMultiplayer) then {
						addSwitchableUnit _veh;
					};

						// TODO: Нужна глобальная функция.
						Private["_cost","_rank"];
						_cost = getNumber (configFile >> "CfgVehicles" >> _type >> "cost");
						_rank="PRIVATE";
						if(_cost>=50000)then{_rank="CORPORAL"};
						if(_cost>=150000)then{_rank="SERGEANT"};
						if(_cost>=250000)then{_rank="LIEUTENANT"};
						if(_cost>=350000)then{_rank="CAPTAIN"};
						if(_cost>=500000)then{_rank="MAJOR"};
						if(_cost>=750000)then{_rank="COLONEL"};
						if (toUpper _rank != "PRIVATE") then {
							#ifdef __ARMA3__
								_veh setRank _rank;
							#else
								// До A3 движок не синхронизирует ранги самостоятельно.
								[nil, _veh, rsetRank, _rank] call RE;
							#endif
						};

					// Для __ARMA3__ нужно тоже отключить.
					#ifndef __A2OA__
					if (isServer) then {
						_veh addEventHandler ["killed",{[_this select 0] call BIS_GC_trashItFunc}];
						if ((!alive _veh) or (isNil "BIS_GC_trashItFunc")) then {
							deleteVehicle _veh;
						};
					};
					#endif

					_veh call _fnc_1;
					[_veh, _name] call gosa_fnc_hint_layout_completed;
			}else{
				hint "10 max";
			};
		};
	};

	//-- Наземный транспорт.
	// TODO: Проверка завода.
	if ([[_type],["Car","Motorcycle","Tank"]] call gosa_fnc_CheckIsKindOfArray) then
	{
		if (isNil "_factory_obj") then {
			if (_type isKindOf "Tank") then {
				_arr = nearestObjects [_player_pos, gosa_type_HeavyFactory, _buy_dist_max];
			}else{
				_arr = nearestObjects [_player_pos, gosa_type_LightFactory, _buy_dist_max];
			};
			// Для совместимости.
			if (count _arr < 1) then {
				_arr = nearestObjects [_player_pos, _HQ+Airport+["WarfareBDepot","WarfareBCamp"], _buy_dist_max];
			};
			if (count _arr > 0) then {
				_factory_obj = _arr select 0;
				_pos = getPos _factory_obj;
			};
		};

		if !(isNil "_factory_obj") then {
			_pos = ([_pos, 0, 10 max sizeOf _type, false, _timeOut] call gosa_fnc_getSafePos);
			if (count _pos > 0) then {
			_veh = (createVehicle [_type, _pos, [], 0, "CAN_COLLIDE"]);
			_veh call _fnc_1;
			[_veh, _name] call gosa_fnc_hint_layout_completed;
			}else{
				[_name] call gosa_fnc_hint_layout_timeOut;
			};
		};
	};

	// TODO: Беспилотники Arma 3.

	//-- Вертолёты.
	if (_type isKindOf "Helicopter") then {
		if (isNil "_factory_obj") then {
			_arr = nearestObjects [_player_pos, gosa_type_AircraftFactory, _buy_dist_max];
			// Для совместимости.
			if (count _arr < 1) then {
				_arr = nearestObjects [_player_pos, _HQ+Airport+["WarfareBDepot","WarfareBCamp"], _buy_dist_max];
			};
			if (count _arr > 0) then {
				_factory_obj = _arr select 0;
				_pos = getPos _factory_obj;
			};
		};

		if !(isNil "_factory_obj") then {
			_b = true;
			_arr = [_pos select 0, _pos select 1, 2000 + random 500];
			_veh = createVehicle [_type, _arr, [], 2000, "NONE"];
			_sizeOf = sizeOf _type;
			#ifdef __ARMA3__
				_box = boundingBoxReal _veh;
			#else
				_box = boundingBox _veh;
			#endif
			if (_sizeOf < _sizeAllowed) then {
				_arr = [_factory_obj, [23,22,20], 1000] call gosa_fnc_findSpawnPos_veh;
				for "_i" from 0 to (count _arr -1) do {
					_obj = _arr select _i;

					_alive = false;
					_arr0 = nearestObjects [_obj, ["LandVehicles","Air"], 5 max _sizeOf];
					for "_i0" from 0 to (count _arr0 -1) do {
						_obj0 = _arr0 select _i0;
						if (alive _obj0) exitWith {
							diag_log format ["Log: [fnc_Client_BuyUnit] %1, alive %2", _obj, _obj0];
							_alive = true;
						};
					};

					if !(_alive) exitWith {
						_b = false;
						_asl = true;
						_arr = getPosASL _obj;
						_num = getDir _obj;
						for "_i0" from 0 to (count _arr0 -1) do {
							diag_log format ["Log: [fnc_Client_BuyUnit] %1, deleteVehicle %2", _obj, _arr0 select _i0];
							deleteVehicle (_arr0 select _i0);
						};
						_arr set [2, (_arr select 2) + (_box select 1 select 2)];
					};
				};

				if (_b) then {
					_arr = [_factory_obj, [23,22,20], 1000, _type, _box, _sizeOf] call gosa_fnc_respawnPosVeh;
					for "_i" from 0 to (count _arr -1) do {
						_obj = _arr select _i select 0;

						_alive = false;
						_arr0 = nearestObjects [_obj, ["LandVehicles","Air"], 5 max _sizeOf];
						for "_i0" from 0 to (count _arr0 -1) do {
							_obj0 = _arr0 select _i0;
							if (alive _obj0) exitWith {
								diag_log format ["Log: [fnc_Client_BuyUnit] %1, alive %2", _obj, _obj0];
								_alive = true;
							};
						};

						if !(_alive) exitWith {
							_b = false;
							_num = _arr select _i select 2;
							_asl = _arr select _i select 3;
							_arr = _arr select _i select 1;
							for "_i0" from 0 to (count _arr0 -1) do {
								diag_log format ["Log: [fnc_Client_BuyUnit] %1, deleteVehicle %2", _obj, _arr0 select _i0];
								deleteVehicle (_arr0 select _i0);
							};
						};
					};
				};
			};
			if (_b) then {
				_arr = ([_pos, 0, 15 max _sizeOf, false, _timeOut] call gosa_fnc_getSafePos);
			};
			if (count _arr > 0) then {
			_veh call _fnc_1;
			if !(_b) then {
				_veh setDir _num;
			};
			if (_asl) then {
				_veh setPosASL _arr;
			}else{
				_arr set [2, _box select 1 select 2];
				_veh setVectorUp surfaceNormal _arr;
			_veh setPos _arr;
			};
			diag_log format ["Log: [fnc_Client_BuyUnit] Created %1", [_veh, _arr, _isUAV, _crew, _sizeOf]];
			[_veh, _name] call gosa_fnc_hint_layout_completed;
			}else{
				[_name] call gosa_fnc_hint_layout_timeOut;
			};
		};
	};

	//-- Самолёты.
	if (_type isKindOf "Plane") then {
		if (isNil "_factory_obj") then {
			_arr = nearestObjects [_player_pos, gosa_type_Airport, _buy_dist_max];
			if (count _arr > 0) then {
				_factory_obj = _arr select 0;
				_pos = getPos _factory_obj;
			}else{
				// Завод вертолётов подходит тоже.
				if (_type isKindOf "MV22") then {
					_arr = nearestObjects [_player_pos, gosa_type_AircraftFactory, _buy_dist_max];
					if (count _arr > 0) then {
						_factory_obj = _arr select 0;
						_pos = getPos _factory_obj;
					};
				};
			};
		};

		if !(isNil "_factory_obj") then {
			_b = true;
			_arr = [_pos select 0, _pos select 1, 2000 + random 500];
			_veh = createVehicle [_type, _arr, [], 2000, "NONE"];
			_sizeOf = sizeOf _type;
			#ifdef __ARMA3__
				_box = boundingBoxReal _veh;
			#else
				_box = boundingBox _veh;
			#endif
			if (_sizeOf < _sizeAllowed) then {
				//- Позиции логики.
				_arr = [_factory_obj, [21,20,22], 1000] call gosa_fnc_findSpawnPos_veh;
				for "_i" from 0 to (count _arr -1) do {
					_obj = _arr select _i;

					_alive = false;
					_arr0 = nearestObjects [_obj, ["LandVehicles","Air"], 5 max _sizeOf];
					for "_i0" from 0 to (count _arr0 -1) do {
						_obj0 = _arr0 select _i0;
						if (alive _obj0) exitWith {
							diag_log format ["Log: [fnc_Client_BuyUnit] %1, alive %2", _obj, _obj0];
							_alive = true;
						};
					};

					if !(_alive) exitWith {
						_b = false;
						_asl = true;
						_arr = getPosASL _obj;
						_num = getDir _obj;
						for "_i0" from 0 to (count _arr0 -1) do {
							diag_log format ["Log: [fnc_Client_BuyUnit] %1, deleteVehicle %2", _obj, _arr0 select _i0];
							deleteVehicle (_arr0 select _i0);
						};
					};
				};

				//- Позиции зданий.
				if (_b) then {
					_arr = [_factory_obj, [21,20,22], 1000, _type, _box, _sizeOf] call gosa_fnc_respawnPosVeh;
					for "_i" from 0 to (count _arr -1) do {
						_obj = _arr select _i select 0;

						_alive = false;
						// FIXME: Позиция не по центру.
						_arr0 = nearestObjects [_obj, ["LandVehicles","Air"], 5 max _sizeOf];
						for "_i0" from 0 to (count _arr0 -1) do {
							_obj0 = _arr0 select _i0;
							if (alive _obj0) exitWith {
								diag_log format ["Log: [fnc_Client_BuyUnit] %1, alive %2", _obj, _obj0];
								_alive = true;
							};
						};

						if !(_alive) exitWith {
							_b = false;
							_num = _arr select _i select 2;
							_asl = _arr select _i select 3;
							_arr = _arr select _i select 1;
							for "_i0" from 0 to (count _arr0 -1) do {
								diag_log format ["Log: [fnc_Client_BuyUnit] %1, deleteVehicle %2", _obj, _arr0 select _i0];
								deleteVehicle (_arr0 select _i0);
							};
						};
					};
				};
			};
			if (_b) then {
				if(_isUAV)then{_num = 35}else{_num = 25};
				_arr = ([_pos, 0, _num max _sizeOf, false, _timeOut] call gosa_fnc_getSafePos);
			};
			if (count _arr > 0) then {
			_veh call _fnc_1;
			if !(_b) then {
				_veh setDir _num;
			};
			if (_asl) then {
				_veh setPosASL _arr;
			}else{
				// FIXME: V-44 X взрывается от падения.
				_arr set [2, (_box select 1 select 2) min 2];
				_veh setVectorUp surfaceNormal _arr;
			_veh setPos _arr;
			};
			diag_log format ["Log: [fnc_Client_BuyUnit] Created %1", [_veh, _arr, _isUAV, _crew, _sizeOf]];
			[_veh, _name] call gosa_fnc_hint_layout_completed;
			}else{
				[_name] call gosa_fnc_hint_layout_timeOut;
			};
		};
	};

	//-- Корабли.
	if ((_type isKindOf "Ship")) then {
		_Objects = (nearestObjects [vehicle player, pier, gosa_distanceCoinBase]);
		if ( count _Objects > 0 ) then {
			Private["_Object","_dir","_pos","_veh","_vel","_speed"];
			_Object = (_Objects select 0);
			_dir = direction _Object;
			_pos = position _Object;
			_pos = _pos findEmptyPosition [0,100,_type];
			_veh = createVehicle[_type, [0,0], [], 5, "FORM"];
			// _pos = ([_pos, (sizeOf typeOf _Object) / 2 + (sizeOf _type) / 2, (180 + _dir)] call BIS_fnc_relPos);
			_dir = [_veh, _Object] call BIS_fnc_dirTo;
			_veh setDir (_dir+180);
			_vel = velocity _veh;
			_dir = direction _veh;
			_veh setPos ([_pos,0, 1 max sizeOf _type, true] call gosa_fnc_getSafePos);
			_speed = -3;
			_veh call _fnc_1;
			[_veh, _name] call gosa_fnc_hint_layout_completed;
		};
	};

	//-- Static.
	if (_type isKindOf "StaticWeapon") then {
		_Objects = (nearestObjects [vehicle player, ["Base_WarfareBBarracks"]+_HQ+Airport+["WarfareBDepot","WarfareBCamp"], gosa_distanceCoinBase]);
		if ( (count _Objects > 0) or (missionNamespace getVariable "gosa_shop" == 2)) then {
			_z = ([player,0, 1 max sizeOf _type, false, _timeOut] call gosa_fnc_getSafePos);
			if (count _z > 0) then {
			_veh = (createVehicle [_type, _z, [], 20, "FORM"]);
			_veh call _fnc_1;
			[_veh, _name] call gosa_fnc_hint_layout_completed;
			}else{
				[_name] call gosa_fnc_hint_layout_timeOut;
			};
		};
	};
	// [_type] call gosa_fnc_setTimeAvailableVehiclesBuyMenu;
}else{
	hint format ["respawn safe distance %1m",safeDistance];
};

// FIXME: Возможно игроку предпочтительно вернутся в меню найма.
gosa_menu = nil;
