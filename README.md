# Decentralized-Will-and-Inheritance-System-Using-Solidity

Automating the distribution of digital assets after a person's death without requiring lawyers or probate courts. Probate processes routinely take 12–24 months and cost 5–10% of an estate's value. This contract replaces legal machinery with a time-based inactivity check — if the owner stops checking in for a defined period, beneficiaries can trigger distribution automatically.

**Data Structures**

Beneficiary — contains: address beneficiaryAddress, string name, uint256 percentage.

Will — contains: address owner, uint256 lastCheckIn, uint256 inactivityThreshold, bool triggered, bool contested, address contester, uint256 contestDeadline, uint256 totalDeposited.

**State Variables & Mappings**

mapping(address => uint256) beneficiaryIndex — quick lookup.

mapping(address => bool) isBeneficiary.

**Functions**

constructor(address[] beneficiaryAddresses, uint256[] percentages, uint256 inactivityDays) — validates that percentages sum exactly to 100. Sets lastCheckIn to block.timestamp.

deposit() payable — owner can deposit ETH into the will contract at any time.

checkIn() — callable only by the owner. Resets lastCheckIn to block.timestamp. Cannot be called if will is already triggered.

triggerInheritance() — callable by any beneficiary if block.timestamp - lastCheckIn > inactivityThreshold and will is not contested.

distributeAssets() — called internally by triggerInheritance. Computes each beneficiary's share as (totalBalance * percentage) / 100 and sends ETH.

contestWill(address contester) — a pre-registered contester address can freeze execution for a defined window (e.g., 30 days).

resolveContest(bool uphold) — callable only by a pre-assigned arbitrator. If uphold is false, unfreezes and executes. If true, blocks execution permanently.

updateBeneficiaries(address[] newBeneficiaries, uint256[] newPercentages) — callable only by the owner, only before triggering.

**Events**

WillCreated(address indexed owner, uint256 totalBeneficiaries, uint256 inactivityThreshold).

CheckInRecorded(address indexed owner, uint256 timestamp).

Deposited(address indexed owner, uint256 amount).

InheritanceTriggered(address indexed triggeredBy, uint256 timestamp).
AssetDistributed(address indexed beneficiary, uint256 percentage, uint256 amount).
WillContested(address indexed contestedBy, uint256 contestDeadline).
ContestResolved(address indexed arbitrator, bool upheld).
WillUpdated(address indexed owner, uint256 newBeneficiaryCount).
