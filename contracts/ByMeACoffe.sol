pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BuyMeACoffee is Ownable {
    uint256 public constant priceLargeCoffee = 0.003 ether;
    string public constant regularCoffee = "Regular Coffee";
    string public constant largeCoffee = "Large Coffee";
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message,
        string coffeesize
    );

    address payable withdrawAddress;
    address payable _owner;

    // Memo struct.
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
        string coffeesize;
    }
    Memo[] memos;

    constructor() {
        _owner = payable(msg.sender);
        withdrawAddress = payable(msg.sender);
    }

    modifier onlyWithdrawer() {
        require(msg.sender == withdrawAddress);
        _;
    }

    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }

    function buyCoffee(string memory _name, string memory _message)
        public
        payable
    {
        require(msg.value > 0, "can't buy coffee for free!");
        string memory _coffeesize = regularCoffee;

        memos.push(
            Memo(msg.sender, block.timestamp, _name, _message, _coffeesize)
        );
        emit NewMemo(msg.sender, block.timestamp, _name, _message, _coffeesize);
    }

    function buyLargeCoffee(string memory _name, string memory _message)
        public
        payable
    {
        require(
            msg.value >= priceLargeCoffee,
            "can't buy a large coffee for less than 0.003 ether!"
        );

        string memory _coffeesize = largeCoffee;

        memos.push(
            Memo(msg.sender, block.timestamp, _name, _message, _coffeesize)
        );

        emit NewMemo(msg.sender, block.timestamp, _name, _message, _coffeesize);
    }

    function withdrawTipsToOwner() public onlyOwner {
        require(_owner.send(address(this).balance));
    }

    function withdrawTipsToSetWithdrawAddress() public onlyOwner {
        require(withdrawAddress.send(address(this).balance));
    }

    function withdrawTipsToOther(address payable _to, uint256 _amount)
        public
        onlyOwner
    {
        _to.transfer(_amount);
    }

    function setWithdrawAddress(address payable newWithdrawAddress)
        public
        onlyOwner
    {
        withdrawAddress = newWithdrawAddress;
    }
}

pragma solidity ^0.8.0;

import "../utils/Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
