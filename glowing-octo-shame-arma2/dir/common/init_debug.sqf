/*
 * Изменение игры помогающие отладке.
 */

// При отладке в траве нет необходимости.
setTerrainGrid 50;
// Чтобы успеть увидеть.
setAccTime 0.5;
// Помогает учесть как день так и ночь.
#ifdef __ARMA3__
setTimeMultiplier 25;
useAISteeringComponent true;
#endif

missionNamespace setVariable ["gosa_patrolCoefficient", 5];
missionNamespace setVariable ["minGroups", 15];
missionNamespace setVariable ["gosa_silvieManager", 1];
missionNamespace setVariable ["gosa_shop", 1];
missionNamespace setVariable ["gosa_landing", 1];

