// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract mATV2 is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable, OwnableUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {
    
    /// blacklistable
    address public blacklister;
    mapping(address => bool) internal blacklisted;

    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);
    event BlacklisterChanged(address indexed newBlacklister);

    /// mATV1
    uint8 private _decimals;
    string public currency;
    address public masterMinter;
    bool internal initialized;
    address public pauser;

    mapping(address => bool) internal minters;
    mapping(address => uint256) internal minterAllowed;

    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
    event MinterRemoved(address indexed oldMinter);
    event MasterMinterChanged(address indexed newMasterMinter);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _currency,
        uint8 __decimals,
        address _masterMinter,
        address _blacklister,
        address _owner,
        address _pauser
        ) initializer public {
        __ERC20_init(_name, _symbol);
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __Ownable_init(_owner);
        __ERC20Permit_init(_name);
        blacklister = _blacklister;
        currency = _currency;
        _decimals = __decimals;
        masterMinter = _masterMinter;
        pauser = _pauser; 
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////// MODIFIER //////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    /**
     * @dev Throws if called by any account other than the blacklister
    */
    modifier onlyBlacklister() {
        require(msg.sender == blacklister, "onlyBlacklister");
        _;
    }

    /**
     * @dev Throws if argument account is blacklisted
     * @param _account The address to check
    */
    modifier notBlacklisted(address _account) {
        require(blacklisted[_account] == false, "Blacklisted");
        _;
    }

    /**
     * @dev Throws if called by any account other than the pauser
    */
    modifier onlyPauser() {
        require(msg.sender == pauser);
        _;
    }

    /**
     * @dev Throws if called by any account other than a minter
    */
    modifier onlyMinters() {
        require(minters[msg.sender] == true, "onlyMinters");
        _;
    }
    
    /**
     * @dev Throws if called by any account other than the masterMinter
    */
    modifier onlyMasterMinter() {
        require(msg.sender == masterMinter, "onlyMasterMinter");
        _;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////// BLACK LIST FUNCTIONS //////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Checks if account is blacklisted
     * @param _account The address to check    
    */
    function isBlacklisted(address _account) public view returns (bool) {
        return blacklisted[_account];
    }

    /**
     * @dev Adds account to blacklist
     * @param _account The address to blacklist
    */
    function blacklist(address _account) public onlyBlacklister {
        blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    /**
     * @dev Removes account from blacklist
     * @param _account The address to remove from the blacklist
    */
    function unBlacklist(address _account) public onlyBlacklister {
        blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }

    function updateBlacklister(address _newBlacklister) public onlyOwner {
        require(_newBlacklister != address(0));
        blacklister = _newBlacklister;
        emit BlacklisterChanged(blacklister);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////// PAUSABLE FUNCTIONS ////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////// MINTABLE FUNCTIONS ////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint. Must be less than or equal to the minterAllowance of the caller.
     * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) whenNotPaused onlyMinters notBlacklisted(msg.sender) notBlacklisted(_to) public returns (bool) {
        require(_to != address(0));
        require(_amount > 0);
        require(balanceOf(_to) == 0, "balanceOf(_to) > 0"); //ADDED LINE TO V2

        uint256 mintingAllowedAmount = minterAllowed[msg.sender];
        require(_amount <= mintingAllowedAmount);

        _mint(_to, _amount);

        minterAllowed[msg.sender] = mintingAllowedAmount - (_amount);
        emit Mint(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @dev Get minter allowance for an account
     * @param minter The address of the minter
    */
    function minterAllowance(address minter) public view returns (uint256) {
        return minterAllowed[minter];
    }

    /**
     * @dev Checks if account is a minter
     * @param account The address to check    
    */
    function isMinter(address account) public view returns (bool) {
        return minters[account];
    }

    /**
     * @dev Function to add/update a new minter
     * @param minter The address of the minter
     * @param minterAllowedAmount The minting amount allowed for the minter
     * @return True if the operation was successful.
    */
    function configureMinter(address minter, uint256 minterAllowedAmount) whenNotPaused onlyMasterMinter public returns (bool) {
        minters[minter] = true;
        minterAllowed[minter] = minterAllowedAmount;
        emit MinterConfigured(minter, minterAllowedAmount);
        return true;
    }

    /**
     * @dev Function to remove a minter
     * @param minter The address of the minter to remove
     * @return True if the operation was successful.
    */
    function removeMinter(address minter) onlyMasterMinter public returns (bool) {
        minters[minter] = false;
        minterAllowed[minter] = 0;
        emit MinterRemoved(minter);
        return true;
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20Upgradeable, ERC20PausableUpgradeable)
    {
        super._update(from, to, value);
    }

    /**
     * @dev allows a minter to burn some of its own tokens
     * Validates that caller is a minter and that sender is not blacklisted
     * amount is less than or equal to the minter's account balance
     * @param _amount uint256 the amount of tokens to be burned
    */
    function burn(uint256 _amount) override whenNotPaused onlyMinters notBlacklisted(msg.sender) public {
        require(_amount > 0);

        _burn(msg.sender, _amount);

        emit Burn(msg.sender, _amount);
    }

    function updateMasterMinter(address _newMasterMinter) onlyOwner public {
        require(_newMasterMinter != address(0));
        masterMinter = _newMasterMinter;
        emit MasterMinterChanged(masterMinter);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////// UPGRADE FUNCTIONS /////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////// TRANSFER FUNCTIONS ////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev This functions cannot be called when paused or when called by blacklisted addresses or to blacklisted addresses.
     */
    function approve(address _spender, uint256 _value) whenNotPaused notBlacklisted(msg.sender) notBlacklisted(_spender) public override returns (bool) {
        address _owner = _msgSender();
        _approve(_owner, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused notBlacklisted(msg.sender) notBlacklisted(_from) notBlacklisted(_to) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(_from, spender, _value);
        _transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) whenNotPaused notBlacklisted(msg.sender) notBlacklisted(_to) public override returns (bool) {
        address _owner = _msgSender();
        _transfer(_owner, _to, _value);
        return true;
    }
}
