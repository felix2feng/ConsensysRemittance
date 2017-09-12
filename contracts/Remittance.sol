pragma solidity ^0.4.4;

contract Owned {
    address owner;
    
    function Owned () {
        owner = msg.sender;
    }
    
    modifier onlyOwner () {
        require(msg.sender == owner);
        _;
    }
}

contract Remittance is Owned {
    uint fee;
    
    event LogWithdrawal(address _address, uint amount);
    event LogDeposit(address _address, uint amount, bytes32 hash);
    
    struct Remitter {
        address owner;
        uint balance;
        uint deadline; // Deadline in block number
    }
    
    mapping(bytes32 => Remitter) public remittances;
    
    function Remittance() {
        // Deploying contract costs 543827 gas
        fee = 400000;
    }
    
    // @param passCode The hash of two hashed inputs
    function deposit(bytes32 passCode, uint deadline) 
        payable
        returns (bool)
    {
        // 1 day (1 day * 24 hour/day * 60min/hour * 
        // 60secs/min * 1 block/20 secs)
        uint dayInBlocks = 24 * 60 * 60 / 20;
        uint weekInBlocks = dayInBlocks * 7;
           
        require(deadline != 0);
        require(deadline >= dayInBlocks && deadline <= weekInBlocks);
        require(passCode != 0);
        
        // Require that the passcode is unique and not a reuse
        // We know it has been used if a previous owner is set
        require(remittances[passCode].owner == 0);
        
        remittances[passCode].owner = msg.sender;
        remittances[passCode].balance = msg.value;
        remittances[passCode].deadline = block.number + deadline;
        
        LogDeposit(msg.sender, msg.value, passCode);
        
        return true;
    }
    
    function withdraw(bytes32 hash1, bytes32 hash2) 
        public
        returns (bool)
    {
        var passCodeAttempt = hashTwoInputs(hash1, hash2);
        // There must be a balance in the hashed figure
        uint currentBalance = remittances[passCodeAttempt].balance;
        
        // There must be a balance in the hashed result
        require(currentBalance != 0);
        
        uint deadlineBlock = remittances[passCodeAttempt].deadline;
        
        if (owner == msg.sender) {
            // If the sender is the owner, he can only withdraw after deadline
            require(block.number > deadlineBlock);
        } else {
            // The current block must be before the deadline to withdraw
            require(block.number <= deadlineBlock);    
        }
        
        remittances[passCodeAttempt].balance = 0;
        
        msg.sender.transfer(currentBalance - fee);
        
        owner.transfer(fee);
        
        LogWithdrawal(msg.sender, currentBalance - fee);
        
        return true;
    }
    
    function hashTwoInputs(bytes32 input1, bytes32 input2) returns(bytes32) {
        return keccak256(input1, input2);
    }
    
    function hashSingleInput(bytes32 input1) returns(bytes32) {
        return keccak256(input1);
    }
    
    function killContract () 
        onlyOwner()
        returns (bool)
    {
        // All ether in the contract is sent to the owner
        // and the storage and code is removed from state
        selfdestruct(owner);
        return true;
    }
}
