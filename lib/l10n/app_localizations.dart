import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('gu'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'DutyDesk'**
  String get appName;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exam Invigilation & Staff Management System'**
  String get appSubtitle;

  /// No description provided for @examInvigilationManagement.
  ///
  /// In en, this message translates to:
  /// **'Exam Invigilation Management'**
  String get examInvigilationManagement;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @staffInvigilator.
  ///
  /// In en, this message translates to:
  /// **'Staff / Invigilator'**
  String get staffInvigilator;

  /// No description provided for @administrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administrator;

  /// No description provided for @adminUsernameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Admin Username or Email'**
  String get adminUsernameOrEmail;

  /// No description provided for @registeredMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Registered Mobile Number'**
  String get registeredMobileNumber;

  /// No description provided for @hintAdminEmail.
  ///
  /// In en, this message translates to:
  /// **'e.g. admin@dutydesk.com'**
  String get hintAdminEmail;

  /// No description provided for @hintMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'e.g. 9876543210'**
  String get hintMobileNumber;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @resourceIdPassword.
  ///
  /// In en, this message translates to:
  /// **'Resource ID (Password)'**
  String get resourceIdPassword;

  /// No description provided for @hintAdminPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter admin password'**
  String get hintAdminPassword;

  /// No description provided for @hintResourceId.
  ///
  /// In en, this message translates to:
  /// **'e.g. RES101 / Staff ID'**
  String get hintResourceId;

  /// No description provided for @signInAsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Sign In as Admin'**
  String get signInAsAdmin;

  /// No description provided for @signInAsStaff.
  ///
  /// In en, this message translates to:
  /// **'Sign In as Staff'**
  String get signInAsStaff;

  /// No description provided for @adminLoginHint.
  ///
  /// In en, this message translates to:
  /// **'Admin: Use your administrative email & master password.'**
  String get adminLoginHint;

  /// No description provided for @staffLoginHint.
  ///
  /// In en, this message translates to:
  /// **'Staff: Use your registered Mobile Number and assigned Resource ID.'**
  String get staffLoginHint;

  /// No description provided for @pleaseEnterAdminCredentials.
  ///
  /// In en, this message translates to:
  /// **'Please enter Admin credentials'**
  String get pleaseEnterAdminCredentials;

  /// No description provided for @pleaseEnterMobileAndResourceId.
  ///
  /// In en, this message translates to:
  /// **'Please enter Mobile Number and Resource ID'**
  String get pleaseEnterMobileAndResourceId;

  /// No description provided for @invalidMobileOrResourceId.
  ///
  /// In en, this message translates to:
  /// **'Invalid Mobile Number or Resource ID'**
  String get invalidMobileOrResourceId;

  /// No description provided for @firebaseNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'Firebase is not initialized. Please check internet connection or configuration.'**
  String get firebaseNotInitialized;

  /// No description provided for @authenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authenticationFailed;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogout;

  /// No description provided for @confirmLogoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogoutMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @totalStaff.
  ///
  /// In en, this message translates to:
  /// **'Total Staff'**
  String get totalStaff;

  /// No description provided for @totalCenters.
  ///
  /// In en, this message translates to:
  /// **'Total Centers'**
  String get totalCenters;

  /// No description provided for @activeSessions.
  ///
  /// In en, this message translates to:
  /// **'Active Sessions'**
  String get activeSessions;

  /// No description provided for @todaysDuties.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Duties'**
  String get todaysDuties;

  /// No description provided for @totalRemuneration.
  ///
  /// In en, this message translates to:
  /// **'Total Remuneration'**
  String get totalRemuneration;

  /// No description provided for @liveMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Live Monitoring'**
  String get liveMonitoring;

  /// No description provided for @arrivalStatus.
  ///
  /// In en, this message translates to:
  /// **'Arrival Status'**
  String get arrivalStatus;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @onTime.
  ///
  /// In en, this message translates to:
  /// **'On Time'**
  String get onTime;

  /// No description provided for @slightlyLate.
  ///
  /// In en, this message translates to:
  /// **'Slightly Late'**
  String get slightlyLate;

  /// No description provided for @needsImprovement.
  ///
  /// In en, this message translates to:
  /// **'Needs Improvement'**
  String get needsImprovement;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @manageStaff.
  ///
  /// In en, this message translates to:
  /// **'Manage Staff'**
  String get manageStaff;

  /// No description provided for @manageCenters.
  ///
  /// In en, this message translates to:
  /// **'Manage Centers'**
  String get manageCenters;

  /// No description provided for @allocateDuty.
  ///
  /// In en, this message translates to:
  /// **'Allocate Duty'**
  String get allocateDuty;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @masterData.
  ///
  /// In en, this message translates to:
  /// **'Master Data'**
  String get masterData;

  /// No description provided for @globalSearch.
  ///
  /// In en, this message translates to:
  /// **'Global Search'**
  String get globalSearch;

  /// No description provided for @liveControlRoom.
  ///
  /// In en, this message translates to:
  /// **'Live Control Room'**
  String get liveControlRoom;

  /// No description provided for @payrollSalary.
  ///
  /// In en, this message translates to:
  /// **'Payroll & Salary'**
  String get payrollSalary;

  /// No description provided for @todaysExams.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Exams'**
  String get todaysExams;

  /// No description provided for @noExamsToday.
  ///
  /// In en, this message translates to:
  /// **'No exams scheduled today'**
  String get noExamsToday;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @recentAllocations.
  ///
  /// In en, this message translates to:
  /// **'Recent Allocations'**
  String get recentAllocations;

  /// No description provided for @noAllocations.
  ///
  /// In en, this message translates to:
  /// **'No allocations found'**
  String get noAllocations;

  /// No description provided for @exportAllAllocations.
  ///
  /// In en, this message translates to:
  /// **'Export All Allocations'**
  String get exportAllAllocations;

  /// No description provided for @exportingRecords.
  ///
  /// In en, this message translates to:
  /// **'Exporting {count} allocation records.'**
  String exportingRecords(int count);

  /// No description provided for @exportAsPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get exportAsPdf;

  /// No description provided for @exportAsExcel.
  ///
  /// In en, this message translates to:
  /// **'Export as Excel'**
  String get exportAsExcel;

  /// No description provided for @pdfError.
  ///
  /// In en, this message translates to:
  /// **'PDF Error: {error}'**
  String pdfError(String error);

  /// No description provided for @excelError.
  ///
  /// In en, this message translates to:
  /// **'Excel Error: {error}'**
  String excelError(String error);

  /// No description provided for @allAllocations.
  ///
  /// In en, this message translates to:
  /// **'All Allocations'**
  String get allAllocations;

  /// No description provided for @dashboardFiltered.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Filtered'**
  String get dashboardFiltered;

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @addStaff.
  ///
  /// In en, this message translates to:
  /// **'Add Staff'**
  String get addStaff;

  /// No description provided for @editStaff.
  ///
  /// In en, this message translates to:
  /// **'Edit Staff'**
  String get editStaff;

  /// No description provided for @deleteStaff.
  ///
  /// In en, this message translates to:
  /// **'Delete Staff'**
  String get deleteStaff;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchStaff.
  ///
  /// In en, this message translates to:
  /// **'Search staff...'**
  String get searchStaff;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @mobileNumberUsername.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number (Username)'**
  String get mobileNumberUsername;

  /// No description provided for @resourceId.
  ///
  /// In en, this message translates to:
  /// **'Resource ID'**
  String get resourceId;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personalDetails;

  /// No description provided for @contactAndCredentials.
  ///
  /// In en, this message translates to:
  /// **'Contact & Login Credentials'**
  String get contactAndCredentials;

  /// No description provided for @addInvigilator.
  ///
  /// In en, this message translates to:
  /// **'Add Invigilator'**
  String get addInvigilator;

  /// No description provided for @editInvigilator.
  ///
  /// In en, this message translates to:
  /// **'Edit Invigilator'**
  String get editInvigilator;

  /// No description provided for @saveInvigilator.
  ///
  /// In en, this message translates to:
  /// **'Save Invigilator'**
  String get saveInvigilator;

  /// No description provided for @updateInvigilator.
  ///
  /// In en, this message translates to:
  /// **'Update Invigilator'**
  String get updateInvigilator;

  /// No description provided for @invigilatorAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invigilator Added Successfully!'**
  String get invigilatorAddedSuccess;

  /// No description provided for @invigilatorUpdated.
  ///
  /// In en, this message translates to:
  /// **'Invigilator Updated!'**
  String get invigilatorUpdated;

  /// No description provided for @manageInvigilators.
  ///
  /// In en, this message translates to:
  /// **'Manage Invigilators'**
  String get manageInvigilators;

  /// No description provided for @noInvigilatorsFound.
  ///
  /// In en, this message translates to:
  /// **'No invigilators found'**
  String get noInvigilatorsFound;

  /// No description provided for @totalInvigilators.
  ///
  /// In en, this message translates to:
  /// **'Total Invigilators'**
  String get totalInvigilators;

  /// No description provided for @deleteInvigilator.
  ///
  /// In en, this message translates to:
  /// **'Delete Invigilator'**
  String get deleteInvigilator;

  /// No description provided for @deleteInvigilatorConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String deleteInvigilatorConfirm(String name);

  /// No description provided for @invigilatorProfile.
  ///
  /// In en, this message translates to:
  /// **'Invigilator Profile'**
  String get invigilatorProfile;

  /// No description provided for @dutyHistory.
  ///
  /// In en, this message translates to:
  /// **'Duty History'**
  String get dutyHistory;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @totalDutiesAssigned.
  ///
  /// In en, this message translates to:
  /// **'Total Duties Assigned'**
  String get totalDutiesAssigned;

  /// No description provided for @dutiesCompleted.
  ///
  /// In en, this message translates to:
  /// **'Duties Completed'**
  String get dutiesCompleted;

  /// No description provided for @dutiesPending.
  ///
  /// In en, this message translates to:
  /// **'Duties Pending'**
  String get dutiesPending;

  /// No description provided for @attendanceRate.
  ///
  /// In en, this message translates to:
  /// **'Attendance Rate'**
  String get attendanceRate;

  /// No description provided for @availabilityCalendar.
  ///
  /// In en, this message translates to:
  /// **'Availability Calendar'**
  String get availabilityCalendar;

  /// No description provided for @markAvailable.
  ///
  /// In en, this message translates to:
  /// **'Mark Available'**
  String get markAvailable;

  /// No description provided for @markUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Mark Unavailable'**
  String get markUnavailable;

  /// No description provided for @markLeave.
  ///
  /// In en, this message translates to:
  /// **'Mark Leave'**
  String get markLeave;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @exams.
  ///
  /// In en, this message translates to:
  /// **'Exams'**
  String get exams;

  /// No description provided for @registeredExams.
  ///
  /// In en, this message translates to:
  /// **'Registered Exams'**
  String get registeredExams;

  /// No description provided for @registerNewExam.
  ///
  /// In en, this message translates to:
  /// **'Register New Exam'**
  String get registerNewExam;

  /// No description provided for @registerExam.
  ///
  /// In en, this message translates to:
  /// **'Register Exam'**
  String get registerExam;

  /// No description provided for @examName.
  ///
  /// In en, this message translates to:
  /// **'Exam Name'**
  String get examName;

  /// No description provided for @examDate.
  ///
  /// In en, this message translates to:
  /// **'Exam Date'**
  String get examDate;

  /// No description provided for @examCenter.
  ///
  /// In en, this message translates to:
  /// **'Exam Center'**
  String get examCenter;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @newExam.
  ///
  /// In en, this message translates to:
  /// **'New Exam'**
  String get newExam;

  /// No description provided for @noRegisteredExams.
  ///
  /// In en, this message translates to:
  /// **'No Registered Exams found. Create one to assign duties.'**
  String get noRegisteredExams;

  /// No description provided for @selectCenter.
  ///
  /// In en, this message translates to:
  /// **'Select Center'**
  String get selectCenter;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectShift.
  ///
  /// In en, this message translates to:
  /// **'Select Shift'**
  String get selectShift;

  /// No description provided for @shift1.
  ///
  /// In en, this message translates to:
  /// **'Shift 1'**
  String get shift1;

  /// No description provided for @shift2.
  ///
  /// In en, this message translates to:
  /// **'Shift 2'**
  String get shift2;

  /// No description provided for @shift3.
  ///
  /// In en, this message translates to:
  /// **'Shift 3'**
  String get shift3;

  /// No description provided for @selectInvigilators.
  ///
  /// In en, this message translates to:
  /// **'Select Invigilators'**
  String get selectInvigilators;

  /// No description provided for @selectedInvigilators.
  ///
  /// In en, this message translates to:
  /// **'Selected Invigilators'**
  String get selectedInvigilators;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @assignDuty.
  ///
  /// In en, this message translates to:
  /// **'Assign Duty'**
  String get assignDuty;

  /// No description provided for @conflictDetected.
  ///
  /// In en, this message translates to:
  /// **'Conflict Detected'**
  String get conflictDetected;

  /// No description provided for @overrideAction.
  ///
  /// In en, this message translates to:
  /// **'Override'**
  String get overrideAction;

  /// No description provided for @recommendedStaff.
  ///
  /// In en, this message translates to:
  /// **'Recommended Staff'**
  String get recommendedStaff;

  /// No description provided for @reassign.
  ///
  /// In en, this message translates to:
  /// **'Reassign'**
  String get reassign;

  /// No description provided for @swapDuty.
  ///
  /// In en, this message translates to:
  /// **'Swap Duty'**
  String get swapDuty;

  /// No description provided for @replacement.
  ///
  /// In en, this message translates to:
  /// **'Replacement'**
  String get replacement;

  /// No description provided for @confirmAssignment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Assignment'**
  String get confirmAssignment;

  /// No description provided for @dutyAllocation.
  ///
  /// In en, this message translates to:
  /// **'Duty Allocation'**
  String get dutyAllocation;

  /// No description provided for @shiftRemuneration.
  ///
  /// In en, this message translates to:
  /// **'Shift Remuneration'**
  String get shiftRemuneration;

  /// No description provided for @shift1Amount.
  ///
  /// In en, this message translates to:
  /// **'Shift 1 — ₹{amount}'**
  String shift1Amount(int amount);

  /// No description provided for @shift2Amount.
  ///
  /// In en, this message translates to:
  /// **'Shift 2 — ₹{amount}'**
  String shift2Amount(int amount);

  /// No description provided for @shift3Amount.
  ///
  /// In en, this message translates to:
  /// **'Shift 3 — ₹{amount}'**
  String shift3Amount(int amount);

  /// No description provided for @myDuties.
  ///
  /// In en, this message translates to:
  /// **'My Duties'**
  String get myDuties;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @assignedDuty.
  ///
  /// In en, this message translates to:
  /// **'Assigned Duty'**
  String get assignedDuty;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @dutyDetails.
  ///
  /// In en, this message translates to:
  /// **'Duty Details'**
  String get dutyDetails;

  /// No description provided for @reportingTime.
  ///
  /// In en, this message translates to:
  /// **'Reporting Time'**
  String get reportingTime;

  /// No description provided for @remuneration.
  ///
  /// In en, this message translates to:
  /// **'Remuneration'**
  String get remuneration;

  /// No description provided for @invigilatorDashboard.
  ///
  /// In en, this message translates to:
  /// **'Invigilator Dashboard'**
  String get invigilatorDashboard;

  /// No description provided for @noDutiesAssigned.
  ///
  /// In en, this message translates to:
  /// **'No duties assigned yet'**
  String get noDutiesAssigned;

  /// No description provided for @upcomingDuties.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Duties'**
  String get upcomingDuties;

  /// No description provided for @pastDuties.
  ///
  /// In en, this message translates to:
  /// **'Past Duties'**
  String get pastDuties;

  /// No description provided for @dutyAccepted.
  ///
  /// In en, this message translates to:
  /// **'Duty accepted'**
  String get dutyAccepted;

  /// No description provided for @dutyRejected.
  ///
  /// In en, this message translates to:
  /// **'Duty rejected'**
  String get dutyRejected;

  /// No description provided for @dutySwapped.
  ///
  /// In en, this message translates to:
  /// **'Duty swapped successfully'**
  String get dutySwapped;

  /// No description provided for @currentDuty.
  ///
  /// In en, this message translates to:
  /// **'Current Duty'**
  String get currentDuty;

  /// No description provided for @reached.
  ///
  /// In en, this message translates to:
  /// **'REACHED'**
  String get reached;

  /// No description provided for @arrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get arrival;

  /// No description provided for @arrivalTime.
  ///
  /// In en, this message translates to:
  /// **'Arrival Time'**
  String get arrivalTime;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @gps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get gps;

  /// No description provided for @locationVerified.
  ///
  /// In en, this message translates to:
  /// **'Location Verified'**
  String get locationVerified;

  /// No description provided for @outsideCenter.
  ///
  /// In en, this message translates to:
  /// **'Outside Center'**
  String get outsideCenter;

  /// No description provided for @distanceFromCenter.
  ///
  /// In en, this message translates to:
  /// **'Distance from Center'**
  String get distanceFromCenter;

  /// No description provided for @arrivalRecorded.
  ///
  /// In en, this message translates to:
  /// **'Arrival Recorded'**
  String get arrivalRecorded;

  /// No description provided for @waitingForInternet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Internet'**
  String get waitingForInternet;

  /// No description provided for @arrivalSyncedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Arrival Synced Successfully'**
  String get arrivalSyncedSuccessfully;

  /// No description provided for @youReachedOnTime.
  ///
  /// In en, this message translates to:
  /// **'You reached on time.'**
  String get youReachedOnTime;

  /// No description provided for @youReachedSlightlyLate.
  ///
  /// In en, this message translates to:
  /// **'You reached slightly late.'**
  String get youReachedSlightlyLate;

  /// No description provided for @reachInProperTime.
  ///
  /// In en, this message translates to:
  /// **'Reach in proper time.'**
  String get reachInProperTime;

  /// No description provided for @geofenceVerified.
  ///
  /// In en, this message translates to:
  /// **'✓ Geofence Verified'**
  String get geofenceVerified;

  /// No description provided for @outsideGeofence.
  ///
  /// In en, this message translates to:
  /// **'⚠ Outside Geofence'**
  String get outsideGeofence;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @requestManualVerification.
  ///
  /// In en, this message translates to:
  /// **'Request Manual Verification'**
  String get requestManualVerification;

  /// No description provided for @outsideGeofenceWarning.
  ///
  /// In en, this message translates to:
  /// **'You appear to be outside the exam center area.'**
  String get outsideGeofenceWarning;

  /// No description provided for @distanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{distance}m from center'**
  String distanceMeters(String distance);

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @totalDuties.
  ///
  /// In en, this message translates to:
  /// **'Total Duties'**
  String get totalDuties;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get exportExcel;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get generateReport;

  /// No description provided for @noReportsFound.
  ///
  /// In en, this message translates to:
  /// **'No reports found'**
  String get noReportsFound;

  /// No description provided for @reportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Report generated successfully'**
  String get reportGenerated;

  /// No description provided for @center.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get center;

  /// No description provided for @shift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get shift;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by Status'**
  String get filterByStatus;

  /// No description provided for @filterByCenter.
  ///
  /// In en, this message translates to:
  /// **'Filter by Center'**
  String get filterByCenter;

  /// No description provided for @filterByShift.
  ///
  /// In en, this message translates to:
  /// **'Filter by Shift'**
  String get filterByShift;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get hindi;

  /// No description provided for @gujarati.
  ///
  /// In en, this message translates to:
  /// **'ગુજરાતી'**
  String get gujarati;

  /// No description provided for @languageChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChangedSuccess;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @lunchProvision.
  ///
  /// In en, this message translates to:
  /// **'Lunch Provision'**
  String get lunchProvision;

  /// No description provided for @reportingTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reporting Time'**
  String get reportingTimeLabel;

  /// No description provided for @arrivalThreshold.
  ///
  /// In en, this message translates to:
  /// **'Arrival Threshold'**
  String get arrivalThreshold;

  /// No description provided for @voiceFeedback.
  ///
  /// In en, this message translates to:
  /// **'Voice Feedback'**
  String get voiceFeedback;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSaved;

  /// No description provided for @dutySettings.
  ///
  /// In en, this message translates to:
  /// **'Duty Settings'**
  String get dutySettings;

  /// No description provided for @centers.
  ///
  /// In en, this message translates to:
  /// **'Centers'**
  String get centers;

  /// No description provided for @addCenter.
  ///
  /// In en, this message translates to:
  /// **'Add Center'**
  String get addCenter;

  /// No description provided for @editCenter.
  ///
  /// In en, this message translates to:
  /// **'Edit Center'**
  String get editCenter;

  /// No description provided for @deleteCenter.
  ///
  /// In en, this message translates to:
  /// **'Delete Center'**
  String get deleteCenter;

  /// No description provided for @centerName.
  ///
  /// In en, this message translates to:
  /// **'Center Name'**
  String get centerName;

  /// No description provided for @locationCity.
  ///
  /// In en, this message translates to:
  /// **'Location / City'**
  String get locationCity;

  /// No description provided for @capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capacity;

  /// No description provided for @saveCenter.
  ///
  /// In en, this message translates to:
  /// **'Save Center'**
  String get saveCenter;

  /// No description provided for @updateCenter.
  ///
  /// In en, this message translates to:
  /// **'Update Center'**
  String get updateCenter;

  /// No description provided for @centerAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Center Added Successfully!'**
  String get centerAddedSuccess;

  /// No description provided for @centerUpdated.
  ///
  /// In en, this message translates to:
  /// **'Center Updated!'**
  String get centerUpdated;

  /// No description provided for @noCentersFound.
  ///
  /// In en, this message translates to:
  /// **'No centers found. Add one!'**
  String get noCentersFound;

  /// No description provided for @deleteCenterConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String deleteCenterConfirm(String name);

  /// No description provided for @geofenceGpsVerification.
  ///
  /// In en, this message translates to:
  /// **'Geofence & GPS Verification'**
  String get geofenceGpsVerification;

  /// No description provided for @useCurrentGps.
  ///
  /// In en, this message translates to:
  /// **'Use Current GPS'**
  String get useCurrentGps;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @allowedArrivalRadius.
  ///
  /// In en, this message translates to:
  /// **'Allowed Arrival Radius (Meters)'**
  String get allowedArrivalRadius;

  /// No description provided for @geofenceHelperText.
  ///
  /// In en, this message translates to:
  /// **'Staff within this radius are marked \"REACHED & VERIFIED\"'**
  String get geofenceHelperText;

  /// No description provided for @capturedGpsLocation.
  ///
  /// In en, this message translates to:
  /// **'✓ Captured current GPS location!'**
  String get capturedGpsLocation;

  /// No description provided for @couldNotAcquireGps.
  ///
  /// In en, this message translates to:
  /// **'Could not acquire GPS location'**
  String get couldNotAcquireGps;

  /// No description provided for @noGpsGeofenceConfigured.
  ///
  /// In en, this message translates to:
  /// **'No GPS Geofence configured'**
  String get noGpsGeofenceConfigured;

  /// No description provided for @reachedCount.
  ///
  /// In en, this message translates to:
  /// **'Reached'**
  String get reachedCount;

  /// No description provided for @pendingCount.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingCount;

  /// No description provided for @lateCount.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get lateCount;

  /// No description provided for @absentCount.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absentCount;

  /// No description provided for @centerHealth.
  ///
  /// In en, this message translates to:
  /// **'Center Health'**
  String get centerHealth;

  /// No description provided for @shortage.
  ///
  /// In en, this message translates to:
  /// **'Shortage'**
  String get shortage;

  /// No description provided for @replacementRequired.
  ///
  /// In en, this message translates to:
  /// **'Replacement Required'**
  String get replacementRequired;

  /// No description provided for @emergencyReplacement.
  ///
  /// In en, this message translates to:
  /// **'Emergency Replacement'**
  String get emergencyReplacement;

  /// No description provided for @todaysDutiesCount.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Duties'**
  String get todaysDutiesCount;

  /// No description provided for @liveExamControlRoom.
  ///
  /// In en, this message translates to:
  /// **'Live Exam-Day Control Room'**
  String get liveExamControlRoom;

  /// No description provided for @liveStats.
  ///
  /// In en, this message translates to:
  /// **'Live Stats'**
  String get liveStats;

  /// No description provided for @outsideGeofenceFilter.
  ///
  /// In en, this message translates to:
  /// **'Outside Geofence'**
  String get outsideGeofenceFilter;

  /// No description provided for @callStaff.
  ///
  /// In en, this message translates to:
  /// **'Call Staff'**
  String get callStaff;

  /// No description provided for @reassignDuty.
  ///
  /// In en, this message translates to:
  /// **'Reassign Duty'**
  String get reassignDuty;

  /// No description provided for @notificationCenter.
  ///
  /// In en, this message translates to:
  /// **'Notification Center'**
  String get notificationCenter;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @dutyUpdates.
  ///
  /// In en, this message translates to:
  /// **'Duty Updates'**
  String get dutyUpdates;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All Read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsRead;

  /// No description provided for @deleteNotification.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteNotification;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @payroll.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get payroll;

  /// No description provided for @payrollRemuneration.
  ///
  /// In en, this message translates to:
  /// **'Payroll & Remuneration'**
  String get payrollRemuneration;

  /// No description provided for @totalRemunerationAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Remuneration'**
  String get totalRemunerationAmount;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @paymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment Pending'**
  String get paymentPending;

  /// No description provided for @paymentReference.
  ///
  /// In en, this message translates to:
  /// **'Payment Reference'**
  String get paymentReference;

  /// No description provided for @paymentRemarks.
  ///
  /// In en, this message translates to:
  /// **'Payment Remarks'**
  String get paymentRemarks;

  /// No description provided for @markPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark Paid'**
  String get markPaid;

  /// No description provided for @bulkPay.
  ///
  /// In en, this message translates to:
  /// **'Bulk Pay'**
  String get bulkPay;

  /// No description provided for @exportStatement.
  ///
  /// In en, this message translates to:
  /// **'Export Statement'**
  String get exportStatement;

  /// No description provided for @paymentStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Payment status updated'**
  String get paymentStatusUpdated;

  /// No description provided for @staffSummary.
  ///
  /// In en, this message translates to:
  /// **'Staff Summary'**
  String get staffSummary;

  /// No description provided for @detailedPayments.
  ///
  /// In en, this message translates to:
  /// **'Detailed Payments'**
  String get detailedPayments;

  /// No description provided for @monthSelector.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthSelector;

  /// No description provided for @masterDataManagement.
  ///
  /// In en, this message translates to:
  /// **'Master Data Management'**
  String get masterDataManagement;

  /// No description provided for @selectModuleDescription.
  ///
  /// In en, this message translates to:
  /// **'Select a module below to view, add, edit, or manage its active status.'**
  String get selectModuleDescription;

  /// No description provided for @searchModules.
  ///
  /// In en, this message translates to:
  /// **'Search modules...'**
  String get searchModules;

  /// No description provided for @esNames.
  ///
  /// In en, this message translates to:
  /// **'ES Names'**
  String get esNames;

  /// No description provided for @examNames.
  ///
  /// In en, this message translates to:
  /// **'Exam Names'**
  String get examNames;

  /// No description provided for @securityGuardNames.
  ///
  /// In en, this message translates to:
  /// **'Security Guard Names'**
  String get securityGuardNames;

  /// No description provided for @jammerNames.
  ///
  /// In en, this message translates to:
  /// **'Jammer Names'**
  String get jammerNames;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'{count} Records'**
  String records(int count);

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get addNew;

  /// No description provided for @noRecords.
  ///
  /// In en, this message translates to:
  /// **'No records found'**
  String get noRecords;

  /// No description provided for @itemAdded.
  ///
  /// In en, this message translates to:
  /// **'Item added successfully'**
  String get itemAdded;

  /// No description provided for @itemUpdated.
  ///
  /// In en, this message translates to:
  /// **'Item updated successfully'**
  String get itemUpdated;

  /// No description provided for @itemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Item deleted successfully'**
  String get itemDeleted;

  /// No description provided for @enterValue.
  ///
  /// In en, this message translates to:
  /// **'Enter value'**
  String get enterValue;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @dutyAssignedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Duty assigned successfully'**
  String get dutyAssignedSuccess;

  /// No description provided for @dutyAllocatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Duty allocated successfully'**
  String get dutyAllocatedSuccess;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get noDataFound;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @less.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @ttsExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent. You reached on time.'**
  String get ttsExcellent;

  /// No description provided for @ttsGood.
  ///
  /// In en, this message translates to:
  /// **'Good. You reached slightly late.'**
  String get ttsGood;

  /// No description provided for @ttsNeedsImprovement.
  ///
  /// In en, this message translates to:
  /// **'Needs improvement. Please reach in proper time.'**
  String get ttsNeedsImprovement;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcomeMessage;

  /// No description provided for @swapRequest.
  ///
  /// In en, this message translates to:
  /// **'Swap Request'**
  String get swapRequest;

  /// No description provided for @swapRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Swap request sent successfully'**
  String get swapRequestSent;

  /// No description provided for @swapApproved.
  ///
  /// In en, this message translates to:
  /// **'Swap approved'**
  String get swapApproved;

  /// No description provided for @swapRejected.
  ///
  /// In en, this message translates to:
  /// **'Swap rejected'**
  String get swapRejected;

  /// No description provided for @requestSwap.
  ///
  /// In en, this message translates to:
  /// **'Request Swap'**
  String get requestSwap;

  /// No description provided for @swapWith.
  ///
  /// In en, this message translates to:
  /// **'Swap With'**
  String get swapWith;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @sendReminder.
  ///
  /// In en, this message translates to:
  /// **'Send Reminder'**
  String get sendReminder;

  /// No description provided for @reminderSent.
  ///
  /// In en, this message translates to:
  /// **'Reminder sent successfully'**
  String get reminderSent;

  /// No description provided for @manualReminder.
  ///
  /// In en, this message translates to:
  /// **'Manual Reminder'**
  String get manualReminder;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInfo;

  /// No description provided for @dutyStatistics.
  ///
  /// In en, this message translates to:
  /// **'Duty Statistics'**
  String get dutyStatistics;

  /// No description provided for @mockDutyCount.
  ///
  /// In en, this message translates to:
  /// **'Mock Duty Count'**
  String get mockDutyCount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobile;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @staffReachedCount.
  ///
  /// In en, this message translates to:
  /// **'{reached} / {total} Reached'**
  String staffReachedCount(int reached, int total);

  /// No description provided for @pendingDutiesCount.
  ///
  /// In en, this message translates to:
  /// **'You have {count} pending duties.'**
  String pendingDutiesCount(int count);

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @deleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteWarning;

  /// No description provided for @operationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Operation completed successfully'**
  String get operationSuccess;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed'**
  String get operationFailed;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @checkInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get checkInternetConnection;

  /// No description provided for @capacityLabel.
  ///
  /// In en, this message translates to:
  /// **'Capacity: {capacity}'**
  String capacityLabel(int capacity);

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @remunerationAmount.
  ///
  /// In en, this message translates to:
  /// **'₹{amount}'**
  String remunerationAmount(String amount);

  /// No description provided for @dutyAllocations.
  ///
  /// In en, this message translates to:
  /// **'Duty Allocations'**
  String get dutyAllocations;

  /// No description provided for @examSessions.
  ///
  /// In en, this message translates to:
  /// **'Exam Sessions'**
  String get examSessions;

  /// No description provided for @sendEmailReport.
  ///
  /// In en, this message translates to:
  /// **'Send Email Report'**
  String get sendEmailReport;

  /// No description provided for @emailSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email sent successfully'**
  String get emailSentSuccess;

  /// No description provided for @emailSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send email'**
  String get emailSendFailed;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not Selected'**
  String get notSelected;

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose Date'**
  String get chooseDate;

  /// No description provided for @chooseDateRange.
  ///
  /// In en, this message translates to:
  /// **'Choose Date Range'**
  String get chooseDateRange;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// No description provided for @typeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type to search...'**
  String get typeToSearch;

  /// No description provided for @staffDetails.
  ///
  /// In en, this message translates to:
  /// **'Staff Details'**
  String get staffDetails;

  /// No description provided for @centerDetails.
  ///
  /// In en, this message translates to:
  /// **'Center Details'**
  String get centerDetails;

  /// No description provided for @dutyInfo.
  ///
  /// In en, this message translates to:
  /// **'Duty Info'**
  String get dutyInfo;

  /// No description provided for @examInfo.
  ///
  /// In en, this message translates to:
  /// **'Exam Info'**
  String get examInfo;

  /// No description provided for @maintenanceData.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Data'**
  String get maintenanceData;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @contactStaff.
  ///
  /// In en, this message translates to:
  /// **'Contact Staff'**
  String get contactStaff;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @noActionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No actions available'**
  String get noActionsAvailable;

  /// No description provided for @geofenceVerification.
  ///
  /// In en, this message translates to:
  /// **'Geofence & GPS Verification'**
  String get geofenceVerification;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @statsAtGlance.
  ///
  /// In en, this message translates to:
  /// **'Statistics at a Glance'**
  String get statsAtGlance;

  /// No description provided for @invigilators.
  ///
  /// In en, this message translates to:
  /// **'Invigilators'**
  String get invigilators;

  /// No description provided for @swapRequests.
  ///
  /// In en, this message translates to:
  /// **'Swap Requests'**
  String get swapRequests;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get late;

  /// No description provided for @invigilatorDirectory.
  ///
  /// In en, this message translates to:
  /// **'Invigilator Directory'**
  String get invigilatorDirectory;

  /// No description provided for @maintainData.
  ///
  /// In en, this message translates to:
  /// **'Maintain Data'**
  String get maintainData;

  /// No description provided for @securityGuardRecords.
  ///
  /// In en, this message translates to:
  /// **'Security Guard Records'**
  String get securityGuardRecords;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @clickDateToToggle.
  ///
  /// In en, this message translates to:
  /// **'Tap any date to mark or unmark your leave/unavailability.'**
  String get clickDateToToggle;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @invigilator.
  ///
  /// In en, this message translates to:
  /// **'Invigilator'**
  String get invigilator;

  /// No description provided for @labStaff.
  ///
  /// In en, this message translates to:
  /// **'Lab Staff'**
  String get labStaff;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'gu':
      return SGu();
    case 'hi':
      return SHi();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
