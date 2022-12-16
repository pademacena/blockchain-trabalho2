//SPDX-License-Identifier: Unlicense

// contracts/BuyMeACoffee.sol
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// Mude para o seu próprio endereço de contrato uma vez implantado, para contabilidade!
// Exemplo de endereço de contrato em Goerli: 0x77701a42289bcf1834D217ffaA28CFD909b599c8

contract BuyMeACoffee is Ownable {
    uint256 public constant priceLargeCoffee = 0.003 ether;
    string public constant regularCoffee = "Regular Coffee";
    string public constant largeCoffee = "Large Coffee";

    // Evento a ser emitido quando um Memo é criado.
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message,
        string coffeesize
    );

    address payable withdrawAddress;
    address payable _owner;

    // Estrutura de memorando.
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
        string coffeesize;
    }

    // Endereço do implantador do contrato. Marcado a pagar para que
    // possamos retirar para este endereço mais tarde.

    // Lista de todos os memorandos recebidos de compras de café.
    Memo[] memos;

    constructor() {
        // Armazena o endereço do implantador como um endereço pagável.
        // Quando retirarmos fundos, retiraremos aqui.
        _owner = payable(msg.sender);
        withdrawAddress = payable(msg.sender);
    }

    modifier onlyWithdrawer() {
        require(msg.sender == withdrawAddress);
        _;
    }

    /**
     * @dev busca todos os memorandos armazenados
     */
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }

    /**
     * @dev compra um café para o proprietário (envia uma dica de ETH e deixa um memorando)
     * @param _name nome do comprador do café
     * @param _message uma boa mensagem do comprador
     */
    function buyCoffee(string memory _name, string memory _message)
        public
        payable
    {
        // Deve aceitar mais de 0 ETH para um café.
        require(msg.value > 0, "can't buy coffee for free!");
        string memory _coffeesize = regularCoffee;

        // Adiciona o memorando ao armazenamento!
        memos.push(
            Memo(msg.sender, block.timestamp, _name, _message, _coffeesize)
        );

        // Emite um evento NewMemo com detalhes sobre o memorando.
        emit NewMemo(msg.sender, block.timestamp, _name, _message, _coffeesize);
    }

    function buyLargeCoffee(string memory _name, string memory _message)
        public
        payable
    {
        // Deve aceitar mais de 0,003 ETH para um Largecoffee.
        require(
            msg.value >= priceLargeCoffee,
            "can't buy a large coffee for less than 0.003 ether!"
        );

        // define o tamanho do café
        string memory _coffeesize = largeCoffee;

        // Adicione o memorando ao armazenamento!
        memos.push(
            Memo(msg.sender, block.timestamp, _name, _message, _coffeesize)
        );

        // Emite um evento NewMemo com detalhes sobre o memorando.
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

/**
 * @dev Módulo de contrato que fornece um mecanismo básico de controle de acesso, onde
 * existe uma conta (um proprietário) que pode receber acesso exclusivo a
 * funções específicas.
 *
 * Por padrão, a conta do proprietário será aquela que implanta o contrato. este
 * pode ser alterado posteriormente com {transferOwnership}.
 *
 * Este módulo é usado por herança. Ele disponibilizará o modificador
 * `onlyOwner`, que pode ser aplicado às suas funções para restringir seu uso ao dono.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Inicializa o contrato definindo o implantador como o proprietário inicial.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Lança se chamado por qualquer conta que não seja o proprietário.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Retorna o endereço do proprietário atual.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Lança se o remetente não for o proprietário.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Deixa o contrato sem dono. Não será possível ligar
     * funções `onlyOwner` mais. Só pode ser chamado pelo proprietário atual.
     *
     * NOTA: A renúncia à propriedade deixará o contrato sem proprietário,
     * removendo assim qualquer funcionalidade que esteja disponível apenas para o proprietário.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfere a propriedade do contrato para uma nova conta (`newOwner`).
     * Só pode ser chamado pelo proprietário atual.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfere a propriedade do contrato para uma nova conta (`newOwner`).
     * Função interna sem restrição de acesso.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

/**
 * @dev Fornece informações sobre o contexto de execução atual, incluindo o
 * remetente da transação e seus dados. Embora estes estejam geralmente disponíveis
 * via msg.sender e msg.data, eles não devem ser acessados de forma tão direta,
 * pois ao lidar com meta-transações a conta enviando e
 * pagando pela execução pode não ser o remetente real (no que diz respeito a um aplicativo
 * está preocupado).
 *
 * Este contrato é necessário apenas para contratos intermediários, semelhantes a bibliotecas.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
