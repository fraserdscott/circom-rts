pragma circom 2.1.0;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/gates.circom";
include "../node_modules/circomlib/circuits/mux1.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

template RangeProof(bits) {
    signal input in; 
    signal input max_abs_value;

    /* check that both max and abs(in) are expressible in `bits` bits  */
    component n2b1 = Num2Bits(bits+1);
    n2b1.in <== in + (1 << bits);
    component n2b2 = Num2Bits(bits);
    n2b2.in <== max_abs_value;

    /* check that in + max is between 0 and 2*max */
    component lowerBound = LessThan(bits+1);
    component upperBound = LessThan(bits+1);

    lowerBound.in[0] <== max_abs_value + in; 
    lowerBound.in[1] <== 0;
    lowerBound.out === 0;

    upperBound.in[0] <== 2 * max_abs_value;
    upperBound.in[1] <== max_abs_value + in; 
    upperBound.out === 0;
}

// input: n field elements, whose abs are claimed to be less than max_abs_value
// output: none
template MultiRangeProof(n, bits) {
    signal input in[n];
    signal input max_abs_value;
    component rangeProofs[n];

    for (var i = 0; i < n; i++) {
        rangeProofs[i] = RangeProof(bits);
        rangeProofs[i].in <== in[i];
        rangeProofs[i].max_abs_value <== max_abs_value;
    }
}

template Divide(divisor_bits, SQRT_P) {
    signal input dividend; // -8
    signal input divisor; // 5
    signal remainder; // 2
    signal output quotient; // -2

    remainder <-- dividend % divisor;

    quotient <-- (dividend - remainder) / divisor; // (-8 - 2) / 5 = -2.

    dividend === divisor * quotient + remainder; // -8 = 5 * -2 + 2.

    component rp = MultiRangeProof(3, 128);
    rp.in[0] <== divisor;
    rp.in[1] <== quotient;
    rp.in[2] <== dividend;
    rp.max_abs_value <== SQRT_P;

    // check that 0 <= remainder < divisor
    component remainderUpper = LessThan(divisor_bits);
    remainderUpper.in[0] <== remainder;
    remainderUpper.in[1] <== divisor;
    remainderUpper.out === 1;
}
