/*
 * Authors: Ruthberg
 * Updates the range card data
 *
 * Arguments:
 * 0: zero range <NUMBER>
 * 1: bore height <NUMBER>
 * 2: ammo class <STRING>
 * 3: magazine class <STRING>
 * 4: weapon class <STRING>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [mode] call ace_rangecard_fnc_openRangeCard
 *
 * Public: No
 */
#include "script_component.hpp"

disableSerialization;
#define __dsp (uiNamespace getVariable "RangleCard_Display")

private ["_airFriction", "_ammoConfig", "_atmosphereModel", "_transonicStabilityCoef", "_barrelLength", "_barrelTwist", "_bc", "_cacheEntry", "_column", "_control", "_dragModel", "_i", "_muzzleVelocity", "_offset", "_row", "_weaponConfig", "_initSpeed", "_initSpeedCoef"];

params ["_zeroRange", "_boreHeight", "_ammoClass", "_magazineClass", "_weaponClass"];

if (_ammoClass == "" || _magazineClass == "" || _weaponClass == "") exitWith {};

{
    ctrlDelete _x;
} forEach GVAR(controls);
GVAR(controls) = [];

for "_row" from 0 to 49 do {
    _offset = if (_row < 5) then {0} else {0.003};
    _control = (__dsp ctrlCreate ["RangeCard_RscText", 790000 + _row]);
    _control ctrlSetPosition [safeZoneX + 0.183, safeZoneY + 0.374 + 0.027 * _row + _offset, 0.062, 0.025];
    if (_row in [0, 8, 18, 28, 38, 48]) then {
        _control ctrlSetTextColor [1, 1, 1, 1];
    } else {
        _control ctrlSetTextColor [0, 0, 0, 1];
    };
    _control ctrlCommit 0;
    _control ctrlSetText Str(100 + _row * 50);
    GVAR(controls) pushBack _control;
};
for "_column" from 0 to 8 do {
    for "_row" from 0 to 49 do {
        _offset = if (_row < 5) then {0} else {0.003};
        _control = (__dsp ctrlCreate ["RangeCard_RscText", 90000 + _column * 100 + _row]);
        _control ctrlSetPosition [safeZoneX + 0.249 + _column * 0.055, safeZoneY + 0.374 + 0.027 * _row + _offset, 0.052, 0.025];
        _control ctrlCommit 0;
        _control ctrlSetText "-0.0";
        GVAR(controls) pushBack _control;
    };
};
for "_column" from 0 to 2 do {
    for "_row" from 0 to 49 do {
        _offset = if (_row < 5) then {0} else {0.003};
        _control = (__dsp ctrlCreate ["RangeCard_RscText", 90000 + (9 +_column) * 100 + _row]);
        _control ctrlSetPosition [safeZoneX + 0.743 + _column * 0.049, safeZoneY + 0.374 + 0.027 * _row + _offset, 0.047, 0.025];
        _control ctrlCommit 0;
        _control ctrlSetText "-0.0";
        GVAR(controls) pushBack _control;
    };
};
for "_column" from 0 to 2 do {
    for "_row" from 0 to 49 do {
        _offset = if (_row < 5) then {0} else {0.003};
        _control = (__dsp ctrlCreate ["RangeCard_RscText", 90000 + (12 +_column) * 100 + _row]);
        _control ctrlSetPosition [safeZoneX + 0.892 + _column * 0.049, safeZoneY + 0.374 + 0.027 * _row + _offset, 0.047, 0.025];
        _control ctrlCommit 0;
        _control ctrlSetText "-0.0";
        GVAR(controls) pushBack _control;
    };
};

lnbClear 770100;
lnbClear 770200;
lnbClear 770300;
lnbClear 770400;

GVAR(rangeCardDataElevation) = [[], [], [], [], [], [], [], [], []];
GVAR(rangeCardDataWindage) = [[], [], [], [], [], [], [], [], []];
GVAR(rangeCardDataLead) = [[], [], [], [], [], [], [], [], []];
GVAR(rangeCardDataMVs) = ["", "", "", "", "", "", "", "", ""];
GVAR(lastValidRow) = [];

GVAR(currentUnit) = 2;
GVAR(rangeCardStartRange) = 100;
GVAR(rangeCardIncrement) = 50;
GVAR(rangeCardEndRange) = GVAR(rangeCardStartRange) + 49 * GVAR(rangeCardIncrement);

_ammoConfig = _ammoClass call EFUNC(advanced_ballistics,readAmmoDataFromConfig);
_weaponConfig = _weaponClass call EFUNC(advanced_ballistics,readWeaponDataFromConfig);
_airFriction = _ammoConfig select 0;
_barrelTwist = _weaponConfig select 0;
_barrelLength = _weaponConfig select 2;
_muzzleVelocity = 0;

