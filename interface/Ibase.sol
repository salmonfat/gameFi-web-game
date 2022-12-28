pragma solidity ^0.8.0;

interface Ibase{
    function earnBanana(address account,uint256 increase)external;
    function useBanana(address account,uint256 decrease)external;
    function viewBuff(address account, uint8 buffNo)external view returns(uint8);
    function viewBuildingLV(address account,uint8 buildNo)external view returns(uint8);
}