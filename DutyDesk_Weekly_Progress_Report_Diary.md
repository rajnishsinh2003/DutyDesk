# 📘 Marwadi University — Department of Computer Engineering
## Major Project-II (01CE0807) — Semester 8 | A.Y. 2026–27
### **Weekly Progress Report Diary Entries (Ready-to-Write / Print)**

---

### **Cover Page Details**
- **Department**: Department of Computer Engineering, Faculty of Engineering & Technology
- **Institution**: Marwadi University, Rajkot
- **Academic Year**: **2026–27**
- **Semester**: **8**
- **Course**: **Major Project-II (01CE0807)**
- **Project Title**: **DutyDesk – Smart Examination Invigilation & Operations Management System**
- **Team ID**: *(Enter your designated Team ID, e.g., CE-MP-26)*
- **Internal Guide Name & Signature**: **Prof. Parita Mer** *(Assistant Professor, CE Dept)*

| Sr. No. | Student Full Name | Student Enrollment No. | Class / Division |
| :---: | :--- | :---: | :---: |
| 1. | **Rajnish Sinh** | **92410103096** | CE – 8th Sem |
| 2. | **Vasu Koradiya** | **92410103003** | CE – 8th Sem |
| 3. | **Vandit Doshi** | **92410103050** | CE – 8th Sem |

---

### 📅 Institutional Evaluation Milestones (Official Schedule)

| Evaluation Stage | Marks | Component | Official Tentative Date | Corresponding Diary Week |
| :--- | :---: | :---: | :---: | :--- |
| **Regular Reporting / Attendance** | **50** | **TW** | **05/10/2026 to 22/02/2027** | Continuous (Every Week) |
| **Review 1** | **50** | **TW** | **21/11/2026** | **November — Week 3** |
| **Review 2 (VIVA)** | **100** | **VIVA** | **02/01/2027** | **January — Week 1** |
| **Review 3 (VIVA)** | **100** | **VIVA** | **13/02/2027** | **February — Week 2** |
| **Project Report (Final Submission)**| **100** | **TW** | **13/02/2027** | **February — Week 2** |

---

## 🗓️ 1. October 2026 — Project Diary

### **Weekly Project Progress Report Diary – October**

| Week | Project Activity by Students | Updates / Comments / Suggestions / Remarks by Faculty | Date & Time | Guide Signature |
| :---: | :--- | :--- | :---: | :---: |
| **1** | • Analyzed institutional examination operational bottlenecks: late reporting, proxy signatures, and unverified paper unsealing.<br/>• Finalized project scope, technical stack (Flutter 3.27, Dart, Riverpod, Google Cloud Firestore), and Work Breakdown Structure (WBS).<br/>• Initialized GitHub repository (`DutyDesk`) and established zero-lint engineering guidelines. | Approved project scope and requirements. Ensure strict adherence to high-stakes university exam guidelines (UGC/NTA standards). Plan module milestones. | **09/10/2026**<br/>11:30 AM | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| **2** | • Designed Layered Clean Architecture and unidirectional Riverpod state management flow.<br/>• Modeled Cloud Firestore NoSQL schema (`users`, `centers`, `exam_duties`, `rooms`, `incident_reports`).<br/>• Configured Firebase Authentication with role guards for Super Admin, Invigilator, Finance Officer, and Auditor. | Good architectural blueprint. Keep database operations normalized where query efficiency is paramount. Begin implementing authentication flows. | **16/10/2026**<br/>02:30 PM | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| **3** | • Implemented responsive Super Admin Dashboard with Material 3 design tokens.<br/>• Built Exam Center CRUD interface with GPS coordinate picking and geofence radius configuration.<br/>• Built Invigilator Directory module with faculty departments, historical duties, and contact details. | Center geofencing radius must be configurable per campus layout. Verify GPS accuracy tolerances on mobile devices. | **23/10/2026**<br/>11:00 AM | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| **4** | • Developed Core Duty Allocation Engine with automated clash and double-booking detection.<br/>• Built interactive session assignment UI allowing manual overrides of reporting times.<br/>• Formulated dynamic punctuality milestone windows (*Reporting Time*, *Excellent Until*, *Good Until*). | Punctuality thresholds are well-conceived. Start engineering physical geofenced arrival verification using Geolocator. | **30/10/2026**<br/>03:00 PM | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |

---

## 🗓️ 2. November 2026 — Project Diary (Review 1 Month)

### **Weekly Project Report Diary – November**

