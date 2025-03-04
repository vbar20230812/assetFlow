import 'package:intl/intl.dart';

class PlannedDistribution {
  final String paymentPeriod;
  final double annualInterestPerPeriod;

  PlannedDistribution({
    required this.paymentPeriod,
    required this.annualInterestPerPeriod,
  });

  Map<String, dynamic> toMap() {
    return {
      'paymentPeriod': paymentPeriod,
      'annualInterestPerPeriod': annualInterestPerPeriod,
    };
  }

  factory PlannedDistribution.fromMap(Map<String, dynamic> map) {
    return PlannedDistribution(
      paymentPeriod: map['paymentPeriod'],
      annualInterestPerPeriod: map['annualInterestPerPeriod'].toDouble(),
    );
  }
  
  // Get number of payments per year based on payment period
  int getPaymentsPerYear() {
    switch (paymentPeriod.toLowerCase()) {
      case 'quarter':
        return 4;
      case 'half':
        return 2;
      case 'yearly':
        return 1;
      case 'exit':
        return 0; // Lump sum at exit
      default:
        return 1;
    }
  }
  
  // Get a human-readable description of the payment period
  String getPaymentPeriodDescription() {
    switch (paymentPeriod.toLowerCase()) {
      case 'quarter':
        return 'Quarterly';
      case 'half':
        return 'Semiannually';
      case 'yearly':
        return 'Annually';
      case 'exit':
        return 'At Exit';
      default:
        return paymentPeriod;
    }
  }
}

class InvestmentPlan {
  final String planId;
  final String planName;
  final String category;
  final int minimalAmount;
  final int periodMonths;
  final int interest;
  final PlannedDistribution plannedDistributions;

  InvestmentPlan({
    required this.planId,
    required this.planName,
    required this.category,
    required this.minimalAmount,
    required this.periodMonths,
    required this.interest,
    required this.plannedDistributions,
  });

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'planName': planName,
      'category': category,
      'minimalAmount': minimalAmount,
      'periodMonths': periodMonths,
      'interest': interest,
      'plannedDistributions': plannedDistributions.toMap(),
    };
  }

  factory InvestmentPlan.fromMap(Map<String, dynamic> map) {
    return InvestmentPlan(
      planId: map['planId'],
      planName: map['planName'],
      category: map['category'],
      minimalAmount: map['minimalAmount'],
      periodMonths: map['periodMonths'],
      interest: map['interest'],
      plannedDistributions: PlannedDistribution.fromMap(map['plannedDistributions']),
    );
  }
  
  // Calculate total interest over full term for a given principal amount
  double calculateTotalInterest(int principal) {
    double annualInterestRate = interest / 100.0;
    double years = periodMonths / 12.0;
    return principal * annualInterestRate * years;
  }
  
  // Calculate the total number of distributions over the term
  int calculateNumberOfDistributions() {
    // For exit-only plans, there's just one distribution
    if (plannedDistributions.paymentPeriod.toLowerCase() == 'exit') {
      return 1;
    }
    
    // Otherwise calculate based on payment frequency
    int paymentsPerYear = plannedDistributions.getPaymentsPerYear();
    double years = periodMonths / 12.0;
    return (paymentsPerYear * years).round();
  }
  
  // Get the investor type description
  String getInvestorTypeDescription() {
    switch (category.toLowerCase().replaceAll(' ', '')) {
      case 'limitedpartner':
        return 'Limited Partner';
      case 'lender':
        return 'Lender';
      case 'development':
        return 'Real Estate Developer';
      default:
        return category;
    }
  }
}

class Distribution {
  final String date;
  final String name;
  final int plannedAmount;
  final String type;
  final bool done;

  Distribution({
    required this.date,
    required this.name,
    required this.plannedAmount,
    required this.type,
    required this.done,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'name': name,
      'plannedAmount': plannedAmount,
      'type': type,
      'done': done,
    };
  }

  factory Distribution.fromMap(Map<String, dynamic> map) {
    return Distribution(
      date: map['date'],
      name: map['name'],
      plannedAmount: map['plannedAmount'],
      type: map['type'],
      done: map['done'],
    );
  }

 // Parse the date string into a DateTime object
  DateTime getDateTime() {
    try {
      final parts = date.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Handle parsing errors
    }
    return DateTime.now(); // Default if parsing fails
  }

