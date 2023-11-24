// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IToken {
    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 _amount) external;

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function decimals() external view returns (uint256);
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function latestAnswer() external view returns (int256);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

interface vestingInterface {

    
    function createVesting(address _creator,uint8 _roundId,uint256 _tokenAmount) external ;
    
    function setAdmin(address _account) external ;

    function setTimeUnit(uint256 _unit) external ;

    function setRoundTokenPrice(uint8 _roundId,uint256 _price) external;

    function getClaimableAmount(address _walletAddress,uint256 _vestingId) external view returns(uint256);

    function userClaimData(address _walletAddress,uint256 _vestingId) external view returns(bool ,address ,uint8 ,uint256 ,uint256 ,uint256 ,uint256 ,uint256 ,uint256 ,uint256 );

    function getVestingIds(address _walletAddress) external view returns(uint256[] memory);

    function timeUnit() external view returns(uint256);

    function launchRound(uint8 _roundId, uint256 _vestingStartTime,bool _status) external;

    function getIslaunched(uint8 _roundId) external view returns(bool) ;

    function setRoundData( uint8 _roundId,  uint256 _totalTokensForSale,uint256 _tokenPrice,uint256 _totalvestingDays,uint256 _vestingStartTime,uint256 _vestingSlicePeriod,uint256 _tgePrecentage) external;

    function roundData(uint8 _roundId) external view returns(bool,uint256,uint256,uint256,uint256,uint256,uint256);  

    // function updateTotalTokenClaimed(uint8 _roundIds,uint _amount) external ;

    function currentRound() external view returns(uint8) ;


}

