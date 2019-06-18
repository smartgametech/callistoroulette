
// File: contracts/safeMath.sol

pragma solidity 0.4.24;

library SafeMath {
  //internals
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    require(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    require(c >= a && c >= b);
    return c;
  }
}

// File: contracts/Ownable.sol

pragma solidity 0.4.24;


contract Ownable {

    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contracts to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contracts to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

// File: contracts/BetherRoulette.sol

pragma solidity 0.4.24;



contract RouletteMatrix {
    function isReady() public view returns( bool) ;
    function getFactor(uint16 bet, uint16 wheelResult) external view returns (uint256);
}

contract BetherRoulette is Ownable {
    using SafeMath for uint256;

    address operator;
    address croupier;
    address distributeProfit;
    // Wait BlockDelay blocks before generate random number
    uint8 blockDelay;

    // The value of a credit in ether
    uint256 oneCreditValue;

    // Enable/disable to place new bets
    bool contractState;

    // table with winner coefficients
    RouletteMatrix rouletteMatrix;

    uint16 constant maxTypeBets = 157;
    //
    mapping(uint8 => uint8) private minCreditsOnBet;
    mapping(uint8 => uint8) private maxCreditsOnBet;
    uint256 bankrolLimit;
    uint256 profitLimit;
    uint256 lastDistributedProfit;
    uint256 lastDateDistributedProfit;

    mapping(address => uint[]) myGames;
    uint[] unSettledGames;
    uint256 jackpotAmount = 0 ether;
    // placed amounts has not been processed
    uint256 lockedAmount = 0;
    uint256 constant MIN_JACKPOT_BET = 200 ether;
    uint16 constant JACKPOT_MODULO = 1000;

    struct GameInfo {
        uint8 wheelResult;
        uint40 blockNumber;
        address player;
        uint256 bets;
        bytes32 values;
        bytes32 values2;
        uint256 jackpotAmount;
    }

    GameInfo[] private gambles;

    struct Jackpot {
        uint16 result;
        address player;
        uint gambleId;
        uint256 winAmount;
    }

    Jackpot[] jackpots;
    enum GameStatus {Success, Skipped, Stop}

    event PlayerBet(uint256 gambleId, address player);
    event EndGame(address player, uint8 result, uint256 gambleId, uint256 winAmount);
    event SettingsChanged();

    event RefundGame(address player, uint gambleId, uint256 refundAmount);
    event JackpotLog(address player, uint gambleId, uint256 winAmount);
    event DistributeProfitEvent(address profitAddr, uint256 amount);
    event InvestEvent(address investor, uint256 amount);

    constructor() public {
        distributeProfit = msg.sender;
        operator = msg.sender;
        croupier = msg.sender;
        rouletteMatrix = RouletteMatrix(0x65465667ec5e5c2c672e5612b13cb1cf806f5362);
        // by default, 1 Credit = 20 CLO
        oneCreditValue = 20 ether;

        blockDelay = 1;
        contractState = true;
        bankrolLimit = 100000 ether;
        profitLimit = 10000 ether;
    }

    function changeSettings(uint256 newOneCreditValue, uint8 newBlockDelay) public onlyOwner {
        require(newOneCreditValue < 10 ether);
        require(newBlockDelay >= 1);

        blockDelay = newBlockDelay;

        if (newOneCreditValue != oneCreditValue) {
            oneCreditValue = newOneCreditValue;
            emit SettingsChanged();
        }
    }

    function changeDistributeProfit(address newDistributeProfitAddr) public onlyOwner {
        require(newDistributeProfitAddr != address(0) && newDistributeProfitAddr != distributeProfit);
        distributeProfit = newDistributeProfitAddr;
    }

    function getDistributeProfitsInfo() public view returns (address distributeProfitAddr, uint256 lastProfit, uint256 lastDate) {
        lastProfit = lastDistributedProfit;
        lastDate = lastDateDistributedProfit;
        distributeProfitAddr = distributeProfit;
    }


    function getCroupier() public view returns (address) {
        return croupier;
    }

    function getOperator() public view returns (address) {
        return operator;
    }

    function getDistributeProfit() public view returns(address) {
        return distributeProfit;
    }


    function distributeProfits() public onlyOwnerOrOperator  {
        if (address(this).balance >= (bankrolLimit + profitLimit + jackpotAmount + lockedAmount)) {
            uint256 diff = address(this).balance.safeSub(bankrolLimit).safeSub(jackpotAmount).safeSub(lockedAmount);
            distributeProfit.transfer(diff);
            lastDistributedProfit = diff;
            lastDateDistributedProfit = now;
            emit DistributeProfitEvent(distributeProfit, diff);
        }
    }


    function changeTokenSettings(uint256 newBankrolLimit, uint256 newProfitLimit) public onlyOwner {
        bankrolLimit = newBankrolLimit;
        profitLimit = newProfitLimit;
    }

    function changeMinBet(uint8[157] value) public onlyOwner {
        // value[i] == 0 means skip this value
        // value[i] == 255 means value will be 0
        // Raw mapping minCreditsOnBet changes from 0 to 254,
        // when compare with real bet we add +1, so min credits changes from 1 to 255
        for (uint8 i = 0; i < 157; i++) {
            if (value[i] > 0) {
                if (value[i] == 255) {
                    minCreditsOnBet[i] = 0;
                } else {
                    minCreditsOnBet[i] = value[i];
                }
            }
        }
        emit SettingsChanged();
    }

    function changeMaxBet(uint8[157] value) public onlyOwner
    {
        // value[i] == 0 means skip this value
        // value[i] == 255 means value will be 0
        // Raw mapping maxCreditsOnBet hold values that reduce max bet from 255 to 0
        // If we want to calculate real max bet value we should do: 256 - maxCreditsOnBet[i]
        // example: if mapping holds 0 it means, that max bet will be 256 - 0 = 256
        //          if mapping holds 50 it means, that max bet will be 256 - 50 = 206
        for (uint8 i = 0; i < 157; i++) {
            if (value[i] > 0) {
                if (value[i] == 255) {
                    maxCreditsOnBet[i] = 0;
                }  else {
                    maxCreditsOnBet[i] = 255 - value[i];
                }

            }
        }
        emit  SettingsChanged();
    }

    function deleteContract() public onlyOwner {
        require(lockedAmount == 0);// all games must be settled or refunded
        selfdestruct(msg.sender);
    }

    // bit from 0 to 255
    function isBitSet(uint256 data, uint8 bit) public pure returns (bool ret)  {
        assembly {
            ret := iszero(iszero(and(data, exp(2, bit))))
        }
        return ret;
    }

    // n form 1 <= to <= 32
    function getBetValue(bytes32 values, uint8 n, uint8 nBit) private view returns (uint256) {
        // bet in credits (1..256)
        uint256 bet = uint256(values[32 - n]) + 1;
        //default: bet < 0+1
        require(bet >= uint256(minCreditsOnBet[nBit] + 1));
        //default: bet > 256-0
        require(bet <= uint256(256 - maxCreditsOnBet[nBit]));
        return oneCreditValue * bet;
    }

    // n - number player bet
    // nBit - betIndex
    function getBetValueByGamble(GameInfo memory gamble, uint8 n, uint8 nBit) private view returns (uint256) {
        if (n <= 32) return getBetValue(gamble.values, n, nBit);
        if (n <= 64) return getBetValue(gamble.values2, n - 32, nBit);
        // there are 64 maximum unique bets (positions) in one game
        revert();
    }

    function totalGames() public view returns (uint256) {
        return gambles.length;
    }

    function getSettings() public view returns (uint256 maxBet, uint256 oneCredit,
        uint8[157] _minCreditsOnBet, uint8[157] _maxCreditsOnBet, uint8 bDelay,
        bool cState){
        maxBet = oneCreditValue;
        oneCredit = oneCreditValue;
        bDelay = blockDelay;
        for (uint8 i = 0; i < maxTypeBets; i++)  {
            _minCreditsOnBet[i] = minCreditsOnBet[i] + 1;
            _maxCreditsOnBet[i] = 255 - maxCreditsOnBet[i];
        }
        cState = contractState;
    }

    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner || msg.sender == operator);
        _;
    }

    modifier onlyOwnerOrCroupier() {
        require(msg.sender == owner || msg.sender == croupier);
        _;
    }

    function disableBetting() public onlyOwnerOrOperator
    {
        contractState = false;
    }

    function enableBetting() public onlyOwnerOrOperator {
        contractState = true;
    }

    function changeOperator(address newOperator) public onlyOwner {
        require(newOperator != address(0) && operator != newOperator);
        operator = newOperator;
    }

    function changeCroupier(address newCroupier) public onlyOwner {
        require(newCroupier != address(0) && newCroupier != croupier);
        croupier = newCroupier;
    }

    function totalBetValue(GameInfo memory g) private view returns (uint256) {
        uint256 totalBetsValue = 0;
        uint8 nPlayerBetNo = 0;
        uint8 betsCount = uint8(bytes32(g.bets)[0]);

        for (uint8 i = 0; i < maxTypeBets; i++)
            if (isBitSet(g.bets, i)) {
                totalBetsValue += getBetValueByGamble(g, nPlayerBetNo + 1, i);
                nPlayerBetNo++;
                if (betsCount == 1) break;
                betsCount--;
            }

        return totalBetsValue;
    }

    function totalBetCount(GameInfo memory g) private pure returns (uint256) {
        uint256 totalBets = 0;
        for (uint8 i = 0; i < maxTypeBets; i++)
            if (isBitSet(g.bets, i)) totalBets++;
        return totalBets;
    }

    // Remove settled game out of temporary unsettled index collection
    function removeUnSettledGame(uint gameId) private returns (bool) {

        for(uint i=0; i<unSettledGames.length;i++) {
            if(unSettledGames[i]==gameId) {
                unSettledGames[i] =  unSettledGames[uint32(unSettledGames.length - 1)];
                unSettledGames.length--;
                break;
            }
        }
        return true;
    }


    function placeBet(uint256 bets, bytes32 values1, bytes32 values2) public payable {

        require(contractState);
        require(bets > 0);
        require(msg.value > 0);

        GameInfo memory g = GameInfo(37, uint40(block.number), msg.sender, bets, values1, values2,0);

        require(totalBetValue(g) == msg.value);
        lockedAmount = lockedAmount.safeAdd(msg.value);
        uint gameId  = gambles.push(g) - 1;
        myGames[msg.sender].push(gameId);
        uint32(unSettledGames.push(gameId));
        emit PlayerBet(gameId, msg.sender);

    }

    // owner can deposit fund for this contract
    function invest() public payable onlyOwner {
        emit InvestEvent(msg.sender, msg.value);
    }

    // only croupier or dev can settle bet
    function settleBet(uint256 index) public onlyOwnerOrCroupier{
        GameInfo memory g = gambles[index];
        require(block.number >= g.blockNumber + blockDelay);
        require(block.number - g.blockNumber < 256);
        require(g.wheelResult == 37);

        gambles[index].wheelResult = getRandomNumber(g.player, g.blockNumber, block.number);
        uint256 placedAmount = totalBetValue(g);
        // deduct 1% bet amount for jackpot fee
        jackpotAmount = jackpotAmount.safeAdd(placedAmount / 100);

        uint256 playerWinnings = getGameResult(gambles[index]);
        if(placedAmount >= MIN_JACKPOT_BET) {
            bytes32 shaJackpot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(g.player, gambles[index].wheelResult))
            ,blockhash(g.blockNumber), blockhash(block.number - 1)));

            uint16 result = uint16(uint256(shaJackpot));
            // jackpot found
            if (result  % JACKPOT_MODULO == 0) {
                Jackpot memory jackpot = Jackpot(result, gambles[index].player, index, jackpotAmount);
                playerWinnings  += jackpotAmount;

                gambles[index].jackpotAmount = jackpotAmount;
                jackpotAmount = 0;
                jackpots.push(jackpot);
            }
        }
        if (playerWinnings > 0) {
            g.player.transfer(playerWinnings);
        }

        lockedAmount = lockedAmount.safeSub(placedAmount);
        removeUnSettledGame(index);
        emit EndGame(g.player, gambles[index].wheelResult, index, playerWinnings);
    }


    function totalJackpot() public view returns (uint) {
        return jackpots.length;
    }

    function getJackpotAmount() public view returns(uint256 jackpot) {
        jackpot = jackpotAmount;
    }

    function getLockedAmount() public view returns(uint256) {
        return lockedAmount;
    }
    // get jackpot information
    function getJackpot(uint index) public view returns (uint jackpotId, address player, uint result, uint gambleId, uint256 jackpotWinAmount) {
        jackpotId = index;
        player = jackpots[index].player;
        result  = jackpots[index].result;
        gambleId = jackpots[index].gambleId;
        jackpotWinAmount = jackpots[index].winAmount;
    }

    // refund for unsettled game and hash block number less than current block - 256
    function refund(uint index) public {
        // allow refund for unsettled game
        require(gambles[index].wheelResult == 37);
        require(gambles[index].blockNumber < block.number - 256);
        GameInfo memory gameInfo = gambles[index];
        gambles[index].wheelResult = 200;
        removeUnSettledGame(index);
        uint256 placedAmount = totalBetValue(gameInfo);
        gameInfo.player.transfer(placedAmount);
        lockedAmount = lockedAmount.safeSub(placedAmount);
        emit RefundGame(gameInfo.player, index, placedAmount);

    }

    function getRandomNumber(address player, uint256 playerblock, uint256 settleBlock) private view returns (uint8 wheelResult) {
        // block.blockhash - hash of the given block - only works for 256 most recent blocks excluding current
        bytes32 blockHash = blockhash(playerblock + blockDelay);
        require(blockHash != 0);
        // retrieve blockhash of  settleBlock - 1,
        // with this value, the house edge can not know the wheel result before settle bet
        bytes32 shaPlayer = keccak256(abi.encodePacked(keccak256(abi.encodePacked(player, blockHash)), blockhash(settleBlock - 1)));

        wheelResult = uint8(uint256(shaPlayer) % 37);

    }

    // get total win amount, deduct 1% bet value for jackpot fee
    function getGameResult(GameInfo memory game) private view returns (uint256 totalWin) {
        totalWin = 0;
        uint8 nPlayerBetNo = 0;
        // we sent count bets at last byte
        uint8 betsCount = uint8(bytes32(game.bets)[0]);
        for (uint8 i = 0; i < maxTypeBets; i++) {
            if (isBitSet(game.bets, i)) {
                // get win coef
                uint256 winMul = rouletteMatrix.getFactor(i, game.wheelResult);
                // + return player bet
                if (winMul > 0) {
                    winMul++;
                    uint256 placedUniqueAmount =  getBetValueByGamble(game, nPlayerBetNo + 1, i);
                    uint256 winAmount = winMul * placedUniqueAmount;
                    // winner will be deducted 1% bet amount for jackpot fee
                    winAmount = winAmount.safeSub(placedUniqueAmount / 100);
                    totalWin += winAmount;
                }
                nPlayerBetNo++;
                if (betsCount == 1) break;
                betsCount--;
            }
        }
    }

    // get game info by id
    function getGame(uint64 index) public view returns (uint64 gambleId, address player, uint256 blockNumber,
        uint256 totalWin, uint8 wheelResult, uint256 bets, uint256 values1, uint256 values2,
        uint256 nTotalBetValue, uint256 nTotalBetCount, uint256 jackpotWinAmount) {
        gambleId = index;
        player = gambles[index].player;
        totalWin = getGameResult(gambles[index]);
        blockNumber = gambles[index].blockNumber;
        wheelResult = gambles[index].wheelResult;
        nTotalBetValue = totalBetValue(gambles[index]);
        nTotalBetCount = totalBetCount(gambles[index]);
        bets = gambles[index].bets;
        values1 = uint256(gambles[index].values);
        values2 = uint256(gambles[index].values2);
        jackpotWinAmount = gambles[index].jackpotAmount;
    }

    // get all game id of player
    function getUserGamesIdx(address player) public view returns(uint[]) {
        return myGames[player];
    }

    // get all un-settle game ids
    function getUnSettledGames() public view returns(uint[]) {
        return unSettledGames;
    }

    // prevent user send ether to this contract
    function() public {
        revert();
    }

}