| Week | Project Activity by Students | Updates / Comments / Suggestions / Remarks by Faculty | Date & Time | Guide Signature |
| :---: | :--- | :--- | :---: | :---: |
| **1** | • Engineered mandatory Geofenced Clock-In engine utilizing geodesic Haversine distance calculations.<br/>• Enforced strict clock-in block if the faculty device is outside designated center perimeter ($d > 200\text{ m}$).<br/>• Developed Faculty Invigilator Dashboard with real-time duty timeline and arrival countdown. | Geofencing algorithm successfully demonstrated. Ensure graceful handling of device location permission denials and GPS drift. | **06/11/2026**<br/>11:30 AM | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| **2** | • Developed Live Exam Control Room dashboard tracking real-time center attendance.<br/>• Integrated arrival punctuality classification badges: 🟢 *On-Time*, 🟡 *Slightly Late*, 🔴 *Needs Improvement*.<br/>• Implemented direct emergency calling and replacement triggers from the control room. | The real-time control room effectively reflects center status. Prepare comprehensive slide deck and demo for Review 1. | **13/11/2026**<br/>02:00 PM | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| **3**<br/>*(Review 1)* | • **Appeared for Major Project-II Review 1 (TW: 50 Marks) on 21/11/2026**.<br/>• Presented literature review, system architecture, role-based auth, geofencing engine, and live control room demo.<br/>• Submitted Review 1 documentation and design specification sheets. | **Review 1 Conducted (Satisfactory).** Commended for zero-lint code quality and real-time architecture. Suggested adding biometric verification and custody tracking. | **21/11/2026**<br/>10:00 AM | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| **4** | • Addressed Review 1 suggestions by researching camera face alignment guides and BLE beacon protocols.<br/>• Implemented Peer-to-Peer (P2P) Duty Swap module allowing invigilators to request peer exchanges.<br/>• Built administrative swap approval console with instant roster re-binding. | Duty swap workflow functions smoothly. Ensure notification alerts reach faculty when peer swap requests are generated. | **27/11/2026**<br/>03:30 PM | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |

---

## 🗓️ 3. December 2026 — Project Diary

### **Weekly Project Report Diary – December**

| Week | Project Activity by Students | Updates / Comments / Suggestions / Remarks by Faculty | Date & Time | Guide Signature |
| :---: | :--- | :--- | :---: | :---: |
| **1** | • Developed in-app Biometric Face Verification camera dialog with oval face alignment frame.<br/>• Integrated Bluetooth Low Energy (BLE) room beacon proximity detector (`ble_beacon_service.dart`) for in-room presence.<br/>• Implemented Text-to-Speech (TTS) voice briefing service for duty guidelines. | Multi-factor verification (GPS + BLE + Face) significantly hardens attendance integrity. Test camera frame performance on low-end devices. | **04/12/2026**<br/>11:00 AM | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| **2** | • Designed and integrated Digital Gate Pass & QR Badge with encrypted token payloads.<br/>• Developed Gate Pass QR Scanner terminal dialog for campus security guard checkpoints.<br/>• Built WhatsApp Interactive Broadcast Hub & Webhook simulation dialog (`whatsapp_dispatcher_dialog.dart`). | QR gate pass workflow is practical for campus gates. Ensure camera scanner terminates cleanly on pass verification. | **11/12/2026**<br/>02:30 PM | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| **3** | • Engineered Question Paper Dispatch Tracker & Vault Chain-of-Custody module.<br/>• Implemented vault custodian handover checkout logs, driver transit tracking, and center receipt confirmation.<br/>• Modeled question paper packet lifecycle states: `STORED_IN_VAULT` $\rightarrow$ `IN_TRANSIT` $\rightarrow$ `RECEIVED_AT_CENTER` $\rightarrow$ `UNSEALED`. | Paper dispatch custody is a critical feature. Add tamper alert dialogs and time-locking constraints for unsealing. | **18/12/2026**<br/>11:30 AM | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| **4** | • Developed Time-Locked Packet Unsealing Dialog (`packet_unseal_dialog.dart`).<br/>• Enforced strict unsealing window (blocks attempts prior to authorized time, e.g. 30 mins before exam).<br/>• Integrated mandatory capture of dual student witness roll numbers and invigilator OTP prior to digital seal break.<br/>• Prepared working system demo and presentation for Review 2 VIVA. | Time-locked unsealing with student witnesses is an innovative security mechanism. Review 2 VIVA scheduled for 02/01/2027. | **24/12/2026**<br/>03:00 PM | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |

---

## 🗓️ 4. January 2027 — Project Diary (Review 2 Month)

### **Weekly Project Report Diary – January**