  // Check if this distribution is upcoming within a certain number of days
  bool isUpcoming(int withinDays) {
    final now = DateTime.now();
    final distributionDate = getDateTime();
    final difference = distributionDate.difference(now).inDays;
    return !done && difference >= 0 && difference <= withinDays;
  }
  
  // Check if this distribution is overdue
  bool isOverdue() {
    final now = DateTime.now();
    final distributionDate = getDateTime();
    return !done && distributionDate.isBefore(now);
  }
}

class Project {
  final String projectId;
  final String projectName;
  final String companyName;
  final String currency;
  final String createDate;
  final String updateDate;
  final List<InvestmentPlan> investPlans;
  final int additionalFeesRefundable;
  final int additionalFeesNonRefundable;
  final String notes;
  final String dateOfContractSign;
  final String dateOfFirstPayment;
  final String dateOfExit;
  final String selectedInvestPlan;
  final int investmentAmount;
  final List<Distribution> distributions;

  Project({
    required this.projectId,
    required this.projectName,
    required this.companyName,
    required this.currency,
    required this.createDate,
    required this.updateDate,
    required this.investPlans,
    required this.additionalFeesRefundable,
    required this.additionalFeesNonRefundable,
    required this.notes,
    required this.dateOfContractSign,
    required this.dateOfFirstPayment,
    required this.dateOfExit,
    required this.selectedInvestPlan,
    required this.investmentAmount,
    required this.distributions,
  });

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'companyName': companyName,
      'currency': currency,
      'createDate': createDate,
      'updateDate': updateDate,
      'investPlans': investPlans.map((plan) => plan.toMap()).toList(),
      'additionalFeesRefundable': additionalFeesRefundable,
      'additionalFeesNonRefundable': additionalFeesNonRefundable,
      'notes': notes,
      'dateOfContractSign': dateOfContractSign,
      'dateOfFirstPayment': dateOfFirstPayment,
      'dateOfExit': dateOfExit,
      'selectedInvestPlan': selectedInvestPlan,
      'investmentAmount': investmentAmount,
      'distributions': distributions.map((dist) => dist.toMap()).toList(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    final List<dynamic> plansList = map['investPlans'] ?? map['InvestPlans'] ?? [];
    final List<dynamic> distributionsList = map['distributions'] ?? [];
    
    return Project(
      projectId: map['projectId'],
      projectName: map['projectName'],
      companyName: map['companyName'],
      currency: map['currency'],
      createDate: map['createDate'],
      updateDate: map['updateDate'],
      investPlans: plansList
          .map((planMap) => InvestmentPlan.fromMap(planMap))
          .toList(),
      additionalFeesRefundable: map['additionalFeesRefundable'],
      additionalFeesNonRefundable: map['additionalFeesNonRefundable'],
      notes: map['notes'] ?? '',
      dateOfContractSign: map['dateOfContractSign'],
      dateOfFirstPayment: map['dateOfFirstPayment'],
      dateOfExit: map['dateOfExit'],
      selectedInvestPlan: map['selectedInvestPlan'],
      investmentAmount: map['investmentAmount'],
      distributions: distributionsList
          .map((distMap) => Distribution.fromMap(distMap))
          .toList(),
    );
  }

  // Get the selected investment plan
  InvestmentPlan? getSelectedPlan() {
    try {
      return investPlans.firstWhere((plan) => plan.planId == selectedInvestPlan);
    } catch (e) {
      return null;
    }
  }
  
  // Calculate total investment including fees
  int getTotalInvestment() {
    return investmentAmount + additionalFeesRefundable + additionalFeesNonRefundable;
  }
  
  // Calculate total interest based on selected plan and investment amount
  int calculateTotalInterest() {
    InvestmentPlan? selectedPlan = getSelectedPlan();
    if (selectedPlan == null) return 0;
    
    return selectedPlan.calculateTotalInterest(investmentAmount).round();
  }
  
  // Calculate total funds to be returned (investment + interest)
  int calculateTotalFunds() {
    return investmentAmount + calculateTotalInterest();
  }
  
  // Get investment term in years
  double getInvestmentTermYears() {
    InvestmentPlan? selectedPlan = getSelectedPlan();
    if (selectedPlan == null) return 0.0;
    
    return selectedPlan.periodMonths / 12.0;
  }
  
