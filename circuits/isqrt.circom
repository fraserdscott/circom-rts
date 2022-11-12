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
    signal output out;

    var sqrt;
    
    // Generate an advice square root for witness generation
    for (var i=0; i < N; i++) {
        if ((i+1) * (i+1) > in && sqrt == 0) {
            sqrt = i;
        }
    }
    out <-- sqrt;

    // Check that the input is greater than or equal to advice square root,
    // but less than the next square number.
    component lessThan = LessEqThan(bits);
    lessThan.in[0] <== out * out;
    lessThan.in[1] <== in;
    lessThan.out === 1;

    component lessThanPrev = GreaterThan(bits);
    lessThanPrev.in[0] <== (out+1) * (out+1);
    lessThanPrev.in[1] <== in;
    lessThanPrev.out === 1;
}