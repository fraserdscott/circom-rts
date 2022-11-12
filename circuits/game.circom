pragma circom 2.1.0;

include "../node_modules/circomlib/circuits/mimcsponge.circom";
include "./transition.circom";

template Event(T, N, D) {
    signal input eventTick;
    signal input eventSelected;  
    signal input eventPosition[D];
    signal input targetPositions[T][N][D];
    signal eventFound[T][N];
    signal output newTargetPositions[T][N][D];

    component isTick[T];
    component isUnit[T][N];
    component isTickANDisUnit[T][N];
    component isTickANDisUnitOReventFound[T][N];
    component mux[T][N];

    // Find the tick and unit that correspond to this event (if any, users can submit invalid data)
    // If found, update this units target position for this tick and all subsequent ticks.
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

            isTickANDisUnitOReventFound[i][j] = OR();
            isTickANDisUnitOReventFound[i][j].a <== isTickANDisUnit[i][j].out;
            isTickANDisUnitOReventFound[i][j].b <== i == 0 ? 0 : eventFound[i-1][j];

            eventFound[i][j] <== (i==0 ? 0 : eventFound[i-1][j]) + isTickANDisUnit[i][j].out;
            
            mux[i][j] = MultiMux1(D);
            mux[i][j].s <== isTickANDisUnitOReventFound[i][j].out;
            for (var k=0; k < D; k++) {
                mux[i][j].c[k][0] <== targetPositions[i][j][k];
                mux[i][j].c[k][1] <== eventPosition[k];
            }

            newTargetPositions[i][j] <== mux[i][j].out;
        }
    }
}

template EventHash(D) {
    signal input eventsHash;             
    signal input eventTick;             // The tick that each event took place in
    signal input eventSelected;         // The selected unit, per event
    signal input eventPosition[D];      // The target position for the selected unit, per event
    signal output newEventsHash;

    component hash = MiMCSponge(3+D, 220, 1);
    hash.ins[0] <== eventsHash;
    hash.ins[1] <== eventTick;
    hash.ins[2] <== eventSelected;
    for (var i=0; i < D; i++) { 
        hash.ins[3+i] <== eventPosition[i];
    }
    hash.k <== 0;

    newEventsHash <== hash.outs[0];
}

// Process user events to determine the target position for each unit per tick
template Events(E, T, N, D) {
    signal input eventTick[E];              // The tick that each event took place in
    signal input eventSelected[E];          // The selected unit, per event
    signal input eventPositions[E][D];      // The target position for the selected unit, per event
    signal input targetPositions[T][N][D];  // The initial target position per tick, for each unit unit, 
    signal output newEventsHash;
    signal output newTargetPositions[T][N][D];
    
    component events[E];
    component eventHashes[E];

    for (var i=0; i < E; i++) {
        events[i] = Event(T, N, D);
        events[i].eventTick <== eventTick[i];
        events[i].eventSelected <== eventSelected[i];
        events[i].eventPosition <== eventPositions[i];
        events[i].targetPositions <== i == 0 ? targetPositions : events[i-1].newTargetPositions;

        eventHashes[i] = EventHash(D);
        eventHashes[i].eventTick <== eventTick[i];
        eventHashes[i].eventSelected <== eventSelected[i];
        eventHashes[i].eventPosition <== eventPositions[i];
        eventHashes[i].eventsHash <== i == 0 ? 0 : eventHashes[i-1].newEventsHash;
    }

    newTargetPositions <== events[E-1].newTargetPositions;
    newEventsHash <== eventHashes[E-1].newEventsHash;
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
    events.eventTick <== eventTick;
    events.eventSelected <== eventSelected;
    events.eventPositions <== eventPositions;
    // By default, units move towards their starting position (ie. stay still)
    for (var i=0; i < T; i++) {
        events.targetPositions[i] <== positions;
    }
    
    component transitions = Transitions(T, N, D, DAMAGE, ATTACK_RADIUS, UNIT_RADIUS, SPEED, bits);
    transitions.healths <== healths;
    transitions.positions <== positions;
    transitions.targetPositions <== events.newTargetPositions;

    newHealths <== transitions.newHealths;
    newPositions <== transitions.newPositions;
}