// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DecentralizedWill {

  

    struct Beneficiary {
        address beneficiaryAddress;
        string name;
        uint256 percentage;
    }

    struct Will {
        address owner;
        uint256 lastCheckIn;
        uint256 inactivityThreshold;
        bool triggered;
        bool contested;
        address contester;
        uint256 contestDeadline;
        uint256 totalDeposited;
    }

    Will public will;

    Beneficiary[] public beneficiaries;



    mapping(address => uint256) public beneficiaryIndex;
    mapping(address => bool) public isBeneficiary;
    mapping(address => uint256) public pendingWithdrawals;

    address public arbitrator;
    bool public permanentlyBlocked;

   

    event WillCreated(
        address indexed owner,
        uint256 totalBeneficiaries,
        uint256 inactivityThreshold
    );

    event CheckInRecorded(
        address indexed owner,
        uint256 timestamp
    );

    event Deposited(
        address indexed owner,
        uint256 amount
    );

    event InheritanceTriggered(
        address indexed triggeredBy,
        uint256 timestamp
    );

    event AssetDistributed(
        address indexed beneficiary,
        uint256 percentage,
        uint256 amount
    );

    event WillContested(
        address indexed contestedBy,
        uint256 contestDeadline
    );

    event ContestResolved(
        address indexed arbitrator,
        bool upheld
    );

    event WillUpdated(
        address indexed owner,
        uint256 newBeneficiaryCount
    );


    modifier onlyOwner() {
        require(msg.sender == will.owner, "Not owner");
        _;
    }

    modifier onlyBeneficiary() {
        require(isBeneficiary[msg.sender], "Not beneficiary");
        _;
    }

    modifier onlyArbitrator() {
        require(msg.sender == arbitrator, "Not arbitrator");
        _;
    }

    modifier notTriggered() {
        require(!will.triggered, "Already triggered");
        _;
    }


    constructor(
        address[] memory beneficiaryAddresses,
        string[] memory names,
        uint256[] memory percentages,
        uint256 inactivityDays,
        address _contester,
        address _arbitrator
    )
    {

        require(
            beneficiaryAddresses.length ==
            percentages.length &&
            names.length ==
            beneficiaryAddresses.length,
            "Length mismatch"
        );

        uint256 total;

        for(uint i=0;i<beneficiaryAddresses.length;i++){

            beneficiaries.push(
                Beneficiary(
                    beneficiaryAddresses[i],
                    names[i],
                    percentages[i]
                )
            );

            beneficiaryIndex[
                beneficiaryAddresses[i]
            ] = i;

            isBeneficiary[
                beneficiaryAddresses[i]
            ] = true;

            total += percentages[i];
        }

        require(total == 100, "Percent must equal 100");

        will = Will({
            owner: msg.sender,
            lastCheckIn: block.timestamp,
            inactivityThreshold: inactivityDays * 1 days,
            triggered: false,
            contested: false,
            contester: _contester,
            contestDeadline: 0,
            totalDeposited: 0
        });

        arbitrator = _arbitrator;

        emit WillCreated(
            msg.sender,
            beneficiaryAddresses.length,
            inactivityDays * 1 days
        );
    }


    function deposit()
        external
        payable
        onlyOwner
    {
        require(msg.value > 0, "Send ETH");

        will.totalDeposited += msg.value;

        emit Deposited(
            msg.sender,
            msg.value
        );
    }


    function checkIn()
        external
        onlyOwner
        notTriggered
    {
        will.lastCheckIn = block.timestamp;

        emit CheckInRecorded(
            msg.sender,
            block.timestamp
        );
    }



    function triggerInheritance()
        external
        onlyBeneficiary
        notTriggered
    {

        require(
            !will.contested,
            "Will contested"
        );

        require(
            block.timestamp >
            will.lastCheckIn +
            will.inactivityThreshold,
            "Owner still active"
        );

        will.triggered = true;

        emit InheritanceTriggered(
            msg.sender,
            block.timestamp
        );

        distributeAssets();
    }

 
function distributeAssets() internal {

    uint256 totalBalance = address(this).balance;

    for(uint i = 0; i < beneficiaries.length; i++) {

        address beneficiary =
            beneficiaries[i].beneficiaryAddress;

        uint256 amount =
            (totalBalance *
            beneficiaries[i].percentage) / 100;

        pendingWithdrawals[beneficiary] += amount;
    }
}



    function contestWill(address contesterAddress)
        external
    {

        require(
            msg.sender == will.contester,
            "Not authorized contester"
        );

        require(!will.triggered);

        will.contested = true;

        will.contestDeadline =
        block.timestamp + 30 days;

        emit WillContested(
            contesterAddress,
            will.contestDeadline
        );
    }

 

    function resolveContest(bool uphold)
        external
        onlyArbitrator
    {

        require(will.contested);

        if(uphold){

            permanentlyBlocked = true;

        } else {

            will.contested = false;

            if(
                block.timestamp >
                will.lastCheckIn +
                will.inactivityThreshold
            ){
                will.triggered = true;

                distributeAssets();
            }
        }

        emit ContestResolved(
            msg.sender,
            uphold
        );
    }


    function updateBeneficiaries(
        address[] memory newAddresses,
        string[] memory names,
        uint256[] memory newPercentages
    )
        external
        onlyOwner
        notTriggered
    {

        require(
            newAddresses.length ==
            newPercentages.length &&
            names.length ==
            newAddresses.length,
            "Mismatch"
        );

        // clear old mappings
        for(uint i=0;i<beneficiaries.length;i++){
            isBeneficiary[
                beneficiaries[i].beneficiaryAddress
            ] = false;
        }

        delete beneficiaries;

        uint total;

        for(uint i=0;i<newAddresses.length;i++){

            beneficiaries.push(
                Beneficiary(
                    newAddresses[i],
                    names[i],
                    newPercentages[i]
                )
            );

            beneficiaryIndex[newAddresses[i]] = i;

            isBeneficiary[newAddresses[i]] = true;

            total += newPercentages[i];
        }

        require(total == 100, "Must equal 100");

        emit WillUpdated(
            msg.sender,
            newAddresses.length
        );
    }
}