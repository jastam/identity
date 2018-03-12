pragma solidity ^0.4.18;

import { ERC725 } from "./ERC725.sol";
import { ClaimHolder } from "./ClaimHolder.sol";

contract Identity is ERC725, ClaimHolder {

    struct Key {
        uint256 keyType; // e.g. 1 = ECDSA, 2 = RSA, etc.
        bytes32 key;
        uint256[] purposes; //e.g. 1 = MANAGEMENT, 2 = ACTION, 3 = CLAIM, 4 = ENCRYPTION, etc.
    }

    mapping(bytes32 => Key) keysByKey;
    mapping(uint256 => bytes32[]) keysByPurpose; // uint256 _purpose => bytes32[] _key

    modifier onlyManagement() {
        bytes32 senderKey = keccak256(msg.sender);
        for (uint256 i = 0; i < keysByPurpose[MANAGEMENT_KEY].length; i++) {
            if (senderKey == keysByPurpose[MANAGEMENT_KEY][i]) {
                _;
            }
        }
    }

    function Identity() public {
        addKey(keccak256(msg.sender), MANAGEMENT_KEY, KEYTYPE_ECDSA);
    }

    function getKey(bytes32 _key, uint256 _purpose) public constant returns(uint256 purpose, uint256 keyType, bytes32 key) {
        Key storage tmpKey = keysByKey[_key];
        for (uint256 i = 0; i < tmpKey.purposes.length; i++) {
            if (_purpose == tmpKey.purposes[i]) {
                return (_purpose, tmpKey.keyType, tmpKey.key);
            }
        }
    }

    function getKeyPurposes(bytes32 _key) public constant returns(uint256[] purpose) {
        return keysByKey[_key].purposes;
    }

    function getKeysByPurpose(uint256 _purpose) public constant returns(bytes32[] keys) {
        return keysByPurpose[_purpose];
    }

    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) public onlyManagement returns (bool success) {
        keysByKey[_key].key = _key;
        keysByKey[_key].keyType = _keyType;
        keysByKey[_key].purposes.push(_purpose);

        keysByPurpose[_purpose].push(_key);

        KeyAdded(_key, _purpose, _keyType);

        return true;
    }

    function removeKey(bytes32 _key, uint256 _purpose) public onlyManagement returns (bool success) {
        // remove key from keysByPurpose[_purpose]
        for (i = 0; i < keysByPurpose[_purpose].length; i++) {
            if (_key == keysByPurpose[_purpose][i]) {
                break;
            }
        }
        delete keysByPurpose[_purpose][i];

        // remove purpose form keysByKey[_key].purposes
        for (uint256 i = 0; i < keysByKey[_key].purposes.length; i++) {
            if (_purpose == keysByKey[_key].purposes[i]) {
                break;
            }
        }
        delete keysByKey[_key].purposes[i];

        KeyRemoved(_key, _purpose, keysByKey[_key].keyType);

        return true;
    }
}
