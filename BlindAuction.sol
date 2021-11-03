pragma solidity >=0.4.0 <0.9.0;
contract BlindAuction{
   
  // VARIABLES
  struct Bid {
      bytes32 blindedBid;
      uint deposit;
  }
  
  address payable public beneficiary;
  uint public biddingEnd;
  uint public revealEnd;
  bool public ended;
  
  mapping(address => Bid[]) public bids;
  
  address public highestBidder;
  uint public highestBid;
  
  mapping(address =>uint) pendingReturns;
  
  // EVENTS
  event AuctionEnded(address winner, uint highestBid);
  
  // MODIFIERS  
  modifier onlyBefore(uint _time) {require(block.timestamp < _time); _; }
  modifier onlyAfter(uint _time) {  
  
  // constructor
  constructor(){
      
  }
  
  // FUNCTIONS
  
  function generateBlindedBidBytes32() public {
      
  }
  
  function bid() public {
      
  }
  
  function reveal() public {
      
  }
  
  function auctionEnd() public {
      
  }
  
  function withdraw() public {
      
  }
  
  function placeBid() public {
      
  }
  
    
}

  
