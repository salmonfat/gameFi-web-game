pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/IPancakeRouter02.sol";
import './interface/IPancakeFactory.sol';

contract tokenGEM is IERC20,Ownable{
    using SafeMath for uint256;
    IPancakeRouter02 pancakeV2Pouter;
    //address BUSDAddress=0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; //Mian Net
    address BUSDAddress=0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;  //先放測試網的地址
    IERC20 IBUSD=IERC20(BUSDAddress);
    address public GEMandBUSDPair;
    mapping (address=>bool)noSlippage;
    address public rewardPool;
    address public farmPool;
    uint[3] public slippageFee;

    string private constant _name = "GEM token";
    string private constant _symbol = "GEM";
    uint8 private constant _decimals = 18;
    uint private constant maxSupply=1*10**8*10**18; //總量1億個

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;


    constructor(address _reward, address _farm){
        _balances[_msgSender()]=maxSupply; //先mint到合約創造者錢包
        pancakeV2Pouter = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //先放測試網的地址
        //pancakeV2Pouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);  //Mian Net
        GEMandBUSDPair = IPancakeFactory(pancakeV2Pouter.factory()).createPair(address(this), BUSDAddress); 
        noSlippage[msg.sender]=true;
        noSlippage[address(this)]=true;
        isSwapingAndAddingLiq=false;
        slippageFee=[5,0,0]; 
        maxTransferAmount=500000*10**18;
        rewardPool=_reward;
        farmPool=_farm;
        emit Transfer(address(0), _msgSender(), maxSupply);
    }

    //ERC20基本functions
    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function name() external pure returns (string memory) {
        return _name;
    }
  
    function decimals() external pure returns (uint8) {
    return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return maxSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
  
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        //emit Approval(owner, spender, amount);
  }
    
    //滑點相關functions
    function isNoSlippage(address account)public view returns(bool){
        return noSlippage[account];
    }
    function setNoSlippage(address account, bool newSetting)external onlyOwner{
        require(isNoSlippage(account)!=newSetting,"you are not changing status");
        noSlippage[account]=newSetting;
    }
    function setSlippageFee(uint[3] memory newFee)external onlyOwner{
        slippageFee=newFee;
    }
    // _Transfer內的設定和更改功能
    uint public maxTransferAmount;
    uint public accumulateTokenToSwap=3000*10**18;
    bool swapAndAddLiqSwitch=true;
    function setMaxTransferAmount(uint newAmount)external onlyOwner{
        require(newAmount>=10000*10**18,"max transfer amount too low");
        maxTransferAmount=newAmount;
    }
    function setAccumulateTokenToSwap(uint newAmount)external onlyOwner{
        accumulateTokenToSwap=newAmount;
    }
    function setSwapAndLiquifyEnabled(bool newStatus)external onlyOwner{
        require(newStatus !=swapAndAddLiqSwitch,"didn't change");
        swapAndAddLiqSwitch=newStatus;
    }
    // override transder
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(
          !noSlippage[from] && !noSlippage[to] && 
          balanceOf(GEMandBUSDPair) > 0 && 
          !isSwapingAndAddingLiq &&
          from != address(pancakeV2Pouter) && 
          (from == GEMandBUSDPair || to == GEMandBUSDPair)
        ) {
          require(amount <= maxTransferAmount, "Transfer amount exceeds the maxTransferAmount.");          
        }
        uint256 tokenBalance = balanceOf(address(this));
        if(tokenBalance >= maxTransferAmount)
        {
          tokenBalance = maxTransferAmount;
        }
        bool overMinTokenBalance = tokenBalance >= accumulateTokenToSwap;
        if (
          overMinTokenBalance &&
          !isSwapingAndAddingLiq &&
          from != GEMandBUSDPair &&
          swapAndAddLiqSwitch
        ) {
          tokenBalance = accumulateTokenToSwap;
          swapAndAddLiqFromFee(tokenBalance);
        }
        bool takeFee = false;
        if (balanceOf(GEMandBUSDPair) > 0 && (from == GEMandBUSDPair || to == GEMandBUSDPair)) {
          takeFee = true;
        }
        if (noSlippage[from] || noSlippage[to] || isSwapingAndAddingLiq){
          takeFee = false;
        }
        _tokenTransfer(from,to,amount,takeFee);
    }
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        uint256 tTransferAmount = amount;
        if (takeFee) {
            tTransferAmount = _takeFees(amount);
        }
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);   
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _takeFees(uint256 amount) internal returns(uint256) {
        uint256 rewardFee = amount.mul(slippageFee[0]).div(100);
        uint256 farmingFee = amount.mul(slippageFee[1]).div(100);
        uint256 liquidityFee = amount.mul(slippageFee[2]).div(100);
        _balances[rewardPool] = _balances[rewardPool].add(rewardFee);
        _balances[farmPool] = _balances[farmPool].add(farmingFee);
        _balances[address(this)] = _balances[address(this)].add(liquidityFee);
        return amount.sub(rewardFee).sub(farmingFee).sub(liquidityFee);
    }
    // pankcake swap 相關功能
    bool isSwapingAndAddingLiq;
    modifier swapingLock { 
        isSwapingAndAddingLiq=true;
        _;
        isSwapingAndAddingLiq=false;
    }

    function swapAndAddLiqFromFee(uint amount)internal swapingLock{
        uint half=amount/2;
        uint otherHalf=amount-half;
        address[] memory thePath=new address[](2);
        thePath[0]=address(this); thePath[1]=BUSDAddress;
        _approve(address(this),address(pancakeV2Pouter),half);
        pancakeV2Pouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(half,0,thePath,address(this),block.timestamp);
        addLiq(otherHalf,IBUSD.balanceOf(address(this)));
    }
    function addLiq(uint thisToken,uint tokenBUSD)private{
        IBUSD.approve(address(pancakeV2Pouter),tokenBUSD);
        _approve(address(this),address(pancakeV2Pouter),thisToken);
        pancakeV2Pouter.addLiquidity(address(this),BUSDAddress,thisToken,tokenBUSD,0,0,address(this),block.timestamp);
    }
}