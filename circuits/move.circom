pragma circom 2.1.0;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/gates.circom";
include "../node_modules/circomlib/circuits/mux1.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "./divide.circom";
include "./isqrt.circom";

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

template Move(D, N, bits) {
    var SPEED = 5;

    signal input positions[N][D];       // The position of each unit
    signal input targetPositions[N][D]; // The target position of each unit
    signal real[N][D];
    signal check[N][D];
    signal output newPositions[N][D];

    component squareSum[N];
    component length[N];
    component lessThan[N][D];
    component divide[N][D];

    // TODO: add collision check
    // probably like the MinInRange primitive, which spits out if there in any collision
    // multiply the updated positions by that
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

            check[i][j] <== (lessThan[i][j].out * divide[i][j].quotient);
            newPositions[i][j] <== positions[i][j] - check[i][j] + ((1 - lessThan[i][j].out) * divide[i][j].quotient);
        }
    }
}

component main = Move(3, 3, 16);