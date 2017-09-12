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
    
    bytes32 hashedPassword;
    uint withdrawDeadline;

    event LogWithdrawal(address _address, uint amount);
    
    // Constructor Function
    function Remittance(
        string emailPw, 
        string smsPw,
        uint deadline
    ) 
        payable 
    {
        // The deadline can only be less than 10k blocks
        // in the future
        require(deadline < 10000);
        
        // Contract is instantiated with supplied passwords
        // The passwords are hashed as to be able to be read
        hashedPassword = keccak256(emailPw, smsPw);
        
        // Set the deadline
        withdrawDeadline = block.number + deadline;
    }
    
    function withdraw(string emailPw, string smsPw) 
        public
        returns (bool)
    {
        require(hashedPassword == keccak256(emailPw, smsPw));
        msg.sender.transfer(this.balance);
        LogWithdrawal(msg.sender, this.balance);
        return true;
    }
    
    function killContract () 
        onlyOwner()
        returns (bool)
    {
        // All ether in the contract is sent to the owner
        // and the storage and code is removed from state
        selfdestruct(owner);
    }
}
