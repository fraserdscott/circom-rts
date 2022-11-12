pragma circom 2.1.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "./transition.circom";

template EventPositions(T, N, D) {
    signal input eventTick;
    signal input eventPlayer;
    signal input eventSelected;
    signal input eventPosition[D];
    signal input unitPlayer[N];
    signal input unitTargetPositions[T][N][D];
    signal eventFound[T][N];
    signal output newTargetPositions[T][N][D];

    component isTick[T];
    component isUnit[T][N];
    component isFaction[N];
    component isTickANDisUnit[T][N];
    component isTickANDisUnitANDisFaction[T][N];
    component isTickANDisUnitANDisFactionOReventFound[T][N];
    component mux[T][N];

    for (var i=0; i < N; i++) { 
        isFaction[i] = IsEqual();
        isFaction[i].in[0] <== eventPlayer;
        isFaction[i].in[1] <== unitPlayer[i];
    }

    // Find the tick and unit that correspond to this event (if any, users can submit invalid data)
    // If found, update this units target position for this tick and all subsequent ticks.
    for (var i=0; i < T; i++) {
        isTick[i] = IsEqual();
        isTick[i].in[0] <== i;
        isTick[i].in[1] <== eventTick;

        // TODO: add an additional check that the unit is in this faction
        for (var j=0; j < N; j++) { 
            isUnit[i][j] = IsEqual();
            isUnit[i][j].in[0] <== j;
            isUnit[i][j].in[1] <== eventSelected;

            isTickANDisUnit[i][j] = AND();
            isTickANDisUnit[i][j].a <== isTick[i].out;
            isTickANDisUnit[i][j].b <== isUnit[i][j].out;

            isTickANDisUnitANDisFaction[i][j] = AND();
            isTickANDisUnitANDisFaction[i][j].a <== isTickANDisUnit[i][j].out;
            isTickANDisUnitANDisFaction[i][j].b <== isFaction[j].out;

            isTickANDisUnitANDisFactionOReventFound[i][j] = OR();
            isTickANDisUnitANDisFactionOReventFound[i][j].a <== isTickANDisUnitANDisFaction[i][j].out;
            isTickANDisUnitANDisFactionOReventFound[i][j].b <== i == 0 ? 0 : eventFound[i-1][j];

            eventFound[i][j] <== (i==0 ? 0 : eventFound[i-1][j]) + isTickANDisUnit[i][j].out;
            
            mux[i][j] = MultiMux1(D);
            mux[i][j].s <== isTickANDisUnitANDisFactionOReventFound[i][j].out;
            for (var k=0; k < D; k++) {
                mux[i][j].c[k][0] <== unitTargetPositions[i][j][k];
                mux[i][j].c[k][1] <== eventPosition[k];
            }

            newTargetPositions[i][j] <== mux[i][j].out;
        }
    }
}

// Process user eventTargetPositions to determine the target position for each unit per tick
template EventTargetPositions(E, T, N, D) {
    signal input eventTick[E];              // The tick that each event took place in
    signal input eventPlayer[E];
    signal input eventSelected[E];          // The selected unit, per event
    signal input eventPositions[E][D];      // The target position for the selected unit, per event
    signal input unitPlayer[N];
    signal input unitTargetPositions[T][N][D];  // The initial target position per tick, for each unit unit
    signal output newTargetPositions[T][N][D];
    
    component eventTargetPositions[E];

    for (var i=0; i < E; i++) {
        eventTargetPositions[i] = EventPositions(T, N, D);
        eventTargetPositions[i].eventTick <== eventTick[i];
        eventTargetPositions[i].eventPlayer <== eventPlayer[i];
        eventTargetPositions[i].eventSelected <== eventSelected[i];
        eventTargetPositions[i].eventPosition <== eventPositions[i];
        eventTargetPositions[i].unitPlayer <== unitPlayer;
        eventTargetPositions[i].unitTargetPositions <== i == 0 ? unitTargetPositions : eventTargetPositions[i-1].newTargetPositions;
    }

    newTargetPositions <== eventTargetPositions[E-1].newTargetPositions;
}

template EventHash(D) {
    signal input eventsHash;            // The sequential hash of each previous event 
    signal input eventTick;             // The tick that each event took place in
    signal input eventSelected;         // The selected unit, per event
    signal input eventPosition[D];      // The target position for the selected unit, per event
    signal output newEventsHash;

    component hash = Poseidon(3+D);
    hash.inputs[0] <== eventsHash;
    hash.inputs[1] <== eventTick;
    hash.inputs[2] <== eventSelected;
    for (var i=0; i < D; i++) { 
        hash.inputs[3+i] <== eventPosition[i];
    }

    newEventsHash <== hash.out;
}

template EventHashes(E, D) {
    signal input eventsHash;                // The sequential hash of each previous event 
    signal input eventTick[E];              // The tick that each event took place in
    signal input eventSelected[E];          // The selected unit, per event
    signal input eventPositions[E][D];      // The target position for the selected unit, per event
    signal output newEventsHash;
    
    component eventHashes[E];

    for (var i=0; i < E; i++) {
        eventHashes[i] = EventHash(D);
        eventHashes[i].eventTick <== eventTick[i];
        eventHashes[i].eventSelected <== eventSelected[i];
        eventHashes[i].eventPosition <== eventPositions[i];
        eventHashes[i].eventsHash <== i == 0 ? eventsHash : eventHashes[i-1].newEventsHash;
    }

    newEventsHash <== eventHashes[E-1].newEventsHash;
}

// TODO: bake health and positions into the circuit.
// TODO: add unit and event factions
template Game(E, T, N, D, DAMAGE, ATTACK_RADIUS, UNIT_RADIUS, SPEED, bits) {
    signal input unitHealths[N];            // The initial health of each unit
    signal input unitPlayer[N];             // The player each unit belongs to
    signal input unitPositions[N][D];       // The initial position of each unit
    signal input eventTick[E];              // The tick that each event took place in
    signal input eventPlayer[E];            // The player that logged the event
    signal input eventSelected[E];          // The selected unit per event
    signal input eventPositions[E][D];      // The target position for the selected unit
    
    signal output newHealths[N];
    signal output newPositions[N][D];

    component eventHashes = EventHashes(E, D);
    eventHashes.eventsHash <== 0;
    eventHashes.eventTick <== eventTick;
    eventHashes.eventSelected <== eventSelected;
    eventHashes.eventPositions <== eventPositions;

    component eventTargetPositions = EventTargetPositions(E, T, N, D);
    eventTargetPositions.eventTick <== eventTick;
    eventTargetPositions.eventPlayer <== eventPlayer;
    eventTargetPositions.eventSelected <== eventSelected;
    eventTargetPositions.eventPositions <== eventPositions;
    eventTargetPositions.unitPlayer <== unitPlayer;
    // By default, units move towards their starting position (ie. stay still)
    for (var i=0; i < T; i++) {
        eventTargetPositions.unitTargetPositions[i] <== unitPositions;
    }
    
    component transitions = Transitions(T, N, D, DAMAGE, ATTACK_RADIUS, UNIT_RADIUS, SPEED, bits);
    transitions.healths <== unitHealths;
    transitions.positions <== unitPositions;
    transitions.targetPositions <== eventTargetPositions.newTargetPositions;

    newHealths <== transitions.newHealths;
    newPositions <== transitions.newPositions;
}