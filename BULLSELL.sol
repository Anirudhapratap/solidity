



pragma solidity 0.5.4;

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
        address referrer;
        uint256 selfBuy;
        uint256 selfSell;
    }
    	bool public saleOpen=false;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    

    uint public lastUserId = 2;

    
    
    uint public  total_token_buy = 0;
	uint public  total_token_sale = 0;
	uint public  priceGap = 0;
	uint64 public  priceIndex = 1;
	uint64 public incrasePrice = 1e2;
	uint64 public decresePrice = 5e1;
	
	
	uint public  MINIMUM_BUY = 1000e6;
	uint public  MINIMUM_SALE = 1000e6;
	uint256 public tokenPrice = 3*1e4;
	uint64 public buyIndex = 1;
	uint64 public sellIndex = 1;
    address public owner;
    
    mapping(uint64 => uint) public buyLevel;
    mapping(uint64 => uint) public priceLevel;

  
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate, uint bnb_amount);
    event onWithdraw(address  _user, uint256 withdrawalAmount);
   
    
   //For Token Transfer
   
   IBEP20 private bullToken; 
   event onBuy(address buyer , uint256 amount);
   mapping(address => uint256) public boughtOf;

    constructor(address ownerAddress, IBEP20 _bullToken) public 
    {
        owner = ownerAddress;
        
        bullToken = _bullToken;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            selfBuy: uint(0),
            selfSell: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        // uint64 i=1;
        // for(;;) {
        //     buyLevel[i]=1000e6;
        //     if(i==1)
        //     priceLevel[i]=3*1e4;
        //     else
        //     priceLevel[i]=priceLevel[i-1]+1e2;
        //     i++;
        // }
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
        else
        bullToken.transfer(msg.sender,amt);
    }


    function registrationExt(address referrerAddress) external payable 
    {
        registration(msg.sender, referrerAddress);
    }
   
    function registration(address userAddress, address referrerAddress) private 
    {
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
            selfBuy: 0,
            selfSell: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        lastUserId++;

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function buyToken(uint256 tokenQty,address referrer) public payable
	{
	     require(!isContract(msg.sender),"Can not be contract");
	     require(tokenQty>=MINIMUM_BUY,"Invalid minimum quantity");
	       uint256 buy_amt;
	   //  (uint256 buy_amt,uint256 newpriceGap, uint64 newpriceIndex)=calcBuyAmt(tokenQty);
	     
	     if(!isUserExists(msg.sender))
	     {
	       registration(msg.sender, referrer);   
	     }
	     require(isUserExists(msg.sender), "user not exists");
	       if(buyIndex>101){
	           tokenPrice.add(incrasePrice);
	           buyIndex=1;
	       }
	       buyIndex++;
	    buy_amt=buy_amt+((tokenQty/1e6)*tokenPrice);
	     users[msg.sender].selfBuy=users[msg.sender].selfBuy+tokenQty;
	     bullToken.transfer(msg.sender , tokenQty);
	     
	   
         total_token_buy=total_token_buy+tokenQty;
		 emit TokenDistribution(address(this), msg.sender, tokenQty, priceLevel[priceIndex],buy_amt);					
	 }
	 
	function sellToken(uint256 tokenQty) public payable 
	{
	    address userAddress=msg.sender;
	    require(isUserExists(userAddress), "user is not exists. Register first.");
	    require(bullToken.balanceOf(userAddress)>=(tokenQty),"Low Balance");
	    require(bullToken.allowance(userAddress,address(this))>=(tokenQty),"Approve your token First");
	    require(!isContract(userAddress),"Can not be contract");
        
	    
	    uint256 busd_amt=(tokenQty/1e18)*priceLevel[priceIndex];
	     
		 bullToken.transferFrom(userAddress ,address(this), (tokenQty));
		 
		users[msg.sender].selfSell=users[msg.sender].selfSell+tokenQty;
		emit TokenDistribution(userAddress,address(this), tokenQty, priceLevel[priceIndex],busd_amt);
		total_token_sale=total_token_sale+tokenQty;
	 }
	
// 	function calcBuyAmt(uint tokenQty) public view returns(uint256,uint256,uint64)
// 	{
// 	    uint256 amt;
// 	    uint256 total_buy=priceGap+tokenQty;
// 	    uint256 newPriceGap=priceGap;
// 	    uint64 newPriceIndex=priceIndex;
// 	        uint64 i=newPriceIndex;
// 	        while(i<101 && tokenQty>0)
// 	        {
// 	               amt=amt+((tokenQty/1e6)*tokenPrice);
// 	            i++;
// 	    }
	    
// 	    return (amt,newPriceGap,newPriceIndex);
// 	}
	
	function calcBuyToken(uint256 amount) public view returns(uint256,uint256,uint64)
	{
	    uint256 quatity;
	    uint256 newPriceGap=priceGap;
	    uint64 newPriceIndex=priceIndex;  
	    uint64 i=newPriceIndex; 
	    while(amount>0 && i<101)
	    {
	        if(i==100)
	        {
	            quatity=quatity+(amount/priceLevel[newPriceIndex]);
	            amount=0;
	        }
	        else
	        {
	            uint256 left=(buyLevel[newPriceIndex]-newPriceGap)/1e18;
	            
	            uint256 LeftValue=(left*priceLevel[newPriceIndex]);
	            
	            if(LeftValue>=amount)
	            {
	                left=(amount/priceLevel[newPriceIndex]);
	                 quatity=quatity+(left*1e18);
	                 amount=0;
	                 newPriceGap=newPriceGap+(left*1e18);
	            }
	            else
	            {
	                 quatity=quatity+(left*1e18);
	                 amount=amount-LeftValue;  
	                 newPriceGap=0;
	            }
	        }
	        newPriceIndex++;
	        i++;
	    }
	    if(newPriceIndex>1)
	    newPriceIndex=newPriceIndex-1;
	     return (quatity,newPriceGap,newPriceIndex);
	}
	
	
	function withdraw() public payable {
        require(msg.value == 0, "withdrawal doesn't allow to transfer trx simultaneously");
        uint256 uid = users[msg.sender].id;
        require(uid != 0, "Can not withdraw because no any investments");
        uint256 withdrawalAmount = 0;
        
        bullToken.transfer(address(this),(withdrawalAmount/priceLevel[priceIndex]));

        emit onWithdraw(msg.sender, withdrawalAmount/priceLevel[priceIndex]);
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
  
    function token_setting(uint min_buy,  uint min_sale) public payable
    {
           require(msg.sender==owner,"Only Owner");
              MINIMUM_BUY = min_buy;
    	      MINIMUM_SALE = min_sale;
             
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
