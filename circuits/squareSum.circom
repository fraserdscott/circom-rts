pragma circom 2.1.0;

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