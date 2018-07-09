pragma solidity ^0.4.18;

contract ERC735 {

    /**
     * COULD be triggered when addClaim was successfully called.
     */
    event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * MUST be triggered when a claim was successfully added.
     */
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * MUST be triggered when removeClaim was successfully called.
     */
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * MUST be triggered when changeClaim was successfully called.
     */
    event ClaimChanged(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

/*
    struct Claim {
        uint256 topic; // The number which represents the topic of the claim. (e.g. 1 biometric, 2 residence)
        uint256 scheme; // The scheme with which this claim SHOULD be verified or how it should be processed.
        address issuer; // The issuers identity contract address, or the address used to sign the above signature.
        bytes signature; // Signature which is the proof that the claim issuer issued a claim of topic for this identity. (this.address + topic + data)
        bytes data; // The hash of the claim data, sitting in another location, a bit-mask, call data, or actual data based on the claim scheme.
        string uri; // The location of the claim, this can be HTTP links, swarm hashes, IPFS hashes, and such.
    }
*/

    /**
     * Returns a claim by ID.
     */
    function getClaim(bytes32 _claimId) public constant returns(uint256 topic, uint256 scheme, address issuer, bytes signature, bytes data, string uri);

    /**
     * Returns an array of claim IDs by topic.
     */
    function getClaimIdsByTopic(uint256 _topic) public constant returns(bytes32[] claimIds);

    /**
     * Requests the ADDITION or the CHANGE of a claim from an issuer.
     *
     * Claims can requested to be added by anybody, including the claim holder itself (self issued).
     *
     * _signature is a signed message of the following structure: keccak256(address identityHolder_address, uint256 topic, bytes data).
     *
     * Claim IDs are generated using keccak256(address issuer_address + uint256 topic).
     *
     * This COULD implement an approval process for pending claims, or add them right away.
     *
     * Returns claimRequestId: COULD be send to the approve function, to approve or reject this claim.
     *
     * Triggers if the claim is new Event and approval process exists: ClaimRequested
     * Triggers if the claim is new Event and is added: ClaimAdded
     * Triggers if the claim index existed Event: ClaimChanged
     */
    function addClaim(uint256 _topic, uint256 _scheme, address _issuer, bytes _signature, bytes _data, string _uri) public returns (uint256 claimRequestId);

    /**
     *
     */
    function changeClaim(bytes32 _claimId, uint256 _topic, uint256 _scheme, address _issuer, bytes _signature, bytes _data, string _uri) public returns (bool success);

    /**
     * Removes a claim.
     * Can only be removed by the claim issuer, or the claim holder itself.
     *
     * Triggers Event: ClaimRemoved
     */
    function removeClaim(bytes32 _claimId) public returns (bool success);
}
