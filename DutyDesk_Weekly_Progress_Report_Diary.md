# 📘 Marwadi University — Department of Computer Engineering
## Major Project-II (01CE0807) — Semester 8 | A.Y. 2026–27
### **Weekly Progress Report Diary (Exact Table Format for Print & Pen Entry)**

---

### **Cover Page Details**

| Field | Detail |
| :--- | :--- |
| **Department** | Department of Computer Engineering, Faculty of Engineering & Technology |
| **University** | Marwadi University, Rajkot |
| **Academic Year** | **2026–27** |
| **Semester** | **8** |
| **Course Code & Name** | **Major Project-II (01CE0807)** |
| **Project Title** | **DutyDesk – Smart Examination Invigilation & Operations Management System** |
| **Team ID** | *(Leave blank or enter your assigned Team ID, e.g. CE-MP-26)* |
| **Internal Guide Name & Signature** | **Prof. Parita Mer** *(Assistant Professor, CE Dept)* |

<br/>

| Sr. No. | Student Full Name | Student En. No. | Class |
| :---: | :--- | :---: | :---: |
| **1** | **Rajnish Sinh** | **92410103096** | CE – 8th Sem |
| **2** | **Vasu Koradiya** | **92410103003** | CE – 8th Sem |
| **3** | **Vandit Doshi** | **92410103050** | CE – 8th Sem |

---

### **Official Evaluation Milestones**

| Evaluation Event | Component | Marks | Tentative Date | Diary Week Mapping |
| :--- | :---: | :---: | :---: | :--- |
| **Regular Reporting / Attendance** | **TW** | **50** | **05/10/2026 to 22/02/2027** | Continuous (Every Week) |
| **Review 1** | **TW** | **50** | **21/11/2026** | **November — Week 3** |
| **Review 2 (VIVA)** | **VIVA** | **100** | **02/01/2027** | **January — Week 1** |
| **Review 3 (VIVA)** | **VIVA** | **100** | **13/02/2027** | **February — Week 2** |
| **Project Report (Submission)** | **TW** | **100** | **13/02/2027** | **February — Week 2** |

---

<div style="page-break-after: always;"></div>

## 🗓️ Weekly Project Progress Report Diary – October

| Week | Project Activity by Students | Updates / Comments / Suggestions / Remarks by Faculty | Date & Time | Guide Signature |
| :---: | :--- | :--- | :---: | :---: |
| **1** | Analyzed university exam bottlenecks (faculty tardiness, proxy sign-in, unverified paper unsealing). Finalized project scope, technical stack (Flutter 3.27, Dart, Riverpod, Google Cloud Firestore), and initialized Git repository with zero-lint policy. | Approved project scope and requirements. Ensure strict adherence to high-stakes university exam guidelines (UGC/NTA standards). Plan module milestones. | 09/10/2026<br/>11:30 AM | |
| **2** | Designed Layered Clean Architecture and unidirectional Riverpod state flow. Modeled Cloud Firestore NoSQL schema (users, centers, exam_duties, rooms, incident_reports). Configured Firebase Authentication with role guards for Admin, Invigilator, Finance, and Auditor. | Good architectural blueprint. Keep database operations normalized where query efficiency is paramount. Begin implementing authentication flows. | 16/10/2026<br/>02:30 PM | |
| **3** | Implemented responsive Super Admin Dashboard using Material 3 design tokens. Built Exam Center CRUD interface with GPS coordinate picking and geofence radius configuration. Developed Invigilator Directory with faculty profiles and historical stats. | Center geofencing radius must be configurable per campus layout. Verify GPS accuracy tolerances on mobile devices. | 23/10/2026<br/>11:00 AM | |
| **4** | Developed Core Duty Allocation Engine with automated clash and double-booking detection. Built interactive session assignment UI allowing manual overrides of reporting times. Formulated dynamic punctuality milestone windows (Reporting Time, Excellent Until, Good Until). | Punctuality thresholds are well-conceived. Start engineering physical geofenced arrival verification using Geolocator. | 30/10/2026<br/>03:00 PM | |

