pragma solidity ^0.8.0;

interface IrewardPool{
    function claimReward(address player, uint amountA, uint amountB)external;
}