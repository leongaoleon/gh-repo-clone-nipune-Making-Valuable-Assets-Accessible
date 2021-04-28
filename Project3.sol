pragma solidity ^0.5.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/Crowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/emission/MintedCrowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/validation/TimedCrowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/distribution/RefundablePostDeliveryCrowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20Detailed.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20Mintable.sol";

// Contract Address: 0x7d7FA8911824b2BDeD6E6C7693843Ffa9f938d23
// The Contract will be called by Python to Update Struct !!!!!
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
    
    // function for external user to retrive infomation stored in mapping!!!!!
    function Get_share_price(string memory data) public view returns(uint) {
        return History[data].share_price;
    }
    function Get_ETH_price(string memory data) public view returns(uint) {
        return History[data].ETH_price;
    }
    function Get_num_ETH(string memory data) public view returns(uint) {
        return History[data].num_ETH_required;
    }
}


// Contract Address: 0xd5B84E58f6022f4c69bC1460588c9110af8a521e
contract BHCoinSaleDeployer {
    
    using SafeMath for uint;
    
    GoalDeployer GoalDeployerContract;
    
    // Address of GoalDeployer !!!!!
    address internal Address = address(0x7d7FA8911824b2BDeD6E6C7693843Ffa9f938d23);
    address payable owner = msg.sender; 
    uint public required_ETH_at_deploy; //number of ETH required
    address public token_sale_address; 
    address public token_address;
    
    constructor(
        // Fill in the constructor parameters
        string memory name,
        string memory symbol,
        address payable _owner // this address will receive all Ether raised by the sale after finalized!!!!!
    )
        public
    {
        // Connect to GoalDeployer Contract !!!!!
        GoalDeployerContract = GoalDeployer(Address);
        required_ETH_at_deploy = GoalDeployerContract.Recent_required_ETH();
        
        _owner = owner;
        
        // create the BHCoin and keep its address handy
        BHCoin token = new BHCoin(_owner, name, symbol, 0, required_ETH_at_deploy);
        token_address = address(token);
        
        
        // Conversion: 1 token to 1 ETH, target is the required ETH Crowsale, target*1000000000000000000 is in TKNbits / Wei !!!!!
        // Trading Time of New York Stock Exchange (NYSE):
        // Pre-market trading typically occurs between 8:00 a.m. and 9:30 a.m.
        // Market Trading 09:30 a.m. to 16:00 p.m.
        // Our contract will initialize at 16:00 p.m. daily and close in two hours.
        
        // For testing purpose, the required ETH is scaled down by 10 times. !!!!!
        // For testing purpose, the contract can be initiazlise at anytime and close in two minutes. !!!!!
        
        BHCoinSale BHCoin_sale = new BHCoinSale(_owner, 1, token, required_ETH_at_deploy.mul(10000000000000000), required_ETH_at_deploy.mul(10000000000000000),
        now, now + 3 minutes); /////////
        token_sale_address = address(BHCoin_sale);
        
        
        // Make the BHCoinSale contract a minter, then have the BHCoinSaleDeployer renounce its minter role
        token.addMinter(token_sale_address);
        token.renounceMinter();
    }
    
    // Get Mapping of another Contract !!!!!
    function Get_history(string memory date) public view returns(string memory, uint256, uint256, uint256) {
        return GoalDeployerContract.History(date);
        }
}


// Contract Address 0x688bE037cd639254C082Ca1e1bB88F9817174183
// Inherit the crowdsale contracts
contract BHCoinSale is Crowdsale, MintedCrowdsale, CappedCrowdsale, TimedCrowdsale, RefundablePostDeliveryCrowdsale {
    
    address payable _owner;
    
    constructor(
        // Fill in the constructor parameters!
        address payable owner, // sale beneficiary
        uint rate, // rate in TKNbits
        BHCoin token, // the BHCoin itself that the BHCoinSale will work with
        uint256 goal,
        uint256 cap,
        uint256 openingTime,
        uint256 closingTime
    )
        // Pass the constructor parameters to the crowdsale contracts.
        Crowdsale(rate, owner, token)
        RefundableCrowdsale(goal)
        CappedCrowdsale(cap)
        TimedCrowdsale(openingTime, closingTime)
        public
    {
        // empty constructor
    }
    
    // Calculating remaining goal
    function Goal_Remaining() public view returns(uint) {
        return cap().sub(weiRaised());
    }
}


