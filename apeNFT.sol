pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/Ipair.sol";

contract apeNFT is ERC721, Ownable{
    using SafeMath for uint256;
    IERC20 gemToken=IERC20(0x6F4507Ad0975e3AA4836706000a9Fa7789736d92);
    IERC20 spiceToken=IERC20(0xEdb21A81c0Fc6C1541f49Ea40371C7aF5aCa70f7);
    IERC20 busdToken=IERC20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    Ipair gemPair=Ipair(0xAf3D198a61A6B532820Acb56C59379db2ad07E4E);
    Ipair spicePair=Ipair(0x7F5BC1027F475a6FF4dB9FbAEe6760A44Cc7a545);
    address rewardPool=0x89A5CF46e124248abdaaD7F4ff01f61F4Ed58530;
    address devWallet=0x8526A4A69147b7A237679BcF8b9B1591289CEd08;
    uint256 private NFTIDcount;
    constructor()ERC721("Monkey Spice","MS"){}
    struct ape{
        uint8 stars; //1~6
        uint8 theType; //同一個星級裡面的哪一隻
        uint8 occupation; //1=captain 2=crew
        uint32 power;
    }
    mapping(uint256=>ape) idToApe;
    function NFTinfo(uint256 id)public view returns(ape memory){
        return idToApe[id];
    }
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(9975);
        amountIn = (numerator / denominator).add(1);
    }
    //function calFee(uint8 token,uint usdAmount)public view returns(uint amountIn){ }
    function charge(uint gemValu,uint spiceValu,uint busd)private{
        if(gemValu!=0){
            (uint112 reserveIn,uint112 reserveOut,)=gemPair.getReserves(); //需確認reserve0和1正反
            uint fee=getAmountIn(gemValu*10**18,reserveIn,reserveOut);
            gemToken.transferFrom(msg.sender,rewardPool,fee);
        }
        if(spiceValu!=0){
            (uint112 reserveOut,uint112 reserveIn,)=spicePair.getReserves(); //需確認reserve0和1正反
            uint fee=getAmountIn(spiceValu*10**18,reserveIn,reserveOut);
            spiceToken.transferFrom(msg.sender,rewardPool,fee);
        }
        if(busd!=0){
            busdToken.transferFrom(msg.sender,devWallet,busd*10**18);
        }
    }
    function mintCaptain()external{
        charge(84,0,36);
        NFTIDcount++;
        uint256 newID=NFTIDcount;
        ape memory temp;
        temp.occupation=1;
        _mint(msg.sender,newID);
        uint256 ran=uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp,block.number,newID,block.coinbase,msg.sender)))%1000;
        if (ran<600){
            ran/=200;
            temp.stars=1;
            temp.power=250;
            if(ran==0){/*普通1號*/}else if(ran==1){/*普通2號*/}else{/*普通3號*/}
        }else if(ran<810){
            temp.stars=2;
            temp.power=350;
            ran=(ran-600)/70;
            if(ran==0){/*罕見1號*/}else if(ran==1){/*罕見2號*/}else{/*罕見3號*/}
        }else if(ran<910){
            temp.stars=3;
            temp.power=450;
            ran=(ran-810)/50;
            if(ran==0){/*稀有1號*/}else{/*稀有2號*/}
        }else if(ran<990){
            temp.stars=4;
            temp.power=550;
            ran=(ran-910)/40;
            if(ran==0){/*史詩1號*/}else{/*史詩2號*/}
        }else if(ran<999){
            require(ran>=990,"invaild random");
            temp.stars=5;
            temp.power=750;
            ran=0;
            /*傳奇1號*/
        }else{
            require(ran==999,"invaild random");
            temp.stars=6;
            temp.power=1000;
            ran=0;
            /*神秘1號*/}
        temp.theType=uint8(ran);
        idToApe[newID]=temp;
    }
    function mintCrew()external{
        charge(28,0,12);
        NFTIDcount++;
        uint256 newID=NFTIDcount;
        ape memory temp;
        temp.occupation=2;
        _mint(msg.sender,newID);
        uint256 ran=uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp,block.number,newID,block.coinbase,msg.sender)))%1000;
        if (ran<600){
            temp.stars=1;
            temp.power=100;
            ran/=60;
            if(ran==0){/*普通1號*/}else if(ran==1){/*普通2號*/}else if(ran==2){/*普通3號*/}else if(ran==3){
            /*普通4號*/}else if(ran==4){/*普通5號*/}else if(ran==5){/*普通6號*/}else if(ran==6){
            /*普通7號*/}else if(ran==7){/*普通8號*/}else if(ran==8){/*普通9號*/}else{
            /*普通10號*/}
        }else if(ran<810){
            temp.stars=2;
            temp.power=200;
            ran=(ran-600)/42;
            if(ran==0){/*罕見1號*/}else if(ran==1){/*罕見2號*/}else if(ran==2){/*罕見3號*/}else if(ran==3){
            /*罕見4號*/}else{/*罕見5號*/}
        }else if(ran<910){
            temp.stars=3;
            temp.power=300;
            ran=(ran-810)/25;
            if(ran==0){/*稀有1號*/}else if(ran==1){/*稀有2號*/}else if(ran==2){/*稀有3號*/}else{/*稀有4號*/}
        }else if(ran<990){
            temp.stars=4;
            temp.power=450;
            ran=(ran-910)/26;
            if(ran==0){/*史詩1號*/}else if(ran==1){/*史詩2號*/}else{/*史詩3號*/}
        }else if(ran<999){
            temp.stars=5;
            temp.power=600;
            ran=(ran-990)/4;
            if(ran==0){/*傳奇1號*/}else{/*傳奇2號*/}
        }else{
            require(ran==999,"invaild random");
            temp.stars=6;
            temp.power=750;
            ran=0;
            /*神秘1號*/}
        temp.theType=uint8(ran);
        idToApe[newID]=temp;
    }
    //chimp
    mapping (address=>uint)ownChimp;
    function viewChimp(address account)external view returns(uint){
        return ownChimp[account];
    }
    function mintChimp()external payable{
        charge(0,15,5);
        unchecked{ownChimp[msg.sender]++;}
    }
    //by game function
    modifier onlyByGame {
        require(msg.sender==gameAddress); 
        _;
    }
    function dieInBattle(uint256 id)external onlyByGame{
        _burn(id);
    }

    //over ride  
    function _transfer(address from,address to,uint256 tokenId) internal override{
        require(_msgSender()==gameAddress || _msgSender()==marketAddress,"only transfer by market");
        super._transfer(from, to, tokenId);
    }
    // for operator
    address gameAddress;
    address marketAddress;
    function setGameAddress(address newGameAddress,address newMarketAddress)external onlyOwner{
        gameAddress=newGameAddress;
        marketAddress=newMarketAddress;
    }
}