// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./utils/LosslessEnv.t.sol";

contract LERC20BurnableTests is LosslessTestEnvironment {

    /// @notice Test deployed Burnable LERC20 variables
    function testLERC20BurnableDeploy() public {
      assertEq(lerc20Burnable.totalSupply(), totalSupply);
      assertEq(lerc20Burnable.name(), "LERC20 Burnable");
      assertEq(lerc20Burnable.admin(), address(this));
      assertEq(lerc20Burnable.recoveryAdmin(), address(this));
      assertEq(lerc20Burnable.timelockPeriod(), 1 days);
    }

    /// @notice Test simple burn
    /// @dev Should not revert
    /// @param burnAmount Random burn amount
    function testLERC20Burn(uint8 burnAmount, address randAddress) public {
      if (randAddress == address(0)) {
        assertTrue(true);
      } else {
        lerc20Burnable.transfer(randAddress, burnAmount + 10000);
        cheats.warp(block.timestamp + settlementPeriod + 1);
        uint256 balanceBefore = lerc20Burnable.balanceOf(randAddress);
        cheats.startPrank(randAddress);
        lerc20Burnable.burn(burnAmount);
        cheats.stopPrank();
        assertEq(lerc20Burnable.balanceOf(randAddress), balanceBefore - burnAmount);
      }
    }


    /// @notice Test burn over limit with one address
    /// @dev Should revert
    /// @param randAddress Random address
    function testLERC20BurnOverLimitSingle(address randAddress) public {

      lerc20Burnable.transfer(randAddress, mintAndBurnLimit + 1);
    
      cheats.warp(block.timestamp + settlementPeriod + 1);

      cheats.prank(randAddress);
      cheats.expectRevert("LSS: Token burn per period limit");
      lerc20Burnable.burn(mintAndBurnLimit + 1);
    }

    /// @notice Test burn over limit with mutliple burning
    /// @dev Should revert
    function testLERC20BurnOverLimitMulti() public {
      address[6] memory burners = [address(1), address(2), address(3), address(4), address(5), address(1)];
      uint256 burnAmount = mintAndBurnLimit + 1 / burners.length;
      uint256 cummulativeBurn = 0;
      
      for (uint i = 0; i < burners.length; i++) {
        lerc20Burnable.transfer(burners[i], burnAmount);
      }
    
      cheats.warp(block.timestamp + settlementPeriod + 1);

      for (uint i = 0; i < burners.length; i++) {
        cheats.prank(burners[i]);
        cummulativeBurn += burnAmount;
        if (cummulativeBurn >= mintAndBurnLimit + 1) {
          cheats.expectRevert("LSS: Token burn per period limit");
        }
        lerc20Burnable.burn(burnAmount);
      }
    }

    
    /// @notice Test simple burnFrom
    /// @dev Should not revert
    /// @param burnAmount Random burn amount
    function testLERC20BurnFrom(uint8 burnAmount, address randAddress) public {
      lerc20Burnable.transfer(randAddress, burnAmount + 10000);
      uint256 balanceBefore = lerc20Burnable.balanceOf(randAddress);
      cheats.prank(randAddress);
      lerc20Burnable.approve(address(this), balanceBefore);
      lerc20Burnable.burnFrom(randAddress, burnAmount);
      assertEq(lerc20Burnable.balanceOf(randAddress), balanceBefore - burnAmount);
    }

    /// @notice Test burnFrom when not admin
    /// @dev Should revert
    /// @param randAddress Random address
    function testLERC20BurnFromNonAdmin(address randAddress) public {
      lerc20Burnable.transfer(address(1), 1500);
      cheats.startPrank(randAddress);
      cheats.expectRevert("ERC20: burn amount exceeds allowance");
      lerc20Burnable.burnFrom(address(1), 1000);
      cheats.stopPrank();
    }
}