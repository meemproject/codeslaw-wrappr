// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

import {ERC1155Votes} from "./ERC1155Votes.sol";
import {Multicallable} from "./Multicallable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title Wrappr
/// @author KaliCo LLC
/// @custom:coauthor Seed Club Ventures (@seedclubvc)
/// @notice Ricardian contract for on-chain structures.
contract Wrappr is ERC1155Votes, Multicallable {
    /// -----------------------------------------------------------------------
    /// EVENTS
    /// -----------------------------------------------------------------------

    event OwnerOfSet(address indexed operator, address indexed to, uint256 id);

    event ManagerSet(address indexed operator, address indexed to, bool set);

    event AdminSet(address indexed operator, address indexed admin);

    event TransferabilitySet(address indexed operator, uint256 id, bool set);

    event PermissionSet(address indexed operator, uint256 id, bool set);

    event UserPermissionSet(
        address indexed operator,
        address indexed to,
        uint256 id,
        bool set
    );

    event BaseURIset(address indexed operator, string baseURI);

    event UserURIset(
        address indexed operator,
        address indexed to,
        uint256 id,
        string uuri
    );

    event MintFeeSet(address indexed operator, uint256 mintFee);

    /// -----------------------------------------------------------------------
    /// WRAPPR STORAGE/LOGIC
    /// -----------------------------------------------------------------------

    string public name;

    string public symbol;

    string internal baseURI;

    uint256 internal mintFee;

    // Changed this from the original wrappr contract so that we now treat the admin as any token holder of a the admin contract address
    address public admin;

    mapping(uint256 => address) public ownerOf;

    mapping(address => bool) public manager;

    mapping(uint256 => bool) internal registered;

    mapping(uint256 => bool) public transferable;

    mapping(uint256 => bool) public permissioned;

    mapping(address => mapping(uint256 => bool)) public userPermissioned;

    mapping(uint256 => string) internal uris;

    mapping(address => mapping(uint256 => string)) public userURI;

    modifier onlyAdmin() virtual {
        require(IERC721(admin).balanceOf(msg.sender) > 0, "NOT_ADMIN");

        _;
    }

    modifier onlyOwnerOfOrAdmin(uint256 id) virtual {
        require(
            msg.sender == ownerOf[id] ||
                IERC721(admin).balanceOf(msg.sender) > 0,
            "NOT_AUTHORIZED"
        );

        _;
    }

    function isAdmin() private view returns (bool) {
        return IERC721(admin).balanceOf(msg.sender) > 0;
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory tokenURI = uris[id];

        if (bytes(tokenURI).length == 0) return baseURI;
        else return tokenURI;
    }

    /// -----------------------------------------------------------------------
    /// CONSTRUCTOR
    /// -----------------------------------------------------------------------

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _mintFee,
        address _admin
    ) payable {
        name = _name;

        symbol = _symbol;

        baseURI = _baseURI;

        mintFee = _mintFee;

        admin = _admin;

        emit BaseURIset(address(0), _baseURI);

        emit MintFeeSet(address(0), _mintFee);

        emit AdminSet(address(0), _admin);
    }

    /// -----------------------------------------------------------------------
    /// PUBLIC FUNCTIONS
    /// -----------------------------------------------------------------------

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data,
        string calldata tokenURI,
        address owner
    ) public payable virtual {
        uint256 fee = mintFee;

        if (fee != 0) require(msg.value == fee, "NOT_FEE");

        require(!registered[id], "REGISTERED");

        if (owner != address(0)) {
            ownerOf[id] = owner;

            emit OwnerOfSet(address(0), owner, id);
        }

        registered[id] = true;

        __mint(to, id, amount, data, tokenURI);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public payable virtual {
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        __burn(from, id, amount);
    }

    /// -----------------------------------------------------------------------
    /// MANAGEMENT FUNCTIONS
    /// -----------------------------------------------------------------------

    function manageMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data,
        string calldata tokenURI,
        address owner
    ) public payable virtual {
        address _owner = ownerOf[id];

        require(
            msg.sender == _owner || manager[msg.sender] || isAdmin(),
            "NOT_AUTHORIZED"
        );

        if (!registered[id]) registered[id] = true;

        if (_owner == address(0) && (ownerOf[id] = owner) != address(0)) {
            emit OwnerOfSet(address(0), owner, id);
        }

        __mint(to, id, amount, data, tokenURI);
    }

    function manageBurn(
        address from,
        uint256 id,
        uint256 amount
    ) public payable virtual {
        require(
            msg.sender == ownerOf[id] || manager[msg.sender] || isAdmin(),
            "NOT_AUTHORIZED"
        );

        __burn(from, id, amount);
    }

    /// -----------------------------------------------------------------------
    /// OWNER FUNCTIONS
    /// -----------------------------------------------------------------------

    function setOwnerOf(address to, uint256 id)
        public
        payable
        virtual
        onlyOwnerOfOrAdmin(id)
    {
        ownerOf[id] = to;

        emit OwnerOfSet(msg.sender, to, id);
    }

    function setTransferability(uint256 id, bool set)
        public
        payable
        virtual
        onlyOwnerOfOrAdmin(id)
    {
        transferable[id] = set;

        emit TransferabilitySet(msg.sender, id, set);
    }

    function setPermission(uint256 id, bool set)
        public
        payable
        virtual
        onlyOwnerOfOrAdmin(id)
    {
        permissioned[id] = set;

        emit PermissionSet(msg.sender, id, set);
    }

    function setUserPermission(
        address to,
        uint256 id,
        bool set
    ) public payable virtual onlyOwnerOfOrAdmin(id) {
        userPermissioned[to][id] = set;

        emit UserPermissionSet(msg.sender, to, id, set);
    }

    function setURI(uint256 id, string calldata tokenURI)
        public
        payable
        virtual
        onlyOwnerOfOrAdmin(id)
    {
        uris[id] = tokenURI;

        emit URI(tokenURI, id);
    }

    function setUserURI(
        address to,
        uint256 id,
        string calldata uuri
    ) public payable virtual onlyOwnerOfOrAdmin(id) {
        userURI[to][id] = uuri;

        emit UserURIset(msg.sender, to, id, uuri);
    }

    /// -----------------------------------------------------------------------
    /// ADMIN FUNCTIONS
    /// -----------------------------------------------------------------------

    function setManager(address to, bool set) public payable virtual onlyAdmin {
        manager[to] = set;

        emit ManagerSet(msg.sender, to, set);
    }

    function setAdmin(address _admin) public payable virtual onlyAdmin {
        admin = _admin;

        emit AdminSet(msg.sender, _admin);
    }

    function setBaseURI(string calldata _baseURI)
        public
        payable
        virtual
        onlyAdmin
    {
        baseURI = _baseURI;

        emit BaseURIset(msg.sender, _baseURI);
    }

    function setMintFee(uint256 _mintFee) public payable virtual onlyAdmin {
        mintFee = _mintFee;

        emit MintFeeSet(msg.sender, _mintFee);
    }

    function claimFee(address to, uint256 amount)
        public
        payable
        virtual
        onlyAdmin
    {
        assembly {
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                mstore(0x00, hex"08c379a0") // Function selector of the error method.
                mstore(0x04, 0x20) // Offset of the error string.
                mstore(0x24, 19) // Length of the error string.
                mstore(0x44, "ETH_TRANSFER_FAILED") // The error string.
                revert(0x00, 0x64) // Revert with (offset, size).
            }
        }
    }

    /// -----------------------------------------------------------------------
    /// TRANSFER FUNCTIONS
    /// -----------------------------------------------------------------------

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public payable virtual override {
        super.safeTransferFrom(from, to, id, amount, data);

        require(transferable[id], "NONTRANSFERABLE");

        if (permissioned[id])
            require(
                userPermissioned[from][id] && userPermissioned[to][id],
                "NOT_PERMITTED"
            );

        _moveDelegates(delegates(from, id), delegates(to, id), id, amount);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public payable virtual override {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            require(transferable[id], "NONTRANSFERABLE");

            if (permissioned[id])
                require(
                    userPermissioned[from][id] && userPermissioned[to][id],
                    "NOT_PERMITTED"
                );

            _moveDelegates(delegates(from, id), delegates(to, id), id, amount);

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }
    }

    /// -----------------------------------------------------------------------
    /// INTERNAL FUNCTIONS
    /// -----------------------------------------------------------------------

    function __mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data,
        string calldata tokenURI
    ) internal virtual {
        _mint(to, id, amount, data);

        _safeCastTo216(totalSupply[id]);

        _moveDelegates(address(0), delegates(to, id), id, amount);

        if (bytes(tokenURI).length != 0) {
            uris[id] = tokenURI;

            emit URI(tokenURI, id);
        }
    }

    function __burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        _burn(from, id, amount);

        _moveDelegates(delegates(from, id), address(0), id, amount);
    }
}
