pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract seaMonsterNFT is ERC1155, Ownable,ReentrancyGuard{
    constructor()ERC1155(""){}
    address public gameAddress;
    bool multiEntrLock;
    function setGameAdd(address _new)external onlyOwner{
        gameAddress=_new;
    }

    function mintNFT(address account,uint256 id)external onlyGame{
        _mint(account,id,1,"");
    }
    function burnTrophy(uint256 id, uint256 amount)external nonReentrant{
        require(id>0 && id<7,"1~6");
        _burn(msg.sender,id,amount);
        if(id==1){
            payable(msg.sender).transfer(5*10**17*amount);
        }else if(id==2){
            payable(msg.sender).transfer(8*10**17*amount);
        }else if(id==3){
            payable(msg.sender).transfer(12*10**17*amount);
        }else if(id==4){
            payable(msg.sender).transfer(2*10**18*amount);
        }else if(id==5){
            payable(msg.sender).transfer(4*10**18*amount);
        }else{
            payable(msg.sender).transfer(5*10**18*amount);
        }
    }

    modifier onlyGame{
        require(msg.sender==gameAddress,"only by game");
        _;
    }
    receive() external payable {}
    fallback() external payable {}
}