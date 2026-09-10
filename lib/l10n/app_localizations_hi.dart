// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class SHi extends S {
  SHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'DutyDesk';

  @override
  String get appSubtitle => 'परीक्षा निरीक्षण एवं स्टाफ प्रबंधन प्रणाली';

  @override
  String get examInvigilationManagement => 'परीक्षा निरीक्षण प्रबंधन';

  @override
  String get login => 'लॉगिन';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get staffInvigilator => 'स्टाफ / निरीक्षक';

  @override
  String get administrator => 'प्रशासक';

  @override
  String get adminUsernameOrEmail => 'एडमिन यूज़रनेम या ईमेल';

  @override
  String get registeredMobileNumber => 'पंजीकृत मोबाइल नंबर';

  @override
  String get hintAdminEmail => 'जैसे admin@dutydesk.com';

  @override
  String get hintMobileNumber => 'जैसे 9876543210';

  @override
  String get password => 'पासवर्ड';

  @override
  String get resourceIdPassword => 'रिसोर्स ID (पासवर्ड)';

  @override
  String get hintAdminPassword => 'एडमिन पासवर्ड दर्ज करें';

  @override
  String get hintResourceId => 'जैसे RES101 / स्टाफ ID';

  @override
  String get signInAsAdmin => 'एडमिन के रूप में साइन इन करें';

  @override
  String get signInAsStaff => 'स्टाफ के रूप में साइन इन करें';

  @override
  String get adminLoginHint =>
      'एडमिन: अपना प्रशासनिक ईमेल और मास्टर पासवर्ड उपयोग करें।';

  @override
  String get staffLoginHint =>
      'स्टाफ: अपना पंजीकृत मोबाइल नंबर और आवंटित रिसोर्स ID उपयोग करें।';

  @override
  String get pleaseEnterAdminCredentials => 'कृपया एडमिन क्रेडेंशियल दर्ज करें';

  @override
  String get pleaseEnterMobileAndResourceId =>
      'कृपया मोबाइल नंबर और रिसोर्स ID दर्ज करें';

  @override
  String get invalidMobileOrResourceId => 'अमान्य मोबाइल नंबर या रिसोर्स ID';

  @override
  String get firebaseNotInitialized =>
      'Firebase इनिशियलाइज़ नहीं हुआ। कृपया इंटरनेट कनेक्शन या कॉन्फ़िगरेशन जाँचें।';

  @override
  String get authenticationFailed => 'प्रमाणीकरण विफल';

  @override
  String get confirmLogout => 'लॉगआउट की पुष्टि करें';

  @override
  String get confirmLogoutMessage => 'क्या आप वाकई लॉगआउट करना चाहते हैं?';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get adminDashboard => 'एडमिन डैशबोर्ड';

  @override
  String get totalStaff => 'कुल स्टाफ';

  @override
  String get totalCenters => 'कुल केंद्र';

  @override
  String get activeSessions => 'सक्रिय सत्र';

  @override
  String get todaysDuties => 'आज की ड्यूटी';

  @override
  String get totalRemuneration => 'कुल पारिश्रमिक';

  @override
  String get liveMonitoring => 'लाइव मॉनिटरिंग';

  @override
  String get arrivalStatus => 'आगमन स्थिति';

  @override
  String get excellent => 'उत्कृष्ट';

  @override
  String get good => 'अच्छा';

  @override
  String get onTime => 'समय पर';

  @override
  String get slightlyLate => 'थोड़ा देर से';

  @override
  String get needsImprovement => 'सुधार आवश्यक';

  @override
  String get quickActions => 'त्वरित कार्य';

  @override
  String get manageStaff => 'स्टाफ प्रबंधित करें';

  @override
  String get manageCenters => 'केंद्र प्रबंधित करें';

  @override
  String get allocateDuty => 'ड्यूटी आवंटित करें';

  @override
  String get reports => 'रिपोर्ट';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get masterData => 'मास्टर डेटा';

  @override
  String get globalSearch => 'वैश्विक खोज';

  @override
  String get liveControlRoom => 'लाइव कंट्रोल रूम';

  @override
  String get payrollSalary => 'वेतन और पारिश्रमिक';

  @override
  String get todaysExams => 'आज की परीक्षाएं';

  @override
  String get noExamsToday => 'आज कोई परीक्षा निर्धारित नहीं है';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get viewDetails => 'विवरण देखें';

  @override
  String get recentAllocations => 'हालिया आवंटन';

  @override
  String get noAllocations => 'कोई आवंटन नहीं मिला';

  @override
  String get exportAllAllocations => 'सभी आवंटन निर्यात करें';

  @override
  String exportingRecords(int count) {
    return '$count आवंटन रिकॉर्ड निर्यात हो रहे हैं।';
  }

  @override
  String get exportAsPdf => 'PDF के रूप में निर्यात करें';

  @override
  String get exportAsExcel => 'Excel के रूप में निर्यात करें';

  @override
  String pdfError(String error) {
    return 'PDF त्रुटि: $error';
  }

  @override
  String excelError(String error) {
    return 'Excel त्रुटि: $error';
  }

  @override
  String get allAllocations => 'सभी आवंटन';

  @override
  String get dashboardFiltered => 'डैशबोर्ड फ़िल्टर्ड';

  @override
  String get staff => 'स्टाफ';

  @override
  String get addStaff => 'स्टाफ जोड़ें';

  @override
  String get editStaff => 'स्टाफ संपादित करें';

  @override
  String get deleteStaff => 'स्टाफ हटाएं';

  @override
  String get search => 'खोजें';

  @override
  String get searchStaff => 'स्टाफ खोजें...';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get mobileNumberUsername => 'मोबाइल नंबर (यूज़रनेम)';

  @override
  String get resourceId => 'रिसोर्स ID';

  @override
  String get emailAddress => 'ईमेल पता';

  @override
  String get address => 'पता';

  @override
  String get active => 'सक्रिय';

  @override
  String get blocked => 'अवरुद्ध';

  @override
  String get available => 'उपलब्ध';

  @override
  String get unavailable => 'अनुपलब्ध';

  @override
  String get leave => 'छुट्टी';

  @override
  String get save => 'सहेजें';

  @override
  String get update => 'अपडेट करें';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get edit => 'संपादित करें';

  @override
  String get add => 'जोड़ें';

  @override
  String get personalDetails => 'व्यक्तिगत विवरण';

  @override
  String get contactAndCredentials => 'संपर्क और लॉगिन क्रेडेंशियल';

  @override
  String get addInvigilator => 'निरीक्षक जोड़ें';

  @override
  String get editInvigilator => 'निरीक्षक संपादित करें';

  @override
  String get saveInvigilator => 'निरीक्षक सहेजें';

  @override
  String get updateInvigilator => 'निरीक्षक अपडेट करें';

  @override
  String get invigilatorAddedSuccess => 'निरीक्षक सफलतापूर्वक जोड़ा गया!';

  @override
  String get invigilatorUpdated => 'निरीक्षक अपडेट हो गया!';

  @override
  String get manageInvigilators => 'निरीक्षक प्रबंधित करें';

  @override
  String get noInvigilatorsFound => 'कोई निरीक्षक नहीं मिला';

  @override
  String get totalInvigilators => 'कुल निरीक्षक';

  @override
  String get deleteInvigilator => 'निरीक्षक हटाएं';

  @override
  String deleteInvigilatorConfirm(String name) {
    return 'क्या आप वाकई $name को हटाना चाहते हैं?';
  }

  @override
  String get invigilatorProfile => 'निरीक्षक प्रोफ़ाइल';

  @override
  String get dutyHistory => 'ड्यूटी इतिहास';

  @override
  String get performance => 'प्रदर्शन';

  @override
  String get totalDutiesAssigned => 'कुल आवंटित ड्यूटी';

  @override
  String get dutiesCompleted => 'पूर्ण ड्यूटी';

  @override
  String get dutiesPending => 'लंबित ड्यूटी';

  @override
  String get attendanceRate => 'उपस्थिति दर';

  @override
  String get availabilityCalendar => 'उपलब्धता कैलेंडर';

  @override
  String get markAvailable => 'उपलब्ध चिह्नित करें';

  @override
  String get markUnavailable => 'अनुपलब्ध चिह्नित करें';

  @override
  String get markLeave => 'छुट्टी चिह्नित करें';

  @override
  String get noDataAvailable => 'कोई डेटा उपलब्ध नहीं है';

  @override
  String get exams => 'परीक्षाएं';

  @override
  String get registeredExams => 'पंजीकृत परीक्षाएं';

  @override
  String get registerNewExam => 'नई परीक्षा पंजीकृत करें';

  @override
  String get registerExam => 'परीक्षा पंजीकृत करें';

  @override
  String get examName => 'परीक्षा का नाम';

  @override
  String get examDate => 'परीक्षा तिथि';

  @override
  String get examCenter => 'परीक्षा केंद्र';

  @override
  String get session => 'सत्र';

  @override
  String get newExam => 'नई परीक्षा';

  @override
  String get noRegisteredExams =>
      'कोई पंजीकृत परीक्षा नहीं मिली। ड्यूटी आवंटित करने के लिए एक बनाएं।';

  @override
  String get selectCenter => 'केंद्र चुनें';

  @override
  String get required => 'आवश्यक';

  @override
  String get selectDate => 'तिथि चुनें';

  @override
  String get selectShift => 'शिफ्ट चुनें';

  @override
  String get shift1 => 'शिफ्ट 1';

  @override
  String get shift2 => 'शिफ्ट 2';

  @override
  String get shift3 => 'शिफ्ट 3';

  @override
  String get selectInvigilators => 'निरीक्षक चुनें';

  @override
  String get selectedInvigilators => 'चयनित निरीक्षक';

  @override
  String get assign => 'आवंटित करें';

  @override
  String get assignDuty => 'ड्यूटी आवंटित करें';

  @override
  String get conflictDetected => 'टकराव का पता चला';

  @override
  String get overrideAction => 'ओवरराइड';

  @override
  String get recommendedStaff => 'अनुशंसित स्टाफ';

  @override
  String get reassign => 'पुनः आवंटित करें';

  @override
  String get swapDuty => 'ड्यूटी बदलें';

  @override
  String get replacement => 'प्रतिस्थापन';

  @override
  String get confirmAssignment => 'आवंटन की पुष्टि करें';

  @override
  String get dutyAllocation => 'ड्यूटी आवंटन';

  @override
  String get shiftRemuneration => 'शिफ्ट पारिश्रमिक';

  @override
  String shift1Amount(int amount) {
    return 'शिफ्ट 1 — ₹$amount';
  }

  @override
  String shift2Amount(int amount) {
    return 'शिफ्ट 2 — ₹$amount';
  }

  @override
  String shift3Amount(int amount) {
    return 'शिफ्ट 3 — ₹$amount';
  }

  @override
  String get myDuties => 'मेरी ड्यूटी';

  @override
  String get myProfile => 'मेरी प्रोफ़ाइल';

  @override
  String get availability => 'उपलब्धता';

  @override
  String get calendar => 'कैलेंडर';

  @override
  String get assignedDuty => 'आवंटित ड्यूटी';

  @override
  String get accept => 'स्वीकार करें';

  @override
  String get reject => 'अस्वीकार करें';

  @override
  String get dutyDetails => 'ड्यूटी विवरण';

  @override
  String get reportingTime => 'रिपोर्टिंग समय';

  @override
  String get remuneration => 'पारिश्रमिक';

  @override
  String get invigilatorDashboard => 'निरीक्षक डैशबोर्ड';

  @override
  String get noDutiesAssigned => 'अभी तक कोई ड्यूटी आवंटित नहीं है';

  @override
  String get upcomingDuties => 'आगामी ड्यूटी';

  @override
  String get pastDuties => 'पिछली ड्यूटी';

  @override
  String get dutyAccepted => 'ड्यूटी स्वीकार की गई';

  @override
  String get dutyRejected => 'ड्यूटी अस्वीकार की गई';

  @override
  String get dutySwapped => 'ड्यूटी सफलतापूर्वक बदली गई';

  @override
  String get currentDuty => 'वर्तमान ड्यूटी';

  @override
  String get reached => 'पहुँच गए';

  @override
  String get arrival => 'आगमन';

  @override
  String get arrivalTime => 'आगमन का समय';

  @override
  String get location => 'स्थान';

  @override
  String get gps => 'GPS';

  @override
  String get locationVerified => 'स्थान सत्यापित';

  @override
  String get outsideCenter => 'केंद्र से बाहर';

  @override
  String get distanceFromCenter => 'केंद्र से दूरी';

  @override
  String get arrivalRecorded => 'आगमन दर्ज किया गया';

  @override
  String get waitingForInternet => 'इंटरनेट की प्रतीक्षा';

  @override
  String get arrivalSyncedSuccessfully => 'आगमन सफलतापूर्वक सिंक हो गया';

  @override
  String get youReachedOnTime => 'आप समय पर पहुँच गए।';

  @override
  String get youReachedSlightlyLate => 'आप थोड़ा देर से पहुँचे।';

  @override
  String get reachInProperTime => 'कृपया उचित समय पर पहुँचें।';

  @override
  String get geofenceVerified => '✓ जियोफ़ेंस सत्यापित';

  @override
  String get outsideGeofence => '⚠ जियोफ़ेंस से बाहर';

  @override
  String get tryAgain => 'पुनः प्रयास करें';

  @override
  String get requestManualVerification => 'मैनुअल सत्यापन का अनुरोध करें';

  @override
  String get outsideGeofenceWarning =>
      'आप परीक्षा केंद्र क्षेत्र से बाहर प्रतीत हो रहे हैं।';

  @override
  String distanceMeters(String distance) {
    return 'केंद्र से $distanceमी';
  }

  @override
  String get dateRange => 'तिथि सीमा';

  @override
  String get status => 'स्थिति';

  @override
  String get accepted => 'स्वीकृत';

  @override
  String get pending => 'लंबित';

  @override
  String get rejected => 'अस्वीकृत';

  @override
  String get completed => 'पूर्ण';

  @override
  String get totalDuties => 'कुल ड्यूटी';

  @override
  String get exportPdf => 'PDF निर्यात करें';

  @override
  String get exportExcel => 'Excel निर्यात करें';

  @override
  String get download => 'डाउनलोड';

  @override
  String get generateReport => 'रिपोर्ट बनाएं';

  @override
  String get noReportsFound => 'कोई रिपोर्ट नहीं मिली';

  @override
  String get reportGenerated => 'रिपोर्ट सफलतापूर्वक बनाई गई';

  @override
  String get center => 'केंद्र';

  @override
  String get shift => 'शिफ्ट';

  @override
  String get all => 'सभी';

  @override
  String get filterByStatus => 'स्थिति द्वारा फ़िल्टर करें';

  @override
  String get filterByCenter => 'केंद्र द्वारा फ़िल्टर करें';

  @override
  String get filterByShift => 'शिफ्ट द्वारा फ़िल्टर करें';

  @override
  String get language => 'भाषा';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिन्दी';

  @override
  String get gujarati => 'ગુજરાતી';

  @override
  String get languageChangedSuccess => 'भाषा सफलतापूर्वक बदल दी गई';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get lunchProvision => 'दोपहर भोजन प्रावधान';

  @override
  String get reportingTimeLabel => 'रिपोर्टिंग समय';

  @override
  String get arrivalThreshold => 'आगमन सीमा';

  @override
  String get voiceFeedback => 'वॉइस फ़ीडबैक';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get lightMode => 'लाइट मोड';

  @override
  String get saveChanges => 'परिवर्तन सहेजें';

  @override
  String get settingsSaved => 'सेटिंग्स सफलतापूर्वक सहेजी गई';

  @override
  String get dutySettings => 'ड्यूटी सेटिंग्स';

  @override
  String get centers => 'केंद्र';

  @override
  String get addCenter => 'केंद्र जोड़ें';

  @override
  String get editCenter => 'केंद्र संपादित करें';

  @override
  String get deleteCenter => 'केंद्र हटाएं';

  @override
  String get centerName => 'केंद्र का नाम';

  @override
  String get locationCity => 'स्थान / शहर';

  @override
  String get capacity => 'क्षमता';

  @override
  String get saveCenter => 'केंद्र सहेजें';

  @override
  String get updateCenter => 'केंद्र अपडेट करें';

  @override
  String get centerAddedSuccess => 'केंद्र सफलतापूर्वक जोड़ा गया!';

  @override
  String get centerUpdated => 'केंद्र अपडेट हो गया!';

  @override
  String get noCentersFound => 'कोई केंद्र नहीं मिला। एक जोड़ें!';

  @override
  String deleteCenterConfirm(String name) {
    return 'क्या आप वाकई $name को हटाना चाहते हैं?';
  }

  @override
  String get geofenceGpsVerification => 'जियोफ़ेंस और GPS सत्यापन';

  @override
  String get useCurrentGps => 'वर्तमान GPS उपयोग करें';

  @override
  String get latitude => 'अक्षांश';

  @override
  String get longitude => 'देशांतर';

  @override
  String get allowedArrivalRadius => 'अनुमत आगमन त्रिज्या (मीटर)';

  @override
  String get geofenceHelperText =>
      'इस त्रिज्या के भीतर स्टाफ को \"पहुँचे और सत्यापित\" चिह्नित किया जाएगा';

  @override
  String get capturedGpsLocation => '✓ वर्तमान GPS स्थान प्राप्त हुआ!';

  @override
  String get couldNotAcquireGps => 'GPS स्थान प्राप्त नहीं हो सका';

  @override
  String get noGpsGeofenceConfigured => 'कोई GPS जियोफ़ेंस कॉन्फ़िगर नहीं है';

  @override
  String get reachedCount => 'पहुँचे';

  @override
  String get pendingCount => 'लंबित';

  @override
  String get lateCount => 'विलंबित';

  @override
  String get absentCount => 'अनुपस्थित';

  @override
  String get centerHealth => 'केंद्र स्वास्थ्य';

  @override
  String get shortage => 'कमी';

  @override
  String get replacementRequired => 'प्रतिस्थापन आवश्यक';

  @override
  String get emergencyReplacement => 'आपातकालीन प्रतिस्थापन';

  @override
  String get todaysDutiesCount => 'आज की ड्यूटी';

  @override
  String get liveExamControlRoom => 'लाइव परीक्षा कंट्रोल रूम';

  @override
  String get liveStats => 'लाइव आँकड़े';

  @override
  String get outsideGeofenceFilter => 'जियोफ़ेंस से बाहर';

  @override
  String get callStaff => 'स्टाफ को कॉल करें';

  @override
  String get reassignDuty => 'ड्यूटी पुनः आवंटित करें';

  @override
  String get notificationCenter => 'सूचना केंद्र';

  @override
  String get unread => 'अपठित';

  @override
  String get dutyUpdates => 'ड्यूटी अपडेट';

  @override
  String get alerts => 'अलर्ट';

  @override
  String get markAllRead => 'सभी पढ़ा चिह्नित करें';

  @override
  String get noNotifications => 'कोई सूचना नहीं';

  @override
  String get markAsRead => 'पढ़ा चिह्नित करें';

  @override
  String get deleteNotification => 'हटाएं';

  @override
  String minutesAgo(int minutes) {
    return '$minutesमि पहले';
  }

  @override
  String hoursAgo(int hours) {
    return '$hoursघं पहले';
  }

  @override
  String get justNow => 'अभी-अभी';

  @override
  String get payroll => 'वेतन';

  @override
  String get payrollRemuneration => 'वेतन और पारिश्रमिक';

  @override
  String get totalRemunerationAmount => 'कुल पारिश्रमिक';

  @override
  String get approved => 'स्वीकृत';

  @override
  String get paid => 'भुगतान किया';

  @override
  String get paymentPending => 'भुगतान लंबित';

  @override
  String get paymentReference => 'भुगतान संदर्भ';

  @override
  String get paymentRemarks => 'भुगतान टिप्पणी';

  @override
  String get markPaid => 'भुगतान चिह्नित करें';

  @override
  String get bulkPay => 'बल्क भुगतान';

  @override
  String get exportStatement => 'विवरण निर्यात करें';

  @override
  String get paymentStatusUpdated => 'भुगतान स्थिति अपडेट हो गई';

  @override
  String get staffSummary => 'स्टाफ सारांश';

  @override
  String get detailedPayments => 'विस्तृत भुगतान';

  @override
  String get monthSelector => 'माह';

  @override
  String get masterDataManagement => 'मास्टर डेटा प्रबंधन';

  @override
  String get selectModuleDescription =>
      'नीचे एक मॉड्यूल चुनें जिसे देखना, जोड़ना, संपादित करना या प्रबंधित करना है।';

  @override
  String get searchModules => 'मॉड्यूल खोजें...';

  @override
  String get esNames => 'ES नाम';

  @override
  String get examNames => 'परीक्षा नाम';

  @override
  String get securityGuardNames => 'सुरक्षा गार्ड नाम';

  @override
  String get jammerNames => 'जैमर नाम';

  @override
  String get users => 'उपयोगकर्ता';

  @override
  String records(int count) {
    return '$count रिकॉर्ड';
  }

  @override
  String get addNew => 'नया जोड़ें';

  @override
  String get noRecords => 'कोई रिकॉर्ड नहीं मिला';

  @override
  String get itemAdded => 'आइटम सफलतापूर्वक जोड़ा गया';

  @override
  String get itemUpdated => 'आइटम सफलतापूर्वक अपडेट हो गया';

  @override
  String get itemDeleted => 'आइटम सफलतापूर्वक हटा दिया गया';

  @override
  String get enterValue => 'मान दर्ज करें';

  @override
  String get name => 'नाम';

  @override
  String get value => 'मान';

  @override
  String get dutyAssignedSuccess => 'ड्यूटी सफलतापूर्वक आवंटित की गई';

  @override
  String get dutyAllocatedSuccess => 'ड्यूटी सफलतापूर्वक आवंटित हुई';

  @override
  String get errorOccurred => 'एक त्रुटि हुई';

  @override
  String get success => 'सफल';

  @override
  String get error => 'त्रुटि';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get noDataFound => 'कोई डेटा नहीं मिला';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get close => 'बंद करें';

  @override
  String get ok => 'ठीक है';

  @override
  String get yes => 'हाँ';

  @override
  String get no => 'नहीं';

  @override
  String get back => 'वापस';

  @override
  String get next => 'अगला';

  @override
  String get done => 'पूर्ण';

  @override
  String get submit => 'जमा करें';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get reset => 'रीसेट करें';

  @override
  String get refresh => 'रिफ्रेश';

  @override
  String get more => 'और';

  @override
  String get less => 'कम';

  @override
  String get seeAll => 'सभी देखें';

  @override
  String get ttsExcellent => 'उत्कृष्ट। आप समय पर पहुँच गए हैं।';

  @override
  String get ttsGood => 'अच्छा। आप थोड़ा देर से पहुँचे हैं।';

  @override
  String get ttsNeedsImprovement => 'सुधार आवश्यक। कृपया उचित समय पर पहुँचें।';

  @override
  String get welcomeMessage => 'स्वागत है!';

  @override
  String get swapRequest => 'बदलाव अनुरोध';

  @override
  String get swapRequestSent => 'बदलाव अनुरोध सफलतापूर्वक भेजा गया';

  @override
  String get swapApproved => 'बदलाव स्वीकृत';

  @override
  String get swapRejected => 'बदलाव अस्वीकृत';

  @override
  String get requestSwap => 'बदलाव अनुरोध करें';

  @override
  String get swapWith => 'बदलें';

  @override
  String get reason => 'कारण';

  @override
  String get sendReminder => 'रिमाइंडर भेजें';

  @override
  String get reminderSent => 'रिमाइंडर सफलतापूर्वक भेजा गया';

  @override
  String get manualReminder => 'मैनुअल रिमाइंडर';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get personalInfo => 'व्यक्तिगत जानकारी';

  @override
  String get contactInfo => 'संपर्क जानकारी';

  @override
  String get dutyStatistics => 'ड्यूटी आँकड़े';

  @override
  String get mockDutyCount => 'मॉक ड्यूटी गणना';

  @override
  String get email => 'ईमेल';

  @override
  String get phone => 'फ़ोन';

  @override
  String get mobile => 'मोबाइल';

  @override
  String get today => 'आज';

  @override
  String get yesterday => 'कल';

  @override
  String get tomorrow => 'कल';

  @override
  String get thisWeek => 'इस सप्ताह';

  @override
  String get thisMonth => 'इस महीने';

  @override
  String get from => 'से';

  @override
  String get to => 'तक';

  @override
  String get date => 'तिथि';

  @override
  String get time => 'समय';

  @override
  String get startDate => 'आरंभ तिथि';

  @override
  String get endDate => 'अंतिम तिथि';

  @override
  String staffReachedCount(int reached, int total) {
    return '$reached / $total पहुँचे';
  }

  @override
  String pendingDutiesCount(int count) {
    return 'आपकी $count ड्यूटी लंबित हैं।';
  }

  @override
  String get confirmDelete => 'हटाने की पुष्टि करें';

  @override
  String get deleteWarning => 'यह कार्य पूर्ववत नहीं किया जा सकता।';

  @override
  String get operationSuccess => 'ऑपरेशन सफलतापूर्वक पूरा हुआ';

  @override
  String get operationFailed => 'ऑपरेशन विफल हुआ';

  @override
  String get noInternetConnection => 'इंटरनेट कनेक्शन नहीं है';

  @override
  String get checkInternetConnection =>
      'कृपया अपना इंटरनेट कनेक्शन जाँचें और पुनः प्रयास करें।';

  @override
  String capacityLabel(int capacity) {
    return 'क्षमता: $capacity';
  }

  @override
  String selectedCount(int count) {
    return '$count चयनित';
  }

  @override
  String remunerationAmount(String amount) {
    return '₹$amount';
  }

  @override
  String get dutyAllocations => 'ड्यूटी आवंटन';

  @override
  String get examSessions => 'परीक्षा सत्र';

  @override
  String get sendEmailReport => 'ईमेल रिपोर्ट भेजें';

  @override
  String get emailSentSuccess => 'ईमेल सफलतापूर्वक भेजा गया';

  @override
  String get emailSendFailed => 'ईमेल भेजने में विफल';

  @override
  String get selectAll => 'सभी चुनें';

  @override
  String get deselectAll => 'सभी अचयनित करें';

  @override
  String get selected => 'चयनित';

  @override
  String get notSelected => 'अचयनित';

  @override
  String get chooseDate => 'तिथि चुनें';

  @override
  String get chooseDateRange => 'तिथि सीमा चुनें';

  @override
  String get noResultsFound => 'कोई परिणाम नहीं मिला';

  @override
  String get searchResults => 'खोज परिणाम';

  @override
  String get typeToSearch => 'खोजने के लिए टाइप करें...';

  @override
  String get staffDetails => 'स्टाफ विवरण';

  @override
  String get centerDetails => 'केंद्र विवरण';

  @override
  String get dutyInfo => 'ड्यूटी जानकारी';

  @override
  String get examInfo => 'परीक्षा जानकारी';

  @override
  String get maintenanceData => 'रखरखाव डेटा';

  @override
  String get viewProfile => 'प्रोफ़ाइल देखें';

  @override
  String get contactStaff => 'स्टाफ से संपर्क करें';

  @override
  String get actions => 'कार्य';

  @override
  String get noActionsAvailable => 'कोई कार्य उपलब्ध नहीं';

  @override
  String get geofenceVerification => 'जियोफ़ेंस और GPS सत्यापन';

  @override
  String get welcome => 'स्वागत';

  @override
  String get statsAtGlance => 'सांख्यिकी एक नज़र में';

  @override
  String get invigilators => 'निरीक्षक';

  @override
  String get swapRequests => 'बदलाव अनुरोध';

  @override
  String get approve => 'स्वीकृत करें';

  @override
  String get late => 'देर';

  @override
  String get invigilatorDirectory => 'निरीक्षक निर्देशिका';

  @override
  String get maintainData => 'डेटा बनाए रखें';

  @override
  String get securityGuardRecords => 'सुरक्षा गार्ड रिकॉर्ड';

  @override
  String get home => 'मुख्य पृष्ठ';

  @override
  String get clickDateToToggle =>
      'अपनी छुट्टी को चिह्नित या हटाने के लिए किसी भी तिथि पर टैप करें।';

  @override
  String get inactive => 'निष्क्रिय';

  @override
  String get invigilator => 'निरीक्षक';

  @override
  String get labStaff => 'लैब स्टाफ';
}
