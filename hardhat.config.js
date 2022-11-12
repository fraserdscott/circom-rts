require("hardhat-circom");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.6.11",
      },
      {
        version: "0.8.9",
      },
    ],
  },
   mocha: {
    timeout: 100000000
  },
  circom: {
    inputBasePath: "./circuits",
    ptau: "https://hermezptau.blob.core.windows.net/ptau/powersOfTau28_hez_final_18.ptau",
    circuits: [
      // {
      //   name: "attackTest"
      // },
      // {
      //   name: "moveTest"
      // },
      // {
      //   name: "divideTest"
      // },
      // {
      //   name: "isqrtTest"
      // },
      // {
      //   name: "transitionTest"
      // },
      // {
      //   name: "gameTest"
      // },
      {
        name: "presetTest"
      },
    ],
  },
};
