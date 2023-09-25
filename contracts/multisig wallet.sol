// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract MultisigWallet{

    struct Transaction{
        address  to;
        bytes data;
        uint value;
        uint numOfConfirmation;
        bool completed;
    }
    address[] public  owners; // people who control the smartcontract
    mapping (address=> bool) public isOwner;  //state of each owner i.e either they confirmed or approved the Tx or not
    mapping (uint=>mapping (address=>bool)) public txConfirmed;  // state of each TxIndex after each owners decision
    Transaction[] public transactions;
    uint public numOfConfirmationsRequired;
    
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(address indexed owner,uint indexed txIndex,address indexed to,bytes data,uint amount);
    event ConfirmTransaction(address indexed to,uint indexed txIndex);
    event RevokeTransaction(address indexed to,uint indexed txIndex);
    event ExecuteTransaction(address indexed to,uint indexed txIndex);

    modifier onlyOwner(){
        require(isOwner[msg.sender],"not the owner");
        _;
    }
    modifier Txexists(uint _TxIndex){
        require(_TxIndex<transactions.length,"Transaction does notexists");   // if the total elements in the Transactions array is more than the TxIndex then that particular index doesnot exists
        _;
    }
    modifier Txnotexecuted(uint _TxIndex){
        require(!transactions[_TxIndex].completed,"transaction already executed");   //if the particular Tx in the whole transactions array is not completed
        _;
    }
    modifier Notconfirmed(uint _TxIndex){
        require(!txConfirmed[_TxIndex][msg.sender],"transaction already confirmed");   //if the particular Tx in the whole transactions array is not completed
        _;
    }
    constructor(address[] memory _owners,uint _numofConfirmationsRequired){
        require(_owners.length>2,"owners required");
        require(_numofConfirmationsRequired>0 && _numofConfirmationsRequired<=_owners.length,"no of confirmations is not in order with total owners");
        numOfConfirmationsRequired=_numofConfirmationsRequired;
        for(uint i=0; i<_owners.length; i++){
            require(_owners[i] != address(0),"owner not in the database");
            owners.push(_owners[i]);  
        }            
}

    function getOwners() public view returns(address[]  memory) {
        return owners;
    }
    receive() external payable{
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    
    function submitTransaction(address _to,bytes memory _data,uint _amount) public onlyOwner{
        uint txIndex=transactions.length;
        transactions.push(Transaction({
            to:_to,
            data:_data,
            value:_amount,
            numOfConfirmation:0,
            completed:false
            })
        );
        emit SubmitTransaction(msg.sender, txIndex, _to, _data, _amount);
    }
    function confirmTransaction(uint _txIndex) public onlyOwner Txexists(_txIndex) Txnotexecuted(_txIndex) Notconfirmed(_txIndex){
        Transaction storage thistransaction= transactions[_txIndex];
        thistransaction.numOfConfirmation += 1;
        txConfirmed[_txIndex][msg.sender]=true;
        emit ConfirmTransaction(msg.sender, _txIndex);
    }
    function executeTransaction(uint _txIndex) public onlyOwner Txexists(_txIndex) Txnotexecuted(_txIndex) {
        Transaction storage thistransaction= transactions[_txIndex];
        require(thistransaction.numOfConfirmation>numOfConfirmationsRequired);
        thistransaction.completed=true;
        (bool success,)= thistransaction.to.call{value: thistransaction.value}(thistransaction.data);
        require(success,"Tx failed");
        emit ExecuteTransaction(msg.sender, _txIndex);
    }
    function revokeConfirmation(uint _txIndex) public onlyOwner{
        Transaction storage thistransaction= transactions[_txIndex];
        require(txConfirmed[_txIndex][msg.sender],"Tx not confirmed");
        thistransaction.numOfConfirmation -=1;
        txConfirmed[_txIndex][msg.sender]=false;
        emit RevokeTransaction(msg.sender, _txIndex);
    }
    function gettotalTx() public view returns(uint){
        return transactions.length;
    }
    function getthetransaction(uint _txIndex) public view returns(address to,bytes memory data, uint value, uint numOfConfirmation,bool completed){
        Transaction storage thetransaction= transactions[_txIndex];
        return (
        thetransaction.to,
        thetransaction.data,
        thetransaction.value,
        thetransaction.numOfConfirmation,
        thetransaction.completed
        );
    }
}