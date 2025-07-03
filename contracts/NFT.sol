pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract NFT is ERC721, Ownable {
    uint256 private ticketsNumber;
    uint256 private ticketsSold;
    uint256 private ticketPrice;
    uint256 private ticketId;
    IERC20 public usdtToken;
    mapping (address => uint256) ticketsOfUser;

    event TicketPaid(address indexed buyer);
    event TicketMinted(address indexed to);


    // Constructorul pentru contractul ERC721
    constructor (uint256 _ticketsNumber, uint256 _initialTicketPrice) ERC721("ConcertTickets", "CTI") Ownable(msg.sender){
        ticketsNumber = _ticketsNumber;
        // Initializați prețul biletului (dacă este necesar)
        ticketPrice = _initialTicketPrice; // sau orice alt preț implicit
        ticketId = 0;
        usdtToken = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    }

    // Funcție pentru modificarea prețului biletului
    function modifyTicketPrice(uint256 _newTicketPrice) external onlyOwner {
        ticketPrice = _newTicketPrice;
    }

    function payForTicket() external {   // o adresa poate plati pretul unui bilet, sau pentru mai multe bilete
        require(ticketsSold < ticketsNumber, "No more tickets available");
        bool succes = usdtToken.transferFrom(msg.sender, address(this), ticketPrice);
        require(succes, "Not enough USDT");
        ticketsOfUser[msg.sender]++;
        ticketsSold++;
        emit TicketPaid(msg.sender);
    }

    function retrieveTicket(address _to) external {     // in ticketsOfUser se retine la cate bilete are dreptul un user si poate alege 
        require(ticketsOfUser[msg.sender] >= 1, "No tickets to retrieve");        // catre ce portofel sa trimita biletul daca vrea sa cumpere si pentru
        require(_to != address(0), "Invalid address.");  // prietenii sai.
        _mint(_to, ticketId);                          
        ticketId++;
        ticketsOfUser[msg.sender]--;
        emit TicketMinted(_to);
    }

    function withdraw() external onlyOwner {
        uint256 balance = usdtToken.balanceOf(address(this));
        require(balance > 0, "No USDT to withdraw");
        usdtToken.transfer(owner(), balance);
    }

    function setUsdtToken(address _usdt) external onlyOwner {
        usdtToken = IERC20(_usdt);
    }
}
