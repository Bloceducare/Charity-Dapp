pragma solidity ^0.5.0;





import "../SnowflakeResolver.sol";
import "../interfaces/IdentityRegistryInterface.sol";
import "../interfaces/HydroInterface.sol";
import "../interfaces/SnowflakeInterface.sol";
import "../zeppelin/math/SafeMath.sol";



 contract Charity is SnowflakeResolver{
     using SafeMath for uint256;
     
     //states for project phases
     
     enum State{
         Approved,
         Awaiting,
         Disabled
     }
     
     //State variables
     
     
     //max amount to be raised,refunds excess back to donators
     uint256 public charityGoal;
     
     
     //The current donations for the Charity
    uint256 public currentBalance;
    
    //deadline set for the Charity
    uint public raiseBy;
    
    //title for the Charity
    string public title;
    
    //description for the Charity
    string public description;
    
    //snowflake address
    address _snowflakeAddress;
    
    //overlord address
    address public overlord=0xF3a57FAbea6e198403864640061E3abc168cee80;
    
    //the only address that can withdraw the funds...should be set by the charity owner
    address public charityOwnerAddress;
    
    
    
    address _creatorAddress;
     
     // initialize on create
     State public state = State.Awaiting;
     
     //keeps track of all contributions by address
     mapping(uint => uint ) public contributions;
     
     //keeps track of all registered participants
     mapping(uint=>bool) public aParticipant;
     
     //emitted when funding is received
     event fundingReceived(address contributor,uint amount,uint currentTotal);
     
     //emitted when donations are paid out to the creator
     event creatorPaid(address recipient);
     
     //emitted when the charity is approved
     event charityApproved(uint timeApproved);
     
     //emitted when the charity is disabled
     event charityDisabled(uint timeDisabled); 
     
     
     
     
     //confirm current State
     
     modifier inState(State _state){
         require(state==_state,"this project has not been approved or has been disabled");
         _;
     }
     

     
     //checks if the ein has this contract as a resolver
     modifier isParticipant(address _target){
         uint _ein=checkEIN(_target);
    require(aParticipant[_ein]==true, 'this EIN has not registered as a participant');
    _;
}

     //checks if target has an ein
     modifier HasEIN(address target){
    require(checkforReg(target)==true);
    _;
}


//double check that this project has not expired
modifier notExpired{
    require(checkIfCharityExpired()==false,"Project has expired");
    _;
}

modifier GoalNotReached{
    require (checkIfFundingComplete()==false,"Goal has been reached");
    _;
}

modifier onlyOverlord{
    require (msg.sender==overlord,"You are not the charity overlord");
    _;
}

modifier onlyCharityOwner{
    require (msg.sender==charityOwnerAddress,"You are not the charity owner");
    _;
}
    constructor (
         address snowflakeAddress,
         string memory projectTitle,
         string memory projectDesc,
         uint charityEnd,
         uint goalAmount,
         address _owner) SnowflakeResolver(projectTitle, projectDesc, snowflakeAddress, true, false) public {
             snowflakeAddress=_snowflakeAddress;
             charityOwnerAddress=_owner;
             title= projectTitle;
             description= projectDesc;
             charityGoal = convertToRealAmount(goalAmount);
             raiseBy = now.add(charityEnd).mul(1 days);
             currentBalance = 0;
         }
         
         function checkEIN(address _address) internal HasEIN(_address) returns(uint){
        SnowflakeInterface snowfl = SnowflakeInterface(snowflakeAddress);
    IdentityRegistryInterface idRegistry= IdentityRegistryInterface(snowfl.identityRegistryAddress());
       uint Ein=idRegistry.getEIN(_address);
       return Ein;
   }
       function convertToRealAmount(uint256 firstAmount) internal pure returns(uint){
          uint256 finalAmount= firstAmount.mul(1000000000000000000);
          return finalAmount;
       }
       
       //approve a charity so it can start receiving donations
       function approveCharity() public onlyOverlord {
           state=State.Approved;
           emit charityApproved(now);
       }

        //disable this charity so it can stop receive funding
       function disableCharity() public onlyOverlord {
           state=State.Disabled;
           emit charityDisabled(now);
           
       }
       
         function checkforReg(address _target) public  returns(bool){
    SnowflakeInterface snowfl = SnowflakeInterface(snowflakeAddress);
    IdentityRegistryInterface idRegistry= IdentityRegistryInterface(snowfl.identityRegistryAddress());
    _target=msg.sender;
    bool hasId=idRegistry.hasIdentity(msg.sender);
    return hasId;
}

 //called to register any new actor in the system
//makes the ein to be a participant in the system
function onAddition(uint ein,uint /**allocation**/,bytes memory) public senderIsSnowflake() returns (bool){
     aParticipant[ein]=true;
    return true;
   
}
function onRemoval(uint, bytes memory) public senderIsSnowflake() returns (bool) {}
 
         //main withdraw function that can be called anytime will send all funds from the contract
     function withdrawContributions(address to) public onlyCharityOwner {
        SnowflakeInterface snowfl = SnowflakeInterface(snowflakeAddress);
        HydroInterface hydro = HydroInterface(snowfl.hydroTokenAddress());
        withdrawHydroBalanceTo(to, hydro.balanceOf(address(this)));
        currentBalance=currentBalance.sub(hydro.balanceOf(address(this)));
        emit creatorPaid(to);
    }
     
     //function to allow registered participants contribute to a charity
      function contribute(uint _amount) public inState(State.Approved) notExpired() isParticipant(msg.sender) {
          require(checkEIN(msg.sender) !=checkEIN(charityOwnerAddress),"you cannot donate to your own Charity");
          uint _realAmount= convertToRealAmount(_amount);
            SnowflakeInterface snowfl = SnowflakeInterface(snowflakeAddress);
            uint ein=checkEIN(msg.sender);
             snowfl.withdrawSnowflakeBalanceFrom(ein, address(this), _realAmount);
           contributions[ein]=contributions[ein].add(convertToRealAmount(_amount));
           currentBalance=currentBalance.add(convertToRealAmount(_amount));
           
           emit fundingReceived(msg.sender,_amount,currentBalance);
          
           }   
           
    
   // check if the the charity has reached its goal    
     function checkIfFundingComplete() public view returns(bool){
         if (currentBalance>=charityGoal){
            return (true);
         }
         else{
 return false;
     }
     }
     
     //function to transfer the overlord position to another address
     function transferOverlordAuthority(address _newOverlord) public onlyOverlord {
         overlord=_newOverlord;
     }
     
     //checks if the charity has expired
     function checkIfCharityExpired() public view returns(bool){
         if(now>=raiseBy){
             return(true);

         }
     }
         
         //check the remaining amount before project reaches its goal
         //should be run when the project has not reached its goal
         function checkRemainingAmount() public view notExpired() returns(uint)  {
             uint _Amount= charityGoal.sub(currentBalance);
            
             return(_Amount);
         }
         
         //check remaining time before project expiration
         //should be called when the project has not expired
             function checkRemainingTime() public view  returns(uint)  {
                 if(now>=raiseBy){
             return 0;
                 }
                 else{
                     uint _real=now.mul(1 days);
             uint _time= raiseBy.sub(_real);
             return(_time);
         }}
         
         function checkState() public view returns(State){
             return state;
         }
       
       
 }
 
 
         
