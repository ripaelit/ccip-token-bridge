// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title PAAL LP token contract corresponding to PAALAI
contract MockUSDT is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _mint(msg.sender, 100000000000 * 10 ** 6);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function burn(address _to, uint256 _amount) public {
        _burn(_to, _amount);
    }
}
