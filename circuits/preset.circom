pragma circom 2.1.0;

include "./game.circom";

// TODO: count up unit healths with factions to determine winner
// TODO: we need to bound the size of the map, because collison searching relies on the fixed bits
// Hardcode damage etc.
template Preset(E, DAMAGE, ATTACK_RADIUS, UNIT_RADIUS, SPEED, bits) {
    var T = 3;
    var N = 4;
    var D = 2;

    signal input eventTick[E];
    signal input eventPlayer[E];
    signal input eventSelected[E];
    signal input eventPositions[E][D];
    signal unitHealths[N];
    signal unitPlayer[N];
    signal unitPositions[N][D];
    signal output winner;

    // Half of the units go to each player
    for (var i=0; i < N; i++) {
        unitHealths[i] <== 100;
        unitPositions[i][0] <== i * 20;
        if (i < (N / 2)) { 
            unitPlayer[i] <== 0;
            unitPositions[i][1] <== 50;
        } else {
            unitPlayer[i] <== 1;
            unitPositions[i][1] <== 200;
        }
    }

    component game = Game(E, T, N, D, DAMAGE, ATTACK_RADIUS, UNIT_RADIUS, SPEED, bits);
    game.eventTick <== eventTick;
    game.eventPlayer <== eventPlayer;
    game.eventSelected <== eventSelected;
    game.eventPositions <== eventPositions;
    game.unitHealths <== unitHealths;
    game.unitPlayer <== unitPlayer;
    game.unitPositions <== unitPositions;
}