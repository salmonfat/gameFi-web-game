pragma solidity ^0.8.0;

interface Imarket{
    function isSelling(uint id)external view returns(bool);
}