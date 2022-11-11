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

    component lessThanIn[N];
    component isSqrt[N];

    // we can precompute the constant bits
    // and partly precompute the bits of `in`
    // that would mean we only need to compute the bits for `n`?
    for (var i=0; i < N; i++) {
        // This operation is really expensive.
        // We want to compare a single field to a bunch of constants.
        // is there some way to optimise that?
        // Also, we know that the input has at most `(bits/2)` bits.
        lessThanIn[i] = LessThan(bits);
        lessThanIn[i].in[0] <== in;
        lessThanIn[i].in[1] <== i * i;

        isSqrt[i] = XOR();
        isSqrt[i].a <== i==0 ? 0 : lessThanIn[i-1].out;
        isSqrt[i].b <== lessThanIn[i].out;

        sqrtAccum[i] <== (i==0 ? 0 : sqrtAccum[i-1]) + (isSqrt[i].out * (i-1));
    }

    out <== sqrtAccum[N-1];
}