const hre = require("hardhat");
const { assert } = require("chai");

describe("attack circuit", () => {
  let circuit;

  const sampleInput = {
    ps: [
      [
        "5",
        "3",
        "9"
      ],
      [
        "5",
        "4",
        "9"
      ],
      [
        "1",
        "2",
        "3"
      ],
      [
        "1",
        "1",
        "3"
      ],
      [
        "1",
        "2",
        "3"
      ]
    ],
    healths: [
      "7",
      "10",
      "150",
      "70",
      "50"
    ]
  }
  const sanityCheck = true;

  before(async () => {
    circuit = await hre.circuitTest.setup("attack");
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
    assert.propertyVal(witness, "main.ps[0][0]", sampleInput.ps[0][0]);
    assert.propertyVal(witness, "main.healths[0]", sampleInput.healths[0]);
  });

  it("has the correct output", async () => {
    const expected = { newHealths: [2, 5, 140, 70, 45] };
    const witness = await circuit.calculateWitness(sampleInput, sanityCheck);
    await circuit.assertOut(witness, expected);
  });
});
