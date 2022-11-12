pragma circom 2.1.0;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/gates.circom";
include "../node_modules/circomlib/circuits/mux1.circom";
include "./squareSum.circom";

// Uses https://math.stackexchange.com/questions/3118238/check-if-3d-point-is-inside-sphere
template NoCollisionIndexIgnore(D, N, RADIUS, bits) {
    signal input index;     // The index we want to ignore
    signal input c[D];      // The centre of the circle
    signal input ps[N][D];  // The points we are checking
    signal outs[N];         // boolean
    signal output out;      // boolean

    component squareSums[N];
    component lessThanRadius2[N];
    component isIndex[N];
    component isNotIndex[N];
    component inRangesANDNotIgnore[N];
    component inRangesANDNotIgnoreOROuts[N];

    for (var i=0; i < N; i++) {
        squareSums[i] = SquareSum(D);
        squareSums[i].a <== c;
        squareSums[i].b <== ps[i];

        lessThanRadius2[i] = LessThan(bits);
        lessThanRadius2[i].in[0] <== squareSums[i].out;
        lessThanRadius2[i].in[1] <== RADIUS * RADIUS;

        isIndex[i] = IsEqual();
        isIndex[i].in[0] <== i;
        isIndex[i].in[1] <== index;

        isNotIndex[i] = NOT();
        isNotIndex[i].in <== isIndex[i].out;

        inRangesANDNotIgnore[i] = AND();
        inRangesANDNotIgnore[i].a <== lessThanRadius2[i].out;
        inRangesANDNotIgnore[i].b <== isNotIndex[i].out;

        inRangesANDNotIgnoreOROuts[i] = OR();
        inRangesANDNotIgnoreOROuts[i].a <== inRangesANDNotIgnore[i].out;
        inRangesANDNotIgnoreOROuts[i].b <== i==0 ? 0 : outs[i-1];

        outs[i] <== inRangesANDNotIgnoreOROuts[i].out;
    }

    out <== (1 - outs[N-1]);
}

template Move(N, D, RADIUS, SPEED, bits) {
    signal input positions[N][D];       // The position of each unit
    signal input vectors[N][D];         // The vector unit the unit is travelling on
    signal accum[N][D];
    signal potentialPositions[N][D];
    signal output newPositions[N][D];

    component isUnit[N];
    component noCollisions[N];
    component mux[N];

    for (var i=0; i < N; i++) {
        for (var j=0; j < D; j++) {
            accum[i][j] <== (j == 0 ? 0 : accum[i][j-1]) + (vectors[i][j]) * (vectors[i][j]);
        }

        isUnit[i] = IsEqual();
        isUnit[i].in[0] <== accum[i][D-1];
        isUnit[i].in[1] <== SPEED * SPEED;

        for (var j=0; j < D; j++) {
            potentialPositions[i][j] <== positions[i][j] + isUnit[i].out * vectors[i][j];
        }

        noCollisions[i] = NoCollisionIndexIgnore(D, N, RADIUS, bits);
        noCollisions[i].index <== i;
        noCollisions[i].c <== potentialPositions[i];
        noCollisions[i].ps <== positions;

        mux[i] = MultiMux1(D);
        mux[i].s <== noCollisions[i].out;
        for (var j=0; j < D; j++) {
            mux[i].c[j][0] <== positions[i][j];
            mux[i].c[j][1] <== potentialPositions[i][j];
        }
        
        newPositions[i] <== mux[i].out;
    }
}