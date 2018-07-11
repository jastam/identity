pragma solidity ^0.4.18;

import { ERC725 } from "./ERC725.sol";

contract Identity is ERC725 {

// ========== testing ==============================
/*
    event TestAddress(address value);

    event TestEvent(uint256 value);

    function test(uint256 value) public {
        emit TestEvent(value);
    }
*/
// ========== end testing ==============================

    struct Key {
        uint256 keyType; // e.g. 1 = ECDSA, 2 = RSA, etc.
        bytes32 key;
        uint256[] purposes; //e.g. 1 = MANAGEMENT, 2 = ACTION, 3 = CLAIM, 4 = ENCRYPTION, etc.
    }
    mapping(bytes32 => Key) keysByKey;
    mapping(uint256 => bytes32[]) keysByPurpose; // uint256 _purpose => bytes32[] _key

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
    }

    struct Claim {
        bytes32 claimId;
        uint256 claimType;
        uint256 scheme;
        address issuer;
        bytes signature;
        bytes data;
        string uri;
    }
    mapping(bytes32 => Claim) claimsById;
    mapping(uint256 => bytes32[]) claimsByType; // uint256 type => bytes32[] Claim

    struct Request {
        Transaction transaction;
        Claim claim;
    }
    mapping(uint256 => Request) requestsById;
    uint256 latestRequestId = 0;

    modifier onlyManager() {
        if (isManagement(msg.sender)) {
            _;
        }
    }

    function isManagement(address addr) private view returns (bool) {
        bytes32 hashedAddr = keccak256(abi.encodePacked(addr));
        for (uint256 i = 0; i < keysByPurpose[MANAGEMENT_KEY].length; i++) {
            if (hashedAddr == keysByPurpose[MANAGEMENT_KEY][i]) {
                return true;
            }
        }
        return false;
    }

    function() public payable { }

    constructor() public {
        bytes32 key = keccak256(abi.encodePacked(msg.sender));
        uint256 purpose = MANAGEMENT_KEY;
        uint256 keyType = KEYTYPE_ECDSA;

        keysByKey[key].key = key;
        keysByKey[key].keyType = keyType;
        keysByKey[key].purposes.push(purpose);

        keysByPurpose[purpose].push(key);

        emit KeyAdded(key, purpose, keyType);
    }

    function getKey(bytes32 _key) public constant returns(uint256[] purposes, uint256 keyType, bytes32 key) {
        return (keysByKey[_key].purposes, keysByKey[_key].keyType, keysByKey[_key].key);
    }

    function keyHasPurpose(bytes32 _key, uint256 _purpose) public constant returns(bool exists) {
        Key storage tmpKey = keysByKey[_key];
        for (uint256 i = 0; i < tmpKey.purposes.length; i++) {
            if (_purpose == tmpKey.purposes[i]) {
                return true;
            }
        }
        return false;
    }

    function getKeysByPurpose(uint256 _purpose) public constant returns(bytes32[] keys) {
        return keysByPurpose[_purpose];
    }

    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) public onlyManager returns (bool success) {
        keysByKey[_key].key = _key;
        keysByKey[_key].keyType = _keyType;
        keysByKey[_key].purposes.push(_purpose);

        keysByPurpose[_purpose].push(_key);

        emit KeyAdded(_key, _purpose, _keyType);

        return true;
    }

    function removeKey(bytes32 _key, uint256 _purpose) public onlyManager returns (bool success) {
        // remove key from keysByPurpose[_purpose]
        for (uint256 i = 0; i < keysByPurpose[_purpose].length; i++) {
            if (_key == keysByPurpose[_purpose][i]) {
                break;
            }
        }
        delete keysByPurpose[_purpose][i];

        // remove purpose form keysByKey[_key].purposes
        for (i = 0; i < keysByKey[_key].purposes.length; i++) {
            if (_purpose == keysByKey[_key].purposes[i]) {
                break;
            }
        }
        delete keysByKey[_key].purposes[i];

        emit KeyRemoved(_key, _purpose, keysByKey[_key].keyType);

        return true;
    }

    function execute(address _to, uint256 _value, bytes _data) public returns (uint256 executionId) {
        Transaction storage transaction = requestsById[++latestRequestId].transaction;
        transaction.to = _to;
        transaction.value = _value;
        transaction.data = _data;

        emit ExecutionRequested(latestRequestId, transaction.to, transaction.value, transaction.data);

        if (isManagement(msg.sender)) {
            if(transaction.to.call.value(transaction.value)(transaction.data)) {
                emit Executed(latestRequestId, transaction.to, transaction.value, transaction.data);
            }
        }

        return latestRequestId;
    }

    function approve(uint256 _id, bool _approve) public returns (bool success) {
        require(isManagement(msg.sender));

        emit Approved(_id, _approve);

        if (_approve) {
            if (requestsById[_id].claim.claimId != 0) {
                Claim storage claim = requestsById[_id].claim;
                claimsById[claim.claimId] = claim;
                emit ClaimAdded(claim.claimId, claim.claimType, claim.scheme, claim.issuer, claim.signature, claim.data, claim.uri);
            } else {
                Transaction storage transaction = requestsById[_id].transaction;
                if(transaction.to.call.value(transaction.value)(transaction.data)) {
                    emit Executed(_id, transaction.to, transaction.value, transaction.data);
                }
            }
        }

        return true;
    }

