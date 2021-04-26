pragma solidity ^0.5.0;

import "./BHCoin.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/Crowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/emission/MintedCrowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/validation/TimedCrowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/distribution/RefundablePostDeliveryCrowdsale.sol";

// Contract Address: 0x9b9a1a65D1bc7544F781e6B10C3749167CfAcB20
// The Contract will be called by Python to Update Vaiables
contract GoalDeployer {
    uint public Recent_required_ETH;
    address owner = msg.sender;
    
    struct history {
        string date;
        uint share_price;
        uint ETH_price;
        uint num_ETH_required;
    }

    mapping(string => history) public History;
    
    // Event log about share&ETH prices, and number of ETH required
    event goal(string date, uint share_price, uint ETH_price, uint num_ETH_required);
    
    // Use Python to Update Variables, then the event is recorded and emitted
    function Update(string memory date, uint share_price, uint ETH_price, uint num_ETH_required) public returns(uint) {
        require(msg.sender == owner, "You are NOT the Oner!");
        
        Recent_required_ETH = num_ETH_required;
        
        History[date].share_price = share_price;
        History[date].ETH_price = ETH_price;
        History[date].num_ETH_required = num_ETH_required;

        emit goal(date, share_price, ETH_price, num_ETH_required);

        return History[date].num_ETH_required;
    }
}

// Contract Address: 0xd5B84E58f6022f4c69bC1460588c9110af8a521e
contract BHCoinSaleDeployer {
    
    GoalDeployer GoalDeployerContract;
    
    // Address of GoalDeployer !!!!!
    address internal Address = address(0x9b9a1a65D1bc7544F781e6B10C3749167CfAcB20);
    uint public required_ETH_at_deploy; // number of ETH required
    address public token_sale_address;
    address public token_address;
    
    constructor(
        // Fill in the constructor parameters
        string memory name,
        string memory symbol,
        address payable wallet // this address will receive all Ether raised by the sale
    )
        public
    {
        // Connect to GoalDeployer Contract !!!!!
        GoalDeployerContract = GoalDeployer(Address);
        required_ETH_at_deploy = GoalDeployerContract.Recent_required_ETH();
        
        
        // create the BHCoin and keep its address handy
        BHCoin token = new BHCoin(name,symbol,0);
        token_address = address(token);
        
        
        // Conversion: 1 token to 1 ETH, target is the required ETH Crowsale, target*1000000000000000000 is in TKNbits / Wei !!!!!
        // Trading Time of New York Stock Exchange (NYSE):
        // Pre-market trading typically occurs between 8:00 a.m. and 9:30 a.m.
        // Market Trading 09:30 a.m. to 16:00 p.m.
        // Our contract will initialize at 16:00 p.m. daily and close in two hours.
        
        // For testing purpose, the required ETH is scaled down by 10 times. !!!!!
        // For testing purpose, the contract can be initiazlise at anytime and close in two minutes. !!!!!
        
        // Create the BHCoinSale and pass the required arguments to it
        BHCoinSale BHCoin_sale = new BHCoinSale(1, wallet, token, required_ETH_at_deploy*1000000000000000000, 
        required_ETH_at_deploy*1000000000000000000, now, now + 2 minutes);
        token_sale_address = address(BHCoin_sale);
        
        
        // make the BHCoinSale contract a minter, then have the BHCoinSaleDeployer renounce its minter role
        token.addMinter(token_sale_address);
        token.renounceMinter();
    }
    // Get Mapping of another Contract !!!!!
    function Get_history(string memory date) public view returns(string memory, uint256, uint256, uint256)  {
        return GoalDeployerContract.History(date);
        }
}


// Contract Address 0x688bE037cd639254C082Ca1e1bB88F9817174183
// Inherit the crowdsale contracts
contract BHCoinSale is Crowdsale, MintedCrowdsale, CappedCrowdsale, TimedCrowdsale, RefundablePostDeliveryCrowdsale {

    constructor(
        // Fill in the constructor parameters!
        uint rate, // rate in TKNbits
        address payable wallet, // sale beneficiary
        BHCoin token, // the BHCoin itself that the BHCoinSale will work with
        uint256 goal,
        uint256 cap,
        uint256 openingTime,
        uint256 closingTime
    )
        // Pass the constructor parameters to the crowdsale contracts.
        Crowdsale(rate, wallet, token)
        RefundableCrowdsale(goal)
        CappedCrowdsale(cap)
        TimedCrowdsale(openingTime, closingTime)
        public
    {
        // constructor can stay empty
    }
}


