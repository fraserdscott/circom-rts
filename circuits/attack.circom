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
template Attack(D,N,DAMAGE,RADIUS,numBits) {
    signal input healths[N];    // The health of each unit
    signal input ps[N][D];      // The position of each unit
    signal newHealthsAccum[N][N];
    signal output newHealths[N];
    
    component attacks[N];
    component isHealthPositive[N];
    component multiMux[N];
    component closestUnit[N];
    component isIndexes[N][N];
    component shouldDecreaseHealth[N][N];
    
    for (var i=0; i < N; i++) {
        isHealthPositive[i] = GreaterThan(numBits);
        isHealthPositive[i].in[0] <== healths[i];
        isHealthPositive[i].in[1] <== 0;

        closestUnit[i] = MinInRangeIndexIgnore(D,N,numBits);
        closestUnit[i].index <== i;
        closestUnit[i].c <== ps[i];
        closestUnit[i].r <== RADIUS;
        closestUnit[i].ps <== ps;

        for (var j=0; j < N; j++) {
            isIndexes[i][j] = IsEqual();
            isIndexes[i][j].in[0] <== j;
            isIndexes[i][j].in[1] <== closestUnit[i].minIndex;

            shouldDecreaseHealth[i][j] = AND();
            shouldDecreaseHealth[i][j].a <== isHealthPositive[i].out;
            shouldDecreaseHealth[i][j].b <== isIndexes[i][j].out;

            newHealthsAccum[i][j] <== (i==0 ? healths[j] : newHealthsAccum[i-1][j]) - shouldDecreaseHealth[i][j].out * DAMAGE;
        }
    }

    newHealths <== newHealthsAccum[N-1];
}

component main = Attack(3, 5, 5, 10, 32);




