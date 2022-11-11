pragma circom 2.1.0;

include "./attack.circom";
include "./move.circom";

template Transition(D, N, DAMAGE, ATTACK_RADIUS, UNIT_RADIUS, SPEED, bits) {
    signal input healths[N];            // The health of each unit
    signal input positions[N][D];       // The position of each unit
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

component main = Transition(3, 4, 5, 10, 4, 5, 16);