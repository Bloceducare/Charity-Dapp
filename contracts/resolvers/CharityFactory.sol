pragma solidity ^0.5.0;

import './Charity.sol';

contract charityFactory {
address snowflake;

Charity[] public charities;

event newCharityCreated(
    address indexed _deployedAddress
);
constructor(address _snowflake) public{
    snowflake=_snowflake;
}


function createNewCharity(string memory _name,string memory _description,uint _days,uint _maxAmount,address _ownerAddress) public returns(address newContract){
       Charity c = new Charity(snowflake,_name,_description,_days,_maxAmount,_ownerAddress);
       charities.push(c);
       emit newCharityCreated(address(c));
        return address(c);
    //returns the new election contract address

}
 function returnAllCharities() external view returns(Charity[] memory){
        return charities;
    }

}