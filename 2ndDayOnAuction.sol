// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 < 0.9.0;

contract demo 
{
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
    
    Auction public auction;
    
        // state
    
    bool public canceled;
    uint public highestBindingBid;
    address public highestBidder;
    bool ownerHasWithdrawn;
    
    ////////////// MAPPING ///////////////
    
    mapping(address => uint256) public fundsByBidder;
    mapping(uint => Auction) public auctionData;

    event LogBid(address bidder, uint bid, address highestBidder, uint highestBid, uint highestBindingBid);
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
    event LogCanceled();

    
    function startAuction(uint _id, address payable _owner, string memory _name, string memory _description, uint _minBid, uint _maxBid, uint _threshold, uint _startTime, uint _endTime, uint _bidIncrement) public
    {
        auctionData[_id] = Auction(_owner, _name, _description, _minBid, _maxBid, _threshold, _startTime, _endTime, _bidIncrement);
    }
    
    function placeBid()
        public
        payable
        onlyAfterStart
        onlyBeforeEnd
        onlyNotCanceled
        onlyNotOwner
        returns (bool success)
    {
        // reject payments of 0 ETH
        require (msg.value == 0);

        // calculate the user's total bid based on the current amount they've sent to the contract
        // plus whatever has been sent with this transaction
        uint newBid = fundsByBidder[msg.sender] + msg.value;

        // if the user isn't even willing to overbid the highest binding bid, there's nothing for us
        // to do except revert the transaction.
        require (newBid <= highestBindingBid);

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
    
    
    function min(uint a, uint b)
        private 
        pure
        returns (uint)
    {
        if (a < b) return a;
        return b;
    }
    
    modifier onlyOwner {
        require (msg.sender != auction.owner);
        _;
    }

    modifier onlyNotOwner {
        require (msg.sender == auction.owner);
        _;
    }

    modifier onlyAfterStart {
        require (block.number < auction.startTime);
        _;
    }

    modifier onlyBeforeEnd {
        require (block.number > auction.endTime);
        _;
    }

    modifier onlyNotCanceled {
        require (canceled);
        _;
    }

    modifier onlyEndedOrCanceled {
        require
        (block.number < auction.endTime && !canceled);
        _;
    }
}
