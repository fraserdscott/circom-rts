pragma circom 2.1.0;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/gates.circom";
include "../node_modules/circomlib/circuits/mux1.circom";
include "./divide.circom";
include "./isqrt.circom";
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

template Move(D, N, RADIUS, SPEED, bits) {
    signal input positions[N][D];       // The position of each unit
    signal input targetPositions[N][D]; // The target position of each unit
    signal real[N][D];
    signal check[N][D];
    signal opp[N][D];
    signal potentialPositions[N][D];
    signal output newPositions[N][D];

    component noCollisions[N];
    component squareSum[N];
    component length[N];
    component mux[N];
    component lessThan[N][D];
    component divide[N][D];

    for (var i=0; i < N; i++) {
        squareSum[i] = SquareSum(D);
        squareSum[i].a <== positions[i];
        squareSum[i].b <== targetPositions[i];
        
        length[i] = ISqrt(bits);
        length[i].in <== squareSum[i].out;

        for (var j=0; j < D; j++) {
            lessThan[i][j] = LessThan(bits);
            lessThan[i][j].in[0] <== targetPositions[i][j];
            lessThan[i][j].in[1] <== positions[i][j];

            divide[i][j] = Divide(bits, 100000000000000000000);

            real[i][j] <== (1 - lessThan[i][j].out) * (targetPositions[i][j] - positions[i][j]);
            divide[i][j].dividend <== (real[i][j] + lessThan[i][j].out * (positions[i][j] - targetPositions[i][j])) * SPEED;
            divide[i][j].divisor <== length[i].out + 1;

            check[i][j] <== lessThan[i][j].out * divide[i][j].quotient;
            opp[i][j] <== (1 - lessThan[i][j].out) * divide[i][j].quotient;
            potentialPositions[i][j] <== positions[i][j] + opp[i][j] - check[i][j];
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