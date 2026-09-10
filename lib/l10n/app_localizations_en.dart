// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'DutyDesk';

  @override
  String get appSubtitle => 'Exam Invigilation & Staff Management System';

  @override
  String get examInvigilationManagement => 'Exam Invigilation Management';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get staffInvigilator => 'Staff / Invigilator';

  @override
  String get administrator => 'Administrator';

  @override
  String get adminUsernameOrEmail => 'Admin Username or Email';

  @override
  String get registeredMobileNumber => 'Registered Mobile Number';

  @override
  String get hintAdminEmail => 'e.g. admin@dutydesk.com';

  @override
  String get hintMobileNumber => 'e.g. 9876543210';

  @override
  String get password => 'Password';

  @override
  String get resourceIdPassword => 'Resource ID (Password)';

  @override
  String get hintAdminPassword => 'Enter admin password';

  @override
  String get hintResourceId => 'e.g. RES101 / Staff ID';

  @override
  String get signInAsAdmin => 'Sign In as Admin';

  @override
  String get signInAsStaff => 'Sign In as Staff';

  @override
  String get adminLoginHint =>
      'Admin: Use your administrative email & master password.';

  @override
  String get staffLoginHint =>
      'Staff: Use your registered Mobile Number and assigned Resource ID.';

  @override
  String get pleaseEnterAdminCredentials => 'Please enter Admin credentials';

  @override
  String get pleaseEnterMobileAndResourceId =>
      'Please enter Mobile Number and Resource ID';

  @override
  String get invalidMobileOrResourceId =>
      'Invalid Mobile Number or Resource ID';

  @override
  String get firebaseNotInitialized =>
      'Firebase is not initialized. Please check internet connection or configuration.';

  @override
  String get authenticationFailed => 'Authentication failed';

  @override
  String get confirmLogout => 'Confirm Logout';

  @override
  String get confirmLogoutMessage => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get totalStaff => 'Total Staff';

  @override
  String get totalCenters => 'Total Centers';

  @override
  String get activeSessions => 'Active Sessions';

  @override
  String get todaysDuties => 'Today\'s Duties';

  @override
  String get totalRemuneration => 'Total Remuneration';

  @override
  String get liveMonitoring => 'Live Monitoring';

  @override
  String get arrivalStatus => 'Arrival Status';

  @override
  String get excellent => 'Excellent';

  @override
  String get good => 'Good';

  @override
  String get onTime => 'On Time';

  @override
  String get slightlyLate => 'Slightly Late';

  @override
  String get needsImprovement => 'Needs Improvement';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get manageStaff => 'Manage Staff';

  @override
  String get manageCenters => 'Manage Centers';

  @override
  String get allocateDuty => 'Allocate Duty';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get masterData => 'Master Data';

  @override
  String get globalSearch => 'Global Search';

  @override
  String get liveControlRoom => 'Live Control Room';

  @override
  String get payrollSalary => 'Payroll & Salary';

  @override
  String get todaysExams => 'Today\'s Exams';

  @override
  String get noExamsToday => 'No exams scheduled today';

  @override
  String get viewAll => 'View All';

  @override
  String get viewDetails => 'View Details';

  @override
  String get recentAllocations => 'Recent Allocations';

  @override
  String get noAllocations => 'No allocations found';

  @override
  String get exportAllAllocations => 'Export All Allocations';

  @override
  String exportingRecords(int count) {
    return 'Exporting $count allocation records.';
  }

  @override
  String get exportAsPdf => 'Export as PDF';

  @override
  String get exportAsExcel => 'Export as Excel';

  @override
  String pdfError(String error) {
    return 'PDF Error: $error';
  }

  @override
  String excelError(String error) {
    return 'Excel Error: $error';
  }

  @override
  String get allAllocations => 'All Allocations';

  @override
  String get dashboardFiltered => 'Dashboard Filtered';

  @override
  String get staff => 'Staff';

  @override
  String get addStaff => 'Add Staff';

  @override
  String get editStaff => 'Edit Staff';

  @override
  String get deleteStaff => 'Delete Staff';

  @override
  String get search => 'Search';

  @override
  String get searchStaff => 'Search staff...';

  @override
  String get fullName => 'Full Name';

  @override
  String get mobileNumber => 'Mobile Number';

  @override
  String get mobileNumberUsername => 'Mobile Number (Username)';

  @override
  String get resourceId => 'Resource ID';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get address => 'Address';

  @override
  String get active => 'Active';

  @override
  String get blocked => 'Blocked';

  @override
  String get available => 'Available';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get leave => 'Leave';

  @override
  String get save => 'Save';

  @override
  String get update => 'Update';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get personalDetails => 'Personal Details';

  @override
  String get contactAndCredentials => 'Contact & Login Credentials';

  @override
  String get addInvigilator => 'Add Invigilator';

  @override
  String get editInvigilator => 'Edit Invigilator';

  @override
  String get saveInvigilator => 'Save Invigilator';

  @override
  String get updateInvigilator => 'Update Invigilator';

  @override
  String get invigilatorAddedSuccess => 'Invigilator Added Successfully!';

  @override
  String get invigilatorUpdated => 'Invigilator Updated!';

  @override
  String get manageInvigilators => 'Manage Invigilators';

  @override
  String get noInvigilatorsFound => 'No invigilators found';

  @override
  String get totalInvigilators => 'Total Invigilators';

  @override
  String get deleteInvigilator => 'Delete Invigilator';

  @override
  String deleteInvigilatorConfirm(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get invigilatorProfile => 'Invigilator Profile';

  @override
  String get dutyHistory => 'Duty History';

  @override
  String get performance => 'Performance';

  @override
  String get totalDutiesAssigned => 'Total Duties Assigned';

  @override
  String get dutiesCompleted => 'Duties Completed';

  @override
  String get dutiesPending => 'Duties Pending';

  @override
  String get attendanceRate => 'Attendance Rate';

  @override
  String get availabilityCalendar => 'Availability Calendar';

  @override
  String get markAvailable => 'Mark Available';

  @override
  String get markUnavailable => 'Mark Unavailable';

  @override
  String get markLeave => 'Mark Leave';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get exams => 'Exams';

  @override
  String get registeredExams => 'Registered Exams';

  @override
  String get registerNewExam => 'Register New Exam';

  @override
  String get registerExam => 'Register Exam';

  @override
  String get examName => 'Exam Name';

  @override
  String get examDate => 'Exam Date';

  @override
  String get examCenter => 'Exam Center';

  @override
  String get session => 'Session';

  @override
  String get newExam => 'New Exam';

  @override
  String get noRegisteredExams =>
      'No Registered Exams found. Create one to assign duties.';

  @override
  String get selectCenter => 'Select Center';

  @override
  String get required => 'Required';

  @override
  String get selectDate => 'Select Date';

  @override
  String get selectShift => 'Select Shift';

  @override
  String get shift1 => 'Shift 1';

  @override
  String get shift2 => 'Shift 2';

  @override
  String get shift3 => 'Shift 3';

  @override
  String get selectInvigilators => 'Select Invigilators';

  @override
  String get selectedInvigilators => 'Selected Invigilators';

  @override
  String get assign => 'Assign';

  @override
  String get assignDuty => 'Assign Duty';

  @override
  String get conflictDetected => 'Conflict Detected';

  @override
  String get overrideAction => 'Override';

  @override
  String get recommendedStaff => 'Recommended Staff';

  @override
  String get reassign => 'Reassign';

  @override
  String get swapDuty => 'Swap Duty';

  @override
  String get replacement => 'Replacement';

  @override
  String get confirmAssignment => 'Confirm Assignment';

  @override
  String get dutyAllocation => 'Duty Allocation';

  @override
  String get shiftRemuneration => 'Shift Remuneration';

  @override
  String shift1Amount(int amount) {
    return 'Shift 1 — ₹$amount';
  }

  @override
  String shift2Amount(int amount) {
    return 'Shift 2 — ₹$amount';
  }

  @override
  String shift3Amount(int amount) {
    return 'Shift 3 — ₹$amount';
  }

  @override
  String get myDuties => 'My Duties';

  @override
  String get myProfile => 'My Profile';

  @override
  String get availability => 'Availability';

  @override
  String get calendar => 'Calendar';

  @override
  String get assignedDuty => 'Assigned Duty';

  @override
  String get accept => 'Accept';

  @override
  String get reject => 'Reject';

  @override
  String get dutyDetails => 'Duty Details';

  @override
  String get reportingTime => 'Reporting Time';

  @override
  String get remuneration => 'Remuneration';

  @override
  String get invigilatorDashboard => 'Invigilator Dashboard';

  @override
  String get noDutiesAssigned => 'No duties assigned yet';

  @override
  String get upcomingDuties => 'Upcoming Duties';

  @override
  String get pastDuties => 'Past Duties';

  @override
  String get dutyAccepted => 'Duty accepted';

  @override
  String get dutyRejected => 'Duty rejected';

  @override
  String get dutySwapped => 'Duty swapped successfully';

  @override
  String get currentDuty => 'Current Duty';

  @override
  String get reached => 'REACHED';

  @override
  String get arrival => 'Arrival';

  @override
  String get arrivalTime => 'Arrival Time';

  @override
  String get location => 'Location';

  @override
  String get gps => 'GPS';

  @override
  String get locationVerified => 'Location Verified';

  @override
  String get outsideCenter => 'Outside Center';

  @override
  String get distanceFromCenter => 'Distance from Center';

  @override
  String get arrivalRecorded => 'Arrival Recorded';

  @override
  String get waitingForInternet => 'Waiting for Internet';

  @override
  String get arrivalSyncedSuccessfully => 'Arrival Synced Successfully';

  @override
  String get youReachedOnTime => 'You reached on time.';

  @override
  String get youReachedSlightlyLate => 'You reached slightly late.';

  @override
  String get reachInProperTime => 'Reach in proper time.';

  @override
  String get geofenceVerified => '✓ Geofence Verified';

  @override
  String get outsideGeofence => '⚠ Outside Geofence';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get requestManualVerification => 'Request Manual Verification';

  @override
  String get outsideGeofenceWarning =>
      'You appear to be outside the exam center area.';

  @override
  String distanceMeters(String distance) {
    return '${distance}m from center';
  }

  @override
  String get dateRange => 'Date Range';

  @override
  String get status => 'Status';

  @override
  String get accepted => 'Accepted';

  @override
  String get pending => 'Pending';

  @override
  String get rejected => 'Rejected';

  @override
  String get completed => 'Completed';

  @override
  String get totalDuties => 'Total Duties';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get exportExcel => 'Export Excel';

  @override
  String get download => 'Download';

  @override
  String get generateReport => 'Generate Report';

  @override
  String get noReportsFound => 'No reports found';

  @override
  String get reportGenerated => 'Report generated successfully';

  @override
  String get center => 'Center';

  @override
  String get shift => 'Shift';

  @override
  String get all => 'All';

  @override
  String get filterByStatus => 'Filter by Status';

  @override
  String get filterByCenter => 'Filter by Center';

  @override
  String get filterByShift => 'Filter by Shift';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिन्दी';

  @override
  String get gujarati => 'ગુજરાતી';

  @override
  String get languageChangedSuccess => 'Language changed successfully';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get lunchProvision => 'Lunch Provision';

  @override
  String get reportingTimeLabel => 'Reporting Time';

  @override
  String get arrivalThreshold => 'Arrival Threshold';

  @override
  String get voiceFeedback => 'Voice Feedback';

  @override
  String get notifications => 'Notifications';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get settingsSaved => 'Settings saved successfully';

  @override
  String get dutySettings => 'Duty Settings';

  @override
  String get centers => 'Centers';

  @override
  String get addCenter => 'Add Center';

  @override
  String get editCenter => 'Edit Center';

  @override
  String get deleteCenter => 'Delete Center';

  @override
  String get centerName => 'Center Name';

  @override
  String get locationCity => 'Location / City';

  @override
  String get capacity => 'Capacity';

  @override
  String get saveCenter => 'Save Center';

  @override
  String get updateCenter => 'Update Center';

  @override
  String get centerAddedSuccess => 'Center Added Successfully!';

  @override
  String get centerUpdated => 'Center Updated!';

  @override
  String get noCentersFound => 'No centers found. Add one!';

  @override
  String deleteCenterConfirm(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get geofenceGpsVerification => 'Geofence & GPS Verification';

  @override
  String get useCurrentGps => 'Use Current GPS';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get allowedArrivalRadius => 'Allowed Arrival Radius (Meters)';

  @override
  String get geofenceHelperText =>
      'Staff within this radius are marked \"REACHED & VERIFIED\"';

  @override
  String get capturedGpsLocation => '✓ Captured current GPS location!';

  @override
  String get couldNotAcquireGps => 'Could not acquire GPS location';

  @override
  String get noGpsGeofenceConfigured => 'No GPS Geofence configured';

  @override
  String get reachedCount => 'Reached';

  @override
  String get pendingCount => 'Pending';

  @override
  String get lateCount => 'Late';

  @override
  String get absentCount => 'Absent';

  @override
  String get centerHealth => 'Center Health';

  @override
  String get shortage => 'Shortage';

  @override
  String get replacementRequired => 'Replacement Required';

  @override
  String get emergencyReplacement => 'Emergency Replacement';

  @override
  String get todaysDutiesCount => 'Today\'s Duties';

  @override
  String get liveExamControlRoom => 'Live Exam-Day Control Room';

  @override
  String get liveStats => 'Live Stats';

  @override
  String get outsideGeofenceFilter => 'Outside Geofence';

  @override
  String get callStaff => 'Call Staff';

  @override
  String get reassignDuty => 'Reassign Duty';

  @override
  String get notificationCenter => 'Notification Center';

  @override
  String get unread => 'Unread';

  @override
  String get dutyUpdates => 'Duty Updates';

  @override
  String get alerts => 'Alerts';

  @override
  String get markAllRead => 'Mark All Read';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get markAsRead => 'Mark as Read';

  @override
  String get deleteNotification => 'Delete';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String get justNow => 'Just now';

  @override
  String get payroll => 'Payroll';

  @override
  String get payrollRemuneration => 'Payroll & Remuneration';

  @override
  String get totalRemunerationAmount => 'Total Remuneration';

  @override
  String get approved => 'Approved';

  @override
  String get paid => 'Paid';

  @override
  String get paymentPending => 'Payment Pending';

  @override
  String get paymentReference => 'Payment Reference';

  @override
  String get paymentRemarks => 'Payment Remarks';

  @override
  String get markPaid => 'Mark Paid';

  @override
  String get bulkPay => 'Bulk Pay';

  @override
  String get exportStatement => 'Export Statement';

  @override
  String get paymentStatusUpdated => 'Payment status updated';

  @override
  String get staffSummary => 'Staff Summary';

  @override
  String get detailedPayments => 'Detailed Payments';

  @override
  String get monthSelector => 'Month';

  @override
  String get masterDataManagement => 'Master Data Management';

  @override
  String get selectModuleDescription =>
      'Select a module below to view, add, edit, or manage its active status.';

  @override
  String get searchModules => 'Search modules...';

  @override
  String get esNames => 'ES Names';

  @override
  String get examNames => 'Exam Names';

  @override
  String get securityGuardNames => 'Security Guard Names';

  @override
  String get jammerNames => 'Jammer Names';

  @override
  String get users => 'Users';

  @override
  String records(int count) {
    return '$count Records';
  }

  @override
  String get addNew => 'Add New';

  @override
  String get noRecords => 'No records found';

  @override
  String get itemAdded => 'Item added successfully';

  @override
  String get itemUpdated => 'Item updated successfully';

  @override
  String get itemDeleted => 'Item deleted successfully';

  @override
  String get enterValue => 'Enter value';

  @override
  String get name => 'Name';

  @override
  String get value => 'Value';

  @override
  String get dutyAssignedSuccess => 'Duty assigned successfully';

  @override
  String get dutyAllocatedSuccess => 'Duty allocated successfully';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get success => 'Success';

  @override
  String get error => 'Error';

  @override
  String get loading => 'Loading...';

  @override
  String get noDataFound => 'No data found';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get submit => 'Submit';

  @override
  String get clear => 'Clear';

  @override
  String get reset => 'Reset';

  @override
  String get refresh => 'Refresh';

  @override
  String get more => 'More';

  @override
  String get less => 'Less';

  @override
  String get seeAll => 'See All';

  @override
  String get ttsExcellent => 'Excellent. You reached on time.';

  @override
  String get ttsGood => 'Good. You reached slightly late.';

  @override
  String get ttsNeedsImprovement =>
      'Needs improvement. Please reach in proper time.';

  @override
  String get welcomeMessage => 'Welcome!';

  @override
  String get swapRequest => 'Swap Request';

  @override
  String get swapRequestSent => 'Swap request sent successfully';

  @override
  String get swapApproved => 'Swap approved';

  @override
  String get swapRejected => 'Swap rejected';

  @override
  String get requestSwap => 'Request Swap';

  @override
  String get swapWith => 'Swap With';

  @override
  String get reason => 'Reason';

  @override
  String get sendReminder => 'Send Reminder';

  @override
  String get reminderSent => 'Reminder sent successfully';

  @override
  String get manualReminder => 'Manual Reminder';

  @override
  String get profile => 'Profile';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get contactInfo => 'Contact Information';

  @override
  String get dutyStatistics => 'Duty Statistics';

  @override
  String get mockDutyCount => 'Mock Duty Count';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get mobile => 'Mobile';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String staffReachedCount(int reached, int total) {
    return '$reached / $total Reached';
  }

  @override
  String pendingDutiesCount(int count) {
    return 'You have $count pending duties.';
  }

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get deleteWarning => 'This action cannot be undone.';

  @override
  String get operationSuccess => 'Operation completed successfully';

  @override
  String get operationFailed => 'Operation failed';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get checkInternetConnection =>
      'Please check your internet connection and try again.';

  @override
  String capacityLabel(int capacity) {
    return 'Capacity: $capacity';
  }

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String remunerationAmount(String amount) {
    return '₹$amount';
  }

  @override
  String get dutyAllocations => 'Duty Allocations';

  @override
  String get examSessions => 'Exam Sessions';

  @override
  String get sendEmailReport => 'Send Email Report';

  @override
  String get emailSentSuccess => 'Email sent successfully';

  @override
  String get emailSendFailed => 'Failed to send email';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get selected => 'Selected';

  @override
  String get notSelected => 'Not Selected';

  @override
  String get chooseDate => 'Choose Date';

  @override
  String get chooseDateRange => 'Choose Date Range';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get searchResults => 'Search Results';

  @override
  String get typeToSearch => 'Type to search...';

  @override
  String get staffDetails => 'Staff Details';

  @override
  String get centerDetails => 'Center Details';

  @override
  String get dutyInfo => 'Duty Info';

  @override
  String get examInfo => 'Exam Info';

  @override
  String get maintenanceData => 'Maintenance Data';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get contactStaff => 'Contact Staff';

  @override
  String get actions => 'Actions';

  @override
  String get noActionsAvailable => 'No actions available';

  @override
  String get geofenceVerification => 'Geofence & GPS Verification';

  @override
  String get welcome => 'Welcome';

  @override
  String get statsAtGlance => 'Statistics at a Glance';

  @override
  String get invigilators => 'Invigilators';

  @override
  String get swapRequests => 'Swap Requests';

  @override
  String get approve => 'Approve';

  @override
  String get late => 'Late';

  @override
  String get invigilatorDirectory => 'Invigilator Directory';

  @override
  String get maintainData => 'Maintain Data';

  @override
  String get securityGuardRecords => 'Security Guard Records';

  @override
  String get home => 'Home';

  @override
  String get clickDateToToggle =>
      'Tap any date to mark or unmark your leave/unavailability.';

  @override
  String get inactive => 'Inactive';

  @override
  String get invigilator => 'Invigilator';

  @override
  String get labStaff => 'Lab Staff';
}
