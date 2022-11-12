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

// for now, say one event per tick. each event specific a target position for some unit
// now, event should have it's own size. if everything is zero, ignore it.
template MultiTransition(T, N, D, DAMAGE, ATTACK_RADIUS, UNIT_RADIUS, SPEED, bits) {
    signal input healths[N];                // The health of each unit
    signal input positions[N][D];           // The position of each unit
    signal input eventSelected[T];          // The selected unit per tick
    signal input eventPositions[T][D];      // The target position for the selected unit
    signal targetPositions[T][N][D];
    signal output newHealths[N];
    signal output newPositions[N][D];
    
    component transitions[T];
    component isIndex[T][N];
    component mux[T][N];

    for (var i=0; i < T; i++) {
        for (var j=0; j < N; j++) {
            isIndex[i][j] = IsEqual();
            isIndex[i][j].in[0] <== eventSelected[i];
            isIndex[i][j].in[1] <== j;
            
            mux[i][j] = MultiMux1(D);
            mux[i][j].s <== isIndex[i][j].out;
            for (var k=0; k < D; k++) {
                mux[i][j].c[k][0] <== i == 0 ? positions[j][k] : targetPositions[i-1][j][k];
                mux[i][j].c[k][1] <== eventPositions[i][k];
            }

            targetPositions[i][j] <== mux[i][j].out;
        }
    }

    // TODO: if there is an event for this unit, that's it target position; otherwise paint previous
    for (var i=0; i < T; i++) {
        transitions[i] = Transition(D, N, DAMAGE, ATTACK_RADIUS, UNIT_RADIUS, SPEED, bits);
        transitions[i].healths <== i==0 ? healths : transitions[i-1].newHealths;
        transitions[i].positions <== i==0 ? positions : transitions[i-1].newPositions;
        transitions[i].targetPositions <== targetPositions[i];
    }

    newHealths <== transitions[T-1].newHealths;
    newPositions <== transitions[T-1].newPositions;
}