contract Presale is Ownable {
    using SafeMath for uint256;
    event WalletCreated(address walletAddress,address userAddress,uint256 amount);
    bool public isPresaleOpen = true;
    address public admin;

    AggregatorV3Interface internal priceFeed;

    address public tokenAddress;
    address public BUSDAddress;
    uint256 public tokenDecimals;
    uint256 public BUSDdecimals;

    //2 means if you want 100 tokens per eth then set the rate as 100 + number of rateDecimals i.e => 10000
    uint256 public rateDecimals = 2;

    mapping(uint8 => uint256 ) public tokenSold ;
    // bool private allowance = false;
    uint256 public totalEthAmount = 0;
    uint256 public totalBUSDAmount = 0;
 

    uint256 public hardcap = 10000*1e18;  // Total Eth Value
    address private dev;
    uint256 private MaxValue;

    vestingInterface vestingAddress;

    //@dev max and min token buy limit per account
    // uint256 public minEthLimit = 1000000000000000;
    // uint256 public maxEthLimit = 2000000000000000000000000;

    mapping(uint8 => uint256) public minBUSDLimit ;
    mapping(uint8 => uint256) public maxBUSDLimit ;
    // mapping(uint8 => uint256) public minEthLimit ;
    // mapping(uint8 => uint256) public maxEthLimit ;

    mapping(address => uint256) public usersInvestments;
    mapping(address => uint256) public usersInvestmentsBUSD ;
    mapping(address => uint256) public userPurchased;

    address public recipient;
    address public developmentWallet;
    uint256 public developmentShare;

    modifier onlyOwnerAndAdmin()   {
        require(
            owner() == _msgSender() || _msgSender() == admin,
            "Ownable: caller is not the owner or admin"
        );
        _;
    }

    constructor(
        address _token,
        address _recipient,
        address _BUSDAddress,
        address _developmentWallet
    ) {
        tokenAddress = _token;
        tokenDecimals = IToken(_token).decimals();
        recipient = _recipient;
        BUSDAddress = _BUSDAddress;
        BUSDdecimals = IToken(BUSDAddress).decimals();
        priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
        admin = _msgSender();
        developmentWallet = _developmentWallet;
        developmentShare = 10000;
        
    }

    function setAdmin(address account) external  onlyOwnerAndAdmin{
        require(account != address(0),"Invalid Address, Address should not be zero");
        admin = account;
    }
    
    function setvestingAddress(address _vestingAddress) external onlyOwnerAndAdmin {
        vestingAddress = vestingInterface(_vestingAddress);
    }

    function setRecipient(address _recipient) external onlyOwnerAndAdmin {
        require(_recipient != address(0),"Invalid Address, Address should not be zero");

        recipient = _recipient;
    }

    function setDevelopmentTeamWallet(address wallet) external onlyOwnerAndAdmin {
        require(wallet != address(0),"Invalid Address, Address should not be zero");
        developmentWallet = wallet;
    }    

    function setHardcap(uint256 _hardcap) external onlyOwnerAndAdmin {
        hardcap = _hardcap;
    }

    function setDevelopmentShare(uint256 _rate) public onlyOwnerAndAdmin {
        developmentShare = _rate;
    }

    function startPresale() external onlyOwnerAndAdmin {
        require(!isPresaleOpen, "Presale is open");

        isPresaleOpen = true;
    }

    function closePresale() external onlyOwnerAndAdmin {
        require(isPresaleOpen, "Presale is not open yet.");

        isPresaleOpen = false;
    }

    function setTokenAddress(address token) external onlyOwnerAndAdmin {
        require(token != address(0), "Token address zero not allowed.");
        tokenAddress = token;
        tokenDecimals = IToken(token).decimals();
    }

    function setBUSDToken(address token) external onlyOwnerAndAdmin {
        require(token != address(0), "Token address zero not allowed.");
        
        BUSDAddress = token;
        BUSDdecimals = IToken(BUSDAddress).decimals();
    }

    function setTokenDecimals(uint256 decimals) external onlyOwnerAndAdmin {
        tokenDecimals = decimals;
    }

    function setMinBUSDLimit(uint8 _roundId,uint256 amount) external onlyOwnerAndAdmin {
        minBUSDLimit[_roundId] = amount;
    }

    function setMaxBUSDLimit(uint8 _roundId,uint256 amount) external onlyOwnerAndAdmin {
        maxBUSDLimit[_roundId] = amount;
    }

    // function setMinEthLimit(uint8 _roundId,uint256 amount) external onlyOwnerAndAdmin {
    //     minEthLimit[_roundId] = amount;
    // }

    // function setMaxEthLimit(uint8 _roundId,uint256 amount) external onlyOwnerAndAdmin {
    //     maxEthLimit[_roundId] = amount;
    // }

    function setRateDecimals(uint256 decimals) external onlyOwnerAndAdmin {
        rateDecimals = decimals;
    }

    function setAdminForVesting(address _address) public onlyOwnerAndAdmin{
        vestingInterface(vestingAddress).setAdmin(_address);
    }
          
    function setTimeUnit(uint _unit) public onlyOwnerAndAdmin{
        vestingInterface(vestingAddress).setTimeUnit(_unit);
    }

    receive() external payable {}

    function getMaxAmount(uint8 _roundId) public view returns(uint256) {
        return(maxBUSDLimit[_roundId])/uint(getEthPriceInUsd()) ;
    }

    function getMinAmount(uint8 _roundId) public view returns(uint256) {
        return(minBUSDLimit[_roundId])/uint(getEthPriceInUsd()) ;
    }

    function buyToken(uint8 _roundId) public payable  {
        require(isPresaleOpen, "Presale is not open.");
        require(!vestingInterface(vestingAddress).getIslaunched(_roundId),"Already Listed!");

        require(
            usersInvestments[msg.sender].add(msg.value) <= getMaxAmount(_roundId) &&
                usersInvestments[msg.sender].add(msg.value) >= getMinAmount(_roundId) ,
            "user input should be  with in the range"
        );

        uint256 tokenAmount = getTokensPerEth(msg.value,_roundId);
        
        vestingCreate(tokenAmount,_msgSender(),_roundId);

        tokenSold[_roundId] += tokenAmount;

        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(msg.value);
        userPurchased[msg.sender] = userPurchased[msg.sender].add(tokenAmount);
        uint256 msgValue = msg.value;
        totalEthAmount = totalEthAmount + msgValue;
        
        uint _developmentShareAmount = (msgValue * developmentShare)/(10**(2+rateDecimals));
        uint _recipientShare = msgValue - _developmentShareAmount    ;
        payable(recipient).transfer(_recipientShare);
        payable(developmentWallet).transfer(_developmentShareAmount);

        // if (totalEthAmount > hardcap) {
        //     isPresaleOpen = false;
        // }
    }

    function buyTokenBUSD(uint8 _roundId,uint _amount) public {
        require(isPresaleOpen, "Presale is not open.");
        require(!vestingInterface(vestingAddress).getIslaunched(_roundId),"Already Listed!");

        require(
            usersInvestmentsBUSD[msg.sender].add(_amount) <= maxBUSDLimit[_roundId] &&
                usersInvestmentsBUSD[msg.sender].add(_amount) >= minBUSDLimit[_roundId],
            "user input should be  with in the range"
        );

        uint256 tokenAmount = getTokenPerBUSD(_amount,_roundId);
        
        vestingCreate(tokenAmount,_msgSender(),_roundId);

        tokenSold[_roundId] += tokenAmount;

        totalBUSDAmount +=  _amount ;

        // payable(recipient).transfer(msg.value);
        usersInvestmentsBUSD[msg.sender] =usersInvestmentsBUSD[msg.sender].add(tokenAmount);
        userPurchased[msg.sender] = userPurchased[msg.sender].add(tokenAmount);

        uint _developmentShareAmount = (_amount * developmentShare)/(10**(2+rateDecimals));
        uint _recipientShare = _amount - _developmentShareAmount;

        IToken(BUSDAddress).transferFrom(_msgSender(),developmentWallet,_developmentShareAmount);
        IToken(BUSDAddress).transferFrom(_msgSender(),recipient,_recipientShare);

        // if (totalEthAmount > hardcap) {
        //     isPresaleOpen = false;
        // }
    }

    function vestingCreate(
        uint256 tokenAmount,
        address _userAddress,
        uint8 _roundId
    ) private {

        (,,,,,,uint256 _tgePrecentage) = getRoundData(_roundId);

        if(_tgePrecentage > 0) {
            uint _tgeAmount = (tokenAmount * _tgePrecentage)/(10**(2+rateDecimals));
            tokenAmount =  tokenAmount - _tgeAmount;


        require(IToken(tokenAddress).transfer(_userAddress, _tgeAmount),
            "Insufficient balance of presale contract!"
        );

        }

            vestingInterface(vestingAddress).createVesting(_userAddress,_roundId,tokenAmount);
            require(IToken(tokenAddress).transfer(address(vestingAddress), tokenAmount),
                "Insufficient balance of presale contract!"
            );
    }

    function createRoundData( 
        uint8 _roundId,
        uint256 _totalTokensForSale,
        uint256 _tokenPrice,
        uint256 _totalvestingDays,
        uint256 _vestingStartTime,
        uint256 _vestingSlicePeriod,
        uint256 _tgePrecentage,
        uint256 _minBUSDLimit,
        uint256 _maxBUSDLimit
        ) public onlyOwnerAndAdmin{
            vestingInterface(vestingAddress).setRoundData(_roundId,_totalTokensForSale,_tokenPrice,_totalvestingDays,_vestingStartTime,_vestingSlicePeriod,_tgePrecentage);
            
            minBUSDLimit[_roundId] = _minBUSDLimit ;
            maxBUSDLimit[_roundId] = _maxBUSDLimit ;
        }

    function burnUnsoldTokens() external onlyOwnerAndAdmin {
        require(
            !isPresaleOpen,
            "You cannot burn tokens untitl the presale is closed."
        );

        IToken(tokenAddress).burn(
            IToken(tokenAddress).balanceOf(address(this))
        );
    }

    function getUnsoldTokens(address to) external onlyOwnerAndAdmin {
        require(
            !isPresaleOpen,
            "You cannot get tokens until the presale is closed."
        );

        IToken(tokenAddress).transfer(to,IToken(tokenAddress).balanceOf(address(this)));
    
    }

    function getvestingAddress() external view returns (address){
        return address(vestingAddress);
    }

    function getEthPriceInUsd() public view returns(int256) {
        return (priceFeed.latestAnswer()/1e8);
    }

    // this function has to be internal
    function getTicketRate(uint8 _roundId) public view returns(uint256) {
        (,,uint256 tokenprice,,,,) = getRoundData(_roundId);
        return tokenprice;
    }

    function getTokensPerEth(uint256 amount,uint8 _roundId) public view returns (uint256) {

        uint _denominator =(getTicketRate(_roundId)*(10**((uint256(18).sub(tokenDecimals))))) ;

        return (((amount.mul(uint(getEthPriceInUsd()))).mul(10**(2+rateDecimals)))/ _denominator) ;
  
    }

    function getTokenPerBUSD(uint256 _BUSDamount,uint8 _roundId) public view returns(uint256) {
        
        return  (((_BUSDamount.mul(10**(2+rateDecimals)))/getTicketRate(_roundId))*10**tokenDecimals).div(10**BUSDdecimals);
    }

    function getVestingId(address _walletAddress) public view returns(uint256[] memory) {
        return vestingInterface(vestingAddress).getVestingIds(_walletAddress);        
    }
 
    function getTimeUnit() public view returns(uint _timeUnit){
        return vestingInterface(vestingAddress).timeUnit();
    }

    function launchRound(uint8 _roundId, uint256 _vestingStartTime,bool _status) public onlyOwnerAndAdmin {
         vestingInterface(vestingAddress).launchRound(_roundId,_vestingStartTime,_status);
    }

    function getClaimAmount(address _walletAddress,uint256 _vestingId) public view returns(uint _claimAmount) {
        return vestingInterface(vestingAddress).getClaimableAmount(_walletAddress,_vestingId);
    }

    function getUserVestingData(address _address,uint256 _vestingId) public view returns(
        
        bool ,//_initialized,
        address ,//_owner,
        uint8 ,//_roundId,
        uint256 ,//_totalEligible,
        uint256 ,//_totalClaimed,
        uint256 ,//_remainingBalTokens,
        uint256 ,//_lastClaimedAt,
        uint256 ,//_startTime,
        uint256 ,//_totalVestingDays,
        uint256 //_slicePeriod
        
        ){
        
        return vestingInterface(vestingAddress).userClaimData(_address,_vestingId);
        
    }

    function getTotalTokensForSale(uint8 _roundId) public view returns(uint256 _totalTokensForSale ){
        (,_totalTokensForSale,,,,,) = getRoundData(_roundId);
    }

    function getRoundData(uint8 _roundId) public view returns(bool,uint256,uint256,uint256,uint256,uint256,uint256) {
        return( vestingInterface(vestingAddress).roundData(_roundId)) ;
    }

    function getCurrentRound() public view returns(uint8) {
        return vestingInterface(vestingAddress).currentRound();
    }

}