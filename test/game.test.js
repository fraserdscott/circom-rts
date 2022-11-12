const hre = require("hardhat");
const { assert } = require("chai");

describe("game circuit", () => {
  let circuit;

  const sampleInput = {
    unitHealths: [
      "7"
    ],
    unitPlayer: [
      "0"
    ],
    unitPositions: [
      [
        "50",
        "50",
        "50"
      ]
    ],
    eventTick: [
      0,
      0,
      1
    ],
    eventPlayer: [
      0,
      0,
      0
    ],
    eventSelected: [
      0,
      0,
      0
    ],
    eventPositions: [
      [
        [
          "100",
          "100",
          "100"
        ]
      ],
      [
        [
          "100",
          "100",
          "100"
        ]
      ],
      [
        [
          "20",
          "35",
          "70"
        ]
      ]
    ]
  };
  const sanityCheck = true;

  before(async () => {
    circuit = await hre.circuitTest.setup("gameTest");
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
    assert.propertyVal(witness, "main.unitPositions[0][0]", sampleInput.unitPositions[0][0]);
  });

  it("has the correct output", async () => {
    const expected = {
      newHealths: [
        "7"
      ],
      newPositions: [
        [
          "49",
          "50",
          "54"
        ]
      ]
    }; const witness = await circuit.calculateWitness(sampleInput, sanityCheck);
    await circuit.assertOut(witness, expected);
  });
});
