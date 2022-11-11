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

            // subtract quotient if lessThan is true
            check[i][j] <== (lessThan[i][j].out * divide[i][j].quotient);
            newPositions[i][j] <== positions[i][j] - check[i][j] + ((1 - lessThan[i][j].out) * divide[i][j].quotient);
        }
    }
}

component main = Move(3, 3, 16);