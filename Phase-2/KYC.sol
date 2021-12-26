pragma solidity ^0.5.9;

contract KYC{

    address admin;

    // This stores total number of banks added by admin
    uint numBanks;

    struct Customer {
        string userName;   
        string data; 
        //This boolean captures status of the KYC request
        bool kycStatus; 
        //Number of downvotes received
        uint downVotes;
        //NUmber of upvotes recieved
        uint upVotes;
        address bank;
    }
    
    struct Bank {
        string name;
        address ethAddress;
        //Number of complaints against this bank
        uint complaintsReported;
        //Number of KYC requests initiated by this bank
        uint KYC_count;
        //Status of the bank
        bool isAllowedToVote;
        string regNumber;
    }

    struct Kyc_request {
      //Maps the KYC request to the customer data
      string userName;
      address bankAddress;
      //Customer's data or identity documents provided by the customer.
      string data;
    }

    mapping(string => Customer) customers;

    mapping(address => Bank) banks;
    mapping(string =>Kyc_request) requests;
  
    //msg.sender as admin while deploying the smart contract
    constructor() public{
      admin = msg.sender;
    }
    
    //modifier to check for admin functionalities
    modifier isadmin(address _senderAddress){
      require(_senderAddress == admin,"This api can only be called by admin");
      _;
    }

    //Modifier to Check that bank is allowed to vote 
    modifier isbankvalid(address _bankAddress){
        require(banks[msg.sender].isAllowedToVote == true,"Bank is not allowed to vote");
        _;
    }

///////////////////////////////Bank Interface/////////////////////////////////////

    //This function is used to add the KYC request to the requests list
    // This function is only accesed by valid bank
    function addRequest(string memory _userName, string memory _customerData) public isbankvalid(msg.sender){
        
        //check whether the customer exists before addKycrequest.
        require(customers[_userName].bank != address(0), "Customer is not present in the database");
       
        requests[_userName].userName = _userName;
        requests[_userName].data = _customerData;
        requests[_userName].bankAddress = msg.sender;

        //Increment KYC count for this bank
        banks[msg.sender].KYC_count++;

    }
    
    //This function will remove the request from the requests list.
    function removeRequest(string memory _userName) public {
      //error handling
      require(requests[_userName].bankAddress != address(0),"No request is present for this user" );

      delete requests[_userName];
    }

    //This function will add a customer to the customer list. 
    // Can only be accessed by valid bank
    function addCustomer(string memory _userName, string memory _customerData) public isbankvalid(msg.sender) {
        //error handling 
        require(customers[_userName].bank == address(0), "Customer is already present, please call modifyCustomer to edit the customer data");

        customers[_userName].userName = _userName;
        customers[_userName].data = _customerData;
        customers[_userName].bank = msg.sender;

        //Initialize upvotes and downvotes to 0 ans set kyc status to false
        customers[_userName].kycStatus = false;
        customers[_userName].downVotes = 0;
        customers[_userName].upVotes = 0;

    }
    
    //This function allows a bank to view the details of a customer.
    function viewCustomer(string memory _userName) public view returns (string memory, string memory, bool, uint, uint, address) {
        require(customers[_userName].bank != address(0), "Customer is not present in the database");
        
        return (customers[_userName].userName, customers[_userName].data, customers[_userName].kycStatus, customers[_userName].downVotes, 
        customers[_userName].upVotes, customers[_userName].bank);
    }
    
    //This function allows a bank to modify a customer's data
    // Can only be accessed by valid bank
    function modifyCustomer(string memory _userName, string memory _newcustomerData) public isbankvalid(msg.sender) {
        require(customers[_userName].bank != address(0), "Customer is not present in the database");

        customers[_userName].data = _newcustomerData;

        //This will remove the customer from the KYC request list and set the number of downvotes and upvotes to zero. 
        customers[_userName].downVotes = 0;
        customers[_userName].upVotes = 0;
        // Remove the request if present
        if(requests[_userName].bankAddress != address(0))
        {
          removeRequest(_userName);
        }
    }    

    // Logic to certain KYC status of customer
    function setKYCstatus(string memory _userName) public{
      // If the number of upvotes is greater than the number of downvotes, then the kycStatus of that customer is set to true
      if(customers[_userName].upVotes > customers[_userName].downVotes){
        customers[_userName].kycStatus = true;  
      }
      //If a customer gets downvoted by one-third of the banks, then the kycStatus of the customer is changed to false
      if(numBanks>=5){
        if(customers[_userName].downVotes > numBanks/3){
          customers[_userName].kycStatus = false;  
        }
      }
    }
    //This function allows a bank to cast a upvote for a customer.
    function upvoteCustomer(string memory _userName) public{

      customers[_userName].upVotes ++;
      // Set KYC status for this customer on receiving update in upvotes
      setKYCstatus(_userName);
    }
    //This function allows a bank to cast a downvote for a customer.
    function downvoteCustomer(string memory _userName) public{

      customers[_userName].downVotes ++;
      // Set KYC status for this customer on receiving update in downvotes
      setKYCstatus(_userName);

      // If the customer verified by a bank gets more nunbanks/2 downvotes, then the bank gets invalidated.
      if(numBanks > 5 &&
         customers[_userName].downVotes > numBanks/2){
        banks[customers[_userName].bank].isAllowedToVote = false;
      }
    }
    // This function returns complain reported against banks
    function Get_bank_complaints(address _bankAddress) public view returns(uint){

      return banks[_bankAddress].complaintsReported;
    }
    //This function is used to fetch the bank details.


    // This function contains logic to check if bank is corrupted 
    function if_bank_corrupted_disallow(address _bankAddress) public {

      //If more than one-third of the total banks in the network complain against this bank
      if(banks[_bankAddress].complaintsReported > numBanks/3){
        banks[_bankAddress].isAllowedToVote = false;
      }

    }
    //This function is used to report a complaint against any bank in the network
    function reportBank(address _bankAddress, string memory _bankName) public{

      banks[_bankAddress].complaintsReported ++;
      // If a bank is corrupted disallow it from voting
      if_bank_corrupted_disallow(_bankAddress);

    }
    
    // Function to view bank details
    // Please note in question it's asked to to return Bank struct as a whole but it's not posssible in solidity
    // Hence returning each element individually
    function view_bankDetails(address _bankAddress) public view returns(string memory, address,
    uint, uint, bool, string memory)
    {
      require(banks[_bankAddress].ethAddress != address(0), "Bank is not present in the database");
        
      return (banks[_bankAddress].name, banks[_bankAddress].ethAddress, banks[_bankAddress].complaintsReported,
      banks[_bankAddress].KYC_count, banks[_bankAddress].isAllowedToVote,banks[_bankAddress].regNumber);
    }
    /////////////////////////////////////////////////////////////
    ///////////////////// Admin Interface ///////////////

    //This function is used by the admin to add a bank to the KYC Contract
    function addbank(string memory _bankName, address _bankAddress, string memory _regNumber) public isadmin(msg.sender){
        // Increment number of banks
      numBanks++;
      banks[_bankAddress].name = _bankName;
      banks[_bankAddress].ethAddress = _bankAddress;
      banks[_bankAddress].regNumber = _regNumber;
      
      // Set the number of complaintsReported initially to zero and KYC permission as 'allowed/true'
      banks[_bankAddress].complaintsReported = 0;
      banks[_bankAddress].isAllowedToVote = true;
      banks[_bankAddress].KYC_count = 0; 
    }

    //Api to change the status of isAllowedToVote of any of the banks
    function modifyBankisAllowedToVote(address _bankAddress, bool _status) public isadmin(msg.sender){
      
      banks[_bankAddress].isAllowedToVote = _status;
    }
    //This function is used by the admin to remove a bank from the KYC Contract
    function removeBank(address _bankAddress) public isadmin(msg.sender){
      // Revert if bank is not present
      require(banks[_bankAddress].ethAddress != address(0),"Bank is not present in database");

      delete banks[_bankAddress];
    }
    ///////////////////////////////////////////////////////////////////
}    


