const { assert } = require("chai")
const { network, getNamedAccounts, deployments, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("lottery Unit tests", async function () {
          let lottery
          let vrfCoordinatorV2Mock
          const chainId = network.config.chainId

          beforeEach(async function () {
              const { deployer } = await getNamedAccounts()
              await deployments.fixture(["all"]) //using fixture we can deploy our contracts with as many tags as we want
              //running all the deploy scripts using this line

              lottery = await ethers.getContract("lottery", deployer)
              vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock", deployer)
          })

          describe("Constructor", async function () {
              it("Initializes the constructor correctly.", async function () {
                  const lotteryState = await lottery.getLotteryState()
                  const interval = await lottery.getInterval()

                  assert.equal(lotteryState.toString(), "0")
                  assert.equal(interval.toString(), networkConfig[chainId]["interval"])
              })
          })
      })
