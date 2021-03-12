pragma solidity ^0.5.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    //调用限制
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20Token is Ownable{
    using SafeMath for uint256;

    string public name; // 代币名称
    string public symbol; // 代币符号
    uint8 public decimals;  // decimals 可以有的小数点个数，最小的代币单位
    uint256 public totalSupply; // 供应的份额，份额跟最小的代币单位有关，份额 = 币数 * 10 ** decimals。

    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event FrozenFunds(address target, bool freeze);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    bool openFrozen; //开启冻结功能
    bool openMint;  //开启增发功能
    bool openBurn;  //开启销毁功能

    constructor (
        uint256 _initialSupply,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        bool _frozen,
        bool _mint,
        bool _burn
    ) public{
        decimals = _decimals;
        totalSupply = _initialSupply * 10 ** uint256(_decimals);
        balanceOf[msg.sender] = totalSupply;
        name = _name;
        symbol = _symbol;

        openFrozen = _frozen;
        openMint = _mint;
        openBurn = _burn;
    }

    //冻结账户（转账和接收代币）
    function freezeAccount(address target, bool freeze) public onlyOwner {
        require(openFrozen,"openFrozen is flase");
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    //转移代币
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    //查看授权转账代币数量
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowance[owner][spender];
    }

    //授权转账代币
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    //代理委托人转账
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowance[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds _allowance"));
        return true;
    }

    //增加授权转账代币数量
    function increase_allowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowance[msg.sender][spender].add(addedValue));
        return true;
    }

    //减少授权转账代币数量
    function decrease_allowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowance[msg.sender][spender].sub(subtractedValue, "ERC20: decreased _allowance below zero"));
        return true;
    }

    //代币增发
    function mint(address account, uint256 amount) public onlyOwner{
        _mint(account, amount);
    }

    //销毁自己的代币
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    //代理销毁委托人的代币
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        if(openFrozen){
            require(!frozenAccount[sender]);
            require(!frozenAccount[recipient]);
        }


        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        balanceOf[sender] = balanceOf[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(openMint,"openMint is flase");
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply = totalSupply.add(amount);
        balanceOf[account] = balanceOf[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(openBurn,"openBurn is flase");
        require(account != address(0), "ERC20: burn from the zero address");

        balanceOf[account] = balanceOf[account].sub(amount, "ERC20: burn amount exceeds balance");
        totalSupply = totalSupply.sub(amount);
        emit Burn(account,amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowance[account][msg.sender].sub(amount, "ERC20: burn amount exceeds _allowance"));
    }

    //合约销毁
    function kill() public onlyOwner{
        selfdestruct(msg.sender);
    }

    //callback
    function fallback() external payable{
        revert();//调用时报错
    }
}