---

<div style="page-break-after: always;"></div>

## 🗓️ Weekly Project Report Diary – November

| Week | Project Activity by Students | Updates / Comments / Suggestions / Remarks by Faculty | Date & Time | Guide Signature |
| :---: | :--- | :--- | :---: | :---: |
| **1** | Engineered mandatory Geofenced Clock-In engine utilizing geodesic Haversine distance calculations. Enforced strict clock-in block if the faculty device is outside designated center perimeter (distance > 200m). Built Invigilator Dashboard with arrival countdown. | Geofencing algorithm successfully demonstrated. Ensure graceful handling of device location permission denials and GPS drift. | 06/11/2026<br/>11:30 AM | |
| **2** | Developed Live Exam Control Room dashboard tracking real-time center attendance. Integrated arrival punctuality classification badges: On-Time (Green), Slightly Late (Amber), Needs Improvement (Red). Implemented direct emergency calling and replacement triggers. | The real-time control room effectively reflects center status. Prepare comprehensive slide deck and demo for Review 1. | 13/11/2026<br/>02:00 PM | |
| **3** | **Appeared for Major Project-II Review 1 (TW: 50 Marks) on 21/11/2026.** Presented literature review, system architecture, role-based auth, geofencing engine, and live control room demo. Submitted Review 1 documentation and design specification sheets. | **Review 1 Conducted (Satisfactory).** Commended for zero-lint code quality and real-time architecture. Suggested adding biometric verification and custody tracking. | 21/11/2026<br/>10:00 AM | |
| **4** | Addressed Review 1 suggestions by researching camera face alignment guides and BLE beacon protocols. Implemented Peer-to-Peer (P2P) Duty Swap module allowing invigilators to request peer exchanges. Built administrative swap approval console with instant roster re-binding. | Duty swap workflow functions smoothly. Ensure notification alerts reach faculty when peer swap requests are generated. | 27/11/2026<br/>03:30 PM | |

---

<div style="page-break-after: always;"></div>

## 🗓️ Weekly Project Report Diary – December

| Week | Project Activity by Students | Updates / Comments / Suggestions / Remarks by Faculty | Date & Time | Guide Signature |
| :---: | :--- | :--- | :---: | :---: |
| **1** | Developed in-app Biometric Face Verification camera dialog with oval face alignment frame. Integrated Bluetooth Low Energy (BLE) room beacon proximity detector (ble_beacon_service.dart) for in-room presence. Implemented Text-to-Speech (TTS) voice briefing service for duty guidelines. | Multi-factor verification (GPS + BLE + Face) significantly hardens attendance integrity. Test camera frame performance on low-end devices. | 04/12/2026<br/>11:00 AM | |
| **2** | Designed and integrated Digital Gate Pass & QR Badge with encrypted token payloads. Developed Gate Pass QR Scanner terminal dialog for campus security guard checkpoints. Built WhatsApp Interactive Broadcast Hub & Webhook simulation dialog (whatsapp_dispatcher_dialog.dart). | QR gate pass workflow is practical for campus gates. Ensure camera scanner terminates cleanly on pass verification. | 11/12/2026<br/>02:30 PM | |
| **3** | Engineered Question Paper Dispatch Tracker & Vault Chain-of-Custody module. Implemented vault custodian handover checkout logs, driver transit tracking, and center receipt confirmation. Modeled question paper packet lifecycle states: VAULT -> TRANSIT -> RECEIVED -> UNSEALED. | Paper dispatch custody is a critical feature. Add tamper alert dialogs and time-locking constraints for unsealing. | 18/12/2026<br/>11:30 AM | |
| **4** | Developed Time-Locked Packet Unsealing Dialog (packet_unseal_dialog.dart). Enforced strict unsealing window (blocks attempts prior to authorized time, e.g. 30 mins before exam). Integrated mandatory capture of dual student witness roll numbers and OTP prior to seal break. | Time-locked unsealing with student witnesses is an innovative security mechanism. Review 2 VIVA scheduled for 02/01/2027. | 24/12/2026<br/>03:00 PM | |

