pragma solidity ^0.4.18;

import { IdentityData } from "IdentityData.sol";

library IdentityLib {

    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Approved(uint256 indexed executionId, bool approved);
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    
    function keyHasPurpose(IdentityData.KeyData storage keyData, bytes32 _key, uint256 _purpose) public view returns(bool exists) {
        IdentityData.Key storage key = keyData.keysByKey[_key];
        for (uint256 i = 0; i < key.purposes.length; i++) {
            if (_purpose == key.purposes[i]) {
                return true;
            }
        }
        return false;
    }

    function addKey(IdentityData.KeyData storage keyData, bytes32 _key, uint256 _purpose, uint256 _keyType) public returns (bool success) {
        keyData.keysByKey[_key].key = _key;
        keyData.keysByKey[_key].keyType = _keyType;
        keyData.keysByKey[_key].purposes.push(_purpose);

        keyData.keysByPurpose[_purpose].push(_key);

        emit KeyAdded(_key, _purpose, _keyType);

        return true;
    }

    function removeKey(IdentityData.KeyData storage keyData, bytes32 _key, uint256 _purpose) public returns (bool success) {
        // remove key from keyData.keysByPurpose[_purpose]
        for (uint256 i = 0; i < keyData.keysByPurpose[_purpose].length; i++) {
            if (_key == keyData.keysByPurpose[_purpose][i]) {
                break;
            }
        }
        delete keyData.keysByPurpose[_purpose][i];

        // remove purpose form keyData.keysByKey[_key].purposes
        for (i = 0; i < keyData.keysByKey[_key].purposes.length; i++) {
            if (_purpose == keyData.keysByKey[_key].purposes[i]) {
                break;
            }
        }
        delete keyData.keysByKey[_key].purposes[i];

        emit KeyRemoved(_key, _purpose, keyData.keysByKey[_key].keyType);

        return true;
    }
    
    function execute(IdentityData.KeyData storage keyData, IdentityData.RequestData storage requestData, address _to, uint256 _value, bytes _data) public returns (uint256 executionId) {
        IdentityData.Transaction storage transaction = requestData.requestsById[++requestData.latestRequestId].transaction;
        transaction.to = _to;
        transaction.value = _value;
        transaction.data = _data;

        emit ExecutionRequested(requestData.latestRequestId, transaction.to, transaction.value, transaction.data);

        if (IdentityData.hasKey(keyData, msg.sender, 1)) { //TODO: use MANAGEMENT_KEY instead of "1"
            if(transaction.to.call.value(transaction.value)(transaction.data)) {
                emit Executed(requestData.latestRequestId, transaction.to, transaction.value, transaction.data);
            }
        }

        return requestData.latestRequestId;
    }

    function approve(IdentityData.KeyData storage keyData, IdentityData.RequestData storage requestData, IdentityData.ClaimData storage claimData, uint256 _id, bool _approve) public returns (bool success) {
        require(IdentityData.hasKey(keyData, msg.sender, 1)); //TODO: use MANAGEMENT_KEY instead of "1"

        emit Approved(_id, _approve);

        if (_approve) {
            if (requestData.requestsById[_id].claim.claimId != 0) {
                IdentityData.Claim storage claim = requestData.requestsById[_id].claim;
                claimData.claimsById[claim.claimId] = claim;
                emit ClaimAdded(claim.claimId, claim.topic, claim.scheme, claim.issuer, claim.signature, claim.data, claim.uri);
            } else {
                IdentityData.Transaction storage transaction = requestData.requestsById[_id].transaction;
                if(transaction.to.call.value(transaction.value)(transaction.data)) {
                    emit Executed(_id, transaction.to, transaction.value, transaction.data);
                }
            }
        }

        return true;
    }

}