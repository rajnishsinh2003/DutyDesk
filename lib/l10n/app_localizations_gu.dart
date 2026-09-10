// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class SGu extends S {
  SGu([String locale = 'gu']) : super(locale);

  @override
  String get appName => 'DutyDesk';

  @override
  String get appSubtitle => 'પરીક્ષા નિરીક્ષણ અને સ્ટાફ વ્યવસ્થાપન પ્રણાલી';

  @override
  String get examInvigilationManagement => 'પરીક્ષા નિરીક્ષણ વ્યવસ્થાપન';

  @override
  String get login => 'લૉગિન';

  @override
  String get logout => 'લૉગઆઉટ';

  @override
  String get staffInvigilator => 'સ્ટાફ / સુપરવાઇઝર';

  @override
  String get administrator => 'એડમિનિસ્ટ્રેટર';

  @override
  String get adminUsernameOrEmail => 'એડમિન યુઝરનેમ અથવા ઇમેઇલ';

  @override
  String get registeredMobileNumber => 'નોંધાયેલ મોબાઇલ નંબર';

  @override
  String get hintAdminEmail => 'દા.ત. admin@dutydesk.com';

  @override
  String get hintMobileNumber => 'દા.ત. 9876543210';

  @override
  String get password => 'પાસવર્ડ';

  @override
  String get resourceIdPassword => 'રિસોર્સ ID (પાસવર્ડ)';

  @override
  String get hintAdminPassword => 'એડમિન પાસવર્ડ દાખલ કરો';

  @override
  String get hintResourceId => 'દા.ત. RES101 / સ્ટાફ ID';

  @override
  String get signInAsAdmin => 'એડમિન તરીકે સાઇન ઇન કરો';

  @override
  String get signInAsStaff => 'સ્ટાફ તરીકે સાઇન ઇન કરો';

  @override
  String get adminLoginHint =>
      'એડમિન: તમારા વહીવટી ઇમેઇલ અને મુખ્ય પાસવર્ડનો ઉપયોગ કરો.';

  @override
  String get staffLoginHint =>
      'સ્ટાફ: તમારા નોંધાયેલા મોબાઇલ નંબર અને ફાળવેલ રિસોર્સ ID નો ઉપયોગ કરો.';

  @override
  String get pleaseEnterAdminCredentials =>
      'કૃપા કરીને એડમિન ઓળખપત્રો દાખલ કરો';

  @override
  String get pleaseEnterMobileAndResourceId =>
      'કૃપા કરીને મોબાઇલ નંબર અને રિસોર્સ ID દાખલ કરો';

  @override
  String get invalidMobileOrResourceId => 'અમાન્ય મોબાઇલ નંબર અથવા રિસોર્સ ID';

  @override
  String get firebaseNotInitialized =>
      'Firebase શરૂ થયું નથી. કૃપા કરીને ઇન્ટરનેટ કનેક્શન અથવા રૂપરેખાંકન તપાસો.';

  @override
  String get authenticationFailed => 'ઓળખ પ્રમાણીકરણ નિષ્ફળ થયું';

  @override
  String get confirmLogout => 'લૉગઆઉટની પુષ્ટિ કરો';

  @override
  String get confirmLogoutMessage => 'શું તમે ખરેખર લૉગઆઉટ કરવા માંગો છો?';

  @override
  String get cancel => 'રદ કરો';

  @override
  String get dashboard => 'ડેશબોર્ડ';

  @override
  String get adminDashboard => 'એડમિન ડેશબોર્ડ';

  @override
  String get totalStaff => 'કુલ સ્ટાફ';

  @override
  String get totalCenters => 'કુલ કેન્દ્રો';

  @override
  String get activeSessions => 'સક્રિય સત્રો';

  @override
  String get todaysDuties => 'આજની ડ્યુટી';

  @override
  String get totalRemuneration => 'કુલ મહેનતાણું';

  @override
  String get liveMonitoring => 'લાઇવ મોનિટરિંગ';

  @override
  String get arrivalStatus => 'આગમન સ્થિતિ';

  @override
  String get excellent => 'ઉત્તમ';

  @override
  String get good => 'સારું';

  @override
  String get onTime => 'સમયસર';

  @override
  String get slightlyLate => 'થોડું મોડું';

  @override
  String get needsImprovement => 'સુધારણા જરૂરી';

  @override
  String get quickActions => 'ઝડપી ક્રિયાઓ';

  @override
  String get manageStaff => 'સ્ટાફ મેનેજ કરો';

  @override
  String get manageCenters => 'કેન્દ્રો મેનેજ કરો';

  @override
  String get allocateDuty => 'ડ્યુટી ફાળવો';

  @override
  String get reports => 'રિપોર્ટ્સ';

  @override
  String get settings => 'સેટિંગ્સ';

  @override
  String get masterData => 'માસ્ટર ડેટા';

  @override
  String get globalSearch => 'વૈશ્વિક શોધ';

  @override
  String get liveControlRoom => 'લાઇવ કંટ્રોલ રૂમ';

  @override
  String get payrollSalary => 'પગાર અને મહેનતાણું';

  @override
  String get todaysExams => 'આજની પરીક્ષાઓ';

  @override
  String get noExamsToday => 'આજે કોઈ પરીક્ષા સુનિશ્ચિત નથી';

  @override
  String get viewAll => 'બધા જુઓ';

  @override
  String get viewDetails => 'વિગતો જુઓ';

  @override
  String get recentAllocations => 'તાજેતરની ફાળવણી';

  @override
  String get noAllocations => 'કોઈ ફાળવણી મળી નથી';

  @override
  String get exportAllAllocations => 'બધી ફાળવણી એક્સપોર્ટ કરો';

  @override
  String exportingRecords(int count) {
    return '$count ફાળવણી રેકોર્ડ્સ એક્સપોર્ટ થઈ રહ્યા છે.';
  }

  @override
  String get exportAsPdf => 'PDF તરીકે એક્સપોર્ટ કરો';

  @override
  String get exportAsExcel => 'Excel તરીકે એક્સપોર્ટ કરો';

  @override
  String pdfError(String error) {
    return 'PDF ભૂલ: $error';
  }

  @override
  String excelError(String error) {
    return 'Excel ભૂલ: $error';
  }

  @override
  String get allAllocations => 'બધી ફાળવણીઓ';

  @override
  String get dashboardFiltered => 'ડેશબોર્ડ ફિલ્ટર કરેલ';

  @override
  String get staff => 'સ્ટાફ';

  @override
  String get addStaff => 'સ્ટાફ ઉમેરો';

  @override
  String get editStaff => 'સ્ટાફ સંપાદિત કરો';

  @override
  String get deleteStaff => 'સ્ટાફ કાઢી નાખો';

  @override
  String get search => 'શોધો';

  @override
  String get searchStaff => 'સ્ટાફ શોધો...';

  @override
  String get fullName => 'પૂરું નામ';

  @override
  String get mobileNumber => 'મોબાઇલ નંબર';

  @override
  String get mobileNumberUsername => 'મોબાઇલ નંબર (યુઝરનેમ)';

  @override
  String get resourceId => 'રિસોર્સ ID';

  @override
  String get emailAddress => 'ઇમેઇલ સરનામું';

  @override
  String get address => 'સરનામું';

  @override
  String get active => 'સક્રિય';

  @override
  String get blocked => 'અવરોધિત';

  @override
  String get available => 'ઉપલબ્ધ';

  @override
  String get unavailable => 'અનુપલબ્ધ';

  @override
  String get leave => 'રજા';

  @override
  String get save => 'સાચવો';

  @override
  String get update => 'અપડેટ કરો';

  @override
  String get confirm => 'પુષ્ટિ કરો';

  @override
  String get delete => 'કાઢી નાખો';

  @override
  String get edit => 'સંપાદિત કરો';

  @override
  String get add => 'ઉમેરો';

  @override
  String get personalDetails => 'વ્યક્તિગત વિગતો';

  @override
  String get contactAndCredentials => 'સંપર્ક અને લૉગિન ઓળખપત્રો';

  @override
  String get addInvigilator => 'સુપરવાઇઝર ઉમેરો';

  @override
  String get editInvigilator => 'સુપરવાઇઝર સંપાદિત કરો';

  @override
  String get saveInvigilator => 'સુપરવાઇઝર સાચવો';

  @override
  String get updateInvigilator => 'સુપરવાઇઝર અપડેટ કરો';

  @override
  String get invigilatorAddedSuccess => 'સુપરવાઇઝર સફળતાપૂર્વક ઉમેરાયા!';

  @override
  String get invigilatorUpdated => 'સુપરવાઇઝર અપડેટ થયા!';

  @override
  String get manageInvigilators => 'સુપરવાઇઝર મેનેજ કરો';

  @override
  String get noInvigilatorsFound => 'કોઈ સુપરવાઇઝર મળ્યા નથી';

  @override
  String get totalInvigilators => 'કુલ સુપરવાઇઝર';

  @override
  String get deleteInvigilator => 'સુપરવાઇઝર કાઢી નાખો';

  @override
  String deleteInvigilatorConfirm(String name) {
    return 'શું તમે ખરેખર $name ને કાઢી નાખવા માંગો છો?';
  }

  @override
  String get invigilatorProfile => 'સુપરવાઇઝર પ્રોફાઇલ';

  @override
  String get dutyHistory => 'ડ્યુટી ઇતિહાસ';

  @override
  String get performance => 'કામગીરી';

  @override
  String get totalDutiesAssigned => 'કુલ સોંપાયેલ ડ્યુટી';

  @override
  String get dutiesCompleted => 'પૂર્ણ થયેલ ડ્યુટી';

  @override
  String get dutiesPending => 'બાકી ડ્યુટી';

  @override
  String get attendanceRate => 'હાજરી દર';

  @override
  String get availabilityCalendar => 'ઉપલબ્ધતા કૅલેન્ડર';

  @override
  String get markAvailable => 'ઉપલબ્ધ ચિહ્નિત કરો';

  @override
  String get markUnavailable => 'અનુપલબ્ધ ચિહ્નિત કરો';

  @override
  String get markLeave => 'રજા ચિહ્નિત કરો';

  @override
  String get noDataAvailable => 'કોઈ ડેટા ઉપલબ્ધ નથી';

  @override
  String get exams => 'પરીક્ષાઓ';

  @override
  String get registeredExams => 'નોંધાયેલ પરીક્ષાઓ';

  @override
  String get registerNewExam => 'નવી પરીક્ષા નોંધો';

  @override
  String get registerExam => 'પરીક્ષા નોંધો';

  @override
  String get examName => 'પરીક્ષાનું નામ';

  @override
  String get examDate => 'પરીક્ષા તારીખ';

  @override
  String get examCenter => 'પરીક્ષા કેન્દ્ર';

  @override
  String get session => 'સત્ર';

  @override
  String get newExam => 'નવી પરીક્ષા';

  @override
  String get noRegisteredExams =>
      'કોઈ નોંધાયેલ પરીક્ષા મળી નથી. ડ્યુટી ફાળવવા માટે એક બનાવો.';

  @override
  String get selectCenter => 'કેન્દ્ર પસંદ કરો';

  @override
  String get required => 'જરૂરી';

  @override
  String get selectDate => 'તારીખ પસંદ કરો';

  @override
  String get selectShift => 'શિફ્ટ પસંદ કરો';

  @override
  String get shift1 => 'શિફ્ટ 1';

  @override
  String get shift2 => 'શિફ્ટ 2';

  @override
  String get shift3 => 'શિફ્ટ 3';

  @override
  String get selectInvigilators => 'સુપરવાઇઝર પસંદ કરો';

  @override
  String get selectedInvigilators => 'પસંદ કરેલ સુપરવાઇઝર';

  @override
  String get assign => 'ફાળવો';

  @override
  String get assignDuty => 'ડ્યુટી ફાળવો';

  @override
  String get conflictDetected => 'વિસંગતતા જણાઈ';

  @override
  String get overrideAction => 'ઓવરરાઇડ';

  @override
  String get recommendedStaff => 'ભલામણ કરેલ સ્ટાફ';

  @override
  String get reassign => 'ફરીથી ફાળવો';

  @override
  String get swapDuty => 'ડ્યુટી બદલો';

  @override
  String get replacement => 'બદલી સ્ટાફ';

  @override
  String get confirmAssignment => 'ફાળવણીની પુષ્ટિ કરો';

  @override
  String get dutyAllocation => 'ડ્યુટી ફાળવણી';

  @override
  String get shiftRemuneration => 'શિફ્ટ મહેનતાણું';

  @override
  String shift1Amount(int amount) {
    return 'શિફ્ટ 1 — ₹$amount';
  }

  @override
  String shift2Amount(int amount) {
    return 'શિફ્ટ 2 — ₹$amount';
  }

  @override
  String shift3Amount(int amount) {
    return 'શિફ્ટ 3 — ₹$amount';
  }

  @override
  String get myDuties => 'મારી ડ્યુટી';

  @override
  String get myProfile => 'મારી પ્રોફાઇલ';

  @override
  String get availability => 'ઉપલબ્ધતા';

  @override
  String get calendar => 'કૅલેન્ડર';

  @override
  String get assignedDuty => 'સોંપાયેલ ડ્યુટી';

  @override
  String get accept => 'સ્વીકારો';

  @override
  String get reject => 'નકારો';

  @override
  String get dutyDetails => 'ડ્યુટી વિગતો';

  @override
  String get reportingTime => 'રિપોર્ટિંગ સમય';

  @override
  String get remuneration => 'મહેનતાણું';

  @override
  String get invigilatorDashboard => 'સુપરવાઇઝર ડેશબોર્ડ';

  @override
  String get noDutiesAssigned => 'હજુ સુધી કોઈ ડ્યુટી સોંપાઈ નથી';

  @override
  String get upcomingDuties => 'આગામી ડ્યુટી';

  @override
  String get pastDuties => 'ભૂતકાળની ડ્યુટી';

  @override
  String get dutyAccepted => 'ડ્યુટી સ્વીકારાઈ';

  @override
  String get dutyRejected => 'ડ્યુટી નકારાઈ';

  @override
  String get dutySwapped => 'ડ્યુટી સફળતાપૂર્વક બદલાઈ';

  @override
  String get currentDuty => 'વર્તમાન ડ્યુટી';

  @override
  String get reached => 'પહોંચી ગયા';

  @override
  String get arrival => 'આગમન';

  @override
  String get arrivalTime => 'આગમન સમય';

  @override
  String get location => 'સ્થાન';

  @override
  String get gps => 'GPS';

  @override
  String get locationVerified => 'સ્થાન ચકાસાયેલ';

  @override
  String get outsideCenter => 'કેન્દ્ર બહાર';

  @override
  String get distanceFromCenter => 'કેન્દ્રથી અંતર';

  @override
  String get arrivalRecorded => 'આગમન નોંધાયું';

  @override
  String get waitingForInternet => 'ઇન્ટરનેટની રાહ જુઓ';

  @override
  String get arrivalSyncedSuccessfully => 'આગમન સફળતાપૂર્વક સિંક થયું';

  @override
  String get youReachedOnTime => 'તમે સમયસર પહોંચી ગયા છો.';

  @override
  String get youReachedSlightlyLate => 'તમે થોડા મોડા પહોંચ્યા છો.';

  @override
  String get reachInProperTime => 'કૃપા કરીને યોગ્ય સમયે પહોંચો.';

  @override
  String get geofenceVerified => '✓ જીઓફેન્સ ચકાસાયેલ';

  @override
  String get outsideGeofence => '⚠ જીઓફેન્સ બહાર';

  @override
  String get tryAgain => 'ફરી પ્રયાસ કરો';

  @override
  String get requestManualVerification => 'મેન્યુઅલ ચકાસણીની વિનંતી કરો';

  @override
  String get outsideGeofenceWarning =>
      'તમે પરીક્ષા કેન્દ્ર વિસ્તારની બહાર હોવાનું જણાય છે.';

  @override
  String distanceMeters(String distance) {
    return 'કેન્દ્રથી $distanceમી';
  }

  @override
  String get dateRange => 'તારીખ શ્રેણી';

  @override
  String get status => 'સ્થિતિ';

  @override
  String get accepted => 'સ્વીકૃત';

  @override
  String get pending => 'બાકી';

  @override
  String get rejected => 'નકારેલ';

  @override
  String get completed => 'પૂર્ણ';

  @override
  String get totalDuties => 'કુલ ડ્યુટી';

  @override
  String get exportPdf => 'PDF એક્સપોર્ટ';

  @override
  String get exportExcel => 'Excel એક્સપોર્ટ';

  @override
  String get download => 'ડાઉનલોડ';

  @override
  String get generateReport => 'રિપોર્ટ બનાવો';

  @override
  String get noReportsFound => 'કોઈ રિપોર્ટ મળ્યો નથી';

  @override
  String get reportGenerated => 'રિપોર્ટ સફળતાપૂર્વક બન્યો';

  @override
  String get center => 'કેન્દ્ર';

  @override
  String get shift => 'શિફ્ટ';

  @override
  String get all => 'બધા';

  @override
  String get filterByStatus => 'સ્થિતિ મુજબ ફિલ્ટર કરો';

  @override
  String get filterByCenter => 'કેન્દ્ર મુજબ ફિલ્ટર કરો';

  @override
  String get filterByShift => 'શિફ્ટ મુજબ ફિલ્ટર કરો';

  @override
  String get language => 'ભાષા';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिन्दी';

  @override
  String get gujarati => 'ગુજરાતી';

  @override
  String get languageChangedSuccess => 'ભાષા સફળતાપૂર્વક બદલાઈ ગઈ છે';

  @override
  String get selectLanguage => 'ભાષા પસંદ કરો';

  @override
  String get lunchProvision => 'બપોરના ભોજનની જોગવાઈ';

  @override
  String get reportingTimeLabel => 'રિપોર્ટિંગ સમય';

  @override
  String get arrivalThreshold => 'આગમન મર્યાદા';

  @override
  String get voiceFeedback => 'વૉઇસ પ્રતિસાદ';

  @override
  String get notifications => 'સૂચનાઓ';

  @override
  String get darkMode => 'ડાર્ક મોડ';

  @override
  String get lightMode => 'લાઇટ મોડ';

  @override
  String get saveChanges => 'ફેરફારો સાચવો';

  @override
  String get settingsSaved => 'સેટિંગ્સ સફળતાપૂર્વક સચવાઈ';

  @override
  String get dutySettings => 'ડ્યુટી સેટિંગ્સ';

  @override
  String get centers => 'કેન્દ્રો';

  @override
  String get addCenter => 'કેન્દ્ર ઉમેરો';

  @override
  String get editCenter => 'કેન્દ્ર સંપાદિત કરો';

  @override
  String get deleteCenter => 'કેન્દ્ર કાઢી નાખો';

  @override
  String get centerName => 'કેન્દ્રનું નામ';

  @override
  String get locationCity => 'સ્થાન / શહેર';

  @override
  String get capacity => 'ક્ષમતા';

  @override
  String get saveCenter => 'કેન્દ્ર સાચવો';

  @override
  String get updateCenter => 'કેન્દ્ર અપડેટ કરો';

  @override
  String get centerAddedSuccess => 'કેન્દ્ર સફળતાપૂર્વક ઉમેરાયું!';

  @override
  String get centerUpdated => 'કેન્દ્ર અપડેટ થયું!';

  @override
  String get noCentersFound => 'કોઈ કેન્દ્ર મળ્યું નથી. એક ઉમેરો!';

  @override
  String deleteCenterConfirm(String name) {
    return 'શું તમે ખરેખર $name ને કાઢી નાખવા માંગો છો?';
  }

  @override
  String get geofenceGpsVerification => 'જીઓફેન્સ અને GPS ચકાસણી';

  @override
  String get useCurrentGps => 'વર્તમાન GPS વાપરો';

  @override
  String get latitude => 'અક્ષાંશ';

  @override
  String get longitude => 'રેખાંશ';

  @override
  String get allowedArrivalRadius => 'માન્ય આગમન ત્રિજ્યા (મીટર)';

  @override
  String get geofenceHelperText =>
      'આ ત્રિજ્યાની અંદરના સ્ટાફને \"પહોંચ્યા અને ચકાસાયેલ\" ચિહ્નિત કરવામાં આવશે';

  @override
  String get capturedGpsLocation => '✓ વર્તમાન GPS સ્થાન મેળવ્યું!';

  @override
  String get couldNotAcquireGps => 'GPS સ્થાન મેળવી શકાયું નથી';

  @override
  String get noGpsGeofenceConfigured => 'કોઈ GPS જીઓફેન્સ ગોઠવેલ નથી';

  @override
  String get reachedCount => 'પહોંચ્યા';

  @override
  String get pendingCount => 'બાકી';

  @override
  String get lateCount => 'મોડા';

  @override
  String get absentCount => 'ગેરહાજર';

  @override
  String get centerHealth => 'કેન્દ્ર સ્થિતિ';

  @override
  String get shortage => 'અછત';

  @override
  String get replacementRequired => 'બદલી જરૂરી';

  @override
  String get emergencyReplacement => 'ઇમરજન્સી બદલી સ્ટાફ';

  @override
  String get todaysDutiesCount => 'આજની ડ્યુટી';

  @override
  String get liveExamControlRoom => 'લાઇવ પરીક્ષા કંટ્રોલ રૂમ';

  @override
  String get liveStats => 'લાઇવ આંકડા';

  @override
  String get outsideGeofenceFilter => 'જીઓફેન્સ બહાર';

  @override
  String get callStaff => 'સ્ટાફને કૉલ કરો';

  @override
  String get reassignDuty => 'ડ્યુટી ફરીથી સોંપો';

  @override
  String get notificationCenter => 'સૂચના કેન્દ્ર';

  @override
  String get unread => 'વણવાંચેલ';

  @override
  String get dutyUpdates => 'ડ્યુટી અપડેટ્સ';

  @override
  String get alerts => 'ચેતવણીઓ';

  @override
  String get markAllRead => 'બધા વંચાયેલ ચિહ્નિત કરો';

  @override
  String get noNotifications => 'કોઈ સૂચનાઓ નથી';

  @override
  String get markAsRead => 'વંચાયેલ ચિહ્નિત કરો';

  @override
  String get deleteNotification => 'કાઢી નાખો';

  @override
  String minutesAgo(int minutes) {
    return '$minutesમિ પહેલાં';
  }

  @override
  String hoursAgo(int hours) {
    return '$hoursક કલાક પહેલાં';
  }

  @override
  String get justNow => 'હમણાં જ';

  @override
  String get payroll => 'પગાર પત્રક';

  @override
  String get payrollRemuneration => 'પગાર અને મહેનતાણું';

  @override
  String get totalRemunerationAmount => 'કુલ મહેનતાણું';

  @override
  String get approved => 'મંજૂર';

  @override
  String get paid => 'ચૂકવેલ';

  @override
  String get paymentPending => 'ચુકવણી બાકી';

  @override
  String get paymentReference => 'ચુકવણી સંદર્ભ';

  @override
  String get paymentRemarks => 'ચુકવણી નોંધ';

  @override
  String get markPaid => 'ચૂકવેલ ચિહ્નિત કરો';

  @override
  String get bulkPay => 'જથ્થાબંધ ચુકવણી';

  @override
  String get exportStatement => 'સ્ટેટમેન્ટ એક્સપોર્ટ કરો';

  @override
  String get paymentStatusUpdated => 'ચુકવણી સ્થિતિ અપડેટ થઈ';

  @override
  String get staffSummary => 'સ્ટાફ સારાંશ';

  @override
  String get detailedPayments => 'વિગતવાર ચુકવણીઓ';

  @override
  String get monthSelector => 'મહિનો';

  @override
  String get masterDataManagement => 'માસ્ટર ડેટા વ્યવસ્થાપન';

  @override
  String get selectModuleDescription =>
      'જોવા, ઉમેરવા, સંપાદિત કરવા અથવા મેનેજ કરવા માટે નીચે એક મોડ્યુલ પસંદ કરો.';

  @override
  String get searchModules => 'મોડ્યુલ શોધો...';

  @override
  String get esNames => 'ES નામો';

  @override
  String get examNames => 'પરીક્ષા નામો';

  @override
  String get securityGuardNames => 'સિક્યુરિટી ગાર્ડ નામો';

  @override
  String get jammerNames => 'જેમર નામો';

  @override
  String get users => 'વપરાશકર્તાઓ';

  @override
  String records(int count) {
    return '$count રેકોર્ડ્સ';
  }

  @override
  String get addNew => 'નવું ઉમેરો';

  @override
  String get noRecords => 'કોઈ રેકોર્ડ મળ્યા નથી';

  @override
  String get itemAdded => 'વસ્તુ સફળતાપૂર્વક ઉમેરાઈ';

  @override
  String get itemUpdated => 'વસ્તુ સફળતાપૂર્વક અપડેટ થઈ';

  @override
  String get itemDeleted => 'વસ્તુ સફળતાપૂર્વક કાઢી નાખવામાં આવી';

  @override
  String get enterValue => 'મૂલ્ય દાખલ કરો';

  @override
  String get name => 'નામ';

  @override
  String get value => 'મૂલ્ય';

  @override
  String get dutyAssignedSuccess => 'ડ્યુટી સફળતાપૂર્વક ફાળવવામાં આવી';

  @override
  String get dutyAllocatedSuccess => 'ડ્યુટી સફળતાપૂર્વક ફાળવાઈ';

  @override
  String get errorOccurred => 'એક ભૂલ આવી';

  @override
  String get success => 'સફળ';

  @override
  String get error => 'ભૂલ';

  @override
  String get loading => 'લોડ થઈ રહ્યું છે...';

  @override
  String get noDataFound => 'કોઈ ડેટા મળ્યો નથી';

  @override
  String get retry => 'ફરી પ્રયાસ કરો';

  @override
  String get close => 'બંધ કરો';

  @override
  String get ok => 'બરાબર';

  @override
  String get yes => 'હા';

  @override
  String get no => 'ના';

  @override
  String get back => 'પાછા';

  @override
  String get next => 'આગળ';

  @override
  String get done => 'થઈ ગયું';

  @override
  String get submit => 'સબમિટ કરો';

  @override
  String get clear => 'સાફ કરો';

  @override
  String get reset => 'રીસેટ કરો';

  @override
  String get refresh => 'રીફ્રેશ';

  @override
  String get more => 'વધુ';

  @override
  String get less => 'ઓછું';

  @override
  String get seeAll => 'બધા જુઓ';

  @override
  String get ttsExcellent => 'ઉત્તમ. તમે સમયસર પહોંચી ગયા છો.';

  @override
  String get ttsGood => 'સારું. તમે થોડા મોડા પહોંચ્યા છો.';

  @override
  String get ttsNeedsImprovement =>
      'સુધારણા જરૂરી. કૃપા કરીને યોગ્ય સમયે પહોંચો.';

  @override
  String get welcomeMessage => 'સ્વાગત છે!';

  @override
  String get swapRequest => 'બદલી વિનંતી';

  @override
  String get swapRequestSent => 'બદલી વિનંતી સફળતાપૂર્વક મોકલાઈ';

  @override
  String get swapApproved => 'બદલી મંજૂર થઈ';

  @override
  String get swapRejected => 'બદલી નકારાઈ';

  @override
  String get requestSwap => 'બદલી માટે વિનંતી કરો';

  @override
  String get swapWith => 'સાથે બદલો';

  @override
  String get reason => 'કારણ';

  @override
  String get sendReminder => 'રીમાઇન્ડર મોકલો';

  @override
  String get reminderSent => 'રીમાઇન્ડર સફળતાપૂર્વક મોકલાયું';

  @override
  String get manualReminder => 'મેન્યુઅલ રીમાઇન્ડર';

  @override
  String get profile => 'પ્રોફાઇલ';

  @override
  String get personalInfo => 'વ્યક્તિગત માહિતી';

  @override
  String get contactInfo => 'સંપર્ક માહિતી';

  @override
  String get dutyStatistics => 'ડ્યુટી આંકડા';

  @override
  String get mockDutyCount => 'મૉક ડ્યુટી ગણતરી';

  @override
  String get email => 'ઇમેઇલ';

  @override
  String get phone => 'ફોન';

  @override
  String get mobile => 'મોબાઇલ';

  @override
  String get today => 'આજે';

  @override
  String get yesterday => 'ગઈકાલે';

  @override
  String get tomorrow => 'આવતીકાલે';

  @override
  String get thisWeek => 'આ અઠવાડિયે';

  @override
  String get thisMonth => 'આ મહિને';

  @override
  String get from => 'થી';

  @override
  String get to => 'સુધી';

  @override
  String get date => 'તારીખ';

  @override
  String get time => 'સમય';

  @override
  String get startDate => 'શરૂઆત તારીખ';

  @override
  String get endDate => 'અંતિમ તારીખ';

  @override
  String staffReachedCount(int reached, int total) {
    return '$reached / $total પહોંચ્યા';
  }

  @override
  String pendingDutiesCount(int count) {
    return 'તમારી $count ડ્યુટી બાકી છે.';
  }

  @override
  String get confirmDelete => 'કાઢી નાખવાની પુષ્ટિ કરો';

  @override
  String get deleteWarning => 'આ ક્રિયા પૂર્વવત્ કરી શકાતી નથી.';

  @override
  String get operationSuccess => 'ઓપરેશન સફળતાપૂર્વક પૂર્ણ થયું';

  @override
  String get operationFailed => 'ઓપરેશન નિષ્ફળ ગયું';

  @override
  String get noInternetConnection => 'ઇન્ટરનેટ કનેક્શન નથી';

  @override
  String get checkInternetConnection =>
      'કૃપા કરીને તમારું ઇન્ટરનેટ કનેક્શન તપાસો અને ફરી પ્રયાસ કરો.';

  @override
  String capacityLabel(int capacity) {
    return 'ક્ષમતા: $capacity';
  }

  @override
  String selectedCount(int count) {
    return '$count પસંદ કરેલ';
  }

  @override
  String remunerationAmount(String amount) {
    return '₹$amount';
  }

  @override
  String get dutyAllocations => 'ડ્યુટી ફાળવણી';

  @override
  String get examSessions => 'પરીક્ષા સત્રો';

  @override
  String get sendEmailReport => 'ઇમેઇલ રિપોર્ટ મોકલો';

  @override
  String get emailSentSuccess => 'ઇમેઇલ સફળતાપૂર્વક મોકલાયો';

  @override
  String get emailSendFailed => 'ઇમેઇલ મોકલવામાં નિષ્ફળ';

  @override
  String get selectAll => 'બધા પસંદ કરો';

  @override
  String get deselectAll => 'બધા નાપસંદ કરો';

  @override
  String get selected => 'પસંદ કરેલ';

  @override
  String get notSelected => 'પસંદ કરેલ નથી';

  @override
  String get chooseDate => 'તારીખ પસંદ કરો';

  @override
  String get chooseDateRange => 'તારીખ શ્રેણી પસંદ કરો';

  @override
  String get noResultsFound => 'કોઈ પરિણામ મળ્યા નથી';

  @override
  String get searchResults => 'શોધ પરિણામો';

  @override
  String get typeToSearch => 'શોધવા માટે ટાઇપ કરો...';

  @override
  String get staffDetails => 'સ્ટાફ વિગતો';

  @override
  String get centerDetails => 'કેન્દ્ર વિગતો';

  @override
  String get dutyInfo => 'ડ્યુટી માહિતી';

  @override
  String get examInfo => 'પરીક્ષા માહિતી';

  @override
  String get maintenanceData => 'જાળવણી ડેટા';

  @override
  String get viewProfile => 'પ્રોફાઇલ જુઓ';

  @override
  String get contactStaff => 'સ્ટાફનો સંપર્ક કરો';

  @override
  String get actions => 'ક્રિયાઓ';

  @override
  String get noActionsAvailable => 'કોઈ ક્રિયા ઉપલબ્ધ નથી';

  @override
  String get geofenceVerification => 'જિયોફેન્સ અને GPS ચકાસણી';

  @override
  String get welcome => 'સ્વાગત';

  @override
  String get statsAtGlance => 'આંકડા એક નજરમાં';

  @override
  String get invigilators => 'નિરીક્ષક';

  @override
  String get swapRequests => 'ડ્યુટી બદલાવ વિનંતી';

  @override
  String get approve => 'મંજૂર કરો';

  @override
  String get late => 'મોડું';

  @override
  String get invigilatorDirectory => 'નિરીક્ષક ડિરેક્ટરી';

  @override
  String get maintainData => 'ડેટા જાળવણી';

  @override
  String get securityGuardRecords => 'સુરક્ષા ગાર્ડ રેકોર્ડ્સ';

  @override
  String get home => 'મુખ્ય પૃષ્ઠ';

  @override
  String get clickDateToToggle =>
      'તમારી રજા ચિહ્નિત કરવા અથવા દૂર કરવા માટે કોઈપણ તારીખ પર ટેપ કરો.';

  @override
  String get inactive => 'નિષ્ક્રિય';

  @override
  String get invigilator => 'નિરીક્ષક';

  @override
  String get labStaff => 'લેબ સ્ટાફ';
}
