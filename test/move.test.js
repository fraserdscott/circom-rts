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
        "155",
        "150",
        "150"
      ]
    ],
    targetPositions: [
      [
        "50",
        "50",
        "50"
      ],
      [
        "130",
        "150",
        "120"
      ],
      [
        "120",
        "120",
        "120"
      ],
      [
        "120",
        "150",
        "150"
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

  // now, have one that will collide with these
  it("has the correct output", async () => {
    const expected = {
      newPositions: [
        [
          "50",
          "50",
          "50"
        ],
        [
          "102",
          "104",
          "101"
        ],
        [
          "148",
          "148",
          "148"
        ],
        [
          "155",
          "150",
          "150"
        ]
      ]
    };
    const witness = await circuit.calculateWitness(sampleInput, sanityCheck);
    await circuit.assertOut(witness, expected);
  });
});
