pragma solidity ^0.4.18;

//import { ERC735 } from "./ERC735.sol";

//contract ERC725 is ERC735 {
contract ERC725 {

    /**
     * MUST be triggered when addKey was successfully called.
     */
    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);

    /**
     * MUST be triggered when removeKey was successfully called.
     */
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);

    /**
     * MUST be triggered when execute was successfully called.
     */
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    /**
     * MUST be triggered when approve was called and the execution was successfully approved.
     */
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    /**
     * MUST be triggered when approve was successfully called.
     */
    event Approved(uint256 indexed executionId, bool approved);
    
    uint256 constant MANAGEMENT_KEY = 1; // keys which can manage the identity
    uint256 constant ACTION_KEY = 2; // keys which perform actions in this identities name (signing, logins, transactions, etc.)
    uint256 constant CLAIM_SIGNER_KEY = 3; // signer keys, used to sign claims on other identities which need to be revokable.
    uint256 constant ENCRYPTION_KEY = 4; // keys used to encrypt data e.g. hold in claims.

    uint256 constant KEYTYPE_ECDSA = 1;
    uint256 constant KEYTYPE_RSA = 2;

    /**
     * One key per purpose
     */
    // struct Key {
    //     uint256 purpose; //e.g. 1 = MANAGEMENT, 2 = ACTION, 3 = CLAIM, 4 = ENCRYPTION, etc.
    //     uint256 keyType; // e.g. 1 = ECDSA, 2 = RSA, etc.
    //     bytes32 key;
    // }

    /** 
     * Returns the full key data, if present in the identity.
     */
    function getKey(bytes32 _key) public constant returns(uint256[] purposes, uint256 keyType, bytes32 key);

    /**
     * Returns the TRUE if a key has is present and has the given purpose. If key is not present it returns FALSE.
     */
    function keyHasPurpose(bytes32 _key, uint256 _purpose) public constant returns(bool exists);

    /**
     * Returns an array of public key bytes32 hold by this identity.
     */
    function getKeysByPurpose(uint256 _purpose) public constant returns(bytes32[] keys);

    /**
     * Adds a _key to the identity. The _purpose specifies the purpose of key.
     *
     * MUST only be done by keys of purpose 1, or the identity itself.
     * If its the identity itself, the approval process will determine its approval.
     *
     * Triggers Event: KeyAdded
     */
    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) public returns (bool success);

    /**
     * Removes _key from the identity.
     *
     * MUST only be done by keys of purpose 1, or the identity itself. 
     * If its the identity itself, the approval process will determine its approval.
     *
     * Triggers Event: KeyRemoved
     */
    function removeKey(bytes32 _key, uint256 _purpose) public returns (bool success);

    /**
     * Executes an action on other contracts, or itself, or a transfer of ether.
     * SHOULD require approve to be called with one or more keys of purpose 1 (MANAGEMENT) or 2 (ACTION) 
     * to approve this execution.
     *
     * Execute COULD be used as the only accessors for addKey, removeKey and replaceKey and removeClaim.
     *
     * Returns executionId: SHOULD be send to the approve function, to approve or reject this execution.
     *
     * Triggers Event: ExecutionRequested
     * Triggers on direct execution Event: Executed
     */
    function execute(address _to, uint256 _value, bytes _data) public returns (uint256 executionId);

    /**
     * Approves an execution or claim addition.
     * This SHOULD require n of m approvals of keys purpose 1 (MANAGEMENT), 
     * if the _to of the execution is the identity contract itself, to successfull approve an execution.
     * And COULD require n of m approvals of keys purpose 2 (ACTION), 
     * if the _to of the execution is another contract, to successfull approve an execution.
     *
     * Triggers Event: Approved
     * Triggers on successfull execution Event: Executed
     * Triggers on successfull claim addition Event: ClaimAdded
     */
    function approve(uint256 _id, bool _approve) public returns (bool success);
}
