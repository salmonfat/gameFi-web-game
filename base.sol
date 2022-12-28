// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IrewardPool.sol";
import "./interface/IapeNFT.sol";

contract base is Ownable{
    IapeNFT apeNFT=IapeNFT(0xE7cD75B29aFe802D30722bade3203d1B27769d94);
    IERC20 gem=IERC20(0x6F4507Ad0975e3AA4836706000a9Fa7789736d92);
    IERC20 spice=IERC20(0xEdb21A81c0Fc6C1541f49Ea40371C7aF5aCa70f7);
    IrewardPool rewardPool=IrewardPool(0x89A5CF46e124248abdaaD7F4ff01f61F4Ed58530);
    constructor(){}

    mapping(address=>uint256)public ownBanana;
        // throneRoom; 0
        // livingQuarters; 1
        // monkeyTavern; 2
        // researchArea; 3
        // repairBay; 4
        // casino; 5
        // GathersBay; 6
        // spiceFarm; 7
    mapping (address=> uint8[8]) public playerBaseLV;
    mapping (address=>bool[8]) public isBuilding;
    mapping (address=>uint256[8]) public buildTime;

    function viewBuildingLV(address account,uint8 buildNo)external view returns(uint8){
        return playerBaseLV[account][buildNo];
    }
    function upBuilding(uint8 buildNo,uint256 monkey)private{
        require(isBuilding[msg.sender][buildNo]==false);
        isBuilding[msg.sender][buildNo]=true;
        require(freeMonkey(msg.sender)>=monkey,"less monkey");
        require(monkey>0 && monkey<11,"1~10");
        chimpBuild[msg.sender][buildNo]+=monkey;
        buildTime[msg.sender][buildNo]=block.timestamp+(2 days)*(100-monkey*5)/100;
    }
    function finishBuilding(uint8 buildNo)private{
        require(isBuilding[msg.sender][buildNo]==true);
        require(block.timestamp>=buildTime[msg.sender][buildNo]);
        isBuilding[msg.sender][buildNo]=false;
        chimpBuild[msg.sender][buildNo]=0;
    }
    //research area
    function upgradeResearch(uint256 monkey)external{  
        uint8 temp=playerBaseLV[msg.sender][3];
        require(temp<10,"highest lv");
        upBuilding(3,monkey);
        uint256 price=(uint256(temp/2)*50+100)*uint256(100-viewBuff(msg.sender,1))/100;
        gem.transferFrom(msg.sender,address(rewardPool),price*10**18);
        spice.transferFrom(msg.sender,address(rewardPool),price*10**18);
    }
    function finishUpResearch(uint8 choose)external{ // 1=eco 2=ship 3=crew
        require(choose>0 && choose<4,"1~3");
        finishBuilding(3);
        uint8 temp=playerBaseLV[msg.sender][3];
        if (temp==0){
            if(choose==1){
                unchecked{techBuff[msg.sender][0]+=5;}
            }else if(choose==2){
                unchecked{techBuff[msg.sender][3]+=3;}
            }else{
                unchecked{techBuff[msg.sender][4]+=5;}
            }
        }else if(temp==1){
            if(choose==1){
                unchecked{techBuff[msg.sender][1]+=10;}
            }else if(choose==2){
                unchecked{techBuff[msg.sender][5]+=7;}
            }else{
                unchecked{techBuff[msg.sender][3]+=5;}
            }
        }else if(temp==2){
        }else if(temp==3){
            if(choose==1){
                unchecked{techBuff[msg.sender][2]+=5;}
            }else if(choose==2){
                unchecked{techBuff[msg.sender][5]+=5;}
            }else{
                unchecked{techBuff[msg.sender][3]+=5;}
            }
        }else if(temp==4){
        }else if(temp==5){

        }else if(temp==6){

        }else if(temp==7){

        }else{

        }unchecked{playerBaseLV[msg.sender][3]++;}
    }

    //monkey tavern
    function upgradeMonkeyTavern(uint256 monkey)external{
        uint8 temp=playerBaseLV[msg.sender][2];
        require(temp<5,"highest lv");
        upBuilding(2,monkey);
        if (temp<=1){
            ownBanana[msg.sender]-=100;
            spice.transferFrom(msg.sender,address(rewardPool),100*10**18);
        }else if(temp==2){
            ownBanana[msg.sender]-=150;
            spice.transferFrom(msg.sender,address(rewardPool),150*10**18);
        }else{
            ownBanana[msg.sender]-=200;
            spice.transferFrom(msg.sender,address(rewardPool),200*10**18);
        }
    }
    function finishUpTavern()external{
        finishBuilding(2);
        uint8 temp=playerBaseLV[msg.sender][2];
        unchecked{
        if(temp==0){
            techBuff[msg.sender][3]+=3;
        }else if(temp==1){
            techBuff[msg.sender][3]+=5;
        }else if(temp==2){
            techBuff[msg.sender][3]+=3;
        }else if(temp==3){
            techBuff[msg.sender][3]+=5;
        }else{
            techBuff[msg.sender][3]+=7;
        }
        playerBaseLV[msg.sender][2]++;}
    }

    // throne
    function upgradeThroneCasino(uint8 buildNo, uint256 monkey)external{ //0:throne  5:casino
        require(buildNo==0 || buildNo==5,"0,5");
        uint8 temp=playerBaseLV[msg.sender][buildNo];
        require(temp<10,"highest lv");
        upBuilding(buildNo,monkey);  
        uint256 price=uint256(temp/2)*50+200;
        spice.transferFrom(msg.sender,address(rewardPool),price*10**18);
        gem.transferFrom(msg.sender,address(rewardPool),price*10**18);
    }  
    function finishUpThrone()external{
        finishBuilding(0);
        uint8 temp=playerBaseLV[msg.sender][0];
        if(temp==2){
                techBuff[msg.sender][7]+=2;
            }else if(temp==5){
                techBuff[msg.sender][7]+=3;
            }else if(temp==9){
                techBuff[msg.sender][7]+=5;
            }else{
                techBuff[msg.sender][7]++;
            }
        unchecked{playerBaseLV[msg.sender][0]++;}
    }
    
    //repair bay
    function upgradeRepairBay(uint256 monkey)external{
        uint8 temp=playerBaseLV[msg.sender][4];
        require(temp<10,"highest lv");
        upBuilding(4,monkey);
        uint256 price=uint256(temp/2)*50+100;
        ownBanana[msg.sender]-=price;
        gem.transferFrom(msg.sender,address(rewardPool),price*10**18);
    }
    function finishRepair()external{
        finishBuilding(4);
        uint8 temp=playerBaseLV[msg.sender][4];
        if(temp==2 || temp==5 || temp==8){
                techBuff[msg.sender][5]+=5;
            }else if(temp==9){
                techBuff[msg.sender][5]+=7;
            }else{
                techBuff[msg.sender][5]+=3;
            }
        unchecked{playerBaseLV[msg.sender][4]++;}
    }
    
    function upgradeGathersBay(uint256 monkey)external{
        uint8 temp=playerBaseLV[msg.sender][6];
        require(temp<10,"highest lv");
        upBuilding(6,monkey);
        uint256 price=uint256(temp/2)*50+200;
        ownBanana[msg.sender]-=price;
        spice.transferFrom(msg.sender,address(rewardPool),price*10**18);
    }
    function upgradeSpiceFarm(uint256 monkey)external{
        uint8 temp=playerBaseLV[msg.sender][7];
        require(temp<10,"highest lv");
        upBuilding(7,monkey);
        uint256 price=uint256(temp/2)*50+200;
        ownBanana[msg.sender]-=price;
        gem.transferFrom(msg.sender,address(rewardPool),price*10**18);
    }
    function finishCasinoGatherFarm(uint8 buildNo)external{
        require(buildNo>4 && buildNo<8,"5~7");
        finishBuilding(buildNo);
        uint8 temp=playerBaseLV[msg.sender][buildNo];
        if(buildNo==5){
            if(temp==2 || temp==5){
                techBuff[msg.sender][6]+=3;
            }else if(temp==8){
                techBuff[msg.sender][6]+=5;
            }else if(temp==9){
                techBuff[msg.sender][6]+=10;
            }else{
                techBuff[msg.sender][6]++;
            }
        }else if(buildNo==6){
            if(temp==2 || temp==5){
                techBuff[msg.sender][0]+=3;
            }else if(temp==8){
                techBuff[msg.sender][0]+=5;
            }else if(temp==9){
                techBuff[msg.sender][0]+=10;
            }else{
                techBuff[msg.sender][0]++;
            }
        }else{
            if(temp==2 || temp==5){
                techBuff[msg.sender][2]+=3;
            }else if(temp==8){
                techBuff[msg.sender][2]+=5;
            }else if(temp==9){
                techBuff[msg.sender][2]+=10;
            }else{
                techBuff[msg.sender][2]++;
            }
        }
        claimReward(buildNo-4);
        unchecked{playerBaseLV[msg.sender][buildNo]++;}
    }

    //little monkey
    mapping (address=> uint256[8])chimpBuild;
    function freeMonkey(address account)public view returns(uint){
        uint256[8] memory chTemp=chimpBuild[account];
        uint256 working=0;
        for(uint i=0;i<chTemp.length;i++){
            working+=chTemp[i];
        }
        return apeNFT.viewChimp(account)-working;
    }

    //passive income
    mapping(address=>uint256[3])lastClaimTime; //0:casino   1:gather  2:farm
    /* passive building no 
    1=casino 
    2=gather 
    3=farm*/
    function claimReward(uint8 buildingNo)public{
        require(buildingNo>0 && buildingNo<4,"1~3");
        if(lastClaimTime[msg.sender][buildingNo-1]!=0){
            uint reward=calculateReward(msg.sender,buildingNo);
            if(buildingNo==1){ //gem
                rewardPool.claimReward(msg.sender,reward,0);
            }else if(buildingNo==2){
                ownBanana[msg.sender]+=reward;
            }else{ //spice
                rewardPool.claimReward(msg.sender,0,reward);
            }
        }
        lastClaimTime[msg.sender][buildingNo-1]=block.timestamp;
    }
    function calculateReward(address account, uint8 buildingNo)public view returns(uint256){ 
        uint256 _last=lastClaimTime[account][buildingNo-1];
        uint256 reward=(block.timestamp-_last);
        if(buildingNo>0 && buildingNo<4 && _last!=0){
            if(buildingNo==1){
                reward=reward*uint(100+viewBuff(msg.sender,6))*10**16;
            }else if(buildingNo==2){
                reward=reward*uint(100+viewBuff(msg.sender,0))/100;
            }else{
                reward=reward*uint(100+viewBuff(msg.sender,2))*10**16;
            }
            return (reward/864);
        }
        return 0;
    }

    //interact with game
    address gameAdd;
    address marketAdd;
    function setGameAdd(address _newGame,address newMarket)external onlyOwner{
        gameAdd=_newGame;
        marketAdd=newMarket;
    }
    modifier onlyByGame {
        require(msg.sender==gameAdd || msg.sender==marketAdd,"game"); 
        _;
    }
    function earnBanana(address account,uint256 increase)external onlyByGame{
        ownBanana[account]+=increase;
    }
    function useBanana(address account,uint256 decrease)external onlyByGame{
        ownBanana[account]-=decrease;
    }

    //technology buff
        // bananaGather; 0
        // researchDiscount; 1
        // spiceFarm; 2
        // shipSpeed; 3
        // crewStrength; 4  
        // repairTime; 5
        // casino; 6
        // mission reward; 7
    mapping(address=>uint8[8])public techBuff;
    function viewBuff(address account, uint8 buffNo)public view returns(uint8){
        return techBuff[account][buffNo];
    }
}