contract BHCoin is ERC20, ERC20Detailed, ERC20Mintable {
    
    using SafeMath for uint;
    
    GoalDeployer GoalDeployerContract;
    
    // Address of GoalDeployer !!!!!
    address internal Address = address(0x7d7FA8911824b2BDeD6E6C7693843Ffa9f938d23);
    address payable owner;
    uint initial_supply;
    uint start_time = now;
    uint unlock_time = now + 1 seconds;   // 365 days Account Lock, for testing, use 1 sec
    uint waiting_period = now + 2 seconds; // allow 365 days to redeem, for testing, use 2 sec

    uint public raised_Wei_at_deploy;
    uint public updated_share_price;
    uint public updated_ETH_price;
    uint public updated_num_Wei_to_deposit;
    uint public worth_coin_to_100Wei;
    
    constructor(
        address payable _owner,
        string memory name,
        string memory symbol,
        uint _initial_supply,
        uint _required_ETH_at_deploy
    )
        ERC20Detailed(name, symbol, 18)
        public
    {
        owner = _owner;
        initial_supply = _initial_supply;
        raised_Wei_at_deploy = _required_ETH_at_deploy.mul(10000000000000000);
        GoalDeployerContract = GoalDeployer(Address);       
    }
    
        
    // Get Updated BRK and ETH Prices !!!!!
    function Get_Updated_Prices(string memory date) public {
        require(msg.sender == owner, "You are NOT the owner!");
        updated_share_price = GoalDeployerContract.Get_share_price(date);
        updated_ETH_price = GoalDeployerContract.Get_ETH_price(date);
        updated_num_Wei_to_deposit = GoalDeployerContract.Get_num_ETH(date).mul(10000000000000000);
        
        // Checking the Prices is Updated
        if (updated_share_price>0 && updated_ETH_price>0) {
            // Solidity ONLY Accepts Int !!!!!
            // Scale up x100 (it will be scale down by 100 when withdraw !!!!!
            worth_coin_to_100Wei = updated_share_price.mul(100).mul(10000000000000000).div(updated_ETH_price).div(raised_Wei_at_deploy);
        }    
            else {
                revert("The Owner has NOT yet Updated the Prices"); 
        }    
    }
    
    // Owner deposit back for user to redeem tokens !!!!!
    function Owner_deposit_ETH_back() public payable  {
        require(msg.sender == owner, "You are NOT the owner!");
        require(unlock_time <= now, "Account is Locked!");
        require(address(this).balance <= updated_num_Wei_to_deposit, "Exceed Required Deposit!");
        require(msg.value == updated_num_Wei_to_deposit, "Need to deposit back the updated_num_Wei!");
    }
    
    // Check current ETH balance in this contract
    function ETH_balance_to_redeem() public view returns(uint) {
        return address(this).balance;
    }
    
    // User will have to successfully send back their token to withdraw ETH at updated rate !!!!!!
    function User_Redeem_Token_Amount(uint amount) public payable {
        // checking various conditions before making transactions
        require(unlock_time <= now, "Account is Locked!");
        require(amount <= balanceOf(msg.sender), "You Don`t have Enogugh Balance of BHCoin!"); 
        require(address(this).balance >= 0, "No Enogugh ETH Available!");
        require(updated_share_price>0 && updated_ETH_price>0, "The Owner has NOT yet Updated the Prices");

        if (transfer(address(this), amount)) {
             // scale down x100 !!!!!
            msg.sender.transfer(amount.mul(worth_coin_to_100Wei).div(100));
        }    
            else {
                revert("Token Tansfer Error!");
            }    
    }
    
    // Allow Owner to withdraw any remaining funds after all user has redeemed
    // Allow 365 days to redeem, then Owner can withdraw any remaining funds 
    function Owner_Withdraw_Unused_ETH(uint amount) public payable {
        require(msg.sender == owner, "You are NOT the owner!");    
        require(ETH_balance_to_redeem()>= 0, "No enough balance!");
        require((balanceOf(address(this)) == raised_Wei_at_deploy || waiting_period <= now), "wait for user to redeem!");
        msg.sender.transfer(amount);
    }
}

