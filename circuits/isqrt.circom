pragma circom 2.1.0;

include "../node_modules/circomlib/circuits/comparators.circom";

template ISqrt(bits) {
    signal input in;
    signal output out;

    var sqrt;
    
    // Generate an advice square root for witness generation
    for (var i=0; i < 2 ** (bits / 2); i++) {
        if (i * i <= in && (i+1) * (i+1) > in) {
            sqrt = i;
        }
    }
    out <-- sqrt;

    // Check that the input is greater than or equal to the advice square root,
    // but less than the next square number.
    component lessThan = LessEqThan(bits);
    lessThan.in[0] <== out * out;
    lessThan.in[1] <== in;
    lessThan.out === 1;

    component greaterThan = GreaterThan(bits);
    greaterThan.in[0] <== (out+1) * (out+1);
    greaterThan.in[1] <== in;
    greaterThan.out === 1;
}