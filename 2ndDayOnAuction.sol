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
    address payable public bidder;
    uint public amount;
    bool public canceled;
    uint public highestBindingBid;
    address public highestBidder;
    bool ownerHasWithdrawn;
    
    ////////////// MAPPING ///////////////
    
    mapping(address => uint256) public fundsByBidder;
    mapping(uint => Auction) public auctionData;
    mapping(address => uint) pendingReturns; 

    event LogBid(address bidder, uint bid, address highestBidder, uint highestBid, uint highestBindingBid);
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
    event LogCanceled();

    
    function startAuction(uint id, address payable owner, string memory name, string memory description, uint minBid, uint maxBid, uint threshold, uint startTime, uint endTime, uint bidIncrement) public
    {
        auctionData[id] = Auction(owner, name, description, minBid, maxBid, threshold, startTime, endTime, bidIncrement);
    }
    
    function placeBid(address payable bidder, uint amount, uint _id)
        public
        payable
        // onlyAfterStart
        // onlyBeforeEnd
        // onlyNotCanceled
        // onlyNotOwner
        returns (bool success)
    {
        // reject payments of 0 ETH
        require (msg.value > 0,"value must be greater then 0");

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
    
    
    // function withdraw()
    //     public
    //     onlyEndedOrCanceled
    //     returns (bool success)
    // {
    //     address withdrawalAccount;
    //     uint withdrawalAmount;

    //     if (canceled) {
    //         // if the auction was canceled, everyone should simply be allowed to withdraw their funds
    //         withdrawalAccount = msg.sender;
    //         withdrawalAmount = fundsByBidder[withdrawalAccount];

    //     } else {
    //         // the auction finished without being canceled

    //         if (msg.sender == auction.owner) {
    //             // the auction's owner should be allowed to withdraw the highestBindingBid
    //             withdrawalAccount = highestBidder;
    //             withdrawalAmount = highestBindingBid;
    //             ownerHasWithdrawn = true;

    //         } else if (msg.sender == highestBidder) {
    //             // the highest bidder should only be allowed to withdraw the difference between their
    //             // highest bid and the highestBindingBid
    //             withdrawalAccount = highestBidder;
    //             if (ownerHasWithdrawn) {
    //                 withdrawalAmount = fundsByBidder[highestBidder];
    //             } else {
    //                 withdrawalAmount = fundsByBidder[highestBidder] - highestBindingBid;
    //             }

    //         } else {
    //             // anyone who participated but did not win the auction should be allowed to withdraw
    //             // the full amount of their funds
    //             withdrawalAccount = msg.sender;
    //             withdrawalAmount = fundsByBidder[withdrawalAccount];
    //         }
    //     }

    //     require (withdrawalAmount == 0, "Exception");

    //     fundsByBidder[withdrawalAccount] -= withdrawalAmount;

    //     // send the funds
    //     require (!msg.sender.send(withdrawalAmount), "through Exception");

    //     LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);

    //     return true;
    // }
    
    
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

    
    modifier onlyOwner {
        require (msg.sender != auction.owner);
        _;
    }

    modifier onlyNotOwner {
        require (msg.sender == auction.owner);
        _;
    }

    modifier onlyAfterStart {
        require (block.timestamp > auction.startTime,"auction not started yet");
        _;
    }

    modifier onlyBeforeEnd {
        require (block.timestamp < auction.endTime);
        _;
    }

    modifier onlyNotCanceled {
        require (!canceled);
        _;
    }

    modifier onlyEndedOrCanceled {
        require
        (block.timestamp < auction.endTime && !canceled);
        _;
    }
}
