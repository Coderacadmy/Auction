// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 < 0.9.0;

contract demo 
{
    struct Auction{
        address payable owner;
        string name;
        string description;
        uint minBid;
        uint maxBid;
        uint threshold;
        uint startTime;
        uint endTime;
        uint bidIncrement;
    }
    
    Auction public auction;
    
     ////// state  //////
     
    address payable public bidder;
    uint public amount;
    bool public canceled;
    uint public highestBindingBid;
    address public highestBidder;
    bool ownerHasWithdrawn;
    uint public biddingEnd;
    
    ////////////// MAPPING ///////////////
    
    mapping(address => uint256) public fundsByBidder;
    mapping(uint => Auction) public auctionData;
    mapping(address => uint) pendingReturns; 
    
    
    ////////////////// modifier /////////////////////
    
    modifier onlyBefore(uint _time) { require(block.timestamp < _time); _; }
    modifier onlyAfter(uint _time) { require(block.timestamp > _time); _; }
    
    modifier onlyOwner { require (msg.sender != auction.owner); _; }
    modifier onlyNotOwner { require (msg.sender == auction.owner); _; }
    modifier onlyAfterStart { require (block.number < auction.startTime); _; }
    modifier onlyBeforeEnd { require (block.number > auction.endTime); _; }
    modifier onlyNotCanceled { require (canceled); _; }
    modifier onlyEndedOrCanceled { require (block.number < auction.endTime && !canceled); _; }
    
    
    ////////////////////  EVENTS //////////////////

    event LogBid(address bidder, uint bid, address highestBidder, uint highestBid, uint highestBindingBid);
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
    event LogCanceled();
    
    
    
    /////////////////   FUNCTIONS  //////////////////

    
    function startAuction(uint _id, address payable _owner, string memory _name, string memory _description, uint _minBid, uint _maxBid, uint _threshold, uint _startTime, uint _endTime, uint _bidIncrement) public
    {
        auctionData[_id] = Auction(_owner, _name, _description, _minBid, _maxBid, _threshold, _startTime, _endTime, _bidIncrement);
    }
    
       
    function bid(address _bid, uint value)   
       public
        payable
        onlyBefore(biddingEnd)
    {
        // If the bid is not higher, send the money back
        // (the failing require will revert all changes in this function execution including it having received the money).
        require(msg.value >= auction.minBid, "Your bid is lower then minimum bidding amount. Try bidding higher!");
        require(msg.value >= auction.threshold, "thereshold achiieved");
        require(msg.sender != auction.owner);
 //       require(!bids[Bid]Bid.bidd, "You already placed a bid");
        
        
        // auction[msg.sender].push(Auction({
        //     bid: _bid,
        //     deposit: msg.value
        // }));
    }
    
        // This is an "internal" function which means that it
    // can only be called from the contract itself (or from
    // derived contracts).
    function placeBid(address bidder, uint value) internal
            returns (bool success)
    {
        if (value <= auction.maxBid || value <= auction.minBid) {
            return false;
        }
        if (highestBidder != address(0)) {
            // Refund the previously highest bidder.
            pendingReturns[highestBidder] += auction.maxBid;
        }
        auction.maxBid = value;
        highestBidder = bidder;
        return true;
    }
    
    
    
}    
