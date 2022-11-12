pragma circom 2.1.0;

include "./transition.circom";

// Process user events to determine the target position for each unit per tick
template Events(E, T, N, D) {
    signal input positions[N][D];           // The initial position of each unit
    signal input eventTick[E];              // The tick that each event took place in
    signal input eventSelected[E];          // The selected unit per event
    signal input eventPositions[E][D];      // The target position for the selected unit
    signal targetPositionsAccum[T][N][E][D];
    signal output targetPositions[T][N][D];
    
    component isTick[T][E];
    component isEvent[T][N][E];
    component isTickANDisEvent[T][N][E];
    component mux[T][N][E];

    for (var i=0; i < T; i++) {
        for (var j=0; j < N; j++) {            
            for (var k=0; k < E; k++) {
                isTick[i][k] = IsEqual();
                isTick[i][k].in[0] <== i;
                isTick[i][k].in[1] <== eventTick[k];

                isEvent[i][j][k] = IsEqual();
                isEvent[i][j][k].in[0] <== k;
                isEvent[i][j][k].in[1] <== eventSelected[k];

                isTickANDisEvent[i][j][k] = AND();
                isTickANDisEvent[i][j][k].a <== isEvent[i][j][k].out;
                isTickANDisEvent[i][j][k].b <== isTick[i][k].out;

                mux[i][j][k] = MultiMux1(D);
                mux[i][j][k].s <== isTickANDisEvent[i][j][k].out;
                for (var l=0; l < D; l++) {
                    mux[i][j][k].c[l][0] <== i == 0 ? positions[j][l] : targetPositions[i-1][j][l];
                    mux[i][j][k].c[l][1] <== eventPositions[k][l];
                }

                // TODO: this is not accumulating!
                targetPositionsAccum[i][j][k] <== mux[i][j][k].out;
            }
            targetPositions[i][j] <== targetPositionsAccum[i][j][E-1];
        }
    }
}

// TODO: bake health and positions into the circuit.
template Game(E, T, N, D, DAMAGE, ATTACK_RADIUS, UNIT_RADIUS, SPEED, bits) {
    signal input healths[N];                // The health of each unit
    signal input positions[N][D];           // The position of each unit
    signal input eventTick[E];              // The tick that each event took place in
    signal input eventSelected[E];          // The selected unit per event
    signal input eventPositions[E][D];      // The target position for the selected unit
    signal output newHealths[N];
    signal output newPositions[N][D];

    component events = Events(E, T, N, D);
    events.positions <== positions;
    events.eventTick <== eventTick;
    events.eventSelected <== eventSelected;
    events.eventPositions <== eventPositions;
    
    component multiTransition = MultiTransition(T, N, D, DAMAGE, ATTACK_RADIUS, UNIT_RADIUS, SPEED, bits);
    multiTransition.healths <== healths;
    multiTransition.positions <== positions;
    multiTransition.targetPositions <== events.targetPositions;

    newHealths <== multiTransition.newHealths;
    newPositions <== multiTransition.newPositions;
}