  // Get progress percentage of the investment term
  double getProgressPercentage() {
    try {
      DateTime contractDate = parseDate(dateOfContractSign);
      DateTime exitDate = parseDate(dateOfExit);
      DateTime now = DateTime.now();
      
      int totalDays = exitDate.difference(contractDate).inDays;
      if (totalDays <= 0) return 0.0;
      
      int daysPassed = now.difference(contractDate).inDays;
      if (daysPassed < 0) return 0.0;
      if (daysPassed > totalDays) return 100.0;
      
      return (daysPassed / totalDays) * 100;
    } catch (e) {
      return 0.0;
    }
  }
  
  // Get next distribution date
  String getNextDistributionDate() {
    try {
      DateTime now = DateTime.now();
      Distribution? nextDist;
      DateTime? nextDate;
      
      for (var dist in distributions) {
        if (!dist.done) {
          DateTime distDate = parseDate(dist.date);
          if (distDate.isAfter(now) && (nextDate == null || distDate.isBefore(nextDate))) {
            nextDate = distDate;
            nextDist = dist;
          }
        }
      }
      
      if (nextDist != null) {
        return nextDist.date;
      }
    } catch (e) {
      // Handle errors
    }
    
    return "No upcoming distributions";
  }
  
  // Count number of distributions completed
  int getCompletedDistributionsCount() {
    return distributions.where((dist) => dist.done).length;
  }
  
  // Count number of distributions remaining
  int getRemainingDistributionsCount() {
    return distributions.where((dist) => !dist.done).length;
  }
  
  // Get completed distributions total
  int getCompletedDistributionsTotal() {
    int total = 0;
    for (var dist in distributions) {
      if (dist.done) {
        total += dist.plannedAmount;
      }
    }
    return total;
  }
  
  // Get remaining distributions total
  int getRemainingDistributionsTotal() {
    int total = 0;
    for (var dist in distributions) {
      if (!dist.done) {
        total += dist.plannedAmount;
      }
    }
    return total;
  }
  
  // Helper method to parse date string
  DateTime parseDate(String dateStr) {
    List<String> parts = dateStr.split('/');
    if (parts.length == 3) {
      int day = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int year = int.parse(parts[2]);
      return DateTime(year, month, day);
    }
    throw FormatException('Invalid date format: $dateStr');
  }
}

class UserInvestments {
  final String uId;
  final List<Project> projects;

  UserInvestments({
    required this.uId,
    required this.projects,
  });

  Map<String, dynamic> toMap() {
    return {
      'uId': uId,
      'projects': projects.map((project) => project.toMap()).toList(),
    };
  }

  factory UserInvestments.fromMap(Map<String, dynamic> map) {
    final List<dynamic> projectsList = map['projects'] ?? [];
    
    return UserInvestments(
      uId: map['uId'],
      projects: projectsList
          .map((projectMap) => Project.fromMap(projectMap))
          .toList(),
    );
  }
  
  // Get total investment amount across all projects
  int getTotalInvestmentAmount() {
    int total = 0;
    for (var project in projects) {
      total += project.getTotalInvestment();
    }
    return total;
  }
  
  // Get total expected returns across all projects
  int getTotalExpectedReturns() {
    int total = 0;
    for (var project in projects) {
      total += project.calculateTotalInterest();
    }
    return total;
  }
  
  // Get upcoming distributions in the next X days
  List<Map<String, dynamic>> getUpcomingDistributions(int days) {
    List<Map<String, dynamic>> upcoming = [];
    
    for (var project in projects) {
      for (var dist in project.distributions) {
        if (dist.isUpcoming(days)) {
          upcoming.add({
            'projectId': project.projectId,
            'projectName': project.projectName,
            'distribution': dist,
          });
        }
      }
    }
    
    // Sort by date
    upcoming.sort((a, b) {
      DateTime dateA = (a['distribution'] as Distribution).getDateTime();
      DateTime dateB = (b['distribution'] as Distribution).getDateTime();
      return dateA.compareTo(dateB);
    });
    
    return upcoming;
  }
  
  // Get count of projects by category
  Map<String, int> getProjectCountByCategory() {
    Map<String, int> counts = {};
    
    for (var project in projects) {
      InvestmentPlan? selectedPlan = project.getSelectedPlan();
      if (selectedPlan != null) {
        String category = selectedPlan.category;
        counts[category] = (counts[category] ?? 0) + 1;
      }
    }
    
    return counts;
  }
}