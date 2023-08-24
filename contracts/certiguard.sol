// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity >=0.8.13 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "fhevm/lib/TFHE.sol";

contract CertiGuard is ERC721 {
    
    // Structure to hold certificate information
    struct Certificate {
        uint256 id;
        string name;
        address owner;
        bool isVerified;
    }

    // Mapping to store certificates
    mapping(uint256 => Certificate) public certificates;
    uint256 public certificateCount;

    // Events for certificate creation and verification
    event CertificateCreated(uint256 indexed id, string name, address indexed owner);
    event CertificateVerified(uint256 indexed id);
    
    // Base URI for token metadata
    string private _baseTokenURI;
    // Admin key to manage the contract
    bytes32 private _adminKey;
    // Private key used for encryption
    euint32 private _privateKey;
    // Mapping to store keys
    mapping(uint => euint32) internal keys;

    // Constructor to initialize the contract
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        bytes32 adminPublicKey
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _adminKey = adminPublicKey;
    }

    // Internal function to return the base token URI
    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return _baseTokenURI;
    }

    // Function to set the private key
    function setPrivateKey(bytes calldata k1) external {
        _privateKey = TFHE.asEuint32(k1);
    }

    // Function to create a new certificate
    function createCertificate(string memory _name) public {
        certificateCount++;
        certificates[certificateCount] = Certificate(certificateCount, _name, msg.sender, false);
        emit CertificateCreated(certificateCount, _name, msg.sender);
    }

    // Function to retrieve the private key for debugging
    function getKeyDebug(bytes32 publicKey) public view returns (bytes memory) {
        return TFHE.reencrypt(_privateKey, publicKey);
    }

    // Function to retrieve the key
    function getKey() public view returns (bytes memory) {
        return TFHE.reencrypt(_privateKey, _adminKey);
    }

    // Function to retrieve the key with a challenge
    function getKeyWithChallenge(bytes calldata challenge) public view returns (bytes memory) {
        euint32 result = TFHE.xor(_privateKey, TFHE.asEuint32(challenge));
        return TFHE.reencrypt(result, _adminKey);
    }

    // Function to verify a certificate
    function verifyCertificate(uint256 _id) public {
        require(_id <= certificateCount, "Certificate not found");
        Certificate storage certificate = certificates[_id];
        require(msg.sender == certificate.owner, "Only owner can verify");
        
        certificate.isVerified = true;
        emit CertificateVerified(_id);
    }

    // Function to check if a certificate is verified
    function isCertificateVerified(uint256 _id) public view returns (bool) {
        require(_id <= certificateCount, "Certificate not found");
        return certificates[_id].isVerified;
    }
}
