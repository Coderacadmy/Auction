// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 < 0.9.0;

contract demo 
{
    
    //////// STRUCTS /////////
    
    struct Auction{
        address payable owner;
        string name;
        string description;
        uint minBid;
        uint MaxBid;
        uint threshold;
        uint startTime;
        uint endTime;
        uint bidIncrement;
    }
    
    struct MultiAuctions {
        address payable _owner;
        uint _id;
    }
    
    struct orders {
       address payable bidderAddresses;
       uint biddingAmount;
    }
    
    ///////// ARRAYS //////////
    
    address[] private bidderAddress; 
    
    address[] private ownerAddress;
    
    
     ////// state  //////
     
    uint public amount;
    bool public canceled;
    uint public highestBindingBid;
    address public highestBidder;
    bool ownerHasWithdrawn;
    
    Auction public auction;
    
    
    ////////////// MAPPING ///////////////

    mapping (address => uint[]) public ownerAuctions;
    
    mapping (address => uint[]) public bidderAuctions;
    
    mapping (uint => orders[]) public orderAuctions;
 
    mapping(address => uint256) public fundsByBidder;
    
    mapping(uint => Auction) public auctionData;
    
    mapping(address => uint) pendingReturns; 
    
    
    /////// EVENTS /////////

    event LogBid(address bidder, uint bid, address highestBidder, uint highestBid, uint highestBindingBid);
    
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
    
    event LogCanceled();
    
    event LogNewAuctioner(address newAuctioner); // adding
    
    event LogNewAuction(address saller, uint _auctioner); // adding
    
    event LogNewBidderAuctioner(address newAuctioner); // adding
    
    event LogNewBidderAuction(address saller, uint _auctioner); // adding
    
    
    /////// FUNCTIONS  //////////
    
    function startAuction (
        uint id,
        address payable owner,
        string memory name,
        string memory description,
        uint minBid,
        uint maxBid,
        uint threshold,
        uint startTime,
        uint endTime,
        uint bidIncrement
    ) 
        public
    {
        auctionData[id] = Auction(
            owner,
            name,
            description,
            minBid,
            maxBid,
            threshold,
            startTime,
            endTime,
            bidIncrement
        );
        updateAuctioner(owner);
    }
    
    
    function isOwner(address owner) public view returns(bool isIndeed) {
        // has auction before
        return ownerAuctions[owner].length > 0;
    }

      
    function updateAuctioner(address owner) public {
        if(!isOwner(owner)) {
            ownerAddress.push(owner);
            emit LogNewAuctioner(owner);
        }
    }
    
    
    function totalOwners() public view returns (uint) {
        return ownerAddress.length;
    }
    
    
    function setAuctioner(uint  _auctioner)  public {
            updateAuctioner(msg.sender);
            ownerAuctions[msg.sender].push(_auctioner);
            emit LogNewAuction(msg.sender, _auctioner);
    }
    
    
    function placeBid(address payable _bidder, uint amount, uint _id)
        public
        payable
        // onlyAfterStart
        // onlyBeforeEnd
        // onlyNotCanceled
        // onlyOwner
        returns (bool success)
    {
        updateBidderAuctioner(_bidder);
        
        
        // reject double bid from same address
        // require (msg.sender != bidderAccts, "You already placed a bin on this Auction");
        
        // reject payments of 0 ETH
        require (msg.value > auction.minBid,"value must be greater then minBid");

        // calculate the user's total bid based on the current amount they've sent to the contract
        // plus whatever has been sent with this transaction
        uint newBid = fundsByBidder[msg.sender] + msg.value;

        // if the user isn't even willing to overbid the highest binding bid, there's nothing for us
        // to do except revert the transaction.
        require (newBid > highestBindingBid,"your bid is less than the last bid");

        // grab the previous highest bid (before updating fundsByBidder, in case msg.sender is the
        // highestBidder and is just increasing their maximum bid).
        uint highestBid = fundsByBidder[highestBidder];

        fundsByBidder[msg.sender] = newBid;

        if (newBid <= highestBid) {
            // if the user has overbid the highestBindingBid but not the highestBid, we simply
            // increase the highestBindingBid and leave highestBidder alone.

            // note that this case is impossible if msg.sender == highestBidder because you can never
            // bid less ETH than you've already bid.

            highestBindingBid = min(newBid + auction.bidIncrement, highestBid);
        } else {
            // if msg.sender is already the highest bidder, they must simply be wanting to raise
            // their maximum bid, in which case we shouldn't increase the highestBindingBid.

            // if the user is NOT highestBidder, and has overbid highestBid completely, we set them
            // as the new highestBidder and recalculate highestBindingBid.

            if (msg.sender != highestBidder) {
                highestBidder = msg.sender;
                highestBindingBid = min(newBid, highestBid + auction.bidIncrement);
            }
            highestBid = newBid;
        }
        
        emit LogBid(msg.sender, newBid, highestBidder, highestBid, highestBindingBid);
        return true;
        
    }
    
    
    function isBidder(address _bidder) public view returns(bool isIndeed) {
        // has auction before
        return bidderAuctions[_bidder].length > 0;
    }

      
    function updateBidderAuctioner(address _bidder) public {
        if(!isBidder(_bidder)) {
            bidderAddress.push(_bidder);
            emit LogNewBidderAuctioner(_bidder);
        }
    }
    
    
    function totalBidder() public view returns (uint) {
        return bidderAddress.length;
    }
    
    
    function setBidderAuctioner(uint  _auctioner)  public {
            // there is no known rule about minimum bid, but let's say 0 is too low.
            updateBidderAuctioner(msg.sender);
            bidderAuctions[msg.sender].push(_auctioner);
            emit LogNewBidderAuction(msg.sender, _auctioner);
    }
    
    
    function min(uint a, uint b)
        private 
        pure
        returns (uint)
    {
        if (a < b) return a;
        return b;
    }
    
    
    function cancelAuction()
        public
        onlyOwner
        onlyBeforeEnd
        onlyNotCanceled
        returns (bool success)
    {
        canceled = true;
        emit LogCanceled();
        return true;
    }
    
    
    function withdraw() public {
        uint amount = fundsByBidder[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `transfer` returns (see the remark above about
            // conditions -> effects -> interaction).
            pendingReturns[msg.sender] = 0;

            payable(msg.sender).transfer(amount);
        }
    }
    
    
    /////// MODIFIERS  //////////

    modifier onlyOwner {
        require (msg.sender != auction.owner, "onlyNotOwner : : Owner cannot call this funtion");
        _;
    }

    modifier onlyAfterStart {
        require (now < auction.startTime,"onlyAfterStart : :   auction not started yet");
        _;
    }

    modifier onlyBeforeEnd {
        require (auction.startTime < auction.endTime, "onlyBeforeEnd :: Auction end");
        _;
    }

    modifier onlyNotCanceled {
        require (!canceled, "onlyNotCanceled :: Auction canceled");
        _;
    }

    modifier onlyEndedOrCanceled {
        require
        (now < auction.endTime && !canceled, "onlyEndedOrCanceled :: Time over and aucti");
        _;
    }
}
