const hre = require("hardhat");
const { assert } = require("chai");

describe("move circuit", () => {
  let circuit;

  const sampleInput = {
    positions: [
      [
        "50",
        "50",
        "50"
      ],
      [
        "100",
        "100",
        "100"
      ],
      [
        "150",
        "150",
        "150"
      ],
      [
        "150",
        "150",
        "150"
      ]
    ],
    "vectors": [
      [
        "5",
        "0",
        "0"
      ],
      [
        "3",
        "4",
        "0"
      ],
      [
        "4",
        "0",
        "3"
      ],
      [
        "0",
        "0",
        "0"
      ]
    ]
  }
  const sanityCheck = true;

  before(async () => {
    circuit = await hre.circuitTest.setup("moveTest");
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

  // now, have one that will collide with these
  it("has the correct output", async () => {
    const expected = {
      newPositions: [
        [
          "55",
          "50",
          "50"
        ],
        [
          "103",
          "104",
          "100"
        ],
        [
          "154",
          "150",
          "153"
        ],
        [
          "150",
          "150",
          "150"
        ]
      ]
    };
    const witness = await circuit.calculateWitness(sampleInput, sanityCheck);
    await circuit.assertOut(witness, expected);
  });
});
