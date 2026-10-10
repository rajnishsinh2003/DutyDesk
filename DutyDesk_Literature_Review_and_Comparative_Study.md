# 🏛️ DutyDesk — Smart Examination Invigilation & Operations Management System

## **Literature Review and Existing System Comparison**

**Technology Stack:** Flutter (Material 3) | Dart | Firebase / Cloud Firestore  
**Repository:** [github.com/rajnishsinh2003/DutyDesk](https://github.com/rajnishsinh2003/DutyDesk)  
**Authors:** Rajnish Sinh R. (92410103096), Vasu Koradiya R. (92410103003), Vandit Doshi A. (92410103050)  
**Department:** Department of Computer Engineering, Faculty of Engineering & Technology, Marwadi University, Rajkot  
**Academic Year:** 2026–2027  

---

## 1. Introduction
Conducting examinations at universities, autonomous colleges, and statutory testing boards involves numerous parallel, high-stakes operational activities:
- Allocating faculty invigilators fairly across physical examination halls.
- Securing confidential question paper packets during vault storage, transit, and classroom unsealing.
- Verifying invigilator physical attendance and punctuality without proxy check-ins.
- Mitigating last-minute faculty no-shows without leaving exam rooms unmonitored.
- Preventing student collusion through randomized, branch-separated seating plans.
- Accurately reconciling collected answer scripts against student attendance.
- Calculating and disbursing exam duty remuneration and travel allowances (TA/DA).

In prevailing higher education institutions across India, these operations remain largely governed by fragmented, manual processes such as spreadsheet rosters, handwritten paper sign-in registers, phone calls, and unencrypted WhatsApp groups. This creates severe structural vulnerabilities:
1. **Unfair or Clashing Duty Allocation:** Faculty members experience inequitable duty loads, schedule collisions across departments, and opaque assignment procedures.
2. **Late Arrivals and No-Shows:** Staff tardiness and unexpected absences are discovered only minutes before exam commencement, leaving exam halls unattended.
3. **Fragile Question Paper Chain of Custody:** Paper packets are handed over via informal signatures with no verifiable timestamp or proof of when envelopes are cut open.
4. **Script Counting Errors & Missing Answer Sheets:** Manual hand-counts under crowded post-exam conditions lead to discrepancies that surface days later at evaluation centers.
5. **Lack of Auditable Non-Repudiation:** In the event of paper leakage allegations, cheating controversies, or administrative grievances, institutions lack tamper-evident digital records.

**DutyDesk** is an enterprise-grade mobile and cloud platform engineered with Flutter (Material 3) and Google Cloud Firestore that digitizes this entire physical examination lifecycle through role-based access, geofenced presence verification, standby auto-promotion, question paper chain-of-custody tracking, mathematical script reconciliation, and immutable audit logging.

---

## 2. Problem Statement
Existing software tools address isolated slices of academic administration: generic commercial shift scheduling (Deputy, When I Work), university course timetabling (FET, aSc), or remote computer-based test proctoring (ProctorU, Mercer Mettl). 

> **Core Research Problem:**  
> *No single affordable, open-source platform integrates invigilator duty allocation, physical attendance integrity, question paper vault custody, mathematical answer script reconciliation, and statutory compliance auditing for physical, pen-and-paper examinations in the Indian institutional context.*

---

## 3. Project Objectives
- **Automate Fair Duty Allocation:** Generate equitable invigilation rosters enforcing deterministic clash detection and faculty leave constraints.
- **Enforce Multi-Factor Presence Verification:** Verify physical invigilator reporting using cryptographic GPS geofencing, Bluetooth Low Energy (BLE) room beacons, dynamic QR Gate Passes, and camera facial alignment frames.
- **Provide a Tamper-Evident Paper Custody Pipeline:** Track question paper packets from central vault checkout through physical transit to time-locked classroom unsealing requiring dual student witness validation.
- **Enforce Mathematical Answer Script Reconciliation:** Balance physical script counts via conservation laws ($\text{Distributed} = \text{Present} + \text{Damaged}$; $\text{Registered} = \text{Collected} + \text{Absent}$) and instantly generate printable vector PDF Form B dockets.
- **Maintain an Immutable Administrative Audit Trail:** Record an append-only chronological log of all administrative actions with actor metadata, timestamps, and JSON diffs.
- **Deliver Multilingual & Offline Resilience:** Provide native runtime localization in English, Hindi, and Gujarati, supported by a local SQLite write queue for operation in network-compromised rural campuses.
- **Provide Role-Tailored Executive Dashboards:** Offer purpose-built operational interfaces for Super Admins, Invigilators, Controller of Examinations (COE), Flying Squad / Vigilance, Deans, Statutory Observers, Security Guards, and Candidates/Parents.

---

## 4. System Overview & Architecture
DutyDesk comprises **39 production modules** engineered using **Flutter (Material 3)** with **Riverpod** reactive unidirectional state management, **GoRouter** declarative deep-link navigation, **Firebase Authentication** for cryptographic role-based tokens, and **Google Cloud Firestore** as the real-time NoSQL cloud database. 

The architecture integrates native device peripherals and cloud communication gateways:
- **Location & Proximity:** Geolocator (geodesic Haversine calculations) and Bluetooth Low Energy (BLE) beacon detection.
- **Biometric & Camera:** Native Camera API with facial oval alignment frames.
- **Security & Scanners:** Dynamic cryptographic QR code generator and high-speed camera barcode/QR scanner terminal.
- **Document & Printing:** On-the-fly vector PDF generator (Form B dockets, seating notices) and Excel/CSV batch importer.
- **Communication Gateways:** Firebase Cloud Messaging (FCM), SMS gateways (Msg91, Fast2SMS, Twilio), two-way WhatsApp webhooks, Flutter Text-to-Speech (TTS), and SMTP email.

### **Table: Key System Capabilities by Operational Domain**

| Operational Domain | Key Capabilities & Technical Features |
| :--- | :--- |
| **Duty Management** | Automated fairness heuristics, clash detection, manual administrative override, peer-to-peer duty swapping with two-way approval, availability calendars, and grace-timer standby auto-promotion. |
| **Attendance Integrity** | Cryptographic GPS geofence clock-in ($\le 200\text{ m}$ perimeter), BLE room-level proximity verification, dynamic QR Digital Gate Pass with security guard scanner, camera face verification frame, and 3-tier arrival punctuality grading. |
| **Exam Security & Custody** | Question paper vault-to-room custody tracking, time-locked unsealing authorization, dual student witness roll number capture, tamper incident filing, and integrated multi-feed CCTV console. |
| **Post-Exam Operations** | Atomic mathematical answer script reconciliation, absentee roll logging, tamper barcode bag binding, vector PDF Form B docket generation, and secure handover sign-off. |
| **Seating Administration** | 2D room matrix layout generator, anti-cheating course/branch interleaving algorithms, printable hall entrance notices, and candidate roll number lookup. |
| **Governance & Compliance** | Immutable append-only audit trail, statutory auditor/observer inspection scorecards, specialized executive views (COE, Flying Squad, Dean), and incident management. |
| **Operations & Payroll** | Punctuality-adjusted invigilation remuneration engine with TA/DA allowances, batch Excel/CSV importer with conflict policies, and automated data archival/purging. |
| **Accessibility & Channels** | Trilingual localization (English, Hindi, Gujarati), offline SQLite mutation queue, multi-channel alerts (SMS, WhatsApp, FCM, Email, TTS), and external read-only Student & Parent Portal. |

---

## 5. Comprehensive Literature Review

### 5.1 Staff Scheduling and Rostering Theory
Personnel scheduling is a foundational problem in Operations Research (OR). Ernst et al. (2004) and Van den Bergh et al. (2013) surveyed the taxonomy of personnel rostering models, classifying solution methodologies into integer linear programming (ILP), constraint programming (CP), metaheuristics (genetic algorithms, simulated annealing, tabu search), and rule-based dispatching heuristics. 

Burke et al. (2004) established in nurse rostering that workforce scheduling is characterized by two distinct classes of constraints:
- **Hard Constraints:** Non-negotiable requirements that must be strictly satisfied (e.g., zero double-booking, certified invigilator qualification, approved medical leave).
- **Soft Constraints:** Desirable operational preferences to be optimized (e.g., equitable historical duty counts, avoidance of consecutive duty slots, preferred shifts).

While exact mathematical solvers guarantee theoretical global optimality, real-world educational institutions frequently face dynamic disruptions (sudden faculty illness, transit delays, emergency leave requests). This makes rigid solvers computationally impractical during time-sensitive operational adjustments. Practical enterprise systems favor **fairness-driven greedy heuristics** paired with administrative override mechanisms. DutyDesk adopts this hybrid paradigm, balancing past duty counts with instant clash detection.

### 5.2 The Academic Gap: Examination Timetabling vs. Invigilator Operations
A vast body of academic literature addresses **examination timetabling** (Carter, Laporte and Lee, 1996; Qu et al., 2009). These studies focus almost exclusively on algorithmic strategies (graph coloring, clique decomposition, memetic algorithms) to assign academic courses and student cohorts to conflict-free time slots and rooms to prevent student schedule collisions.

However, once timetables are published, the physical operational lifecycle of **exam-day execution**—including dynamic invigilator presence verification, question paper envelope security, emergency standby promotions, and post-exam script reconciliation—remains virtually unexplored in academic literature. **DutyDesk directly fills this published research gap.**

### 5.3 Fairness in Workload Distribution
Unfair duty allocation creates significant workplace friction, staff grievances, and administrative disputes. Rostering literature defines equity as equalizing total cumulative duty burdens, balancing undesirable shifts (e.g., weekend sessions, evening shifts), and avoiding consecutive assignments. DutyDesk implements this via a transparent allocation weight vector, historical duty tracking, and a peer-to-peer (P2P) duty swap exchange requiring dual-party faculty consent and administrative oversight.

### 5.4 Location-Based Presence and Geofencing Limitations
GPS-based attendance is common in modern workforce management. However, empirical studies highlight critical limitations of single-signal GPS in university campuses:
- **Multipath Indoor GPS Drift:** Satellite signals attenuate significantly inside multi-story reinforced concrete academic buildings.
- **Software Mock-Location Spoofing:** Android developer options permit mock-location provider apps that report fabricated coordinates.

Rostering and security literature emphasizes that combining heterogeneous physical signals (multi-factor defense-in-depth) is essential for presence verification. DutyDesk layers:
1. Geodesic Haversine GPS boundaries ($\le 200\text{ m}$ perimeter).
2. Bluetooth Low Energy (BLE) indoor room beacon proximity detection.
3. Cryptographically signed dynamic QR Gate Passes verified by security guards.
4. Camera-based facial oval alignment frames.

### 5.5 Role-Based Access Control (RBAC)
Sandhu et al. (1996) formalized RBAC models where permissions bind strictly to organizational roles rather than individual user accounts. This model is ideally suited to hierarchical educational institutions. DutyDesk implements fine-grained RBAC enforced through cryptographically signed Firebase Authentication tokens and Cloud Firestore security rules across eight distinct stakeholder roles.

### 5.6 Chain of Custody and Tamper Evidence
Forensic chain-of-custody principles (verifiable handovers, exact timestamps, dual witnesses, sealed evidence packets) are directly applicable to confidential examination materials. Question paper leaks represent a recurring, high-stakes crisis in public and university examinations in India. DutyDesk applies digital custody principles through:
- Vault checkout logging with custodian identification.
- Transit escort monitoring.
- Time-locked unsealing dialogs strictly disabled until official statutory release time.
- Mandatory recording of two independent student witness roll numbers and OTP verification before unsealing envelopes.

### 5.7 Audit Logging and Non-Repudiation
Audit trails provide foundational support for accountability, compliance, and non-repudiation in enterprise systems. Good architectural practice dictates recording *who*, *what*, *when*, and *from where*, while protecting log records from retrospective tampering. DutyDesk maintains an append-only Firestore audit collection protected by database rules that disallow updates and deletions.

### 5.8 Offline-First Design for Campus Networks
Many educational campuses—particularly rural institutions and affiliated regional colleges—suffer from intermittent cellular connectivity or intentionally activated RF jammers during high-stakes exams. An offline-first architecture utilizing a local write queue with automatic background synchronization upon reconnection is essential for field reliability.

### 5.9 Multichannel Emergency Notification
In the Indian institutional context, SMS and WhatsApp channels achieve significantly higher real-time open and response rates than email. DutyDesk integrates Firebase Cloud Messaging (FCM) push notifications, SMS gateways (Msg91, Fast2SMS, Twilio), two-way WhatsApp webhooks, and Text-to-Speech (TTS) voice alerts.

### 5.10 Cross-Platform and Serverless Cloud Infrastructure
Flutter provides a unified, reactive codebase across Android, iOS, and Web. Paired with Google Cloud Firebase serverless infrastructure (managed authentication, reactive NoSQL data streams, cloud messaging), this minimizes hardware procurement and server maintenance overheads, making the platform affordable for colleges with lean IT staffing.

---

## 6. Categorization of Existing Systems

| Category | Representative Platforms | Primary Strengths | Critical Limitations for Exam Operations |
| :--- | :--- | :--- | :--- |
| **Generic Shift Scheduling Apps** | Deputy, When I Work, Sling, Humanity | Mature shift scheduling, peer swaps, time clocks, mobile apps. | Designed for retail and hospitality; zero exam domain concepts (centers, halls, paper packets, script dockets, Form B); costly per-user monthly SaaS fees. |
| **University ERP / Exam Modules** | Fedena, Entab, Campus365, University Portals | Student records, course registration, semester results processing. | Primitive duty assignment; zero real-time presence checks (rely on paper registers); zero paper transit custody; no script conservation math. |
| **Online Proctoring Platforms** | ProctorU, Examity, Inspera, Safe Exam Browser | Remote webcam AI proctoring, lockdown browser test security. | Exclusively target digital/online exams; incapable of managing physical exam halls, printed paper packet seals, or script bundling. |
| **Academic Timetabling Software** | FET Timetabling, TimeTabler, aSc Timetables | Mathematical slot and hall conflict optimization. | Stop strictly at pre-exam schedule generation; zero execution-day operational tracking, no-show detection, or custody controls. |
| **Manual & Fragmented Methods** | Microsoft Excel, Paper Registers, WhatsApp Groups | Zero software license cost; universally familiar to staff. | Error-prone; untracked faculty proxy clock-in; no real-time administrative visibility; zero audit trail; vulnerable to paper leaks. |

*Source: Synthesized from published vendor technical specifications, university examination operating manuals, and field operational studies (2024–2026).*

---

## 7. Deep Feature Comparison Matrix

| Operational Feature / Capability | Generic Shift Apps | ERP Exam Modules | Online Proctoring | Manual / Excel | **DutyDesk (Proposed System)** |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Invigilation Duty Allocation** | Generic shifts only | Basic manual list | No | Manual spreadsheet | **Auto-fairness heuristics + clash detection** |
| **Peer Duty Swap with Admin Approval** | Yes | Rare / custom ticket | No | No (informal) | **Yes (Two-way in-app request & Admin sign-off)** |
| **GPS Geofenced Clock-In** | Yes | Rare | No | No | **Yes (Haversine $\le 200\text{ m}$ configurable perimeter)** |
| **BLE Room-Level Presence Beacon** | No | No | No | No | **Yes (Proximity RSSI detection)** |
| **QR Gate Pass + Security Guard Terminal** | No | No | No | No | **Yes (Dynamic signed QR code & guard scanner)** |
| **Face Verification at Arrival** | Some (paid tier) | No | Yes (webcam AI) | No | **Yes (In-app camera alignment frame & liveness)** |
| **Auto Standby Promotion for No-Shows** | No | No | No | Manual phone calls | **Yes (Grace-timer expiration auto-substitution)** |
| **Arrival Quality & Punctuality Grading** | Basic | No | No | No | **Yes (3-tier: On-Time, Slightly Late, Needs Impr.)** |
| **Question Paper Chain-of-Custody** | No | No | No | Paper register | **Yes (Vault $\to$ Transit $\to$ Hall time-locked log)** |
| **Time-Locked Unseal + Dual Student Witnesses** | No | No | No | No | **Yes (Time-lock enforcement + 2 witness roll numbers)** |
| **Answer Script Reconciliation + Form B** | No | No | No | Manual hand-count | **Yes (Conservation balance math + Vector PDF docket)** |
| **Anti-Cheating 2D Seating Plan Grid** | No | Some (basic list) | No | Manual chart | **Yes (2D visual matrix + course interleaving)** |
| **Real-Time Incident Reporting** | Basic text | Rare | Yes (remote flags) | Paper complaint | **Yes (Classified severity, room tag & photo attachment)** |
| **Live CCTV Multi-Feed Surveillance Panel** | No | No | No | Separate DVR room | **Yes (Integrated 2×2 / 3×3 grid stream inspector)** |
| **Exam Duty Remuneration & TA/DA Payroll** | Generic payroll | Some | No | Manual calculation | **Yes (Punctuality-adjusted honorarium generator)** |
| **Immutable Audit Logging** | Limited | Limited | Yes (session log) | None | **Yes (Append-only Firestore trail with diff metadata)** |
| **Dedicated Statutory Auditor / Observer Mode**| No | No | No | No | **Yes (Read-only inspection scorecards & live feed)** |
| **Executive Dashboards (COE, Vigilance, Dean)** | No | Limited | No | No | **Yes (Specialized KPI views for senior leadership)** |
| **Student & Parent Read-Only Public Portal** | No | Yes (grade portal) | Yes (test window) | Notice board | **Yes (External schedule, hall & seat number lookup)** |
| **Multilingual Interface (English, Hindi, Gujarati)**| Rare | Some | Rare | N/A | **Yes (Runtime switchable ARB localization)** |
| **Offline-First Synchronization Engine** | Partial | Rare | Rare | N/A | **Yes (Local SQLite mutation queue + auto-sync)** |
| **Multichannel Emergency Alerts** | Limited | Some (SMS) | No | Manual calls | **Yes (FCM Push, SMS Gateway, WhatsApp, Email, TTS)**|
| **Cost & Software Licensing Model** | Subscription ($$$) | Heavy license fee | Per-candidate fee | Free | **100% Free & Open-Source (MIT License)** |

---

## 8. Gap Analysis: Why Current Systems Fall Short
1. **No Integrated Lifecycle Solution:** Existing tools address fragmented slices. DutyDesk is the first unified platform covering allocation, physical arrival, paper custody, script reconciliation, and compliance auditing.
2. **Physical Pen-and-Paper Exams Are Neglected:** Industry edtech focuses almost exclusively on remote online testing, whereas over 85% of university examinations in India are handwritten on paper.
3. **Weak Attendance Integrity:** Paper registers permit retro-active signing, while single-signal mobile GPS is vulnerable to spoofing. DutyDesk layers multi-factor physical verification.
4. **Absence of Automated No-Show Recovery:** Prevailing exam cells rely on ad-hoc phone calls when staff fail to report. DutyDesk promotes standby reserves automatically upon grace period expiration.
5. **Paper Custody Security is Entirely Manual:** Question paper packets lack verifiable digital custody logs, tamper-evident seals, and classroom unseal witnesses.
6. **Linguistic, Accessibility, and Financial Barriers:** Commercial ERPs impose steep recurring fees, lack vernacular languages, and fail under poor connectivity. DutyDesk is free, open-source, multilingual, and offline-resilient.
7. **Statutory Observer Compliance Gap:** External university observers and state auditors lack digital observation tools and real-time control room visibility.

---

## 9. Unique Contributions of DutyDesk
1. **End-to-End Operational Lifecycle Coverage:** A single platform spanning pre-exam scheduling, exam-day custody, and post-exam reconciliation.
2. **Multi-Factor Physical Presence Verification:** Defense-in-depth presence assurance combining GPS Haversine, BLE room beacons, dynamic QR Gate Passes, and camera facial verification.
3. **Automated Standby Promotion Engine:** Background queue monitoring reporting grace periods and executing auto-substitutions with instant notification dispatch.
4. **Time-Locked Classroom Paper Unsealing:** Digital unseal verification requiring dual student witness roll numbers and OTP authorization within an enforced statutory time window.
5. **Mathematical Answer Script Reconciliation:** Real-time equation balancing ($\text{Distributed} = \text{Present} + \text{Damaged}$; $\text{Registered} = \text{Collected} + \text{Absent}$) with instant vector PDF Form B generation.
6. **Multi-Tier Specialized Dashboards:** Tailored interfaces for COE, Vigilance / Flying Squad, Deans, Statutory Observers, and Security Guards.
7. **Vernacular & Offline Architecture:** Full support for English, Hindi, and Gujarati, supported by a local SQLite write queue.
8. **100% Free & Open-Source:** Zero licensing cost, MIT open-source license.

---

## 10. Proposed Future Research & Engineering Extensions

| Proposed Innovation | Research & Engineering Rationale |
| :--- | :--- |
| **Explainable Fairness Scoring Model** | Displays a transparent fairness index ($0.0-1.0$) to each faculty member, detailing duty burden equity, weekend allocation balance, and past assignments to eliminate workplace dissatisfaction. |
| **Constraint-Based Allocation (OR-Tools / GA)** | Benchmark the current greedy fairness heuristic against formal integer linear programming (ILP) or genetic metaheuristics to quantify optimality vs. real-time latency trade-offs. |
| **Mock-Location & Spoof Anomaly Detection** | Query Android `isFromMockProvider` flags, accelerometer motion consistency, and cell tower IDs to detect spoofed GPS check-ins. |
| **Cryptographic Hash-Chained Audit Ledger** | Embed the SHA-256 hash of the preceding log entry into each new audit record, creating a verifiable blockchain-like tamper-evident hash-chain. |
| **Predictive No-Show Risk Modeling** | Machine learning model analyzing historical punctuality, weather, transit distances, and traffic to forecast no-show probabilities and pre-alert standby staff. |
| **PKI Digital Signatures on Form B** | Embed cryptographic X.509 digital signatures into vector PDF Form B dockets and paper handover slips for legal-grade non-repudiation. |
| **Post-Exam Operations Analytics & Heatmaps** | Executive analytics console for the Controller of Examinations displaying arrival punctuality curves, incident density heatmaps, and reconciliation timing metrics. |
| **Automated Conflict-of-Interest Filtering** | Introduce hard constraints preventing faculty from being assigned to examination halls hosting candidates from their own department or relatives. |
| **SMS Fallback Check-In for Low Bandwidth** | Provide encrypted, two-way SMS gateway check-ins for remote examination centers experiencing complete mobile data outages. |
| **Accessibility Mode for Scribes & PwD Rooms** | Dedicated workflows for extra-time tracking and scribe attendance verification compliant with statutory Rights of Persons with Disabilities guidelines. |

---

## 11. System Boundaries and Limitations to Acknowledge
For academic rigor and transparent viva defense, the following implementation boundaries must be acknowledged:
1. **Facial Alignment vs. 1:N Biometric Recognition:** The in-app camera check utilizes an oval alignment guide for visual attendance confirmation and anti-proxy auditing. It functions as a presence verification protocol rather than a 1:N neural network facial feature vector matcher against a pre-enrolled template database.
2. **Database Immutability vs. Cryptographic Hash-Chains:** Audit log immutability is enforced via Cloud Firestore Security Rules blocking updates and deletions. Mathematical proof of non-repudiation would be further enhanced by cryptographic hash-chaining.
3. **GPS Spoofing & Basements:** Geofencing relies on device-reported GPS coordinates. Deep basements can cause GPS signal attenuation, necessitating fallback to BLE room beacons.
4. **CCTV Stream Validation:** The multi-feed CCTV monitor was evaluated against standard RTSP and HLS network camera feeds rather than proprietary closed-circuit campus DVR hardware.
5. **NoSQL Read Scaling & Concurrency Costs:** Firestore provides real-time reactive snapshot streams. For massive concurrent deployments (>10,000 active users), query indexing and SQLite caching must be tuned to minimize cloud read costs.

---

## 12. Conclusion
Existing software solutions across higher education fall into isolated silos: generic commercial shift apps, static university ERP modules, remote computer-based test proctoring tools, and vulnerable manual paper methods. None provides an integrated, secure, and auditable operating system for physical, offline examination operations.

DutyDesk successfully bridges this operational and research gap with a 39-module, multi-role, trilingual, offline-capable, and open-source platform. Grounded in operations research rostering theory and modern cyber-physical security principles, DutyDesk delivers a production-ready solution that transforms examination integrity, staff fairness, and institutional accountability.

---

## 13. References

1. A. T. Ernst, H. Jiang, M. Krishnamoorthy, and D. Sier, "Staff scheduling and rostering: A review of applications, methods and models," *European Journal of Operational Research*, vol. 153, no. 1, pp. 3–27, 2004.
2. J. Van den Bergh, J. Beliën, P. De Bruecker, E. Demeulemeester, and L. De Boeck, "Personnel scheduling: A literature review," *European Journal of Operational Research*, vol. 226, no. 3, pp. 367–385, 2013.
3. E. K. Burke, P. De Causmaecker, G. Vanden Berghe, and H. Van Landeghem, "The state of the art of nurse rostering," *Journal of Scheduling*, vol. 7, no. 6, pp. 441–499, 2004.
4. M. W. Carter, G. Laporte, and S. Y. Lee, "Examination timetabling: Algorithmic strategies and applications," *Journal of the Operational Research Society*, vol. 47, no. 3, pp. 373–383, 1996.
5. R. Qu, E. K. Burke, B. McCollum, L. T. G. Merlot, and S. Y. Lee, "A survey of search methodologies and automated system development for examination timetabling," *Journal of Scheduling*, vol. 12, no. 1, pp. 55–89, 2009.
6. R. S. Sandhu, E. J. Coyne, H. L. Feinstein, and C. E. Youman, "Role-based access control models," *IEEE Computer*, vol. 29, no. 2, pp. 38–47, 1996.
7. R. Adebayo, S. Adegoke, and O. Folorunso, "Automated Examination Duty Allocation System Using Genetic Algorithms," in *Proc. IEEE Africon*, 2018, pp. 245–251.
8. V. Kumar and A. Sharma, "Smart Campus: Geofenced Attendance Management System Using GPS and BLE," *Int. J. Comput. Appl.*, vol. 176, no. 12, pp. 18–25, 2019.
9. A. Oluwaseun, T. Babatunde, and K. Adeleke, "IoT-Based Secure Question Paper Delivery Box with Biometric Lock," *IEEE Access*, vol. 8, pp. 112450–112461, 2020.
10. D. Patel and H. Mehta, "Cryptographic Protocol for Secure Examination Paper Distribution," in *Communications in Computer and Information Science*, Springer, vol. 1422, pp. 312–325, 2021.
11. M. Rahman, S. Islam, and T. Noor, "Automated Seating Arrangement System with Anti-Collusion Constraints," *J. Educ. Technol. Syst.*, vol. 50, no. 3, pp. 388–404, 2022.
12. S. Sengupta and P. Roy, "End-to-End Chain of Custody for High-Stakes Educational Testing Using Distributed Ledgers," *Int. J. Inf. Secur.*, vol. 22, pp. 981–996, 2023.
13. N. Verma and S. Joshi, "AI-Driven Biometric Authentication and Punctuality Monitoring for Exam Proctors," *IEEE Trans. Learn. Technol.*, vol. 17, pp. 415–428, 2024.
14. Google Flutter Documentation, "Building Cross-Platform User Interfaces with Material 3," 2026. [Online]. Available: https://flutter.dev/docs
15. Google Cloud, "Firebase Firestore Scalable NoSQL Realtime Database," 2025. [Online]. Available: https://firebase.google.com/docs/firestore
16. Remi Rousselet, "Riverpod: Reactive Caching and Data-Binding Framework for Flutter," 2024. [Online]. Available: https://riverpod.dev
17. National Testing Agency (NTA), "Standard Operating Procedures for Examination Center Superintendents and Observers," Ministry of Education, Govt. of India, 2024.
18. University Grants Commission (UGC), "Guidelines on Conduct of Examinations and Academic Calendar," 2023.
19. R. Sinnott, "Virtues of the Haversine," *Sky and Telescope*, vol. 68, no. 2, p. 159, 1984.
20. R. C. Martin, *Clean Architecture: A Craftsman's Guide to Software Structure and Design*, Prentice Hall, 2017.
