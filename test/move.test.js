const hre = require("hardhat");
const { assert } = require("chai");

describe("move circuit", () => {
  let circuit;

  const sampleInput = {
    positions: [
      [
        "100",
        "100",
        "100"
      ],
      [
        "100",
        "100",
        "100"
      ],
      [
        "100",
        "100",
        "100"
      ]
    ],
    targetPositions: [
      [
        "100",
        "100",
        "100"
      ],
      [
        "130",
        "150",
        "120"
      ],
      [
        "80",
        "80",
        "80"
      ]
    ]
  }
  const sanityCheck = true;

  before(async () => {
    circuit = await hre.circuitTest.setup("move");
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
      newPositions: [
        [
          "100",
          "100",
          "100"
        ],
        [
          "102",
          "104",
          "101"
        ],
        [
          "98",
          "98",
          "98"
        ]
      ]
    };
    const witness = await circuit.calculateWitness(sampleInput, sanityCheck);
    await circuit.assertOut(witness, expected);
  });
});
