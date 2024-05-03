import { getAddress, parseGwei, parseEther, formatEther, Account } from "viem";
import {ethers } from 'hardhat'
import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-network-helpers";
import { expect, use } from "chai";

const tokenName = 'Uncuts Trading Card'

const tokenSymbol = 'UNCUTS'

const metaDataPrefix = 'https://www.uncuts.app/cards/releases/'

const metaDataSuffix = '/metadata/'

const basePrice = '250'


const prizePoolFeeDestination = '0x0EA70bEdB155e55A09E841cbbADF1A479d260101'
 

describe("UncutsTradingCard", function () {

  async function deployTradingCardFixture() {

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount, thirdAccount, fourthAccount] = await ethers.getSigners();

    const protocolReleaseCardFee = parseEther("0.005");

    const protocolTradeCardFeePercent = 2500;
    const prizePoolTradeCardFeePercent = 2500;

    const authorTradeCardFeePercent = 5000;

    const payToken = await ethers.deployContract("PayToken", ['UNCUTS', 'UNCUTS', 18]);

    // console.log(payToken)
    
    const uncutsTradingCard = await ethers.deployContract("UncutsTradingCard", [
      tokenName, 
      tokenSymbol, 
      metaDataPrefix, 
      metaDataSuffix, 
      payToken.target,
      basePrice,
    ]);

    await uncutsTradingCard.waitForDeployment();

    await uncutsTradingCard.setPrizePoolFeeDestination(prizePoolFeeDestination)
    // const publicClient = await hre.viem.getPublicClient();

    return {
      uncutsTradingCard,
      payToken,
      protocolReleaseCardFee,
      protocolTradeCardFeePercent,
      authorTradeCardFeePercent,
      prizePoolTradeCardFeePercent,
      owner,
      otherAccount,
      thirdAccount,
      fourthAccount
    };
  }

  describe("Deployment", function () {
    it("Should set the right protocolReleaseCardFee", async function () {

      const { uncutsTradingCard, protocolReleaseCardFee } = await loadFixture(deployTradingCardFixture);

      expect(await uncutsTradingCard.protocolReleaseCardFee()).to.equal(protocolReleaseCardFee);

    });

    it("Should set the right protocolTradeCardFeePercent", async function () {

      const { uncutsTradingCard, protocolTradeCardFeePercent } = await loadFixture(deployTradingCardFixture);

      expect(await uncutsTradingCard.protocolTradeCardFeePercent()).to.equal(protocolTradeCardFeePercent);

    });

    it("Should set the right prizePoolTradeCardFeePercent", async function () {

      const { uncutsTradingCard, prizePoolTradeCardFeePercent } = await loadFixture(deployTradingCardFixture);

      expect(await uncutsTradingCard.prizePoolTradeCardFeePercent()).to.equal(prizePoolTradeCardFeePercent);

    });

    it("Should set the right authorTradeCardFeePercent", async function () {

      const { uncutsTradingCard, authorTradeCardFeePercent } = await loadFixture(deployTradingCardFixture);

      expect(await uncutsTradingCard.authorTradeCardFeePercent()).to.equal(authorTradeCardFeePercent);

    });

    it("Should set the right owner", async function () {
      const { uncutsTradingCard, owner } = await loadFixture(deployTradingCardFixture);

      expect(await uncutsTradingCard.owner()).to.equal(getAddress(owner.address));
    });

    it("Should set the right prize pool destination", async function () {
      const { uncutsTradingCard } = await loadFixture(deployTradingCardFixture);

      expect(await uncutsTradingCard.prizePoolFeeDestination()).to.equal(getAddress(prizePoolFeeDestination));
    });

    it("Should fail if the protocolTradeCardFeePercent is more than 100", async function () {
      const { uncutsTradingCard, owner } = await loadFixture(deployTradingCardFixture);
      // We don't use the fixture here because we want a different deployment
      await expect(uncutsTradingCard.setProtocolTradeCardFeePercent(101000)).to.be.rejectedWith("Value must be between 0 and 100000");
    });

    it("Should fail if the authorTradeCardFeePercent is more than 100", async function () {
      // We don't use the fixture here because we want a different deployment
      const { uncutsTradingCard, owner } = await loadFixture(deployTradingCardFixture);
      // We don't use the fixture here because we want a different deployment
      await expect(uncutsTradingCard.setAuthorTradeCardFeePercent(101000)).to.be.rejectedWith("Value must be between 0 and 100000");
    });


    it("Should set pause", async function () {
      const { uncutsTradingCard, owner } = await loadFixture(deployTradingCardFixture);

      await uncutsTradingCard.setPause(true)

      expect(await uncutsTradingCard.isPaused()).to.equal(true);

    });

    it("Should fail to pause if not owner", async function () {
      const { uncutsTradingCard, otherAccount } = await loadFixture(deployTradingCardFixture);

      // await uncutsTradingCard.setPause(true)

      await expect( uncutsTradingCard.connect(otherAccount).setPause(true)).to.be.rejectedWith(uncutsTradingCard, 'OwnableUnauthorizedAccount');

    });
    
  });

  describe("Release Card", function () {

    it("Should fail if Public release not enabled", async function () {

      const { 
        uncutsTradingCard, 
        otherAccount, 
        protocolReleaseCardFee
      } = await loadFixture(deployTradingCardFixture);

      await expect(uncutsTradingCard.connect(otherAccount).releaseCard()).to.be.rejectedWith(uncutsTradingCard, 'TradingCard__PublicReleaseDisabled');

    });


    it("Should fail if insufficient allowance", async function () {

      const { 
        uncutsTradingCard, 
        otherAccount, 
        protocolReleaseCardFee
      } = await loadFixture(deployTradingCardFixture);

      await uncutsTradingCard.setPublicReleaseStatus(true)
      
      await expect(uncutsTradingCard.connect(otherAccount).releaseCard()).to.be.rejectedWith(uncutsTradingCard, 'ERC20InsufficientAllowance');

    });

    it("Should fail if insufficient balance", async function () {

      const { 
        payToken,
        uncutsTradingCard, 
        otherAccount, 
        protocolReleaseCardFee
      } = await loadFixture(deployTradingCardFixture);

      await uncutsTradingCard.setPublicReleaseStatus(true)

      await payToken.connect(otherAccount).approve(uncutsTradingCard.target, BigInt(Number(protocolReleaseCardFee)*2))
      
      await expect(uncutsTradingCard.connect(otherAccount).releaseCard()).to.be.rejectedWith(uncutsTradingCard, 'ERC20InsufficientBalance');

    });

    it("Should release card if balance is enough and protocol fee sent", async function () {

      const { 
        payToken,
        uncutsTradingCard, 
        otherAccount, 
        owner,
        protocolReleaseCardFee
      } = await loadFixture(deployTradingCardFixture);

      await uncutsTradingCard.setPublicReleaseStatus(true)

      let decimals = await payToken.decimals()

      let fee = protocolReleaseCardFee.toString()


      await payToken.transfer(otherAccount.address, BigInt(Number(protocolReleaseCardFee)*2))
      let balance = await payToken.balanceOf(owner.address)
      console.log(balance, fee)

      await payToken.connect(otherAccount).approve(uncutsTradingCard.target, BigInt(Number(protocolReleaseCardFee)*2))
      
      expect(await uncutsTradingCard.connect(otherAccount).releaseCard())
      .to.emit(uncutsTradingCard, 'ReleaseCard');

      expect(await payToken.balanceOf(owner.address)).to.equal(balance + protocolReleaseCardFee);

    });

    it("Should reject if draining the contract via release reentrancy", async function () {
      const { 
        uncutsTradingCard, 
        payToken,
        otherAccount, 
        protocolReleaseCardFee
      } = await loadFixture(deployTradingCardFixture);

      // Deploy attacker contract.
      const attack_contract_release = await ethers.deployContract("Reentrancy_Attack_Release", [
        uncutsTradingCard.target, 
        payToken.target,
      ]);

      // Fund the attacker contract 
      payToken.transfer(attack_contract_release.target, ethers.parseEther('10000'));

      // The first card is released.
      await uncutsTradingCard.releaseCardTo(otherAccount.address)
      
      const priceWithFeesFiveCards = await uncutsTradingCard.getBuyPriceAfterFee(1,5);
      const priceWithoutFeesFiveCards = await uncutsTradingCard.getBuyPrice(1,5);
      
      await payToken.approve(uncutsTradingCard.target, priceWithFeesFiveCards)
      await uncutsTradingCard.buy(otherAccount.address, 1, 5, priceWithFeesFiveCards)

      // Uncuts contract balance equals the amount paid by the previous purchase of 5 cards.
      // These are the funds that are going to be drained.
      const uncutsBalance = await payToken.balanceOf(uncutsTradingCard.target);
      expect(uncutsBalance).to.equal(priceWithoutFeesFiveCards);
      
      await uncutsTradingCard.setPublicReleaseStatus(true);
     
      // Perform the attack.
      await expect(attack_contract_release.release_card()).to.be.rejectedWith('ReentrancyGuardReentrantCall()');

    })

  });

  ///////////////////////////
  ///////////////////////////
  describe("Buy Cards", function () {

    it("Should fail if Card not released yet", async function () {

      const { 
        uncutsTradingCard, 
        otherAccount, 
        protocolReleaseCardFee
      } = await loadFixture(deployTradingCardFixture);

      let price = await uncutsTradingCard.getBuyPriceAfterFee(1, 1);

      await expect(uncutsTradingCard.connect(otherAccount).buy(otherAccount.address, 1, 1, price)).to.be.rejectedWith("Card not released");

    });

    it("Should fail if trying to buy 0 Cards", async function () {

      const { 
        uncutsTradingCard, 
        otherAccount, 
        protocolReleaseCardFee
      } = await loadFixture(deployTradingCardFixture);

      await expect(uncutsTradingCard.releaseCardTo(otherAccount.address)).to.not.be.rejected;

      const price = await uncutsTradingCard.getBuyPriceAfterFee(1, 1);

      await expect(uncutsTradingCard.connect(otherAccount).buy(otherAccount.address, 1, 0, price)).to.be.rejectedWith("Minimum amount is 1");

    });

    it("Should fail buy if insufficient balance", async function () {

      const { 
        uncutsTradingCard, 
        otherAccount, 
        protocolReleaseCardFee,
        payToken
      } = await loadFixture(deployTradingCardFixture);


      await expect(uncutsTradingCard.releaseCardTo(otherAccount.address)).to.not.be.rejected;


      const price = await uncutsTradingCard.getBuyPrice(1,1);
      const priceWithFees = await uncutsTradingCard.getBuyPriceAfterFee(1,1);

      console.log(formatEther(price), formatEther(priceWithFees));

      await payToken.connect(otherAccount).approve(uncutsTradingCard.target, priceWithFees)

      await expect(uncutsTradingCard.connect(otherAccount).buy(otherAccount.address, 1,1,priceWithFees)).to.be.rejectedWith('ERC20InsufficientBalance');

    });


    it("Should fail buy if price is too high", async function () {

      const { 
        uncutsTradingCard, 
        otherAccount, 
        protocolReleaseCardFee,
        payToken
      } = await loadFixture(deployTradingCardFixture);


      await expect(uncutsTradingCard.releaseCardTo(otherAccount.address)).to.not.be.rejected;


      const price = await uncutsTradingCard.getBuyPrice(1,1);
      const priceWithFees = await uncutsTradingCard.getBuyPriceAfterFee(1,1);

      await payToken.transfer(otherAccount.address, BigInt(Number(priceWithFees)*10))

      console.log(formatEther(price), formatEther(priceWithFees));

      await payToken.connect(otherAccount).approve(uncutsTradingCard.target, BigInt(Number(priceWithFees)*10))

      await uncutsTradingCard.connect(otherAccount).buy(otherAccount.address, 1,1,priceWithFees)

      await expect(uncutsTradingCard.connect(otherAccount).buy(otherAccount.address, 1,1,priceWithFees)).to.be.rejectedWith('Price is too high');

    });

    it("Should release then buy 1 NFT CARD and check if balance is 2", async function () {

      const { 
        payToken,
        uncutsTradingCard, 
        otherAccount, 
        owner,
        protocolReleaseCardFee
      } = await loadFixture(deployTradingCardFixture);


      
      expect(await uncutsTradingCard.releaseCardTo(otherAccount.address))
      .to.emit(uncutsTradingCard, 'ReleaseCard');

      const priceWithFees = await uncutsTradingCard.getBuyPriceAfterFee(1,1);

      await payToken.approve(uncutsTradingCard.target, priceWithFees)

      expect(await uncutsTradingCard.buy(otherAccount.address, 1, 1, priceWithFees))
      .to.emit(uncutsTradingCard, 'Buy');

      const price2 = await uncutsTradingCard.getBuyPrice(1,1);
      const priceWithFees2 = await uncutsTradingCard.getBuyPriceAfterFee(1,1);
      console.log('price2', formatEther(price2))

      const balance = await uncutsTradingCard.balanceOf(otherAccount.address, 1)

      console.log('buy balance:', balance)

      expect(balance).to.equal(2);

    });

    it("Should trade cards randomly and return zero contract balance finally", async function () {

      const { 
        payToken,
        uncutsTradingCard, 
        otherAccount
      } = await loadFixture(deployTradingCardFixture);


      
      expect(await uncutsTradingCard.releaseCardTo(otherAccount.address))
      .to.emit(uncutsTradingCard, 'ReleaseCard');

      for(let i = 0; i < 25; i++) {

        const buy_count = 1

        let price = await uncutsTradingCard.getBuyPrice(1,buy_count);
        let priceWithFees = await uncutsTradingCard.getBuyPriceAfterFee(1,buy_count);
        let tokenSupply = await uncutsTradingCard.getReleaseSupply(1)

        console.log('price buy',  formatEther(price), tokenSupply.toString())

        try {
          await payToken.approve(uncutsTradingCard.target, priceWithFees)
          await uncutsTradingCard.buy(otherAccount.address, 1, buy_count, priceWithFees)
        } catch (error) {
          console.log(error)
        }

        let contractBalance = await payToken.balanceOf(uncutsTradingCard.target)
        let prizePoolBalance = await payToken.balanceOf(prizePoolFeeDestination)
        console.log('contract balance:', formatEther(contractBalance), 'prize pool balance:', formatEther(prizePoolBalance))

      }

      for(let i = 0; i < 25; i++) {

        const sell_count = 1

        let price = await uncutsTradingCard.getSellPrice(1,sell_count);
        let priceWithFees = await uncutsTradingCard.getSellPriceAfterFee(1,sell_count);


        await uncutsTradingCard.connect(otherAccount).sell(otherAccount.address, 1, sell_count,priceWithFees)
        let tokenSupply = await uncutsTradingCard.getReleaseSupply(1)
        console.log('price sell',  formatEther(price), tokenSupply)

        let contractBalance = await payToken.balanceOf(uncutsTradingCard.target)
        let prizePoolBalance = await payToken.balanceOf(prizePoolFeeDestination)
        console.log('contract balance:', formatEther(contractBalance), 'prize pool balance:', formatEther(prizePoolBalance))

      }

      for(let i = 0; i < 7; i++) {

        const buy_count = 3

        let price = await uncutsTradingCard.getBuyPrice(1,buy_count);
        let priceWithFees = await uncutsTradingCard.getBuyPriceAfterFee(1,buy_count);
        let tokenSupply = await uncutsTradingCard.getReleaseSupply(1)

        console.log('price buy',  formatEther(price), tokenSupply.toString())

        try {
          await payToken.approve(uncutsTradingCard.target, priceWithFees)
          await uncutsTradingCard.buy(otherAccount.address, 1, buy_count, priceWithFees)
        } catch (error) {
          console.log(error)
        }

        let contractBalance = await payToken.balanceOf(uncutsTradingCard.target)
        let prizePoolBalance = await payToken.balanceOf(prizePoolFeeDestination)
        console.log('contract balance:', formatEther(contractBalance), 'prize pool balance:', formatEther(prizePoolBalance))

      }

      for(let i = 0; i < 21; i++) {

        const sell_count = 1

        let price = await uncutsTradingCard.getSellPrice(1,sell_count);
        let priceWithFees = await uncutsTradingCard.getSellPriceAfterFee(1,sell_count);


        await uncutsTradingCard.connect(otherAccount).sell(otherAccount.address, 1, sell_count,priceWithFees)
        let tokenSupply = await uncutsTradingCard.getReleaseSupply(1)
        console.log('price sell',  formatEther(price), tokenSupply)

        let contractBalance = await payToken.balanceOf(uncutsTradingCard.target)
        let prizePoolBalance = await payToken.balanceOf(prizePoolFeeDestination)
        console.log('contract balance:', formatEther(contractBalance), 'prize pool balance:', formatEther(prizePoolBalance))

      }

      for(let i = 0; i < 21; i++) {

        const buy_count = 1

        let price = await uncutsTradingCard.getBuyPrice(1,buy_count);
        let priceWithFees = await uncutsTradingCard.getBuyPriceAfterFee(1,buy_count);
        let tokenSupply = await uncutsTradingCard.getReleaseSupply(1)

        console.log('price buy',  formatEther(price), tokenSupply.toString())

        try {
          await payToken.approve(uncutsTradingCard.target, priceWithFees)
          await uncutsTradingCard.buy(otherAccount.address, 1, buy_count, priceWithFees)
        } catch (error) {
          console.log(error)
        }

        let contractBalance = await payToken.balanceOf(uncutsTradingCard.target)
        let prizePoolBalance = await payToken.balanceOf(prizePoolFeeDestination)
        console.log('contract balance:', formatEther(contractBalance), 'prize pool balance:', formatEther(prizePoolBalance))

      }

      for(let i = 0; i < 7; i++) {

        const sell_count = 3

        let price = await uncutsTradingCard.getSellPrice(1,sell_count);
        let priceWithFees = await uncutsTradingCard.getSellPriceAfterFee(1,sell_count);


        await uncutsTradingCard.connect(otherAccount).sell(otherAccount.address, 1, sell_count,priceWithFees)
        let tokenSupply = await uncutsTradingCard.getReleaseSupply(1)
        console.log('price sell' ,  formatEther(price), tokenSupply)

        let contractBalance = await payToken.balanceOf(uncutsTradingCard.target)
        let prizePoolBalance = await payToken.balanceOf(prizePoolFeeDestination)
        console.log('contract balance:', formatEther(contractBalance), 'prize pool balance:', formatEther(prizePoolBalance))

      }
      
      let finalContractBalance = await payToken.balanceOf(uncutsTradingCard.target);

      expect(finalContractBalance).to.equals('0');

      let lastSellPrice = await uncutsTradingCard.getSellPrice(1,1)

      console.log('lastSellPrice', lastSellPrice)

      let zeroBuyPrice = await uncutsTradingCard.getBuyPrice(2,1)

      console.log('zeroBuyPrice', zeroBuyPrice)

    });

    it("Should release 1 card then buy this CARD from another account and check that all fees are delivered and contract balance is added", async function () {

      const { 
        payToken,
        uncutsTradingCard, 
        otherAccount, 
        thirdAccount,
        owner
      } = await loadFixture(deployTradingCardFixture);

      await expect(uncutsTradingCard.releaseCardTo(otherAccount.address)).to.not.be.rejected;


      const protocolTradeCardFeePercent = await uncutsTradingCard.protocolTradeCardFeePercent();
      const authorTradeCardFeePercent = await uncutsTradingCard.authorTradeCardFeePercent();
      const prizePoolTradeCardFeePercent = await uncutsTradingCard.prizePoolTradeCardFeePercent();

      let mint_array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
      // let mint_amounts = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
      for(let i of mint_array) {

        await uncutsTradingCard.releaseCardTo(otherAccount.address)

        let priceWithFees= await uncutsTradingCard.getBuyPriceAfterFee(i,1);

        await payToken.approve(uncutsTradingCard.target, priceWithFees * BigInt(2))

        // let mintPriceWithFees = await uncutsTradingCard.connect(thirdAccount).getBuyPriceAfterFee(i, 1);
        await uncutsTradingCard.buy(thirdAccount.address, i, 1, priceWithFees);

      }
      

      const releaseSupply = await uncutsTradingCard.getReleaseSupply(1);
      
      let priceWithFees= await uncutsTradingCard.connect(thirdAccount).getBuyPriceAfterFee(1,5);
      const price = await uncutsTradingCard.connect(thirdAccount).getBuyPrice(1, 5);
      // console.log(formatEther(price), formatEther(priceWithFees));

      await payToken.connect(owner).transfer(thirdAccount.address, priceWithFees)

      await payToken.connect(thirdAccount).approve(uncutsTradingCard.target, priceWithFees * BigInt(2))
  

      console.log(releaseSupply, formatEther(priceWithFees), formatEther(price))

      // console.log(formatEther(mintPrice), formatEther(mintPriceWithFees), protocolTradeCardFeePercent)

      await expect(uncutsTradingCard.connect(thirdAccount).buy(thirdAccount.address, 1, 5, priceWithFees)).to.changeTokenBalances(
        payToken,
        [
          owner, 
          otherAccount, 
          prizePoolFeeDestination,
          uncutsTradingCard,
        ], 
        [
          price * BigInt(protocolTradeCardFeePercent) / BigInt(100000), 
          price * BigInt(authorTradeCardFeePercent) / BigInt(100000), 
          price * BigInt(prizePoolTradeCardFeePercent) / BigInt(100000), 
          price
        ]);

    });

    it("Should revert if buy two cards with reentrancy", async function () {
      const { 
        uncutsTradingCard, 
        payToken,
        otherAccount, 
        protocolReleaseCardFee
      } = await loadFixture(deployTradingCardFixture);
  
      // Deploy attacker contract.
      const attack_contract = await ethers.deployContract("Reentrancy_Attack", [
        uncutsTradingCard.target, 
        payToken.target,
      ]);
  
      // The first card is released.
      await uncutsTradingCard.releaseCardTo(otherAccount.address)
      
      // Prices for buying the first card after the release.
      const priceWithFeesOneCard = await uncutsTradingCard.getBuyPriceAfterFee(1,1);
  
      // Fund the attacker contract with only twice the price (with fees) for the first card.
      payToken.transfer(attack_contract.target, BigInt(Number(priceWithFeesOneCard)*2))
  
      // Perform the attack.
      await expect(attack_contract.buy_card(1, 1, priceWithFeesOneCard)).to.be.rejectedWith('ReentrancyGuardReentrantCall()')

    })

  });

  describe("Sell Cards", function () {

    it("Should buy 20 cards, sell 10 cards and return 10 cards on balance", async function () {

      const { 
        uncutsTradingCard, 
        otherAccount, 
        thirdAccount,
        owner,
        authorTradeCardFeePercent,
        payToken
      } = await loadFixture(deployTradingCardFixture);

      await expect(uncutsTradingCard.releaseCardTo(otherAccount.address)).to.not.be.rejected;

      const card_count = 20

      const buyPrice = await uncutsTradingCard.connect(thirdAccount).getBuyPrice(1, card_count);
      const buyPriceWithFees = await uncutsTradingCard.connect(thirdAccount).getBuyPriceAfterFee(1, card_count);
      const protocolTradeCardFeePercent = await uncutsTradingCard.protocolTradeCardFeePercent();
      const prizePoolTradeCardFeePercent = await uncutsTradingCard.prizePoolTradeCardFeePercent();

      await payToken.connect(owner).transfer(thirdAccount.address, buyPriceWithFees)

      await payToken.connect(thirdAccount).approve(uncutsTradingCard.target, buyPriceWithFees * BigInt(2))

      // console.log(formatEther(mintPrice), formatEther(mintPriceWithFees) * 2800, protocolTradeCardFeePercent)

      await uncutsTradingCard.connect(thirdAccount).buy(thirdAccount.address, 1, card_count,buyPriceWithFees);

      const sellPriceAfterFees = await uncutsTradingCard.getSellPriceAfterFee(1, card_count/2);
      const sellPrice = await uncutsTradingCard.getSellPrice(1, card_count/2);

      console.log({
        sellPrice: formatEther(sellPrice),
        sellPriceAfterFees: formatEther(sellPriceAfterFees)
      })

      await expect(uncutsTradingCard.connect(thirdAccount).sell(thirdAccount.address, 1, card_count/2,sellPriceAfterFees)).to.changeTokenBalances(
        payToken,
        [
          owner, 
          otherAccount, 
          prizePoolFeeDestination,
          uncutsTradingCard,
          thirdAccount
        ], 
        [
          sellPrice * BigInt(protocolTradeCardFeePercent) / BigInt(100000), 
          sellPrice * BigInt(authorTradeCardFeePercent) / BigInt(100000), 
          sellPrice * BigInt(prizePoolTradeCardFeePercent) / BigInt(100000), 
          sellPrice * BigInt(-1),
          sellPriceAfterFees
        ]);

    });

    it("Should fail if mint 5 cards and burn 10 cards", async function () {

      const { 
        uncutsTradingCard, 
        otherAccount, 
        thirdAccount,
        owner,
        protocolReleaseCardFee,
        authorTradeCardFeePercent,
        payToken
      } = await loadFixture(deployTradingCardFixture);

      await expect(uncutsTradingCard.releaseCardTo(otherAccount.address)).to.not.be.rejected;

      const card_count = 5

      const buyPriceWithFees = await uncutsTradingCard.connect(thirdAccount).getBuyPriceAfterFee(1, card_count);

      await payToken.approve(uncutsTradingCard.target, buyPriceWithFees * BigInt(2))
      await uncutsTradingCard.buy(owner.address, 1, card_count,buyPriceWithFees);



      const nextBuyPriceWithFees = await uncutsTradingCard.connect(thirdAccount).getBuyPriceAfterFee(1, card_count);
      await payToken.connect(owner).transfer(thirdAccount.address, nextBuyPriceWithFees)

      await payToken.connect(thirdAccount).approve(uncutsTradingCard.target, nextBuyPriceWithFees * BigInt(2))

      // console.log(formatEther(mintPrice), formatEther(mintPriceWithFees) * 2800, protocolTradeCardFeePercent)

      await uncutsTradingCard.connect(thirdAccount).buy(thirdAccount.address, 1, card_count,nextBuyPriceWithFees);

      const sellPrice = await uncutsTradingCard.getSellPriceAfterFee(1, card_count*2);

      await expect(uncutsTradingCard.connect(thirdAccount).sell(thirdAccount.address, 1, card_count*2,sellPrice)).to.be.rejectedWith('Insufficient cards');

    });

    it("Should fail if mint 5 cards and then sell 2 and price is too low", async function () {

      const { 
        uncutsTradingCard, 
        otherAccount, 
        thirdAccount,
        owner,
        protocolReleaseCardFee,
        authorTradeCardFeePercent,
        payToken,
        fourthAccount
      } = await loadFixture(deployTradingCardFixture);

      await expect(uncutsTradingCard.releaseCardTo(otherAccount.address)).to.not.be.rejected;

      const first_buy_count = 2

      const firstBuyPriceWithFees = await uncutsTradingCard.connect(thirdAccount).getBuyPriceAfterFee(1, first_buy_count);

      await payToken.connect(owner).transfer(thirdAccount.address, firstBuyPriceWithFees)
      await payToken.connect(thirdAccount).approve(uncutsTradingCard.target, firstBuyPriceWithFees * BigInt(2))

      await uncutsTradingCard.connect(thirdAccount).buy(thirdAccount.address, 1, first_buy_count,firstBuyPriceWithFees);


      const next_card_count = 5

      const nextBuyPriceWithFees = await uncutsTradingCard.connect(fourthAccount).getBuyPriceAfterFee(1, next_card_count);
      await payToken.connect(owner).transfer(fourthAccount.address, nextBuyPriceWithFees)

      await payToken.connect(fourthAccount).approve(uncutsTradingCard.target, nextBuyPriceWithFees * BigInt(2))
      await uncutsTradingCard.connect(fourthAccount).buy(fourthAccount.address, 1, next_card_count,nextBuyPriceWithFees);

      const sellPrice = await uncutsTradingCard.getSellPriceAfterFee(1, 2);

      await uncutsTradingCard.connect(thirdAccount).sell(thirdAccount.address, 1, 2,sellPrice)

      await expect(uncutsTradingCard.connect(fourthAccount).sell(thirdAccount.address, 1, 2,sellPrice)).to.be.rejectedWith('Price is too low');

    });

  });

  describe("Metadata URI", function () {

    it("Should fail to advance epoch if too early", async function () {

      const { 
        uncutsTradingCard, 
        otherAccount, 
        thirdAccount,
        owner
      } = await loadFixture(deployTradingCardFixture);

      await expect(uncutsTradingCard.advanceEpoch()).to.be.rejectedWith('TradingCard__EpochNotEnded');
        
    });

    it("Should advance epoch if not too early", async function () {

      const { 
        uncutsTradingCard, 
        otherAccount, 
        thirdAccount,
        owner
      } = await loadFixture(deployTradingCardFixture);

      await time.increase(7 * 24 * 60 * 61);

      await expect(uncutsTradingCard.advanceEpoch()).to.emit(uncutsTradingCard, 'EpochAdvanced').withArgs(2);

      expect(await uncutsTradingCard.epoch()).to.be.equal(2);
        
    });

    it("Should release card and return valid metadata url", async function () {

      const { 
        uncutsTradingCard, 
        otherAccount, 
        thirdAccount,
        owner
      } = await loadFixture(deployTradingCardFixture);

      await expect(uncutsTradingCard.releaseCardTo(otherAccount.address)).to.not.be.rejected;

      expect(await uncutsTradingCard.uri(1)).to.be.equal(
        `${metaDataPrefix}1${metaDataSuffix}1`
      )

        
    });

  })

  

})