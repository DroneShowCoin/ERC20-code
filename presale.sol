pragma solidity ^0.4.11;

/**
 * @title SafeMath
    * @dev Math operations with safety checks that throw on error
       */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }
}

/**
 * @title Ownable
    * @dev The Ownable contract has an owner address, and provides basic authorization control 
       * functions, this simplifies the implementation of "user permissions". 
          */
contract Ownable {
  address public owner;


  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
        * account.
             */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner. 
        */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
        * @param newOwner The address to transfer ownership to. 
             */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

/**
 * @title Token
   * @dev interface for interacting with droneshowcoin token
             */
interface  Token {
 function transfer(address _to, uint256 _value) returns (bool);
 function balanceOf(address _owner) constant returns(uint256 balance);
}

contract DroneShowCoinPresaleContract is Ownable {
    
    using SafeMath for uint256;
    
    Token token;
    
    uint256 public constant RATE = 1000; //tokens per ether
    uint256 public constant CAP = 15000; //cap in ether
    uint256 public constant START = 1508760000; //GMT: Monday, October 23, 2017 12:00:00 PM
    uint256 public constant DAYS = 7; //
    
    bool public initialized = false;
    uint256 public raisedAmount = 0;
    uint256 public bonusesGiven = 0;
    
    event BoughtTokens(address indexed to, uint256 value);
    
    modifier whenPreSaleIsActive() {
        assert (isActive());
        _;
    }
    
    function DroneShowCoinPresaleContract(address _tokenAddr) {
        require(_tokenAddr != 0);
        token = Token(_tokenAddr);
    }
    
    function initialize(uint256 numTokens) onlyOwner {
        require (initialized == false);
        require (tokensAvailable() == numTokens);
        initialized = true;
    }
    
    function isActive() constant returns (bool) {
        return (
            initialized == true &&  //check if initialized
            now >= START && //check if after start date
            now <= START.add(DAYS * 1 days) && //check if before end date
            goalReached() == false //check if goal was not reached
        ); // if all of the above are true we are active, else we are not
    }
    
    function goalReached() constant returns (bool) {
        return (raisedAmount >= CAP * 1 ether);
    }
    
    function () payable {
        buyTokens();
    }
    
    function buyTokens() payable whenPreSaleIsActive {
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(RATE);
        
        uint256 bonusAmount = calculateBonus(tokens);
        tokens.add(bonusAmount);
        BoughtTokens(msg.sender, tokens);
        
        raisedAmount = raisedAmount.add(msg.value);
        bonusesGiven = bonusesGiven.add(bonusAmount);
        token.transfer(msg.sender, tokens);
        
        owner.transfer(msg.value);
        
    }
    
    function calculateBonus(uint256 notokens) constant returns (uint256)
    {
        //days passed since START
        assert (now < START); //how did we get here
        uint256 secondspassed = now.sub(START);
        uint256 dayspassed = secondspassed.div(60).div(60).div(24);
        assert (dayspassed > DAYS); //shouldn't happen but just to be safe
        uint256 bonusPrcnt = 0;
        if (dayspassed == 0) {
            //first 24 hours 30% bonus
            bonusPrcnt = 30;
        } else if (dayspassed == 1) {
            //second day 25% bonus
            bonusPrcnt = 25;
        } else if (dayspassed == 2) {
            //third day 20% bonus
            bonusPrcnt = 20;
        } else if (dayspassed == 3) {
            //fourth day 18%
            bonusPrcnt = 18;
        } else if (dayspassed == 4) {
            //fifth day 15%
            bonusPrcnt = 15;
        } else if (dayspassed == 5) {
            //sixth day 10%
            bonusPrcnt = 10;
        } else {
            //no bonus
            bonusPrcnt = 0;
        }
        return notokens.mul(bonusPrcnt).div(100);
    }
    
    function tokensAvailable() constant returns (uint256) {
        return token.balanceOf(this);
    }
    
    function destroy() onlyOwner {
        uint256 balance = token.balanceOf(this);
        assert (balance > 0);
        token.transfer(owner,balance);
        selfdestruct(owner);
        
    }
}

