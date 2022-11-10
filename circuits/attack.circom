pragma circom 2.1.0;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/gates.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

template SquareSum(D) {
    signal input a[D]; 
    signal input b[D]; 
    signal accum[D];
    signal output out;

    for (var i=0; i < D; i++) {
        accum[i] <== (i == 0 ? 0 : accum[i-1]) + (a[i] - b[i]) * (a[i] - b[i]);
    }

    out <== accum[D-1];
}

// Uses https://math.stackexchange.com/questions/3118238/check-if-3d-point-is-inside-sphere
template MinInRangeIndexIgnore(D, N, numBits) {
    signal input index;     // The index we want to ignore
    signal input c[D];      // The centre of the circle
    signal input ps[N][D];  // The points we are checking
    signal input r;         // The radius of the circle
    signal minAccum[N];
    signal minIndexAccum[N];
    signal output minIndex;

    component squareSums[N];
    component isInside[N];
    component lessThanMax[N];
    component isIndex[N];
    component isNotIndex[N];
    component inRangesANDlessThanMax[N];
    component inRangesANDlessThanMaxANDNotIgnore[N];
    component mux[N];
    component muxIndex[N];

    for (var i=0; i < N; i++) {
        squareSums[i] = SquareSum(D);
        squareSums[i].a <== c;
        squareSums[i].b <== ps[i];

        isInside[i] = LessThan(numBits);
        isInside[i].in[0] <== squareSums[i].out;
        isInside[i].in[1] <== r * r;

        lessThanMax[i] = LessThan(numBits);
        lessThanMax[i].in[0] <== squareSums[i].out;
        lessThanMax[i].in[1] <== i == 0 ? 2**numBits : minAccum[i-1];

        inRangesANDlessThanMax[i] = AND();
        inRangesANDlessThanMax[i].a <== isInside[i].out;
        inRangesANDlessThanMax[i].b <== lessThanMax[i].out;

        isIndex[i] = IsEqual();
        isIndex[i].in[0] <== i;
        isIndex[i].in[1] <== index;

        isNotIndex[i] = NOT();
        isNotIndex[i].in <== isIndex[i].out;

        inRangesANDlessThanMaxANDNotIgnore[i] = AND();
        inRangesANDlessThanMaxANDNotIgnore[i].a <== inRangesANDlessThanMax[i].out;
        inRangesANDlessThanMaxANDNotIgnore[i].b <== isNotIndex[i].out;

        mux[i] = Mux1();
        mux[i].c[0] <== i == 0 ? 2**numBits : minAccum[i-1];
        mux[i].c[1] <== squareSums[i].out;
        mux[i].s <== inRangesANDlessThanMaxANDNotIgnore[i].out;

        muxIndex[i] = Mux1();
        muxIndex[i].c[0] <== i == 0 ? N : minIndexAccum[i-1];
        muxIndex[i].c[1] <== i;
        muxIndex[i].s <== inRangesANDlessThanMaxANDNotIgnore[i].out;

        minAccum[i] <== mux[i].out;
        minIndexAccum[i] <== muxIndex[i].out;
    }

    minIndex <== minIndexAccum[N-1];

}

// TODO: can this circuit be laid out more efficiently because c[D] is not some arbitrary point?
template Attack(D,N,DAMAGE,numBits) {
    signal input index;         // The index we want to ignore
    signal input c[D];          // The centre of the circle
    signal input r;             // The radius of the circle
    signal input healths[N];    // The health of each unit
    signal input ps[N][D];      // The position of each unit
    signal output newHealths[N];
    
    // We loop once to find the closest unit
    // Then loop to find the closest unit and damage it's health.
    component closestUnit = MinInRangeIndexIgnore(D,N,numBits);
    closestUnit.index <== index;
    closestUnit.c <== c;
    closestUnit.r <== r;
    closestUnit.ps <== ps;
    
    component isIndex[N];

    for (var i=0; i < N; i++) {
        isIndex[i] = IsEqual();
        isIndex[i].in[0] <== i;
        isIndex[i].in[1] <== closestUnit.minIndex;

        newHealths[i] <== healths[i] - (isIndex[i].out * DAMAGE);
    }
}

/*  
    Given a set of units (represented by `healths` and `ps`), 
    loop through each unit and damage the nearest unit,
    within range of its position.
    D is the dimensionality of unit position, 
    N is the number of units,
    DAMAGE is the damage each unit does upon attack
    RADIUS is the attack range of each unit
    numBits is the number of bits used to represent healths and positions
*/
template AttackMulti(D,N,DAMAGE,RADIUS,numBits) {
    signal input healths[N];    // The health of each unit
    signal input ps[N][D];      // The position of each unit
    signal output newHealths[N];
    
    component attacks[N];
    component isHealthPositive[N];
    component multiMux[N];

    for (var i=0; i < N; i++) {
        attacks[i] = Attack(D,N,DAMAGE,numBits);
        attacks[i].index <== i;
        attacks[i].c <== ps[i];
        attacks[i].r <== RADIUS;
        attacks[i].healths <== i == 0 ? healths : attacks[i-1].newHealths;
        attacks[i].ps <== ps;

        isHealthPositive[i] = GreaterThan(numBits);
        isHealthPositive[i].in[0] <== healths[i];
        isHealthPositive[i].in[1] <== 0;

        multiMux[i] = MultiMux1(N);
        for (var j=0; j < N; j++) {
            multiMux[i].c[j][0] <== i == 0 ? healths[j] : multiMux[i-1].out[j];
            multiMux[i].c[j][1] <== attacks[i].newHealths[j];
        }
        multiMux[i].s <== isHealthPositive[i].out;
    }

    newHealths <== multiMux[N-1].out;
}

component main = AttackMulti(3, 5, 5, 10, 32);

