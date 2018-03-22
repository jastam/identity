pragma solidity ^0.4.18;

contract RecoverableByDelagates {

    event delegateGroupAdded(bytes32[] delegates, uint8 numConfirmations, bytes32 delegateGroupId);

    event delegateGroupRemoved(bytes32 delegateGroupId);

    event newKeyConfirmed(bytes32 key, address byAddres, bytes32[] byGroups);

    event accountRecovered(bytes32 key, bytes32 byGroup);

    function addDelegateGroup(bytes32[] _delegates, uint8 _numConfirmations) public returns (bytes32 delegateGroupId);

    function removeDelegateGroup(bytes32 _delegateGroupId) public returns (bool success);

    function confirmNewKey(bytes32 _key) public;
}
