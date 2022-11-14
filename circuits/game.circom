pragma circom 2.1.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "./transition.circom";

template EventVector(T, N, D) {
    signal input unitVectors_in[T][N][D];
    signal output unitVectors_out[T][N][D];

    signal input eventTick;
    signal input eventPlayer;
    signal input eventUnit;
    signal input eventVectors[D];
    signal input unitPlayer[N];

    signal eventFound[T][N];

    component isTick[T];
    component isFaction[N];
    component isUnit[T][N];
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

        for (var j=0; j < N; j++) { 
            isUnit[i][j] = IsEqual();
            isUnit[i][j].in[0] <== j;
            isUnit[i][j].in[1] <== eventUnit;

            isTickANDisUnitANDisFaction[i][j] = MultiAND(3);
            isTickANDisUnitANDisFaction[i][j].in[0] <== isTick[i].out;
            isTickANDisUnitANDisFaction[i][j].in[1] <== isUnit[i][j].out;
            isTickANDisUnitANDisFaction[i][j].in[2] <== isFaction[j].out;

            isTickANDisUnitANDisFactionOReventFound[i][j] = OR();
            isTickANDisUnitANDisFactionOReventFound[i][j].a <== isTickANDisUnitANDisFaction[i][j].out;
            isTickANDisUnitANDisFactionOReventFound[i][j].b <== i == 0 ? 0 : eventFound[i-1][j];

            eventFound[i][j] <== (i==0 ? 0 : eventFound[i-1][j]) + isTickANDisUnitANDisFaction[i][j].out;
            
            mux[i][j] = MultiMux1(D);
            mux[i][j].s <== isTickANDisUnitANDisFactionOReventFound[i][j].out;
            for (var k=0; k < D; k++) {
                mux[i][j].c[k][0] <== unitVectors_in[i][j][k];
                mux[i][j].c[k][1] <== eventVectors[k];
            }

            unitVectors_out[i][j] <== mux[i][j].out;
        }
    }
}

// Process user events to determine the target position for each unit per tick
template EventVectors(E, T, N, D) {
    signal input eventTick[E]; 
    signal input eventPlayer[E];
    signal input eventUnit[E];
    signal input eventVectors[E][D];
    signal input unitPlayer[N];
    signal input unitVectors[T][N][D];
    signal output newVectors[T][N][D];
    
    component eventVector[E];

    for (var i=0; i < E; i++) {
        eventVector[i] = EventVector(T, N, D);
        eventVector[i].eventTick <== eventTick[i];
        eventVector[i].eventPlayer <== eventPlayer[i];
        eventVector[i].eventUnit <== eventUnit[i];
        eventVector[i].eventVectors <== eventVectors[i];
        eventVector[i].unitPlayer <== unitPlayer;
        eventVector[i].unitVectors_in <== i == 0 ? unitVectors : eventVector[i-1].unitVectors_out;
    }

    newVectors <== eventVector[E-1].unitVectors_out;
}

template EventHash(D) {
    signal input eventHash_in;          // The sequential hash of each previous event 
    signal output eventHash_out;        // The sequential hash of each previous event, and this event
    
    signal input eventTick;             // The tick that each event took place in
    signal input eventPlayer;           // The player that logged the event
    signal input eventUnit;             // The selected unit, per event
    signal input eventVector[D];        // The vector for the selected unit, per event

    component hash = Poseidon(4+D);
    hash.inputs[0] <== eventHash_in;
    hash.inputs[1] <== eventTick;
    hash.inputs[2] <== eventPlayer;
    hash.inputs[3] <== eventUnit;
    for (var i=0; i < D; i++) { 
        hash.inputs[4+i] <== eventVector[i];
    }

    eventHash_out <== hash.out;
}

template EventHashes(E, D) {
    signal input eventHash_in;
    signal output eventHash_out;

    signal input eventTick[E];
    signal input eventPlayer[E];
    signal input eventUnit[E];
    signal input eventVectors[E][D];
    
    component eventHashes[E];

    for (var i=0; i < E; i++) {
        eventHashes[i] = EventHash(D);
        eventHashes[i].eventTick <== eventTick[i];
        eventHashes[i].eventPlayer <== eventPlayer[i];
        eventHashes[i].eventUnit <== eventUnit[i];
        eventHashes[i].eventVector <== eventVectors[i];
        eventHashes[i].eventHash_in <== i == 0 ? eventHash_in : eventHashes[i-1].eventHash_out;
    }

    eventHash_out <== eventHashes[E-1].eventHash_out;
}

template Game(E, T, N, D, DAMAGE, ATTACK_RADIUS, UNIT_RADIUS, SPEED, bits) {
    signal input unitHealths[N];            // The initial health of each unit
    signal input unitPlayer[N];             // The player each unit belongs to
    signal input unitPositions[N][D];       // The initial position of each unit
    signal input eventTick[E];              // The tick that each event took place in
    signal input eventPlayer[E];            // The player that logged the event
    signal input eventSelected[E];          // The selected unit per event
    signal input eventVectors[E][D];        // The new vector for the selected unit
    
    signal output eventHash_out;
    signal output newHealths[N];
    signal output newPositions[N][D];

    component eventHashes = EventHashes(E, D);
    eventHashes.eventHash_in <== 0;
    eventHashes.eventTick <== eventTick;
    eventHashes.eventPlayer <== eventPlayer;
    eventHashes.eventUnit <== eventSelected;
    eventHashes.eventVectors <== eventVectors;

    component events = EventVectors(E, T, N, D);
    events.eventTick <== eventTick;
    events.eventPlayer <== eventPlayer;
    events.eventUnit <== eventSelected;
    events.eventVectors <== eventVectors;
    events.unitPlayer <== unitPlayer;
    // By default, units move towards nothing (ie. stay still)
    for (var i=0; i < T; i++) {
        for (var j=0; j < N; j++) {
            for (var k=0; k < D; k++) {
                events.unitVectors[i][j][k] <== 0;
            }
        }
    }
    
    component transitions = Transitions(T, N, D, DAMAGE, ATTACK_RADIUS, UNIT_RADIUS, SPEED, bits);
    transitions.health_in <== unitHealths;
    transitions.position_in <== unitPositions;
    transitions.vectors <== events.newVectors;

    eventHash_out <== eventHashes.eventHash_out;
    newHealths <== transitions.health_out;
    newPositions <== transitions.position_in;
}