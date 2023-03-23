// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Loan {
    using SafeMath for uint256;
    
    address public lender;
    address public borrower;
    uint256 public principal;
    uint256 public interestRate;
    uint256 public loanDuration;
    uint256 public startDate;
    uint256 public totalRepayment;
    uint256 public totalInterest;
    uint256 public balance;
    uint256 public lateFee;
    bool public collateralRequired;
    bool public collateralReturned;
    bool public loanClosed;
    mapping (address => uint256) public collateral;
    mapping (uint256 => Payment) public payments;
    uint256 public numPayments;
    
    struct Payment {
        uint256 paymentDate;
        uint256 paymentAmount;
        uint256 interestAmount;
        uint256 principalAmount;
        bool paid;
    }
    
    event LoanFunded(address indexed lender, uint256 amount);
    event CollateralAdded(address indexed borrower, uint256 amount);
    event CollateralReturned(address indexed borrower, uint256 amount);
    event PaymentMade(address indexed borrower, uint256 amount);
    event LateFeeAdded(address indexed borrower, uint256 amount);
    event LoanClosed(address indexed borrower, uint256 amount);
    
    constructor(address _borrower, uint256 _principal, uint256 _interestRate, uint256 _loanDuration, bool _collateralRequired) {
        lender = msg.sender;
        borrower = _borrower;
        principal = _principal;
        interestRate = _interestRate;
        loanDuration = _loanDuration;
        collateralRequired = _collateralRequired;
        startDate = block.timestamp;
        balance = _principal;
        totalRepayment = _principal.mul(_interestRate.add(100)).div(100);
        totalInterest = totalRepayment.sub(_principal);
    }
    
    function fundLoan() public payable {
        require(msg.sender == lender, "Only the lender can fund the loan");
        require(msg.value == principal, "Incorrect loan amount");
        emit LoanFunded(lender, msg.value);
    }
    
    function addCollateral() public payable {
        require(msg.sender == borrower, "Only the borrower can add collateral");
        require(collateralRequired == true, "Collateral is not required for this loan");
        collateral[borrower] = collateral[borrower].add(msg.value);
        emit CollateralAdded(borrower, msg.value);
    }
    
    function returnCollateral() public {
        require(msg.sender == borrower, "Only the borrower can return collateral");
        require(collateralReturned == false, "Collateral has already been returned");
        collateralReturned = true;
        payable(borrower).transfer(collateral[borrower]);
        emit CollateralReturned(borrower, collateral[borrower]);
    }
    
    function makePayment() public payable {
        require(msg.sender == borrower, "Only the borrower can make payments");
        require(loanClosed == false, "Loan has already been fully repaid");
        require(msg.value > 0, "Payment amount must be greater than 0");
        uint256 paymentAmount = msg.value;
        uint256 interestAmount = calculateInterest();
        uint256 principalAmount = paymentAmount.sub(interestAmount);
        balance = balance.sub(principalAmount);
        if(balance == 0){
            loanClosed = true;
        }
        payments[numPayments] = Payment(block.timestamp, paymentAmount, interestAmount, principalAmount, true);
        numPayments++;
        emit PaymentMade(borrower, paymentAmount);
    }
    
    function calculateInterest() public view returns (uint256) {
        uint256 timeElapsed = block.timestamp.sub(startDate);
        uint256 interest = principal.mul(interestRate).mul(timeElapsed).div(365 days).div(100);
        return interest;
    }
    
    function addLateFee() public {
        require(msg.sender == borrower, "Only the borrower can add late fees");
        require(loanClosed == false, "Loan has already been fully repaid");
        require(block.timestamp > startDate.add(loanDuration), "Loan is not yet late");
        lateFee = totalRepayment.mul(10).div(100);
        balance = balance.add(lateFee);
        emit LateFeeAdded(borrower, lateFee);
    }
    
    function partialRepayment(uint256 _amount) public {
        require(msg.sender == borrower, "Only the borrower can make partial repayments");
        require(loanClosed == false, "Loan has already been fully repaid");
        require(_amount > 0, "Payment amount must be greater than 0");
        require(_amount <= balance, "Payment amount is greater than remaining balance");
        uint256 interestAmount = calculateInterest();
        uint256 principalAmount = _amount.sub(interestAmount);
        balance = balance.sub(principalAmount);
        if(balance == 0){
            loanClosed = true;
        }
        payments[numPayments] = Payment(block.timestamp, _amount, interestAmount, principalAmount, true);
        numPayments++;
        emit PaymentMade(borrower, _amount);
    }
    
    function closeLoan() public {
        require(msg.sender == lender, "Only the lender can close the loan");
        require(loanClosed == true, "Loan has not yet been fully repaid");
        payable(lender).transfer(balance.add(lateFee));
        emit LoanClosed(borrower, balance.add(lateFee));
    }
}