pragma solidity ^0.4.18;

import { IdentityData } from "IdentityData.sol";

library ClaimHolderLib {
    
    event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimChanged(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    function addClaim(IdentityData.KeyData storage keyData, IdentityData.RequestData storage requestData, IdentityData.ClaimData storage claimData, uint256 _topic, uint256 _scheme, address _issuer, bytes _signature, bytes _data, string _uri) public returns (uint256 claimRequestId) {
        IdentityData.Claim storage claim = requestData.requestsById[++requestData.latestRequestId].claim;
        claim.claimId = keccak256(abi.encodePacked(msg.sender, _topic));
        claim.topic = _topic;
        claim.scheme = _scheme;
        claim.issuer = _issuer;
        claim.signature = _signature;
        claim.data = _data;
        claim.uri = _uri;

        if (IdentityData.hasKey(keyData, msg.sender, 1)) { //TODO: use MANAGEMENT_KEY instead of "1"
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

    function removeClaim(IdentityData.KeyData storage keyData, IdentityData.RequestData storage requestData, IdentityData.ClaimData storage claimData, bytes32 _claimId) public returns (bool success) {
        IdentityData.Claim memory claim = claimData.claimsById[_claimId];

        require(msg.sender == claim.issuer || IdentityData.hasKey(keyData, msg.sender, 1)); //TODO: use MANAGEMENT_KEY instead of "1"

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
