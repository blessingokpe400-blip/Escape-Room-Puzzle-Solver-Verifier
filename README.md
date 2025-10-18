# 🧩 Escape Room Puzzle Solver Verifier

> On-chain proofs for puzzle completions, rewarding solvers with exclusive NFTs for global, cheat-proof escape room challenges! 🌍✨

## 🎯 Overview

The Escape Room Puzzle Solver Verifier is a Clarity smart contract that revolutionizes team-building events and puzzle competitions by providing tamper-proof verification of puzzle solutions on the Stacks blockchain. Solvers earn unique NFTs as proof of their achievements, creating a global leaderboard of puzzle masters! 🏆

## ✨ Features

- 🔐 **Cheat-Proof Verification**: Solutions are verified using cryptographic hashes
- 🎨 **Exclusive NFT Rewards**: Each successful solve earns a unique NFT
- 📊 **Real-Time Leaderboards**: Track top solvers across all puzzles  
- ⏰ **Time-Limited Challenges**: Puzzles can have expiration dates
- 👥 **Limited Solver Slots**: Control the number of participants per puzzle
- 📈 **Difficulty Scaling**: Puzzles rated from 1-10 difficulty
- 📱 **Global Accessibility**: Participate from anywhere in the world
- 🔄 **Extensible Duration**: Puzzle creators can extend time limits

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts
- Stacks wallet for testing

### Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd Escape-Room-Puzzle-Solver-Verifier
```

2. Install dependencies:
```bash
npm install
```

3. Run tests:
```bash
npm test
```

4. Check contract syntax:
```bash
clarinet check
```

## 📖 Usage Guide

### 🎯 For Puzzle Creators

#### Creating a Puzzle

```clarity
(contract-call? .escape-room-puzzle-solver-verifier create-puzzle
  "Escape the Digital Prison"           ; title (max 100 chars)
  "Find the hidden key in binary code"  ; description (max 500 chars)
  0x1234567890abcdef...                 ; solution hash (SHA256)
  u5                                    ; difficulty (1-10)
  u1000                                 ; reward amount
  u50                                   ; max solvers
  u1440                                 ; duration (blocks)
)
```

#### Managing Your Puzzles

```clarity
;; Deactivate a puzzle
(contract-call? .escape-room-puzzle-solver-verifier deactivate-puzzle u1)

;; Extend puzzle duration
(contract-call? .escape-room-puzzle-solver-verifier extend-puzzle-duration u1 u720)
```

### 🧩 For Puzzle Solvers

#### Solving a Puzzle

```clarity
(contract-call? .escape-room-puzzle-solver-verifier solve-puzzle
  u1                    ; puzzle ID
  "correct-solution"    ; your solution (max 200 chars)
)
```

#### Transferring Your NFT

```clarity
(contract-call? .escape-room-puzzle-solver-verifier transfer-nft
  u1                    ; NFT ID
  tx-sender            ; current owner
  'SP123...            ; recipient address
)
```

### 📊 Reading Contract Data

#### Get Puzzle Information

```clarity
(contract-call? .escape-room-puzzle-solver-verifier get-puzzle u1)
```

#### Check Your Stats

```clarity
(contract-call? .escape-room-puzzle-solver-verifier get-user-stats tx-sender)
```

#### View Leaderboard

```clarity
(contract-call? .escape-room-puzzle-solver-verifier get-puzzle-leaderboard u1)
```

#### Contract Statistics

```clarity
(contract-call? .escape-room-puzzle-solver-verifier get-contract-stats)
```

## 🏗️ Contract Architecture

### 📝 Data Structures

#### Puzzles Map
- **Creator**: Address of puzzle creator
- **Title & Description**: Puzzle metadata
- **Solution Hash**: SHA256 hash of correct answer
- **Difficulty**: Rating from 1-10
- **Reward Amount**: Points awarded for solving
- **Solver Limits**: Maximum number of solvers
- **Timing**: Creation and expiration blocks
- **Status**: Active/inactive flag

#### User Statistics
- **Puzzles Solved**: Total count of completed puzzles
- **NFTs Earned**: Number of reward NFTs obtained  
- **Total Rewards**: Cumulative reward points
- **Solve History**: First and last solve timestamps

### 🔒 Security Features

- ✅ **Solution Verification**: Cryptographic hash matching
- ✅ **Access Control**: Owner-only administrative functions
- ✅ **Duplicate Prevention**: Users can't solve the same puzzle twice
- ✅ **Time Validation**: Automatic expiration checking
- ✅ **Capacity Management**: Automatic solver limit enforcement

### ⚠️ Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | err-owner-only | Only contract owner can perform this action |
| u101 | err-not-found | Puzzle does not exist |
| u102 | err-already-exists | Resource already exists |
| u103 | err-unauthorized | Insufficient permissions |
| u104 | err-invalid-solution | Solution doesn't match puzzle |
| u105 | err-puzzle-inactive | Puzzle is not active |
| u106 | err-already-solved | User already solved this puzzle |
| u107 | err-time-expired | Puzzle time limit exceeded |
| u108 | err-min-difficulty | Invalid difficulty level |
| u109 | err-max-solvers-reached | Solver limit reached |

## 🎮 Use Cases

### 🏢 Corporate Team Building
- Create department vs department challenges
- Track team collaboration metrics
- Award NFT certificates for achievements

### 🎓 Educational Institutions  
- Gamify computer science assignments
- Create coding challenges with verifiable solutions
- Build portfolio of achievement NFTs

### 🌐 Global Competitions
- Host international puzzle tournaments
- Create time-zone synchronized events
- Maintain permanent leaderboards

### 🎪 Entertainment Venues
- Physical escape rooms with digital verification
- Multi-location tournament series
- Exclusive NFT collectibles for participants

## 🔮 Future Enhancements

- 🏆 **Tournament Brackets**: Elimination-style competitions
- 💰 **Token Rewards**: STX payouts for winners
- 🤝 **Team Puzzles**: Multi-user collaborative challenges
- 📱 **Mobile Integration**: Dedicated mobile app
- 🎨 **Custom NFT Art**: Unique artwork for each puzzle theme
- 📈 **Analytics Dashboard**: Detailed performance metrics

## 🤝 Contributing

We welcome contributions! Please feel free to:

1. 🐛 Report bugs via GitHub issues
2. 💡 Suggest new features  
3. 🔧 Submit pull requests
4. 📚 Improve documentation
5. 🧪 Add more test cases

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙋‍♀️ Support

Having trouble? Check out our:
- 📖 [Documentation](docs/)
- 💬 [Discord Community](https://discord.gg/stacks)
- 🐛 [Issue Tracker](https://github.com/your-repo/issues)
- 📧 Email: support@escaperoomverifier.com

---

**Ready to create the next generation of puzzle competitions?** 🚀

Get started by creating your first puzzle and join the global community of verified puzzle masters! 🧩✨
