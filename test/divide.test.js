const hre = require("hardhat");
const { assert } = require("chai");

describe("divide circuit", () => {
  let circuit;

  const sampleInput = {
    dividend: "11",
    divisor: "5"
  }
  const sanityCheck = true;

  before(async () => {
    circuit = await hre.circuitTest.setup("divide");
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
    assert.propertyVal(witness, "main.dividend", sampleInput.dividend);
    assert.propertyVal(witness, "main.divisor", sampleInput.divisor);
  });

  it("has the correct output", async () => {
    const expected = { quotient: "2" };
    const witness = await circuit.calculateWitness(sampleInput, sanityCheck);
    await circuit.assertOut(witness, expected);
  });
});
