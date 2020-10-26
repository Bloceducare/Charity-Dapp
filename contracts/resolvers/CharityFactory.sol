pragma solidity ^0.5.0;
import "../zeppelin/math/SafeMath.sol";
import "./Charity.sol";


contract charityFactory {
    using SafeMath for uint256;
    
Charity[] private charities;
address snowflake;
event charityStarted(
    address contractAdd,
    address charityOwner,
    string title,
    string description,
    uint256 deadline,
    uint256 maxAmount
    
    );
    
    constructor(address _snowflake) public {
        snowflake=_snowflake;
    }
    
function startCharity(
    string memory _title,string memory _description,uint deadline,uint maxAmountToRaise) public returns(address) {
        
        Charity newCharity= new Charity(snowflake,_title,_description,deadline,maxAmountToRaise);
        charities.push(newCharity);
        emit charityStarted(
            address(newCharity),
            msg.sender,
            _title,
            _description,
            deadline,
            maxAmountToRaise
            );
            return address(newCharity);
        
        
    }  
    
    function returnAllCharities() external view returns (Charity[] memory){
        return charities;
    }
}