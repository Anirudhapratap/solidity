
/**
 *Submitted for verification at BscScan.com on 2021-08-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

pragma solidity 0.5.4;
//  token == 0xCD4998E4aB9616Ff1B8B388575EB907a5ED1E1D0

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender)
  external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)
  external returns (bool);
  
  function transferFrom(address from, address to, uint256 value)
  external returns (bool);
  function burn(uint256 value)
  external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}
   
contract ZEE{

    
    struct User 
    {
        uint id;
        address referrer;
        uint256 refIncome;
        uint256 selfBuy;
    }
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
     mapping(address => bool) whitelist;
   
    uint public lastUserId = 2;
    uint public refPercent=10;
    
    uint public buyPercent=0;

    // uint public token_price =150000000000000;
    // uint public token_price =125000000000000;
    
    uint public token_price = 52083333333334;
    
    
    uint public  total_token_buy = 0;
	
// 	uint public  MINIMUM_BUY = 3e17;
	uint public  MINIMUM_BUY = 25e16;
	
	
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;
    
      modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
        
    }
  
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event TokenPriceHistory(uint  previous, uint indexed inc_desc, uint new_price, uint8 type_of);
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate);
    event onWithdraw(address  _user, uint256 withdrawalAmount);
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);
    
   //For Token Transfer
   
   IBEP20 private zeeToken; 
   mapping(address => uint256) public boughtOf;

    constructor(address ownerAddress,IBEP20 _zeeToken) public 
    {
        owner = ownerAddress;
        
        zeeToken = _zeeToken;
        
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            refIncome:uint(0),
            selfBuy: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
         
    }
    
    function() external payable 
    {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

   

    function withdrawBalance(uint256 amt,uint8 _type) public 
    {
        require(msg.sender == owner, "onlyOwner");
        if(_type==1)
        msg.sender.transfer(amt);
        else if(_type==2)
        zeeToken.transfer(msg.sender,amt);
    }


    function registrationExt(address referrerAddress) external payable 
    {
        registration(msg.sender, referrerAddress);
    }
    
   
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            refIncome:0,
            selfBuy: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        lastUserId++;
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
  
  
 
    
    function isUserExists(address user) public view returns (bool) 
    {
        return (users[user].id != 0);
    }

	function buyToken(uint tokenQty,address _referrer) public payable onlyWhitelisted
	{
	     require(!isContract(msg.sender),"Can not be contract");
	     if(!isUserExists(msg.sender))
	     {
	       registration(msg.sender, _referrer);  
	     }
	     require(isUserExists(msg.sender), "user not exists");
	     require(tokenQty>=MINIMUM_BUY,"Invalid minimum quatity");	            
	     uint buy_amt=((tokenQty/15e13)*(token_price/1e18))*1e18;
	     require(msg.value>=buy_amt,"Invalid buy amount");
		 zeeToken.transfer(msg.sender , (tokenQty));
		
		 
		 users[msg.sender].selfBuy=users[msg.sender].selfBuy+tokenQty;
		 emit TokenDistribution(address(this), msg.sender, tokenQty, token_price);					
	 }
    function addWhitelist(address _address) public 
    {
        require(msg.sender == owner, "onlyOwner");
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function removeWhitelist(address _address) public 
    {
        require(msg.sender == owner, "onlyOwner");
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

	
    function isContract(address _address) public view returns (bool _isContract)
    {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }     
	 
    
    
        
        
    function token_setting(uint min_buy, uint price) public payable
    {
           require(msg.sender==owner,"Only Owner");
              MINIMUM_BUY = min_buy;
    
              if(price>0)
              {
                token_price=price;
              }
        }
   
        
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
     function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }
}
