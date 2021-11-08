pragma solidity >=0.4.0 <0.9.0;

contract BlindAuction {
    
    // VERIABLES
    struct Bid{
      bytes32 blindedBid;
      uint deposit;
    }
    
    uint threshold; // Threshold of the Auction
    address payable public beneficiary; //contract and auction owner
    uint public biddingEnd; //bids can no longer be placed after this time
    bool public ended;
    uint public maxBid;
    uint public minBid;
    address public highestBidder;
    
 
    
    // MAPPINGS
    mapping(address => Bid[]) public bids;
    mapping(address => uint) pendingReturns; 
    
    // EVENTS
    event AuctionEnded(address winner, uint highestBid);

    
    /// Modifiers are a convenient way to validate inputs to
    /// functions. `onlyBefore` is applied to `bid` below:
    /// The new function body is the modifier's body where
    /// `_` is replaced by the old function body.
    modifier onlyBefore(uint _time) { require(now < _time); _; }
    modifier onlyAfter(uint _time) { require(now > _time); _; }


    
    // constructor
    constructor(
      string memory name,
      string memory description,
      uint _biddingTime,
      uint _min_Bid,
      uint _max_Bid,
      uint _thereshold,
      address payable _beneficiary
  ) public {
       beneficiary = _beneficiary;
       biddingEnd = block.timestamp + _biddingTime;
      
  }
    
    // FUNCTIONS
    
    function generateBlindedBidBytes32(uint value, bool fake) public view returns (bytes32) {
      return keccak256(abi.encodePacked(value, fake));
      
  }
  
    /// Place a blinded bid with `_blindedBid` =
    /// keccak256(abi.encodePacked(value, fake, secret)).
    /// The sent ether is only refunded if the bid is correctly
    /// revealed in the revealing phase. The bid is valid if the
    /// ether sent together with the bid is at least "value" and
    /// "fake" is not true. Setting "fake" to true and sending
    /// not the exact amount are ways to hide the real bid but
    /// still make the required deposit. The same address can
    /// place multiple bids.
    function bid(bytes32 _blindedBid)
        public
        payable
        onlyBefore(biddingEnd)
    {
        // If the bid is not higher, send the money back
        // (the failing require will revert all changes in this function execution including it having received the money).
        require(msg.value >= minBid, "Your bid is lower then minimum bidding amount. Try bidding higher!");
        require(msg.sender != );
        
        bids[msg.sender].push(Bid({
            blindedBid: _blindedBid,
            deposit: msg.value
        }));
    }
    
        // This is an "internal" function which means that it
    // can only be called from the contract itself (or from
    // derived contracts).
    function placeBid(address bidder, uint value) internal
            returns (bool success)
    {
        if (value <= maxBid || value <= minBid) {
            return false;
        }
        if (highestBidder != address(0)) {
            // Refund the previously highest bidder.
            pendingReturns[highestBidder] += maxBid;
        }
        maxBid = value;
        highestBidder = bidder;
        return true;
    }
       /// Withdraw a bid that was overbid.
    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `transfer` returns (see the remark above about
            // conditions -> effects -> interaction).
            pendingReturns[msg.sender] = 0;

            msg.sender.transfer(amount);
        }
    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd()
        public
        onlyAfter(biddingEnd)
    {
     //   require(threshold != highestBidder, "ccsdfrgv");
        require(!ended);
        emit AuctionEnded(highestBidder, maxBid);
        ended = true;
        beneficiary.transfer(maxBid);
    }
}
