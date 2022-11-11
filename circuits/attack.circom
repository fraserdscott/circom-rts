pragma circom 2.1.0;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/gates.circom";
include "../node_modules/circomlib/circuits/mux1.circom";
include "./isqrt.circom";

// Uses https://math.stackexchange.com/questions/3118238/check-if-3d-point-is-inside-sphere
template MinInRangeIndexIgnore(D, N, RADIUS, bits) {
    signal input index;     // The index we want to ignore
    signal input c[D];      // The centre of the circle
    signal input ps[N][D];  // The points we are checking
    signal output minIndex;

    component squareSums[N];
    component lessThanRadius2[N];
    component lessThanMax[N];
    component isIndex[N];
    component isNotIndex[N];
    component lessThanRadius2ANDLessThanMax[N];
    component inRangesANDlessThanMaxANDNotIgnore[N];
    component mux[N];
    component muxIndex[N];

    for (var i=0; i < N; i++) {
        var prev = i == 0 ? 2**bits : mux[i-1].out;

        squareSums[i] = SquareSum(D);
        squareSums[i].a <== c;
        squareSums[i].b <== ps[i];

        lessThanRadius2[i] = LessThan(bits);
        lessThanRadius2[i].in[0] <== squareSums[i].out;
        lessThanRadius2[i].in[1] <== RADIUS * RADIUS;

        lessThanMax[i] = LessThan(bits);
        lessThanMax[i].in[0] <== squareSums[i].out;
        lessThanMax[i].in[1] <== prev;

        lessThanRadius2ANDLessThanMax[i] = AND();
        lessThanRadius2ANDLessThanMax[i].a <== lessThanRadius2[i].out;
        lessThanRadius2ANDLessThanMax[i].b <== lessThanMax[i].out;

        isIndex[i] = IsEqual();
        isIndex[i].in[0] <== i;
        isIndex[i].in[1] <== index;

        isNotIndex[i] = NOT();
        isNotIndex[i].in <== isIndex[i].out;

        inRangesANDlessThanMaxANDNotIgnore[i] = AND();
        inRangesANDlessThanMaxANDNotIgnore[i].a <== lessThanRadius2ANDLessThanMax[i].out;
        inRangesANDlessThanMaxANDNotIgnore[i].b <== isNotIndex[i].out;

        mux[i] = Mux1();
        mux[i].c[0] <== prev;
        mux[i].c[1] <== squareSums[i].out;
        mux[i].s <== inRangesANDlessThanMaxANDNotIgnore[i].out;

        muxIndex[i] = Mux1();
        muxIndex[i].c[0] <== i == 0 ? N : muxIndex[i-1].out;
        muxIndex[i].c[1] <== i;
        muxIndex[i].s <== inRangesANDlessThanMaxANDNotIgnore[i].out;
    }

    minIndex <== muxIndex[N-1].out;
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
    bits is the number of bits used to represent healths and positions
*/
template Attack(D, N, DAMAGE, RADIUS, bits) {
    signal input healths[N];            // The health of each unit
    signal input positions[N][D];       // The position of each unit
    signal newHealthsAccum[N][N];
    signal output newHealths[N];
    
    component isHealthPositive[N];
    component closestUnit[N];
    component isIndexes[N][N];
    component shouldDecreaseHealth[N][N];
    
    for (var i=0; i < N; i++) {
        isHealthPositive[i] = GreaterThan(bits);
        isHealthPositive[i].in[0] <== healths[i];
        isHealthPositive[i].in[1] <== 0;

        closestUnit[i] = MinInRangeIndexIgnore(D, N, RADIUS, bits);
        closestUnit[i].index <== i;
        closestUnit[i].c <== positions[i];
        closestUnit[i].ps <== positions;

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