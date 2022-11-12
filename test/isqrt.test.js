const hre = require("hardhat");
const { assert } = require("chai");

describe("isqrt circuit", () => {
  let circuit;

  const sampleInput = {
    in: "27"
  }
  const sanityCheck = true;

  before(async () => {
    circuit = await hre.circuitTest.setup("isqrtTest");
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
    assert.propertyVal(witness, "main.in", sampleInput.in);
  });

  it("has the correct output", async () => {
    const expected = { out: Math.floor(Math.sqrt(sampleInput.in)) };
    const witness = await circuit.calculateWitness(sampleInput, sanityCheck);
    await circuit.assertOut(witness, expected);
  });
});
