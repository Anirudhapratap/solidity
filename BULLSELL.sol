


pragma solidity 0.5.4;

// interface IBEP20 {
//   function totalSupply() external view returns (uint256);
//   function balanceOf(address who) external view returns (uint256);
//   function allowance(address owner, address spender)
//   external view returns (uint256);
//   function transfer(address to, uint256 value) external returns (bool);
//   function approve(address spender, uint256 value)
//   external returns (bool);
  
//   function transferFrom(address from, address to, uint256 value)
//   external returns (bool);
//   function burn(uint256 value)
//   external returns (bool);
//   event Transfer(address indexed from,address indexed to,uint256 value);
//   event Approval(address indexed owner,address indexed spender,uint256 value);
// }

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
   
contract BULLSELL  {
     using SafeMath for uint256;
     
    struct User {
        uint id;
        uint256 selfBuy;
        uint256 selfSell;
    }
    	bool public saleOpen=false;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    

    uint public lastUserId = 2;

    
    
    uint public  total_token_buy = 0;
	uint public  total_token_sale = 0;
	uint64 public incrasePrice = 1e2;
	uint64 public decresePrice = 5e1;
	
	
	uint public  MINIMUM_BUY = 1000;
	uint256 public tokenPrice = 3e4;
    address public owner;
    
    uint256 public buyValue=0;
    uint256 public sellValue=0;
    
    event Registration(address indexed user);
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate, uint trx_amount);
    event onWithdraw(address  _user, uint256 withdrawalAmount);
    event checkStatus(string msg, uint256 value, uint256 token);
   
    
   //For Token Transfer
   
   trcToken bullToken=1000944; 
   event onBuy(address buyer , uint256 amount);

    constructor(address ownerAddress) public 
    {
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            selfBuy: uint(0),
            selfSell: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
    }
    
    function() external payable 
    {
        if(msg.data.length == 0) {
            return registration(msg.sender);
        }
        
        registration(msg.sender);
    }

    function withdrawBalance(uint256 amt, uint _type) public 
    {
           require(msg.sender == owner, "onlyOwner");
        if(_type==1)
        msg.sender.transferToken((amt*1e6),bullToken);
    }


    // function registrationExt(address referrerAddress) external payable 
    // {
    //     registration(msg.sender, referrerAddress);
    // }
   
    function registration(address userAddress) private 
    {
        require(!isUserExists(userAddress), "user exists");
        // require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            selfBuy: 0,
            selfSell: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        
        lastUserId++;

        emit Registration(userAddress);
    }

    function buyToken(uint256 tokenQty) public payable
	{
	     require(!isContract(msg.sender),"Can not be contract");
	     require(tokenQty>=MINIMUM_BUY,"Invalid minimum quantity");
	    //   uint256 buy_amt;
	   //  (uint256 buy_amt,uint256 newpriceGap, uint64 newpriceIndex)=calcBuyAmt(tokenQty);
	     
	     if(!isUserExists(msg.sender))
	     {
	       registration(msg.sender);   
	     }
	     require(isUserExists(msg.sender), "user not exists");
	     buyValue = buyValue+tokenQty;
	     uint256 amt = buyValue/10**2;
	     buyValue = buyValue%100;
	     
	       if(amt>0){
	           uint256 _incrasePrice = incrasePrice*amt;
	           tokenPrice +=_incrasePrice;
	       }
	    uint256 buy_amt=(tokenQty*tokenPrice);
	    require(msg.value>=buy_amt,"Invalid buy amount");
	     users[msg.sender].selfBuy=users[msg.sender].selfBuy+tokenQty;
	     
	     msg.sender.transferToken((tokenQty*1e6), bullToken);
	     
	   
         total_token_buy=total_token_buy+tokenQty;
		 emit TokenDistribution(address(this), msg.sender, tokenQty, tokenPrice,buy_amt);					
	 }
	 
	function sellToken(uint256 tokenQty) public payable 
	{
	    address userAddress=msg.sender;
	    require(isUserExists(userAddress), "user is not exists. Register first.");
	   require(userAddress.tokenBalance(bullToken)>=(tokenQty),"Low Balance");
	    require(!isContract(userAddress),"Can not be contract");
        
	     sellValue = sellValue+tokenQty;
	     uint256 amt = buyValue/10**2;
	     sellValue = sellValue%100;
	     
	       if(amt>0){
	           uint256 _decresePrice = decresePrice*amt;
	           tokenPrice -=_decresePrice;
	       }
	    uint256 sell_amt=(tokenQty*tokenPrice);
	    require(msg.value>=sell_amt,"Invalid buy amount");
	    	  msg.sender.transferToken((tokenQty*1e6), bullToken);
		 
		users[msg.sender].selfSell=users[msg.sender].selfSell+tokenQty;
		emit TokenDistribution(userAddress,address(this), tokenQty, tokenPrice,sell_amt);
		total_token_sale=total_token_sale+tokenQty;
	 }

	

	function isUserExists(address user) public view returns (bool) 
    {
        return (users[user].id != 0);
    }
	
    function isContract(address _address) public view returns (bool _isContract)
    {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }    
  
    function token_setting(uint min_buy) public payable
    {
           require(msg.sender==owner,"Only Owner");
              MINIMUM_BUY = min_buy;
             
    }
    
      function sale_setting(uint8 _type) public payable
    {
           require(msg.sender==owner,"Only Owner");
            if(_type==1)
            saleOpen=true;
            else
            saleOpen=false;
             
    }
        
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}
