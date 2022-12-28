pragma solidity ^0.8.0;
import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IapeNFT is IERC721{
    struct ape{
        uint8 stars;
        uint8 theType;
        uint8 occupation; //1=captain 2=crew
        uint32 power;
    }
    function NFTinfo(uint256 id)external view returns(ape memory);
    function dieInBattle(uint256 id)external;
    function viewChimp(address account)external view returns(uint);
}