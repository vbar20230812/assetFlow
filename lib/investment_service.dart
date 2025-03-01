import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'investment_models.dart';

class InvestmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('InvestmentService');

  // Create a new project investment
  Future<void> createInvestment(Map<String, dynamic> investmentData) async {
    User? user = _auth.currentUser;
    if (user != null) {
      _logger.info('Starting investment creation for user: ${user.uid}');
      
      // First, get or create the user's investments document
      DocumentReference userInvestmentsRef = _firestore.collection('investments').doc(user.uid);
      
      try {
        // Get current projects or create empty array if it doesn't exist
        DocumentSnapshot userDoc = await userInvestmentsRef.get();
        List<dynamic> currentProjects = [];
        
        if (userDoc.exists) {
          _logger.info('Existing user investments document found');
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          if (userData.containsKey('projects')) {
            currentProjects = userData['projects'] as List<dynamic>;
            _logger.info('Found ${currentProjects.length} existing projects');
          }
        } else {
          _logger.info('No existing investments document, creating new one');
        }
        
        // Generate a unique project ID if not provided
        if (!investmentData.containsKey('projectId') || investmentData['projectId'] == null) {
          investmentData['projectId'] = FirebaseFirestore.instance.collection('temp').doc().id;
          _logger.info('Generated new project ID: ${investmentData['projectId']}');
        }
        
        // Add creation and update dates
        final now = DateTime.now();
        final formattedDate = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
        
        investmentData['createDate'] = formattedDate;
        investmentData['updateDate'] = formattedDate;
        
        // Generate distributions if not provided
        if (!investmentData.containsKey('distributions') || investmentData['distributions'] == null) {
          _logger.info('Generating distributions for the project');
          // Convert to a Project object temporarily to generate distributions
          Project tempProject = Project.fromMap(investmentData);
          List<Distribution> distributions = _generateDistributions(tempProject);
          investmentData['distributions'] = distributions.map((dist) => dist.toMap()).toList();
          _logger.info('Generated ${distributions.length} distributions');
        }
        
        // Add new project to the array
        currentProjects.add(investmentData);
        
        // Log the operation we're about to perform
        _logger.info('Attempting to write to investments/${user.uid} with ${currentProjects.length} projects');
        
        // Update the document with the new projects array
        await userInvestmentsRef.set({
          'uId': user.uid,
          'projects': currentProjects,
        });
        
        _logger.info('Investment created successfully for project: ${investmentData['projectName']}');
      } catch (e) {
        _logger.severe('Error creating investment: $e');
        rethrow;
      }
    } else {
      _logger.warning('User not logged in, cannot create investment.');
      throw Exception('User not logged in');
    }
  }

  // Helper method to generate distributions based on the project data
  List<Distribution> _generateDistributions(Project project) {
    List<Distribution> distributions = [];
    InvestmentPlan? selectedPlan = project.getSelectedPlan();
    
    if (selectedPlan == null) {
      return distributions;
    }
    
    try {
      // Get start and end dates
      DateTime firstPaymentDate = _parseDate(project.dateOfFirstPayment);
      DateTime exitDate = _parseDate(project.dateOfExit);
      
      // Calculate amount per distribution
      int distributionAmount = selectedPlan.calculateTotalInterest(project.investmentAmount).round() ~/ 
          (selectedPlan.calculateNumberOfDistributions() == 0 ? 1 : selectedPlan.calculateNumberOfDistributions());
      
      // For exit-only plans, just add a single distribution at the exit date
      if (selectedPlan.plannedDistributions.paymentPeriod.toLowerCase() == 'exit') {
        distributions.add(Distribution(
          date: project.dateOfExit,
          name: "Final Payment",
          plannedAmount: distributionAmount + project.investmentAmount, // Include principal
          type: "exit",
          done: false,
        ));
        return distributions;
      }
      
      // For regular distributions
      int paymentFrequencyMonths;
      String paymentType;
      
      switch (selectedPlan.plannedDistributions.paymentPeriod.toLowerCase()) {
        case 'quarter':
          paymentFrequencyMonths = 3;
          paymentType = "quarter";
          break;
        case 'half':
          paymentFrequencyMonths = 6;
          paymentType = "half";
          break;
        case 'yearly':
          paymentFrequencyMonths = 12;
          paymentType = "yearly";
          break;
        default:
          paymentFrequencyMonths = 12;
          paymentType = "yearly";
      }
      
      // Generate regular distributions
      DateTime currentDate = firstPaymentDate;
      int year = 1;
      int period = 1;
      
      while (currentDate.isBefore(exitDate) || currentDate.isAtSameMomentAs(exitDate)) {
        String formattedDate = "${currentDate.day.toString().padLeft(2, '0')}/${currentDate.month.toString().padLeft(2, '0')}/${currentDate.year}";
        
        String name;
        if (paymentType == "quarter") {
          name = "q${period}y$year";
          period++;
          if (period > 4) {
            period = 1;
            year++;
          }
        } else if (paymentType == "half") {
          name = "h${period}y$year";
          period++;
          if (period > 2) {
            period = 1;
            year++;
          }
        } else {
          name = "y$year";
          year++;
        }
        
        distributions.add(Distribution(
          date: formattedDate,
          name: name,
          plannedAmount: distributionAmount,
          type: paymentType,
          done: false,
        ));
        
        // Move to next payment date
        currentDate = DateTime(
          currentDate.year, 
          currentDate.month + paymentFrequencyMonths, 
          currentDate.day
        );
      }
      
      // Add final payment at exit if it doesn't coincide with a regular distribution
      bool exitPaymentExists = distributions.any((dist) => dist.date == project.dateOfExit);
      if (!exitPaymentExists) {
        // Add the final payment that includes principal return
        distributions.add(Distribution(
          date: project.dateOfExit,
          name: "Final Payment",
          plannedAmount: project.investmentAmount,
          type: "exit",
          done: false,
        ));
      }
    } catch (e) {
      _logger.severe('Error generating distributions: $e');
    }
    
    return distributions;
  }

  // Get all investments for the current user
  Future<Map<String, dynamic>> getInvestments() async {
    User? user = _auth.currentUser;
    if (user != null) {
      _logger.info('Fetching investments for user: ${user.uid}');
      try {
        DocumentSnapshot doc = await _firestore.collection('investments').doc(user.uid).get();
        
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          int projectCount = data['projects']?.length ?? 0;
          _logger.info('Retrieved $projectCount investments for user');
          return data;
        } else {
          _logger.info('No investments found for user, returning empty list');
          return {'uId': user.uid, 'projects': []};
        }
      } catch (e) {
        _logger.severe('Error getting investments: $e');
        // Return empty data rather than throwing an exception
        return {'uId': user.uid, 'projects': []};
      }
    } else {
      _logger.warning('User not logged in, cannot get investments.');
      throw Exception('User not logged in');
    }
  }

  // Update an existing investment
  Future<void> updateInvestment(String projectId, Map<String, dynamic> updatedData) async {
    User? user = _auth.currentUser;
    if (user != null) {
      _logger.info('Updating investment $projectId for user: ${user.uid}');
      try {
        // Get the current investments document
        DocumentSnapshot doc = await _firestore.collection('investments').doc(user.uid).get();
        
        if (doc.exists) {
          Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
          List<dynamic> projects = userData['projects'] as List<dynamic>;
          
          // Find the project to update
          int index = projects.indexWhere((project) => project['projectId'] == projectId);
          
          if (index != -1) {
            // Update the project data
            final now = DateTime.now();
            final formattedDate = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
            updatedData['updateDate'] = formattedDate;
            
            // Preserve the original creation date
            updatedData['createDate'] = projects[index]['createDate'];
            
            // Replace the old project with updated one
            projects[index] = {...projects[index], ...updatedData};
            
            _logger.info('Attempting to update project in Firestore');
            
            // Update the document
            await _firestore.collection('investments').doc(user.uid).update({
              'projects': projects
            });
            
            _logger.info('Investment updated successfully: $projectId');
          } else {
            _logger.warning('Project not found: $projectId');
            throw Exception('Project not found');
          }
        } else {
          _logger.warning('No investments document found for user');
          throw Exception('No investments found');
        }
      } catch (e) {
        _logger.severe('Error updating investment: $e');
        rethrow;
      }
    } else {
      _logger.warning('User not logged in, cannot update investment.');
      throw Exception('User not logged in');
    }
  }

  // Delete an investment
  Future<void> deleteInvestment(String projectId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      _logger.info('Deleting investment $projectId for user: ${user.uid}');
      try {
        // Get the current investments document
        DocumentSnapshot doc = await _firestore.collection('investments').doc(user.uid).get();
        
        if (doc.exists) {
          Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
          List<dynamic> projects = userData['projects'] as List<dynamic>;
          
          int originalLength = projects.length;
          
          // Remove the project
          projects.removeWhere((project) => project['projectId'] == projectId);
          
          if (projects.length < originalLength) {
            _logger.info('Project found and removed from array, updating Firestore');
            
            // Update the document
            await _firestore.collection('investments').doc(user.uid).update({
              'projects': projects
            });
            
            _logger.info('Investment deleted successfully: $projectId');
          } else {
            _logger.warning('Project not found for deletion: $projectId');
            throw Exception('Project not found');
          }
        } else {
          _logger.warning('No investments document found for user');
          throw Exception('No investments found');
        }
      } catch (e) {
        _logger.severe('Error deleting investment: $e');
        rethrow;
      }
    } else {
      _logger.warning('User not logged in, cannot delete investment.');
      throw Exception('User not logged in');
    }
  }
  
  // Helper method to parse date string
  DateTime _parseDate(String dateStr) {
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