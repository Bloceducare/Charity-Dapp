pragma solidity ^0.5.0;

import './Charity.sol';

contract charityFactory {
address snowflake;
address public globalOverlord;

Charity[] public charities;

event newCharityCreated(
    address indexed _deployedAddress
);

modifier onlyOverlord{
    require (msg.sender==globalOverlord,"You are not the OVERLORD");
    _;
}

constructor(address _snowflake) public{
    snowflake=_snowflake;
    
    //sets the deployer of the factory contract as the overlord
    globalOverlord=msg.sender;
}

//creates a new charity instance
function createNewCharity(string memory _name,string memory _description,uint _days,uint _maxAmount,address _ownerAddress) public returns(address newContract){
       Charity c = new Charity(snowflake,_name,_description,_days,_maxAmount,_ownerAddress,globalOverlord);
       charities.push(c);
       emit newCharityCreated(address(c));
        return address(c);
    //returns the new election contract address

}

 //function to transfer the overlord position to another address
 //can only be called by the existing overlord
     function transferOverlordAuthority(address _newOverlord) public onlyOverlord {
        globalOverlord=_newOverlord;
     }
     
     //returns the addresses of all charities that have all been deployed
 function returnAllCharities() external view returns(Charity[] memory){
        return charities;
    }

}