/*
    function getClaim(bytes32 _claimId) public constant returns(uint256 claimType, uint256 scheme, address issuer, bytes signature, bytes data, string uri) {
        Claim storage claim = claimsById[_claimId];
        return (claim.claimType, claim.scheme, claim.issuer, claim.signature, claim.data, claim.uri);
    }

    function getClaimIdsByType(uint256 _claimType) public constant returns(bytes32[] claimIds) {
        return claimsByType[_claimType];
    }

    function addClaim(uint256 _claimType, uint256 _scheme, address _issuer, bytes _signature, bytes _data, string _uri) public returns (uint256 claimRequestId) {
        Claim storage claim = requestsById[++latestRequestId].claim;
        claim.claimId = keccak256(abi.encodePacked(msg.sender, _claimType));
        claim.claimType = _claimType;
        claim.scheme = _scheme;
        claim.issuer = _issuer;
        claim.signature = _signature; // keccak256(abi.encodePacked(this, _claimType, _data));
        claim.data = _data;
        claim.uri = _uri;

        if (isManagement(msg.sender)) {
            bool isExistingClaim = claimExists(claim.claimId);

            claimsById[claim.claimId] = claim;

            if (isExistingClaim) {
                emit ClaimChanged(claim.claimId, claim.claimType, claim.scheme, claim.issuer, claim.signature, claim.data, claim.uri);
            } else {
                emit ClaimAdded(claim.claimId, claim.claimType, claim.scheme, claim.issuer, claim.signature, claim.data, claim.uri);
            }
        } else {
            emit ClaimRequested(latestRequestId, claim.claimType, claim.scheme, claim.issuer, claim.signature, claim.data, claim.uri);
        }

        return latestRequestId;
    }
    
    function claimExists(bytes32 _claimId) private view returns (bool exitst) {
        return claimsById[_claimId].claimId != 0;
    }

    function removeClaim(bytes32 _claimId) public returns (bool success) {
        Claim memory claim = claimsById[_claimId];

        require(msg.sender == claim.issuer || isManagement(msg.sender));

        // remove claim from claimsByType[]
        for (uint256 i = 0; i < claimsByType[claim.claimType].length; i++) {
            if (_claimId == claimsByType[claim.claimType][i]) {
                break;
            }
        }
        delete claimsByType[claim.claimType][i];
        
        // remove claim from claimsById
        delete claimsById[_claimId];

        emit ClaimRemoved(claim.claimId, claim.claimType, claim.scheme, claim.issuer, claim.signature, claim.data, claim.uri);

        return true;
    }
*/
}
