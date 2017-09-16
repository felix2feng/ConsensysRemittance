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
    event LogDeposit(address _address, address _recipient, uint amount, bytes32 hash);
    
    struct Remitter {
        address owner;
        address recipient;
        uint balance;
        uint deadline; // Deadline in block number
        bytes32 passCode1;
        bytes32 passCode2;
    }
    
    mapping(bytes32 => Remitter) public remittances;
    mapping(bytes32 => bool) public usedPasscodes;
    
    function Remittance() {
        // Deploying contract costs 543827 gas
        fee = 400000;
    }
    
    // @param passCode The hash of two hashed inputs
    function deposit(bytes32 hashCode1, bytes32 hashCode2, uint deadline, address recipient) 
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

        bytes32 doublyHashedPasscode = hashTwoInputs(hashCode1, hashCode2);
        
        // Require that the passcode is unique and not a reuse
        // We know it has been used if a previous owner is set
        require(remittances[passCode].owner == 0);

        // Require that previous indiividual passcodes have not been used
        require(usedPasscodes[hashCode1] == 0);
        require(usedPasscodes[hashCode2] == 0);
        
        remittances[passCode].owner = msg.sender;
        remittances[passCode].recipient = recipient;
        remittances[passCode].balance = msg.value;
        remittances[passCode].deadline = block.number + deadline;

        // Log used passcodes so they cannot be used again
        usedPassCodes[hashCode1] = true;
        usedPassCodes[hashCode2] = true;
        
        LogDeposit(msg.sender, recipient, msg.value, passCode);
        
        return true;
    }
    
    function withdraw(string passcode1, string passcode2) 
        public
        returns (bool)
    {
        bytes32 hashedCode1 = hashOneInput(passcode1);
        bytes32 hashedCode2 = hashOneInput(passcode2);

        bytes32 remittanceLocation = hashTwoInputs(hashedCode1, hashedCode2);

        require(remittances[remittanceLocation].passCode1 == hashedCode1);
        require(remittances[remittanceLocation].passCode2 == hashedCode2);

        // There must be a balance in the hashed figure
        uint currentBalance = remittances[remittanceLocation].balance;
        
        // There must be a balance in the hashed result
        require(currentBalance != 0);
        
        uint deadlineBlock = remittances[remittanceLocation].deadline;
        
        if (owner == msg.sender) {
            // If the sender is the owner, he can only withdraw after deadline
            require(block.number > deadlineBlock);
        } else {
            // The caller of this function must be the recipient
            require(msg.sender == remittances[passwordAttempt].recipient);

            // The current block must be before the deadline to withdraw
            require(block.number <= deadlineBlock);    
        }
        
        remittances[remittanceLocation].balance = 0;
        
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
