pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IapeNFT.sol"; 
import "./interface/Ibase.sol";
import "./interface/Igame.sol";


contract market is Ownable{
    IapeNFT gameNFT; 
    IERC20 gameToken;
    Ibase base;
    Igame game;
    uint public floorPrice;
    uint8 public taxFromSeller;//0~100
    uint8 public taxFromBuyer;//0~100

    constructor(){
        gameNFT= IapeNFT(0xE7cD75B29aFe802D30722bade3203d1B27769d94);
        gameToken=IERC20(0x6F4507Ad0975e3AA4836706000a9Fa7789736d92);
        base=Ibase(0x56Bf3E882b7F8C048d6542EFd5F7e53933F3F6c6);
    }
    struct product{
        bool selling;
        uint Price;
    }
    mapping(uint=>product) onSale; 
    function productInfo(uint id)public view returns(product memory){
        return onSale[id];
    }
    function isSelling(uint id)public view returns(bool){
        return onSale[id].selling;
    }
    function listNFT(uint id, uint listingPrice)external NFTOwner(id) cantOnSale(id){
        require(listingPrice>=floorPrice,"floor price");
        require(!game.NftMission(id),"mission");
        product memory temp;
        temp.selling=true;
        temp.Price=listingPrice;
        onSale[id]=temp;
        _addTokenToAllTokensEnumeration(id);
    }
    function revokeListing(uint id)external NFTOwner(id){
        product memory tempProduct=productInfo(id);
        require(tempProduct.selling==true);
        _removeTokenFromAllTokensEnumeration(id);
        delete onSale[id];
    }
    function buy(uint id)external{
        product memory tempProduct=productInfo(id);
        require(tempProduct.selling==true);
        address seller=gameNFT.ownerOf(id);
        address buyer= msg.sender;
        gameToken.transferFrom(buyer,address(this),(tempProduct.Price*(uint256(taxFromBuyer)+100)/100));
        gameToken.transfer(seller,tempProduct.Price*(100-uint256(taxFromSeller))/100);
        gameNFT.safeTransferFrom(seller,buyer,id);
        _removeTokenFromAllTokensEnumeration(id);
        delete onSale[id];
    }
    function give(uint id, address to)external NFTOwner(id)cantOnSale(id){
        require(!game.NftMission(id),"mission");
        gameNFT.safeTransferFrom(msg.sender,to,id);
    }

    modifier NFTOwner(uint id){
        require(msg.sender==gameNFT.ownerOf(id));
        _;
    }
    modifier cantOnSale(uint id) {
        require(isSelling(id)==false,"It's on sell");
        _;
    }
    //sell banana
    mapping (address=>uint256) public bananaSellerIndex;
    address[] private index;
    struct bananaProduct{
        uint amount;
        uint price;
    }
    mapping(uint=>bananaProduct)public indexToBananaSell;

    function getIndexLength()external view returns(uint){
        return index.length;
    }

    function sellBanana(uint _amount,uint _price)external{
        if(bananaSellerIndex[msg.sender]==0){
            uint newIndex=index.length+1;
            bananaSellerIndex[msg.sender]=newIndex;
            index.push(msg.sender);
        }
        uint temp=bananaSellerIndex[msg.sender];
        indexToBananaSell[temp].amount+=_amount;
        indexToBananaSell[temp].price=_price;
        base.useBanana(msg.sender,_amount);
    }
    function revokeBanana()external{
        uint theIndex=bananaSellerIndex[msg.sender];
        base.earnBanana(msg.sender,indexToBananaSell[theIndex].amount);
        removeBananaIndex(theIndex);
    }
    function buyBanana(uint _amount,uint _index)external{
        bananaProduct memory temp= indexToBananaSell[_index];
        indexToBananaSell[_index].amount-=_amount;
        address seller=index[_index-1];
        address buyer= msg.sender;
        gameToken.transferFrom(buyer,address(this),(temp.price*_amount*(uint256(taxFromBuyer)+100)/100));
        gameToken.transfer(seller,temp.price*_amount*(100-uint256(taxFromSeller))/100);
        base.earnBanana(buyer,_amount);
        if(indexToBananaSell[_index].amount==0){
            removeBananaIndex(_index);
        }
    }
    function removeBananaIndex(uint delIndex)private{
        uint lastIndex=index.length;
        address lastInDexAdd=index[lastIndex-1];
        index[delIndex-1]=lastInDexAdd;
        bananaSellerIndex[lastInDexAdd]=delIndex;
        indexToBananaSell[delIndex]=indexToBananaSell[lastIndex];
        delete indexToBananaSell[lastIndex];
        index.pop();
    }

    //operator functions
    function setFloorPrice(uint newFloorPrice)external onlyOwner{
        floorPrice=newFloorPrice;
    }
    function setTax(uint8 newTaxFromSeller, uint8 newTaxFromBuyer)external onlyOwner{
        require(newTaxFromSeller<=100);
        require(newTaxFromBuyer<=100);
        taxFromSeller=newTaxFromSeller;
        taxFromBuyer=newTaxFromBuyer;
    }
    function setGameAdd(address _game)external onlyOwner{
        game=Igame(_game);
    }
    function withdrawTax()external onlyOwner{}

    // enmerable
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastTokenId; 
        _allTokensIndex[lastTokenId] = tokenIndex; 
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    function getMarketList()external view returns(uint256[] memory){
        return _allTokens;
    }
}