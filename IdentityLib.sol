pragma solidity ^0.4.18;

library IdentityLib {

    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Approved(uint256 indexed executionId, bool approved);
    event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimChanged(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    struct Key {
        uint256 keyType; // e.g. 1 = ECDSA, 2 = RSA, etc.
        bytes32 key;
        uint256[] purposes; //e.g. 1 = MANAGEMENT, 2 = ACTION, 3 = CLAIM, 4 = ENCRYPTION, etc.
    }
    struct KeyData {
        mapping(bytes32 => Key) keysByKey;
        mapping(uint256 => bytes32[]) keysByPurpose; // uint256 _purpose => bytes32[] _key
    }

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
    }

    struct Claim {
        bytes32 claimId;
        uint256 topic;
        uint256 scheme;
        address issuer;
        bytes signature;
        bytes data;
        string uri;
    }
    struct ClaimData {
        mapping(bytes32 => Claim) claimsById;
        mapping(uint256 => bytes32[]) claimIdsByTopic; // uint256 type => bytes32[] Claim
    }

    struct Request {
        Transaction transaction;
        Claim claim;
    }
    struct RequestData {
        mapping(uint256 => Request) requestsById;
        uint256 latestRequestId;
    }

    function hashAddress(address addr) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(addr));
    }

    function hasKey(KeyData storage keyData, address sender, uint256 keyType) public view returns (bool) {
        bytes32 hashedAddr = hashAddress(sender);
        for (uint256 i = 0; i < keyData.keysByPurpose[keyType].length; i++) {
            if (hashedAddr == keyData.keysByPurpose[keyType][i]) {
                return true;
            }
        }
        return false;
    }
    
    function keyHasPurpose(KeyData storage keyData, bytes32 _key, uint256 _purpose) public view returns(bool exists) {
        Key storage key = keyData.keysByKey[_key];
        for (uint256 i = 0; i < key.purposes.length; i++) {
            if (_purpose == key.purposes[i]) {
                return true;
            }
        }
        return false;
    }

    function addKey(KeyData storage keyData, bytes32 _key, uint256 _purpose, uint256 _keyType) public returns (bool success) {
        keyData.keysByKey[_key].key = _key;
        keyData.keysByKey[_key].keyType = _keyType;
        keyData.keysByKey[_key].purposes.push(_purpose);

        keyData.keysByPurpose[_purpose].push(_key);

        emit KeyAdded(_key, _purpose, _keyType);

        return true;
    }

    function removeKey(KeyData storage keyData, bytes32 _key, uint256 _purpose) public returns (bool success) {
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
    
    function execute(KeyData storage keyData, RequestData storage requestData, address _to, uint256 _value, bytes _data) public returns (uint256 executionId) {
        Transaction storage transaction = requestData.requestsById[++requestData.latestRequestId].transaction;
        transaction.to = _to;
        transaction.value = _value;
        transaction.data = _data;

        emit ExecutionRequested(requestData.latestRequestId, transaction.to, transaction.value, transaction.data);

        if (hasKey(keyData, msg.sender, 1)) { //TODO: use MANAGEMENT_KEY instead of "1"
            if(transaction.to.call.value(transaction.value)(transaction.data)) {
                emit Executed(requestData.latestRequestId, transaction.to, transaction.value, transaction.data);
            }
        }

        return requestData.latestRequestId;
    }

    function approve(KeyData storage keyData, RequestData storage requestData, ClaimData storage claimData, uint256 _id, bool _approve) public returns (bool success) {
        require(hasKey(keyData, msg.sender, 1)); //TODO: use MANAGEMENT_KEY instead of "1"

        emit Approved(_id, _approve);

        if (_approve) {
            if (requestData.requestsById[_id].claim.claimId != 0) {
                Claim storage claim = requestData.requestsById[_id].claim;
                claimData.claimsById[claim.claimId] = claim;
                emit ClaimAdded(claim.claimId, claim.topic, claim.scheme, claim.issuer, claim.signature, claim.data, claim.uri);
            } else {
                Transaction storage transaction = requestData.requestsById[_id].transaction;
                if(transaction.to.call.value(transaction.value)(transaction.data)) {
                    emit Executed(_id, transaction.to, transaction.value, transaction.data);
                }
            }
        }

        return true;
    }

    function addClaim(KeyData storage keyData, RequestData storage requestData, ClaimData storage claimData, uint256 _topic, uint256 _scheme, address _issuer, bytes _signature, bytes _data, string _uri) public returns (uint256 claimRequestId) {
        Claim storage claim = requestData.requestsById[++requestData.latestRequestId].claim;
        claim.claimId = keccak256(abi.encodePacked(msg.sender, _topic));
        claim.topic = _topic;
        claim.scheme = _scheme;
        claim.issuer = _issuer;
        claim.signature = _signature;
        claim.data = _data;
        claim.uri = _uri;

        if (hasKey(keyData, msg.sender, 1)) { //TODO: use MANAGEMENT_KEY instead of "1"
            bool isExistingClaim = claimData.claimsById[claim.claimId].claimId == claim.claimId;

            claimData.claimsById[claim.claimId] = claim;

            if (isExistingClaim) {
                emit ClaimChanged(claim.claimId, claim.topic, claim.scheme, claim.issuer, claim.signature, claim.data, claim.uri);
            } else {
                claimData.claimIdsByTopic[claim.topic][claimData.claimIdsByTopic[claim.topic].length] = claim.claimId;
                emit ClaimAdded(claim.claimId, claim.topic, claim.scheme, claim.issuer, claim.signature, claim.data, claim.uri);
            }
        } else {
            emit ClaimRequested(requestData.latestRequestId, claim.topic, claim.scheme, claim.issuer, claim.signature, claim.data, claim.uri);
        }

        return requestData.latestRequestId;
    }

    /*
    function changeClaim(KeyData storage keyData, RequestData storage requestData, ClaimData storage claimData, bytes32 _claimId, uint256 _topic, uint256 _scheme, address _issuer, bytes _signature, bytes _data, string _uri) public returns (bool success) {
        bytes32 claimId = keccak256(abi.encodePacked(msg.sender, _topic));
        if (claimId != _claimId) {
            return false;
        }
        addClaim(keyData, requestData, claimData, _topic, _scheme, _issuer, _signature, _data, _uri);
        return true;
    }
    */

    function removeClaim(KeyData storage keyData, RequestData storage requestData, ClaimData storage claimData, bytes32 _claimId) public returns (bool success) {
        Claim memory claim = claimData.claimsById[_claimId];

        require(msg.sender == claim.issuer || hasKey(keyData, msg.sender, 1)); //TODO: use MANAGEMENT_KEY instead of "1"

        // remove claim from claimIdsByTopic[]
        for (uint256 i = 0; i < claimData.claimIdsByTopic[claim.topic].length; i++) {
            if (_claimId == claimData.claimIdsByTopic[claim.topic][i]) {
                break;
            }
        }
        delete claimData.claimIdsByTopic[claim.topic][i];
        
        // remove claim from claimsById
        delete claimData.claimsById[_claimId];

        emit ClaimRemoved(claim.claimId, claim.topic, claim.scheme, claim.issuer, claim.signature, claim.data, claim.uri);

        return true;
    }

}