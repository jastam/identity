pragma solidity ^0.4.18;

contract Subject {
    function setRecord(bytes32 _key, string _value) public returns (bool success);
}

contract Oracle {

    mapping(bytes32 => bool) allowedSources;

    modifier onlyAllowedSources() {
        require(isAllowedSource(msg.sender));
        _;
    }

    function isAllowedSource(address addr) private view returns (bool) {
        return allowedSources[keccak256(abi.encodePacked(addr))];
    }

    function() public payable { }

    constructor() public {
        allowedSources[keccak256(abi.encodePacked(msg.sender))] = true;
    }

    event RecordRequested(address indexed subject, bytes32 indexed key);

    function requestRecord(bytes32 _key) public {
        emit RecordRequested(msg.sender, _key);
    }

    function setRecord(bytes32 _key, string _value, address _subject) public onlyAllowedSources() {
        Subject subject = Subject(_subject);
        subject.setRecord(_key, _value);
    }

}
