// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/Ibase.sol";
import "./interface/IrewardPool.sol";
import "./interface/IseaMonsterNFT.sol";
import "./interface/IapeNFT.sol";
import "./interface/Imarket.sol";

contract game is Ownable{
    IseaMonsterNFT seaMonsterNFT=IseaMonsterNFT(0x5B0148BF949815C1C1E169c5D5BAE555f9F8D808);
    IapeNFT apeNFT=IapeNFT(0xE7cD75B29aFe802D30722bade3203d1B27769d94);
    Ibase base= Ibase(0x56Bf3E882b7F8C048d6542EFd5F7e53933F3F6c6);
    Imarket market= Imarket(0x4fC6b3bf64A895310B09D360504CEA0fbEE572f8);
    IrewardPool rewardPool=IrewardPool(0x89A5CF46e124248abdaaD7F4ff01f61F4Ed58530);
    IERC20 gem=IERC20(0x6F4507Ad0975e3AA4836706000a9Fa7789736d92);
    IERC20 spice=IERC20(0xEdb21A81c0Fc6C1541f49Ea40371C7aF5aCa70f7);
    constructor(){}
    
    struct teamDetail{
        uint8 theType; //1:mercham  2:gover  3:monster   0:no mission
        uint8 difficalty; //1~5
        uint8 winRate;
        uint256 unlockTime;
        uint256[] members;
    }
    mapping(address=>uint8[3]) public shipLV;
    mapping (address=>uint16[3])public shipEXP;
    mapping (address=>teamDetail[3])teamInfo;
    mapping(address=>uint256[3])public shipRepairTime;
    mapping (uint256=>bool) public NftMission;

    function viewTeam(address account,uint8 shipNo)public view returns(teamDetail memory){
        return teamInfo[account][shipNo-1];
    }
    function maxXP(uint8 lv)private pure returns(uint16){
        uint16 max;
        if(lv==0){
            max=100;
        }else if(lv==1){
            max=225;
        }else if(lv==2){
            max=375;
        }else if(lv==3){
            max=550;
        }else if(lv==4){
            max=750;
        }else if(lv==5){
            max=970;
        }else if(lv==6){
            max=1210;
        }else if(lv==7){
            max=1470;
        }else if(lv==8){
            max=1750;
        }else if(lv==9){
            max=2050;
        }else if(lv==10){
            max=2380;
        }else if(lv==11){
            max=2740;
        }else if(lv==12){
            max=3140;
        }else if(lv==13){
            max=3580;
        }else if(lv==14){
            max=4060;
        }else if(lv==15){
            max=4590;
        }else if(lv==16){
            max=5170;
        }else if(lv==17){
            max=5810;
        }else{
            max=6510;
        } return max;
    }
    function spend(uint _gem,uint _spice,uint _banana)private{
        if(_gem!=0){
            gem.transferFrom(msg.sender,address(rewardPool),_gem*10**18);
        }
        if(_spice!=0){
            spice.transferFrom(msg.sender,address(rewardPool),_spice*10**18);
        }
        if(_banana!=0){
            base.useBanana(msg.sender,_banana);
        }
    }
    function upgradeShip(uint8 shipNo)external{
        require(shipNo>0 && shipNo<4,"1~3");
        uint8 tempLV;
        tempLV=shipLV[msg.sender][shipNo-1];
        require(tempLV<19);
        require(shipEXP[msg.sender][shipNo-1]==maxXP(tempLV),"XP");
        if(tempLV==0){
            spend(25,25,25);
        }else if(tempLV==1){
            spend(30,30,25);
        }else if(tempLV==2){
            spend(30,35,30);
        }else if(tempLV==3){
            spend(35,35,35);
        }else if(tempLV==4){
            spend(40,40,35);
        }else if(tempLV==5){
            spend(40,45,40);
        }else if(tempLV==6){
            spend(45,45,45);
        }else if(tempLV==7){
            spend(50,50,45);
        }else if(tempLV==8){
            spend(50,55,50);
        }else if(tempLV==9){
            spend(55,55,55);
        }else if(tempLV==10){
            spend(60,60,55);
        }else if(tempLV==11){
            spend(60,65,60);
        }else if(tempLV==12){
            spend(65,65,65);
        }else if(tempLV==13){
            spend(70,70,65);
        }else if(tempLV==14){
            spend(70,75,70);
        }else if(tempLV==15){
            spend(75,75,75);
        }else if(tempLV==16){
            spend(80,80,75);
        }else if(tempLV==17){
            spend(80,85,80);
        }else{
            spend(90,85,85);
        }
        shipLV[msg.sender][shipNo-1]++;
    }
    function plusEXP(uint8 shipNo, uint16 earnXP)private{
        uint8 theLV; uint16 maxEXP;
        theLV=shipLV[msg.sender][shipNo-1];
        maxEXP=maxXP(theLV);
        if (shipEXP[msg.sender][shipNo-1]+earnXP>=maxEXP){
            shipEXP[msg.sender][shipNo-1]=maxEXP;
        }else{
            shipEXP[msg.sender][shipNo-1]+=earnXP;
        }
    }

    // main game
    function startMission(uint256[] memory member, uint8 lv, uint8 shipNo, uint8 missionNo)external{ //1:mer 2:gov 3:sea
        require(shipNo>0 && shipNo<4,"1~3");
        require(missionNo>0 && missionNo<4,"1~3");
        if(missionNo==3){
            require(lv>0 && lv<7,"1~6");
            require(base.viewBuildingLV(msg.sender,3)>=5,"5");
        }else{require(lv>0 && lv<6,"1~5");}
        if(missionNo==2){require(base.viewBuildingLV(msg.sender,3)>=3,"3");}
        require(checkMissionOpen(missionNo,lv),"not open");
        require(block.timestamp>shipRepairTime[msg.sender][shipNo-1],"re");
        require(teamInfo[msg.sender][shipNo-1].theType==0,"st");
        teamDetail memory temp;
        temp.difficalty=lv; temp.members=member; temp.theType=missionNo;
        temp.unlockTime=block.timestamp+(((uint(lv)+3)*1 hours/2)*uint256(100-base.viewBuff(msg.sender,3))/100);
        uint32 teamPower=0; uint32 miniPower; uint maxMem;
        maxMem=(shipLV[msg.sender][shipNo-1]+8)/2;
        require(maxMem>=member.length,"mem");
        for (uint i=0;i<member.length;i++){
            if(i==0){
                require(apeNFT.NFTinfo(member[0]).occupation==1,"ca");
            }else{
                require(apeNFT.NFTinfo(member[i]).occupation==2,"cr");
            }
            require(!NftMission[member[i]],"mi");
            require(!market.isSelling(member[i]),"se");
            NftMission[member[i]]=true;
            require(apeNFT.ownerOf(member[i])==msg.sender,"ow");
            teamPower+=apeNFT.NFTinfo(member[i]).power;
        }
        teamPower=teamPower*uint32(100+base.viewBuff(msg.sender,4))/100;
        if(missionNo==1){
            if(lv==1){
                miniPower=550;
                temp.winRate=calcuWinRate(75,85,miniPower,750,teamPower);
            }else if(lv==2){
                miniPower=650;
                temp.winRate=calcuWinRate(65,85,miniPower,850,teamPower);
            }else if(lv==3){
                miniPower=750;
                temp.winRate=calcuWinRate(60,75,miniPower,1050,teamPower);
            }else if(lv==4){
                miniPower=1000;
                temp.winRate=calcuWinRate(55,70,miniPower,1200,teamPower);
            }else{
                miniPower=1200;
                temp.winRate=calcuWinRate(50,60,miniPower,1400,teamPower);
            }
        }else if(missionNo==2){
            if(lv==1){
                miniPower=600;
                temp.winRate=calcuWinRate(65,75,miniPower,800,teamPower);
            }else if(lv==2){
                miniPower=750;
                temp.winRate=calcuWinRate(55,65,miniPower,950,teamPower);
            }else if(lv==3){
                miniPower=900;
                temp.winRate=calcuWinRate(50,60,miniPower,1100,teamPower);
            }else if(lv==4){
                miniPower=1250;
                temp.winRate=calcuWinRate(45,55,miniPower,1450,teamPower);
            }else{
                miniPower=1500;
                temp.winRate=calcuWinRate(40,50,miniPower,1700,teamPower);
            }
        }else{
            if(lv==1){
                miniPower=800;
                temp.winRate=calcuWinRate(65,75,miniPower,1000,teamPower);
            }else if(lv==2){
                miniPower=1000;
                temp.winRate=calcuWinRate(55,65,miniPower,1200,teamPower);
            }else if(lv==3){
                miniPower=1200;
                temp.winRate=calcuWinRate(50,60,miniPower,1400,teamPower);
            }else if(lv==4){
                miniPower=1400;
                temp.winRate=calcuWinRate(45,55,miniPower,1600,teamPower);
            }else if(lv==5){
                miniPower=1500;
                temp.winRate=calcuWinRate(40,50,miniPower,1700,teamPower);
            }else{
                miniPower=1800;
                temp.winRate=calcuWinRate(25,35,miniPower,2000,teamPower);
            }
        }
        require(teamPower>=miniPower,"weak");
        teamInfo[msg.sender][shipNo-1]=temp;
    }
    uint count;
    function finishMission(uint8 shipNo)external{
        teamDetail memory temp; bool win;
        temp=teamInfo[msg.sender][shipNo-1];
        require(temp.unlockTime<=block.timestamp);
        require(temp.theType>0 && temp.theType<4,"no mission");
        unchecked{count++;}
        uint256 ran=uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp,block.number,count,block.coinbase,msg.sender)))%100;
        win=uint256(temp.winRate-1)>=ran;
        for(uint i=0;i<temp.members.length;i++){
            NftMission[temp.members[i]]=false;
        }
        if(temp.theType==1){
                if(win){
                plusEXP(shipNo,(uint16(temp.difficalty)*15));
                if(temp.difficalty==1){
                    getReward(75,25,0);
                }else if(temp.difficalty==2){
                    getReward(150,50,0);
                }else if(temp.difficalty==3){
                    getReward(200,80,0);
                }else if(temp.difficalty==4){
                    getReward(120,120,120);
                }else{
                    getReward(180,180,180);
                }
            }else{
                plusEXP(shipNo,(uint16(temp.difficalty)*15/2));
                ran=uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp)))%100;
                if(temp.difficalty==1){
                    if(ran<50){dead(shipNo,1);}
                }else if(temp.difficalty==2){
                    if(ran<55){dead(shipNo,1);}
                }else if(temp.difficalty==3){
                    if(ran<60){dead(shipNo,1);}
                }else if(temp.difficalty==4){
                    if(ran<50){dead(shipNo,1);}else if(ran<65){dead(shipNo,2);}
                }else{
                    if(ran<55){dead(shipNo,1);}else if(ran<70){dead(shipNo,2);}
                }
            }
        }else if(temp.theType==2){
            if(win){
                if(temp.difficalty==1){
                    plusEXP(shipNo,30);
                    getReward(0,50,75);
                }else if(temp.difficalty==2){
                    plusEXP(shipNo,50);
                    getReward(0,80,100);
                }else if(temp.difficalty==3){
                    plusEXP(shipNo,70);
                    getReward(0,120,150);
                }else if(temp.difficalty==4){
                    plusEXP(shipNo,85);
                    getReward(0,170,200);
                }else{
                    plusEXP(shipNo,100);
                    getReward(0,250,350);
                }
            }else{
                ran=uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp)))%100;
                if(temp.difficalty==1){
                    plusEXP(shipNo,15);
                    if(ran<50){dead(shipNo,1);}
                }else if(temp.difficalty==2){
                    plusEXP(shipNo,25);
                    if(ran<40){dead(shipNo,1);}else if(ran<60){dead(shipNo,2);}
                }else if(temp.difficalty==3){
                    plusEXP(shipNo,35);
                    if(ran<60){dead(shipNo,1);}else{dead(shipNo,2);}
                }else if(temp.difficalty==4){
                    plusEXP(shipNo,42);
                    if(ran<50){dead(shipNo,1);}else{dead(shipNo,2);}
                }else{
                    plusEXP(shipNo,50);
                    if(ran<50){dead(shipNo,1);}else if(ran<75){dead(shipNo,2);}else{dead(shipNo,3);}
                }
            }
        }else{
            if(win){
                if(temp.difficalty==1){
                    plusEXP(shipNo,30);
                }else if(temp.difficalty==2){
                    plusEXP(shipNo,60);
                }else if(temp.difficalty==3){
                    plusEXP(shipNo,80);
                }else if(temp.difficalty==4){
                    plusEXP(shipNo,120);
                }else if(temp.difficalty==5){
                    plusEXP(shipNo,150);
                }else{
                    plusEXP(shipNo,220);
                }
                seaMonsterNFT.mintNFT(msg.sender,temp.difficalty);
            }else{
                ran=uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp)))%100;
                if(temp.difficalty==1){
                    plusEXP(shipNo,15);
                    if(ran<50){dead(shipNo,1);}
                }else if(temp.difficalty==2){
                    plusEXP(shipNo,25);
                    if(ran<40){dead(shipNo,1);}else if(ran<60){dead(shipNo,2);}
                }else if(temp.difficalty==3){
                    plusEXP(shipNo,35);
                    if(ran<60){dead(shipNo,1);}else{dead(shipNo,2);}
                }else if(temp.difficalty==4){
                    plusEXP(shipNo,42);
                    if(ran<50){dead(shipNo,1);}else{dead(shipNo,2);}
                }else if(temp.difficalty==5){
                    plusEXP(shipNo,50);
                    if(ran<50){dead(shipNo,1);}else if(ran<75){dead(shipNo,2);}else{dead(shipNo,3);}
                }else{
                    plusEXP(shipNo,110);
                    if(ran<50){dead(shipNo,1);}else if(ran<75){dead(shipNo,2);}else{dead(shipNo,3);}
                }
            }
        }
        delete teamInfo[msg.sender][shipNo-1];
        shipRepairTime[msg.sender][shipNo-1]=block.timestamp+((uint256(temp.difficalty)+3)*1 hours)/2*uint256(100-base.viewBuff(msg.sender,5))/100;
    }

    function dead(uint8 shipNo, uint8 dieNum)private{
        uint256[] memory temp=teamInfo[msg.sender][shipNo-1].members;
        uint denominator;
        uint[] memory deadrate=new uint[](temp.length);
        uint[] memory tempRate=new uint[](temp.length);
        uint ran=uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp)));
        for(uint i=0;i<temp.length;i++){
            uint8 _star=apeNFT.NFTinfo(temp[i]).stars;
            if(_star==1){
                denominator+=48;
                tempRate[i]=48;
            }else if(_star==2){
                denominator+=25;
                tempRate[i]=25;
            }else if(_star==3){
                denominator+=15;
                tempRate[i]=15;
            }else if(_star==4){
                denominator+=8;
                tempRate[i]=8;
            }else if(_star==5){
                denominator+=3;
                tempRate[i]=3;
            }else{
                denominator+=1;
                tempRate[i]=1;
            }
            deadrate[i]=denominator;
        }
        for(uint8 i=1;i<=dieNum;i++){
            uint _ran=(ran%denominator)+1;
            for(uint8 j=0;j<deadrate.length;j++){
                if(_ran<=deadrate[j]){
                    apeNFT.dieInBattle(temp[j]);
                    deadrate[j]=0;
                    denominator-=tempRate[j];
                    for(uint8 p=j+1;p<deadrate.length;p++){
                        if(deadrate[p]!=0){
                            deadrate[p]-=tempRate[j];
                        }
                    }
                    break;
                }
            }
        }
    }
    function calcuWinRate(uint32 chanceMin,uint32 chanceMax,uint32 powerMin,uint32 powerMax,uint32 teamPower)private pure returns(uint8){
        uint32 theRate=chanceMin+(teamPower-powerMin)%((powerMax-powerMin)/(chanceMax-chanceMin));
        if(theRate>chanceMax){
            return uint8(chanceMax);
        }
        return uint8(theRate);
    }
    function getReward(uint banana, uint _spice, uint _gem)private{
        if(banana!=0){
            base.earnBanana(msg.sender,banana);
        }
        if(_spice!=0 || _gem!=0){
            rewardPool.claimReward(msg.sender,_gem*10**18,_spice*10**18);
        }
    }
    function checkMissionOpen(uint8 _type,uint8 lv)private view returns(bool){
        if (_type==1){
            return merchanMissionSwitch[lv-1];
        }else if(_type==2){
            return govermentMissionSwitch[lv-1];
        }else{
            return seaMonsterMissionSwitch[lv-1];
        }
    }
    //operator open and close mission
    bool[5] public merchanMissionSwitch;
    bool[5] public govermentMissionSwitch;
    bool[6] public seaMonsterMissionSwitch;
    function setMissionStatus(uint8 _type, uint8 _mission, bool _switch)external onlyOwner{
        require(_type>0 && _type<4,"1~3"); //1:merchan   2:goverment   3:sea monster
        if (_type==1){
            require(_mission>0 && _mission<6,"1~5");
            merchanMissionSwitch[_mission-1]=_switch;
        }else if(_type==2){
            require(_mission>0 && _mission<6,"1~5");
            govermentMissionSwitch[_mission-1]=_switch;
        }else{
            require(_mission>0 && _mission<7,"1~6");
            seaMonsterMissionSwitch[_mission-1]=_switch;
        }
    }
}