pragma circom 2.1.0;

include "./transition.circom";

template Event(T, N, D) {
    signal input eventTick;
    signal input eventSelected;  
    signal input eventPosition[D];
    signal input targetPositions[T][N][D];
    signal output newTargetPositions[T][N][D];

    component isTick[T];
    component isUnit[T][N];
    component isTickANDisUnit[T][N];
    component mux[T][N];

    // Find the tick and unit that correspond to this event (if any, users can submit invalid data)
    // If found, update the target position for this unit during this tick.
    for (var i=0; i < T; i++) {
        isTick[i] = IsEqual();
        isTick[i].in[0] <== i;
        isTick[i].in[1] <== eventTick;

        for (var j=0; j < N; j++) { 
            isUnit[i][j] = IsEqual();
            isUnit[i][j].in[0] <== j;
            isUnit[i][j].in[1] <== eventSelected;

            isTickANDisUnit[i][j] = AND();
            isTickANDisUnit[i][j].a <== isTick[i].out;
            isTickANDisUnit[i][j].b <== isUnit[i][j].out;

            mux[i][j] = MultiMux1(D);
            mux[i][j].s <== isTickANDisUnit[i][j].out;
            for (var k=0; k < D; k++) {
                mux[i][j].c[k][0] <== targetPositions[i][j][k];
                mux[i][j].c[k][1] <== eventPosition[k];
            }

            newTargetPositions[i][j] <== mux[i][j].out;
        }
    }
}
// Process user events to determine the target position for each unit per tick
template Events(E, T, N, D) {
    signal input positions[N][D];           // The initial position of each unit
    signal input eventTick[E];              // The tick that each event took place in
    signal input eventSelected[E];          // The selected unit, per event
    signal input eventPositions[E][D];      // The target position for the selected unit, per event
    signal targetPositions[T][N][D];
    signal output newTargetPositions[T][N][D];
    
    component events[E];

    // By default, units move towards their starting position (ie. stay still)
    for (var i=0; i < T; i++) {
        targetPositions[i] <== positions;
    }

    for (var i=0; i < E; i++) {
        events[i] = Event(T, N, D);
        events[i].eventTick <== eventTick[i];
        events[i].eventSelected <== eventSelected[i];
        events[i].eventPosition <== eventPositions[i];
        events[i].targetPositions <== targetPositions;
    }

    newTargetPositions <== events[E-1].newTargetPositions;
}

// TODO: bake health and positions into the circuit.
// TODO: structure events recursivley and add hashing
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
    multiTransition.targetPositions <== events.newTargetPositions;

    newHealths <== multiTransition.newHealths;
    newPositions <== multiTransition.newPositions;
}