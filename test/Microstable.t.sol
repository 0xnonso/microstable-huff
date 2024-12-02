// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "foundry-huff/HuffConfig.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../lib/huffmate/src/tokens/interfaces/IERC20.sol";

contract MicrostableTest is Test {
    /// @dev Address of the SimpleStore contract.
    Manager public manager;
    MockOracle public oracle;
    MockERC20 public weth;
    Token public hUSD;


    /// @dev Setup the testing environment.
    function setUp() public {
        oracle = new MockOracle();
        weth = new MockERC20();
        HuffConfig config = HuffDeployer.config();
        hUSD = Token(computeCreateAddress(address(config), 2));
        manager = Manager(
            config
            .with_args(bytes.concat(abi.encode(weth), abi.encode(hUSD), abi.encode(oracle)))
            .deploy("Manager")
        );
        hUSD = Token(
            config
            .with_args(bytes.concat(abi.encode(address(manager))))
            .deploy("HUSD")
        );
    }

    function testDeposit(uint256 amount) public {
        uint256 amount = bound(amount, 0, 1e51);
        address bob = makeAddr("bob");
        vm.startPrank(bob);

        deal(address(weth), bob, type(uint).max);
        weth.approve(address(manager), amount);

        manager.deposit(amount);

        uint256 mintAmt = _calculateMaxMint(amount);
        manager.mint(mintAmt);
        manager.burn(mintAmt);

        manager.withdraw(amount);

        vm.stopPrank();
    }

    function _calculateMaxMint(uint256 depositAmt) internal view returns(uint256){
        // will round down
        // if(depositAmt > 1.5e18) return (depositAmt / 1.5e18)*1e10;
        return depositAmt/1.5e8;
    }
}

contract MockOracle {
    function latestAnswer() external view returns(uint256){
        return 1e18;
    }
}

interface Token is IERC20 {
    function burn(address to, uint256 amount) external;
    function mint(address to, uint256 amount) external;
}

interface Manager {
    function deposit(uint amount) external;
    function burn(uint amount) external;
    function mint(uint amount) external;
    function withdraw(uint amount) external ;
    function liquidate(address user) external;
    function collatRatio(address user) external view returns (uint);
    function oracle() external view returns(address);
    function weth() external view returns(address);
    function hUSD() external view returns(address);
}

// https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;


    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }
}
contract MockERC20 is ERC20("Wrapped Ether", "weth", 18) {}
