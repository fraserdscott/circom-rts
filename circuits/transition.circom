pragma circom 2.1.0;

include "./attack.circom";
include "./move.circom";

template Transition(D, N, DAMAGE, ATTACK_RADIUS, UNIT_RADIUS, SPEED, bits) {
    signal input health_in[N];            // The current health of each unit
    signal input position_in[N][D];       // The current position of each unit
    signal output health_out[N];
    signal output position_out[N][D]; 

    signal input vectors[N][D]; // The target position of each unit

    component attack = Attack(D, N, DAMAGE, ATTACK_RADIUS, bits);
    attack.healths <== health_in;
    attack.positions <== position_in;

    component move = Move(N, D, UNIT_RADIUS, SPEED, bits);
    move.positions <== position_in;
    move.vectors <== vectors;

    health_out <== attack.newHealths;
    position_out <== move.newPositions;
}

template Transitions(T, N, D, DAMAGE, ATTACK_RADIUS, UNIT_RADIUS, SPEED, bits) {
    signal input health_in[N];
    signal input position_in[N][D];
    signal output health_out[N];
    signal output position_out[N][D];

    signal input vectors[T][N][D];
    
    component transitions[T];

    for (var i=0; i < T; i++) {
        transitions[i] = Transition(D, N, DAMAGE, ATTACK_RADIUS, UNIT_RADIUS, SPEED, bits);
        transitions[i].health_in <== i==0 ? health_in : transitions[i-1].health_out;
        transitions[i].position_in <== i==0 ? position_in : transitions[i-1].position_out;
        transitions[i].vectors <== vectors[i];
    }

    health_out <== transitions[T-1].health_out;
    position_out <== transitions[T-1].position_out;
}