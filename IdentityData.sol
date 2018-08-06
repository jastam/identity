pragma solidity ^0.4.18;

library IdentityData {

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

}