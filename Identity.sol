pragma solidity ^0.4.18;

import { IdentityData } from "IdentityData.sol";
import { IdentityLib } from "IdentityLib.sol";
import { ClaimHolderLib } from "ClaimHolderLib.sol";

contract Identity {

    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Approved(uint256 indexed executionId, bool approved);
    event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimChanged(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    
    uint256 constant MANAGEMENT_KEY = 1; // keys which can manage the identity
    uint256 constant ACTION_KEY = 2; // keys which perform actions in this identities name (signing, logins, transactions, etc.)
    uint256 constant CLAIM_SIGNER_KEY = 3; // signer keys, used to sign claims on other identities which need to be revokable.
    uint256 constant ENCRYPTION_KEY = 4; // keys used to encrypt data e.g. hold in claims.

    uint256 constant KEYTYPE_ECDSA = 1;
    uint256 constant KEYTYPE_RSA = 2;

    IdentityData.KeyData keyData;
    IdentityData.ClaimData claimData;
    IdentityData.RequestData requestData;

    modifier onlyManager() {
        if (IdentityData.hasKey(keyData, msg.sender, MANAGEMENT_KEY)) {
            _;
        }
    }

    function() public payable { }

    constructor() public {
        IdentityLib.addKey(
            keyData, 
            bytes32(msg.sender),
            MANAGEMENT_KEY,
            KEYTYPE_ECDSA
        );
    }

    function getKey(bytes32 _key) public view returns(uint256[] purposes, uint256 keyType, bytes32 key) {
        return (keyData.keysByKey[_key].purposes, keyData.keysByKey[_key].keyType, keyData.keysByKey[_key].key);
    }

    function keysByPurpose(uint256 _purpose) public view returns(bytes32[] keys) {
        return keyData.keysByPurpose[_purpose];
    }

    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) public onlyManager returns (bool success) {
        return IdentityLib.addKey(keyData, _key, _purpose, _keyType);
    }

    function removeKey(bytes32 _key, uint256 _purpose) public onlyManager returns (bool success) {
        return IdentityLib.removeKey(keyData, _key, _purpose);
    }

    function execute(address _to, uint256 _value, bytes _data) public returns (uint256 executionId) {
        return IdentityLib.execute(keyData, requestData, _to, _value, _data);
    }

    function approve(uint256 _id, bool _approve) public returns (bool success) {
        return IdentityLib.approve(keyData, requestData, claimData, _id, _approve);
    }


    function getClaim(bytes32 _claimId) public view returns(uint256 topic, uint256 scheme, address issuer, bytes signature, bytes data, string uri) {
        IdentityData.Claim storage claim = claimData.claimsById[_claimId];
        return (claim.topic, claim.scheme, claim.issuer, claim.signature, claim.data, claim.uri);
    }

    function getClaimIdsByTopic(uint256 _topic) public view returns(bytes32[] claimIds) {
        return claimData.claimIdsByTopic[_topic];
    }

    function addClaim(uint256 _topic, uint256 _scheme, address _issuer, bytes _signature, bytes _data, string _uri) public returns (uint256 claimRequestId) {
        return ClaimHolderLib.addClaim(keyData, requestData, claimData, _topic, _scheme, _issuer, _signature, _data, _uri);
    }

    /*
    function changeClaim(bytes32 _claimId, uint256 _topic, uint256 _scheme, address _issuer, bytes _signature, bytes _data, string _uri) public returns (bool success) {
        return ClaimHolderLib.changeClaim(keyData, requestData, claimData, _claimId, _topic, _scheme, _issuer, _signature, _data, _uri);
    }
    */

    function changeClaim(bytes32 _claimId, uint256 _topic, uint256 _scheme, address _issuer, bytes _signature, bytes _data, string _uri) public returns (bool success) {
        bytes32 claimId = keccak256(abi.encodePacked(msg.sender, _topic));
        if (claimId != _claimId) {
            return false;
        }
        addClaim(_topic, _scheme, _issuer, _signature, _data, _uri);
        return true;
    }

    function removeClaim(bytes32 _claimId) public returns (bool success) {
        return ClaimHolderLib.removeClaim(keyData, requestData, claimData, _claimId);
    }

}
