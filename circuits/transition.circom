pragma circom 2.1.0;

include "./attack.circom";
include "./move.circom";

template Transition(D, N, DAMAGE, ATTACK_RADIUS, UNIT_RADIUS, SPEED, bits) {
    signal input healths[N];            // The health of each unit
    signal input positions[N][D];       // The current position of each unit
    signal input targetPositions[N][D]; // The target position of each unit
    signal output newHealths[N];
    signal output newPositions[N][D]; 

    component attack = Attack(D, N, DAMAGE, ATTACK_RADIUS, bits);
    attack.healths <== healths;
    attack.positions <== positions;

    component move = Move(D, N, UNIT_RADIUS, SPEED, bits);
    move.positions <== positions;
    move.targetPositions <== targetPositions;

    newHealths <== attack.newHealths;
    newPositions <== move.newPositions;
}

template MultiTransition(T, N, D, DAMAGE, ATTACK_RADIUS, UNIT_RADIUS, SPEED, bits) {
    signal input healths[N];                // The health of each unit
    signal input positions[N][D];           // The position of each unit
    signal input targetPositions[T][N][D];
    signal output newHealths[N];
    signal output newPositions[N][D];
    
    component transitions[T];

    for (var i=0; i < T; i++) {
        transitions[i] = Transition(D, N, DAMAGE, ATTACK_RADIUS, UNIT_RADIUS, SPEED, bits);
        transitions[i].healths <== i==0 ? healths : transitions[i-1].newHealths;
        transitions[i].positions <== i==0 ? positions : transitions[i-1].newPositions;
        transitions[i].targetPositions <== targetPositions[i];
    }

    newHealths <== transitions[T-1].newHealths;
    newPositions <== transitions[T-1].newPositions;
}