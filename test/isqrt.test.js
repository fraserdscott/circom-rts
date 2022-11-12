const hre = require("hardhat");
const { assert } = require("chai");

const SAMPLES = 100;

describe("isqrt circuit", () => {
  let circuit;

  const sampleInputs = Array.from(Array(SAMPLES).keys()).map(i => ({ in: i.toString() }))
  const sanityCheck = true;

  before(async () => {
    circuit = await hre.circuitTest.setup("isqrtTest");
  });

  it("produces a witness with valid constraints", async () => {
    for (let i = 0; i < SAMPLES; i++) {
      const witness = await circuit.calculateWitness(sampleInputs[i], sanityCheck);
      await circuit.checkConstraints(witness);
    }
  });

  it("has expected witness values", async () => {
    for (let i = 0; i < SAMPLES; i++) {
      const witness = await circuit.calculateLabeledWitness(
        sampleInputs[i],
        sanityCheck
      );
      assert.propertyVal(witness, "main.in", sampleInputs[i].in);
    }
  });

  it("has the correct output", async () => {
    for (let i = 0; i < SAMPLES; i++) {
      const expected = { out: Math.floor(Math.sqrt(sampleInputs[i].in)) };
      const witness = await circuit.calculateWitness(sampleInputs[i], sanityCheck);
      await circuit.assertOut(witness, expected);
    }
  });
});
