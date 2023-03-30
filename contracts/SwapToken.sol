// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {IERC20} from "./IERC.sol";

import "@opengsn/contracts/src/ERC2771Recipient.sol";



contract SwapToken is ERC2771Recipient {

    address owner;
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint decimal = 1e18;

    AggregatorV3Interface internal priceFeedDai;
    AggregatorV3Interface internal priceFeedUni;
    AggregatorV3Interface internal priceFeedEth;

    constructor() {
        owner = msg.sender;
        priceFeedDai = AggregatorV3Interface(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
        priceFeedEth = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        priceFeedUni = AggregatorV3Interface(0x553303d460EE0afB37EdFf9bE42922D8FF63220e);
        tokenA = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        tokenB = IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "not owner");
        _;
    }

    function getLatestPrice(AggregatorV3Interface priceFeed) public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price/1e8;
    }

    function swapDaiForUni (uint _amountToSwap) public returns(bool isSwapped) {
        (int priceOfDai) = getLatestPrice(priceFeedDai);
        (int priceOfUni) = getLatestPrice(priceFeedUni);
        uint priceOfDaiUSD = uint(priceOfDai);
        uint priceOfUniUSD = uint(priceOfUni);
        uint oneDaiToUniPrice = priceOfDaiUSD/priceOfUniUSD;
        uint amountToReceive = _amountToSwap * oneDaiToUniPrice;
        bool successful = tokenA.approve(address(this), _amountToSwap);
        bool debit = tokenA.transferFrom(msg.sender, address(this), _amountToSwap);
        bool credit = tokenB.transfer(msg.sender, amountToReceive);
        require(successful, "could not approve amount");
        require(debit, "transfer of token A failed");
        require(credit, "transfer of token B failed");
        isSwapped = true;
    }

    function swapUniForDai (uint _amountToSwap) public returns(bool isSwapped) {
        (int priceOfUni) = getLatestPrice(priceFeedUni);
        (int priceOfDai) = getLatestPrice(priceFeedDai);
        uint priceOfUniUSD = uint(priceOfUni);
        uint priceOfDaiUSD = uint(priceOfDai);
        uint oneUniToDaiPrice = priceOfUniUSD/priceOfDaiUSD;
        uint amountToReceive = _amountToSwap * oneUniToDaiPrice;
        bool successful = tokenB.approve(address(this), _amountToSwap);
        bool debit = tokenB.transferFrom(msg.sender, address(this), _amountToSwap);
        bool credit = tokenA.transfer(msg.sender, amountToReceive);
        require(successful, "could not approve amount");
        require(debit, "transfer of token B failed");
        require(credit, "transfer of token A failed");
        isSwapped = true;
    } 

    function swapEthForDai (uint _amountToSwap) public payable returns(bool isSwapped) {
        (int priceOfEth) = getLatestPrice(priceFeedEth);
        (int priceOfDai) = getLatestPrice(priceFeedDai);
        uint priceOfEthUSD = uint(priceOfEth);
        uint priceOfDaiUSD = uint(priceOfDai);
        uint oneEthToDaiPrice = priceOfEthUSD/priceOfDaiUSD;
        uint amountToReceive = _amountToSwap * oneEthToDaiPrice;
        bool debit = msg.value == _amountToSwap;
        address payable receiver = payable (address(this));
        receiver.transfer(msg.value);
        bool pay = tokenA.transferFrom(msg.sender, address(this), amountToReceive);
        require(debit, "transfer of token A failed");
        require(pay, "transfer of token B failed");
        isSwapped = true;
    }

    receive() external payable{}

    fallback() external{}

    function withdrawETH (uint _value) public {}
}