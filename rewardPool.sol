pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract rewardPool is Ownable{
    IERC20 TokenA;
    IERC20 TokenB;
    mapping (address =>bool)public gameAddress;
    event cliamed(address player, uint amountA, uint amountB);
    function setTokenAddress(address _tokenA,address _tokenB)external onlyOwner{
        TokenA=IERC20(_tokenA);
        TokenB=IERC20(_tokenB);
    }
    function setGameAddress(address newGameAddress)external onlyOwner{
        gameAddress[newGameAddress]=true;
    }
    modifier onlyGame(){// can only contoled by game contract.
        require(gameAddress[msg.sender],"can only controled by game");
        _;
    }
    function claimReward(address player, uint amountA,uint amountB)external onlyGame{ //A:GEM B:SPICE
        if(amountA!=0){
            TokenA.transfer(player,amountA);
        }
        if(amountB!=0){
            TokenB.transfer(player,amountB);
        }
        emit cliamed(player,amountA,amountB);
    }
}