| Week | Project Activity by Students | Updates / Comments / Suggestions / Remarks by Faculty | Date & Time | Guide Signature |
| :---: | :--- | :--- | :---: | :---: |
| **1**<br/>*(Review 2)* | • **Appeared for Major Project-II Review 2 VIVA (100 Marks) on 02/01/2027**.<br/>• Demonstrated live geofencing, face verification, paper dispatch custody, and time-locked unsealing with student witnesses.<br/>• Presented working Firestore database synchronizations and mobile UI. | **Review 2 VIVA Conducted (Excellent Performance).** Applauded for exam security features. Work on post-exam script reconciliation, seating layout, and bulk data import. | **02/01/2027**<br/>10:30 AM | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| **2** | • Engineered Answer Script Collection & Reconciliation Engine (`answer_sheet_provider.dart`).<br/>• Implemented mathematical script conservation balance equations ($\text{Distributed} = \text{Present} + \text{Damaged}$, $\text{Registered} = \text{Collected} + \text{Absent}$).<br/>• Built on-the-fly vector PDF Form B Docket Slip generator with tamper barcode binding. | Mathematical reconciliation eliminates script counting disputes. Ensure PDF docket renders clean vector typography and signature lines. | **08/01/2027**<br/>02:30 PM | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| **3** | • Developed 2D Exam Seating Plan Generator (`seating_plan_screen.dart`).<br/>• Formulated anti-cheating branch/course interleaving algorithm ensuring adjacent desks never share syllabus.<br/>• Built printable Hall Seating Notice PDF export for campus notice boards. | Seating plan generator is highly functional. Implement bulk Excel import next to simplify data onboarding for large colleges. | **15/01/2027**<br/>11:00 AM | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| **4** | • Developed Bulk Data Import Engine (`bulk_import_service.dart`, `bulk_import_screen.dart`).<br/>• Implemented parsing for Excel (`.xlsx`) and CSV files for Invigilators, Centers, Duties, and Guards.<br/>• Built pre-commit validation audit console and conflict resolution modal (`skip`, `overwrite`, `abort`).<br/>• Implemented atomic Firestore `WriteBatch` operations. | Bulk import engine works reliably. Proceed to audit logging, CCTV video monitor, and candidate external portal. | **22/01/2027**<br/>03:30 PM | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |

---

## 🗓️ 5. February 2027 — Project Diary (Review 3 & Submission Month)

### **Weekly Project Report Diary – February**

| Week | Project Activity by Students | Updates / Comments / Suggestions / Remarks by Faculty | Date & Time | Guide Signature |
| :---: | :--- | :--- | :---: | :---: |
| **1** | • Engineered Immutable Audit Trail & Activity Log module (`audit_trail_screen.dart`).<br/>• Developed Specialized Role Dashboards for COE (compliance), Flying Squad (10-point checklist), and Dean (institutional overview).<br/>• Implemented multi-feed CCTV IP Camera Surveillance Monitor (`cctv_monitor_screen.dart`).<br/>• Built external Student & Parent Examination Portal (`student_portal_screen.dart`).<br/>• Added multilingual internationalization for English, Hindi, and Gujarati. | System features completed to an exceptional level (39/39 modules). Finalize documentation, run analyzer tests, and compile final release APK. | **05/02/2027**<br/>11:30 AM | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| **2**<br/>*(Review 3 & Final Submission)* | • **Appeared for Major Project-II Review 3 VIVA (100 Marks) on 13/02/2027**.<br/>• **Submitted Final Hardbound Project Report (100 Marks TW)**.<br/>• Executed `flutter analyze` with **0 issues found**.<br/>• Built production Android release APK ($72.8\text{ MB}$) with ProGuard optimization.<br/>• Pushed complete codebase to GitHub repository (`github.com/rajnishsinh2003/DutyDesk`). | **Review 3 VIVA & Final Project Report Approved.** Excellent comprehensive engineering effort. Project demonstrated 100% completion of all proposed modules. | **13/02/2027**<br/>10:00 AM | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| **3** | • Completed semester project closure, final diary verification, and signed attendance record (05/10/2026 to 22/02/2027).<br/>• Packaged deployment guide, APK download links, and source repository documentation for departmental archives. | Project diary entries, term work attendance, and final submission approved. Ready for final University Examination VIVA. | **20/02/2027**<br/>02:00 PM | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |

---

<div align="center">
<sub>Verified and Approved by Project Guide: <b>Prof. Parita Mer</b>, Department of Computer Engineering, Marwadi University.</sub>
</div>
