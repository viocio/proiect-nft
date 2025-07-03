// test/NFT.test.js
const { expect } = require("chai");
const hre = require("hardhat");
const { ethers } = hre;

describe("NFT Tickets", function () {
  let nft, mockUsdt, owner, user;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    // Deploy mock USDT token
    const MockUSDT = await ethers.getContractFactory("MockUSDT");
    mockUsdt = await MockUSDT.deploy();
    await mockUsdt.waitForDeployment();

    // Deploy NFT contract
    const NFT = await ethers.getContractFactory("NFT");
    nft = await NFT.deploy(5, ethers.utils.parseUnits("10", 18));
    await nft.waitForDeployment();

    // Set mock USDT address in NFT contract
    await nft.setUsdtToken(mockUsdt.target);

    // Transfer USDT to user
    await mockUsdt.transfer(user.address, ethers.utils.parseUnits("100", 18));
  });

  it("should not allow minting without payment", async function () {
    await expect(
      nft.connect(user).retrieveTicket(user.address)
    ).to.be.revertedWith("ticketsOfUser[msg.sender] >= 1");
  });

  it("should fail payment without approval", async function () {
    await expect(nft.connect(user).payForTicket()).to.be.reverted;
  });

  it("should allow payment with approval and mint", async function () {
    await mockUsdt
      .connect(user)
      .approve(nft.target, ethers.utils.parseUnits("10", 18));
    await nft.connect(user).payForTicket();

    await nft.connect(user).retrieveTicket(user.address);
    expect(await nft.ownerOf(0)).to.equal(user.address);
  });

  it("should not allow more than max tickets", async function () {
    await mockUsdt
      .connect(user)
      .approve(nft.target, ethers.utils.parseUnits("50", 18));
    for (let i = 0; i < 5; i++) {
      await nft.connect(user).payForTicket();
    }
    await expect(nft.connect(user).payForTicket()).to.be.revertedWith(
      "No more tickets available"
    );
  });

  it("should only allow owner to withdraw", async function () {
    await mockUsdt
      .connect(user)
      .approve(nft.target, ethers.utils.parseUnits("10", 18));
    await nft.connect(user).payForTicket();

    const balanceBefore = await mockUsdt.balanceOf(owner.address);
    await nft.withdraw();
    const balanceAfter = await mockUsdt.balanceOf(owner.address);

    expect(balanceAfter).to.be.gt(balanceBefore);
  });
});
