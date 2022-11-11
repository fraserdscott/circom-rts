pragma circom 2.1.0;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/gates.circom";

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

template ISqrt(bits) {
    var N = 2 ** (bits / 2);

    signal input in;
    signal sqrtAccum[N];
    signal output out;

    component greaterThanSquare[N];
    component isSqrt[N];

    for (var i=0; i < N; i++) {
        greaterThanSquare[i] = GreaterThan(bits);
        greaterThanSquare[i].in[0] <== i * i;
        greaterThanSquare[i].in[1] <== in;

        isSqrt[i] = XOR();
        isSqrt[i].a <== i==0 ? 0 : greaterThanSquare[i-1].out;
        isSqrt[i].b <== greaterThanSquare[i].out;

        sqrtAccum[i] <== (i==0 ? 0 : sqrtAccum[i-1]) + (isSqrt[i].out * (i-1));
    } 

    out <== sqrtAccum[N-1];
}