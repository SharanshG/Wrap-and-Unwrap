// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Interface for Wrapped ETH (WETH)
interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

contract Vault is Ownable {
    using SafeERC20 for IERC20;

    // Mapping to track user balances
    mapping(address => uint256) public balances;

    // Wrapped ETH (WETH) address
    address public wethAddress;

    event ETHDeposited(address indexed user, uint256 amount);
    event ETHWithdrawn(address indexed user, uint256 amount);
    event ERC20Deposited(address indexed user, address indexed token, uint256 amount);
    event ERC20Withdrawn(address indexed user, address indexed token, uint256 amount);
    event ETHWrapped(address indexed user, uint256 amount);
    event ETHUnwrapped(address indexed user, uint256 amount);

    constructor(address _wethAddress) Ownable(msg.sender) {
        wethAddress = _wethAddress;
    }

    modifier nonZeroAmount(uint256 amount) {
        require(amount > 0, "Amount must be greater than zero");
        _;
    }

    // Deposit ETH into the vault
    function depositETH() external payable nonZeroAmount(msg.value) {
        balances[msg.sender] += msg.value;
        emit ETHDeposited(msg.sender, msg.value);
    }

    // Withdraw ETH from the vault
    function withdrawETH(uint256 amount) external nonZeroAmount(amount) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit ETHWithdrawn(msg.sender, amount);
    }

    // Deposit ERC20 tokens into the vault
    function depositERC20(address tokenAddress, uint256 amount) external nonZeroAmount(amount) {
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
        emit ERC20Deposited(msg.sender, tokenAddress, amount);
    }

    // Withdraw ERC20 tokens from the vault
    function withdrawERC20(address tokenAddress, uint256 amount) external nonZeroAmount(amount) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
        emit ERC20Withdrawn(msg.sender, tokenAddress, amount);
    }

    // Wrap ETH into WETH within the vault
    function wrapETH() external nonZeroAmount(balances[msg.sender]) {
        IWETH(wethAddress).deposit{value: balances[msg.sender]}();
        balances[msg.sender] = 0;
        emit ETHWrapped(msg.sender, balances[msg.sender]);
    }

    // Unwrap WETH into ETH within the vault
    function unwrapWETH(uint256 amount) external nonZeroAmount(amount) {
        require(balances[msg.sender] >= amount, "Insufficient WETH balance");
        IWETH(wethAddress).withdraw(amount);
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit ETHUnwrapped(msg.sender, amount);
    }
}
