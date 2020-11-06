pragma solidity ^0.6.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./interfaces/IMuseToken.sol";
import "./interfaces/IVNFT.sol";
import "./interfaces/IVNFTx.sol";

// @TODO create interface for VNFTx
contract V1 is Ownable, ERC1155Holder {
    using SafeMath for uint256;

    bool paused = false;
    //for upgradability
    address public delegateContract;
    address[] public previousDelegates;
    uint256 public total = 1;

    IVNFT public vnft;
    IMuseToken public muse;
    IERC1155 public addons;

    uint256 public artistPct = 5;

    struct Addon {
        string _type;
        uint256 price;
        uint256 hp;
        uint256 rarity;
        string artistName;
        address artistAddr;
        uint256 quantity;
        uint256 used;
    }

    using EnumerableSet for EnumerableSet.UintSet;

    mapping(uint256 => Addon) public addon;

    mapping(uint256 => EnumerableSet.UintSet) private addonsConsumed;

    //nftid to rarity points
    mapping(uint256 => uint256) public rarity;
    mapping(uint256 => uint256) public challengesUsed;

    using Counters for Counters.Counter;
    Counters.Counter private _addonId;

    IVNFTx public vnftx;

    constructor(
        IVNFT _vnft,
        IMuseToken _muse,
        IVNFTx _vnftx
    ) public {
        vnft = _vnft;
        muse = _muse;
        vnftx = _vnftx;
    }

    modifier notPaused() {
        require(!paused, "PAUSED");
        _;
    }

    modifier tokenOwner(uint256 _id) {
        require(
            vnft.ownerOf(_id) == msg.sender ||
                vnft.careTaker(_id, vnft.ownerOf(_id)) == msg.sender,
            "You must own the vNFT or be a care taker to buy addons"
        );
        _;
    }

    // func to test store update with delegatecall
    function challenge1(uint256 _nftId) public {
        rarity[_nftId] = rarity[_nftId] + 888;
    }

    // simple battle for muse
    function battle(uint256 _nftId, uint256 _opponent)
        public
        tokenOwner(_nftId)
    {
        // require x challenges and x hp or xx rarity for battles
        require(
            vnftx.getChallenges(_nftId) >= 1 && rarity[_nftId] >= 100,
            "can't challenge"
        );

        // require opponent to be of certain threshold
        require(vnftx.getHp(_opponent) <= 100, "You can't attack this pet");

        // challenge used.
        challengesUsed[_nftId] = challengesUsed[_nftId].sub(1);

        // decrease something, maybe rarity or something that will lower the opponents hp;
        rarity[_opponent] = rarity[_opponent].sub(100);

        // send muse to attacker based on condition
        muse.mint(msg.sender, 1 ether);
    }
}