---

<div style="page-break-after: always;"></div>

## 🗓️ Weekly Project Report Diary – January

| Week | Project Activity by Students | Updates / Comments / Suggestions / Remarks by Faculty | Date & Time | Guide Signature |
| :---: | :--- | :--- | :---: | :---: |
| **1** | **Appeared for Major Project-II Review 2 VIVA (100 Marks) on 02/01/2027.** Demonstrated live geofencing, face verification, paper dispatch custody, and time-locked unsealing with student witnesses. Presented working Firestore database synchronizations and mobile UI. | **Review 2 VIVA Conducted (Excellent Performance).** Applauded for exam security features. Work on post-exam script reconciliation, seating layout, and bulk data import. | 02/01/2027<br/>10:30 AM | |
| **2** | Engineered Answer Script Collection & Reconciliation Engine (answer_sheet_provider.dart). Implemented mathematical script conservation balance equations (Distributed = Present + Damaged, Registered = Collected + Absent). Built on-the-fly vector PDF Form B Docket Slip generator. | Mathematical reconciliation eliminates script counting disputes. Ensure PDF docket renders clean vector typography and signature lines. | 08/01/2027<br/>02:30 PM | |
| **3** | Developed 2D Exam Seating Plan Generator (seating_plan_screen.dart). Formulated anti-cheating branch/course interleaving algorithm ensuring adjacent desks never share syllabus. Built printable Hall Seating Notice PDF export for campus notice boards. | Seating plan generator is highly functional. Implement bulk Excel import next to simplify data onboarding for large colleges. | 15/01/2027<br/>11:00 AM | |
| **4** | Developed Bulk Data Import Engine (bulk_import_service.dart, bulk_import_screen.dart). Implemented parsing for Excel (.xlsx) and CSV files for Invigilators, Centers, Duties, and Guards. Built pre-commit validation audit console and conflict resolution modal (skip, overwrite, abort). | Bulk import engine works reliably. Proceed to audit logging, CCTV video monitor, and candidate external portal. | 22/01/2027<br/>03:30 PM | |

---

<div style="page-break-after: always;"></div>

## 🗓️ Weekly Project Report Diary – February

| Week | Project Activity by Students | Updates / Comments / Suggestions / Remarks by Faculty | Date & Time | Guide Signature |
| :---: | :--- | :--- | :---: | :---: |
| **1** | Engineered Immutable Audit Trail module (audit_trail_screen.dart). Developed Specialized Role Dashboards for COE, Flying Squad, and Dean. Implemented multi-feed CCTV IP Camera Monitor (cctv_monitor_screen.dart). Built external Student & Parent Portal. Added English, Hindi, and Gujarati i18n. | System features completed to an exceptional level (39/39 modules). Finalize documentation, run analyzer tests, and compile final release APK. | 05/02/2027<br/>11:30 AM | |
| **2** | **Appeared for Major Project-II Review 3 VIVA (100 Marks) on 13/02/2027.** **Submitted Final Hardbound Project Report (100 Marks TW).** Executed flutter analyze with 0 issues found. Built production Android release APK (72.8 MB). Pushed complete codebase to GitHub. | **Review 3 VIVA & Final Project Report Approved.** Excellent comprehensive engineering effort. Project demonstrated 100% completion of all proposed modules. | 13/02/2027<br/>10:00 AM | |
| **3** | Completed semester project closure, final diary verification, and signed attendance record (05/10/2026 to 22/02/2027). Packaged deployment guide, APK download links, and source repository documentation for departmental archives. | Project diary entries, term work attendance, and final submission approved. Ready for final University Examination VIVA. | 20/02/2027<br/>02:00 PM | |

---