_bc = 0;
if (count (_ammoConfig select 6) > 0) then {
    _bc = (_ammoConfig select 6) select 0;
};
_transonicStabilityCoef = _ammoConfig select 4;
_dragModel = _ammoConfig select 5;
_atmosphereModel = _ammoConfig select 8;

private _useABConfig = (missionNamespace getVariable [QEGVAR(advanced_ballistics,enabled), false]);
if (_bc == 0) then {
    _useABConfig = false;
};

if (_barrelLength > 0 && _useABConfig) then {
    _muzzleVelocity = [_barrelLength, _ammoConfig select 10, _ammoConfig select 11, 0] call EFUNC(advanced_ballistics,calculateBarrelLengthVelocityShift);
} else {
    _initSpeed     = getNumber (configFile >> "CfgMagazines" >> _magazineClass >> "initSpeed");
    _initSpeedCoef = getNumber (configFile >> "CfgWeapons" >> _weaponClass >> "initSpeed");
    if (_initSpeedCoef < 0) then {
        _initSpeed = _initSpeed * -_initSpeedCoef;
    };
    if (_initSpeedCoef > 0) then {
        _initSpeed = _initSpeedCoef;
    };
    _muzzleVelocity = _initSpeed;
};

if (_useABConfig) then {
    ctrlSetText [770000, format["%1'' - %2 gr (%3)", round((_ammoConfig select 1) * 39.3700787) / 1000, round((_ammoConfig select 3) * 15.4323584), _ammoClass]];
    if (_barrelLength > 0 && _barrelTwist > 0) then {
        ctrlSetText [770002, format["Barrel: %1'' 1:%2'' twist", round(2 * _barrelLength * 0.0393700787) / 2, round(_barrelTwist * 0.0393700787)]];
    } else {
        ctrlSetText [770002, ""];
    };
} else {
    ctrlSetText [770000, getText (configFile >> "CfgMagazines" >> _magazineClass >> "displayNameShort")];
    ctrlSetText [770002, getText (configFile >> "CfgWeapons" >> _weaponClass >> "displayName")];
};

lnbAddRow [770100, ["4mps Wind(MRADs)", "1mps LEAD(MRADs)"]];
if (missionNamespace getVariable [QEGVAR(advanced_ballistics,enabled), false]) then {
    lnbAddRow [770100, ["Air/Ammo Temp", "Air/Ammo Temp"]];

    lnbAddRow [770200, ["-15°C", " -5°C", "  5°C", " 10°C", " 15°C", " 20°C", " 25°C", " 30°C", " 35°C"]];
    lnbAddRow [770300, ["-15°C", " 10°C", " 35°C", "-15°C", " 10°C", " 35°C"]];
};

ctrlSetText [77003, format["%1m ZERO", round(_zeroRange)]];

if (missionNamespace getVariable [QEGVAR(advanced_ballistics,enabled), false]) then {
    ctrlSetText [770001, format["Drop Tables for B.P.: %1mb; Corrected for MVV at Air/Ammo Temperatures -15-35 °C", round(EGVAR(scopes,zeroReferenceBarometricPressure) * 100) / 100]];
    ctrlSetText [77004 , format["B.P.: %1mb", round(EGVAR(scopes,zeroReferenceBarometricPressure) * 100) / 100]];
} else {
    ctrlSetText [770001, ""];
    ctrlSetText [77004 , ""];
};

