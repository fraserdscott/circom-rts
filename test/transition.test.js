const hre = require("hardhat");
const { assert } = require("chai");

describe("transition circuit", () => {
  let circuit;

  const sampleInput = {
    healths: [
      "10"
    ],
    positions: [
      [
        "50",
        "50",
        "50"
      ]
    ],
    targetPositions: [
      [
        "55",
        "55",
        "55"
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
    assert.propertyVal(witness, "main.positions[0][0]", sampleInput.positions[0][0]);
  });

  it("has the correct output", async () => {
    const expected = {
      newHealths: [
        "10"
      ],
      newPositions: [
        [
          "52",
          "52",
          "52"
        ]
      ]
    }; const witness = await circuit.calculateWitness(sampleInput, sanityCheck);
    await circuit.assertOut(witness, expected);
  });
});
