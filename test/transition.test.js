const hre = require("hardhat");
const { assert } = require("chai");

describe("transition circuit", () => {
  let circuit;

  const sampleInput = {
    "health_in": [
      "7"
    ],
    "position_in": [
      [
        "50",
        "50",
        "50"
      ]
    ],
    "vectors": [
      [
        "0",
        "3",
        "4"
      ]
    ]
  };
  const sanityCheck = true;

  before(async () => {
    circuit = await hre.circuitTest.setup("transitionTest");
  });

  it("produces a witness with valid constraints", async () => {
    const witness = await circuit.calculateWitness(sampleInput, sanityCheck);
    await circuit.checkConstraints(witness);
  });

  it("has expected witness values", async () => {
    const witness = await circuit.calculateLabeledWitness(
      sampleInput,
      sanityCheck
    );
    sampleInput.position_in.map((p, i) =>
      sampleInput.position_in[i].map((q, j) =>
        assert.propertyVal(witness, `main.position_in[${i}][${j}]`, sampleInput.position_in[i][j])
      )
    );
  });

  it("has the correct output", async () => {
    const expected = {
      health_out: [
        "7"
      ],
      position_out: [
        [
          "50",
          "53",
          "54"
        ]
      ]
    };
    const witness = await circuit.calculateWitness(sampleInput, sanityCheck);
    await circuit.assertOut(witness, expected);
  });
});