_cacheEntry = missionNamespace getVariable format[QGVAR(%1_%2_%3_%4_%5), _zeroRange, _boreHeight, _ammoClass, _weaponClass, missionNamespace getVariable [QEGVAR(advanced_ballistics,enabled), false]];
if (isNil {_cacheEntry}) then {
    private _scopeBaseAngle = if (!_useABConfig) then {
        private _zeroAngle = "ace_advanced_ballistics" callExtension format ["zeroAngleVanilla:%1:%2:%3:%4", _zeroRange, _muzzleVelocity, _airFriction, _boreHeight];
        (parseNumber _zeroAngle)
    } else {
        private _zeroAngle = "ace_advanced_ballistics" callExtension format ["zeroAngle:%1:%2:%3:%4:%5:%6:%7:%8:%9", _zeroRange, _muzzleVelocity, _boreHeight, EGVAR(scopes,zeroReferenceTemperature), EGVAR(scopes,zeroReferenceBarometricPressure), EGVAR(scopes,zeroReferenceHumidity), _bc, _dragModel, _atmosphereModel];
        (parseNumber _zeroAngle)
    };
    if (missionNamespace getVariable [QEGVAR(advanced_ballistics,enabled), false] && missionNamespace getVariable [QEGVAR(advanced_ballistics,ammoTemperatureEnabled), false]) then {
        {
            private _mvShift = [_ammoConfig select 9, _x] call EFUNC(advanced_ballistics,calculateAmmoTemperatureVelocityShift);
            private _mv = _muzzleVelocity + _mvShift;

            [_scopeBaseAngle,_boreHeight,_airFriction,_mv,_x,EGVAR(scopes,zeroReferenceBarometricPressure),EGVAR(scopes,zeroReferenceHumidity),100,4,1,GVAR(rangeCardEndRange),_bc,_dragModel,_atmosphereModel,_transonicStabilityCoef,_forEachIndex,_useABConfig] call FUNC(calculateRangeCard);
        } forEach [-15, -5, 5, 10, 15, 20, 25, 30, 35];
    } else {
        [_scopeBaseAngle,_boreHeight,_airFriction,_muzzleVelocity,15,EGVAR(scopes,zeroReferenceBarometricPressure),EGVAR(scopes,zeroReferenceHumidity),100,4,1,GVAR(rangeCardEndRange),_bc,_dragModel,_atmosphereModel,_transonicStabilityCoef,3,_useABConfig] call FUNC(calculateRangeCard);
    };

    for "_i" from 0 to 9 do {
        GVAR(lastValidRow) pushBack count (GVAR(rangeCardDataElevation) select _i);
        while {count (GVAR(rangeCardDataElevation) select _i) < 50} do {
            if (missionNamespace getVariable [QEGVAR(advanced_ballistics,enabled), false]) then {
                (GVAR(rangeCardDataElevation) select _i) pushBack "###";
                (GVAR(rangeCardDataWindage) select _i) pushBack "##";
                (GVAR(rangeCardDataLead) select _i) pushBack "##";
            } else {
                (GVAR(rangeCardDataElevation) select _i) pushBack "";
                (GVAR(rangeCardDataWindage) select _i) pushBack "";
                (GVAR(rangeCardDataLead) select _i) pushBack "";
            };
        };
    };

    missionNamespace setVariable [format[QGVAR(%1_%2_%3_%4_%5), _zeroRange, _boreHeight, _ammoClass, _weaponClass, missionNamespace getVariable [QEGVAR(advanced_ballistics,enabled), false]], [GVAR(rangeCardDataElevation), GVAR(rangeCardDataWindage), GVAR(rangeCardDataLead), GVAR(rangeCardDataMVs), GVAR(lastValidRow)]];
} else {
    GVAR(rangeCardDataElevation) = _cacheEntry select 0;
    GVAR(rangeCardDataWindage)   = _cacheEntry select 1;
    GVAR(rangeCardDataLead)      = _cacheEntry select 2;
    GVAR(rangeCardDataMVs)       = _cacheEntry select 3;
    GVAR(lastValidRow)           = _cacheEntry select 4;
};

lnbAddRow [770200, GVAR(rangeCardDataMVs)];

for "_column" from 0 to 8 do {
    for "_row" from 0 to 49 do {
        _control = (__dsp displayCtrl (90000 + _column * 100 + _row));
        _control ctrlSetText ((GVAR(rangeCardDataElevation) select _column) select _row);
        if (_row >= (GVAR(lastValidRow) select _column)) then {
            _control ctrlSetTextColor [0, 0, 0, 0.6];
        } else {
            _control ctrlSetTextColor [0, 0, 0, 1.0];
        };
        _control ctrlCommit 0;
    };
};
{
    for "_row" from 0 to 49 do {
        _control = (__dsp displayCtrl (90000 + (9 + _forEachIndex) * 100 + _row));
        _control ctrlSetText ((GVAR(rangeCardDataWindage) select _x) select _row);
        if (_row >= (GVAR(lastValidRow) select _x)) then {
            _control ctrlSetTextColor [0, 0, 0, 0.6];
        } else {
            _control ctrlSetTextColor [0, 0, 0, 1.0];
        };
        _control ctrlCommit 0;
    };
} forEach [0, 3, 8];

{
    for "_row" from 0 to 49 do {
        _control = (__dsp displayCtrl (90000 + (12 + _forEachIndex) * 100 + _row));
        _control ctrlSetText ((GVAR(rangeCardDataLead) select _x) select _row);
        if (_row >= (GVAR(lastValidRow) select _x)) then {
            _control ctrlSetTextColor [0, 0, 0, 0.6];
        } else {
            _control ctrlSetTextColor [0, 0, 0, 1.0];
        };
        _control ctrlCommit 0;
    };
} forEach [0, 3, 8];

if (_useABConfig) then {
    ctrlSetText [770020, "For best results keep ammunition at ambient air temperature. Tables calculated for the above listed barrel"];
    ctrlSetText [770021, format["and load with optic mounted %1'' above line of bore.", round((_boreHeight / 2.54) * 10) / 10]];
} else {
    ctrlSetText [770020, ""];
    ctrlSetText [770021, ""];
};
