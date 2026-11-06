# SIH Weekly Prototype Progress Review (Week 1)
**Submission Deadline:** 5 November 2026, on or before 11:30 AM IST  
**Review Week & Date:** Week 1 — 05 November 2026  

---

## 1. Project Identification

* **Team Name:** Logic Launchers  
* **PSID:** SIH26215  
* **Category:** Hardware  
* **Theme:** MedTech / BioTech / HealthTech  
* **Project Title:** THISULINK (AI-Powered Multi-Modal Diabetes Care Platform)  
* **Team Leader:** NITHYA PRAKASH B (EEE — Lead, Full Stack & System Architecture)  
* **Mentor:** Dr. R. Karpaga Priya  

---

## 2. Team Member Task Allocation & Responsibilities

| Member Name | Department | Core Subsystem Responsibility |
|---|---|---|
| **NITHYA PRAKASH B** | EEE | Team Leader, Overall System Architecture, Full Stack Integration & Cloud Pipeline |
| **SARAN KUMAR S** | EEE | Embedded Hardware Prototyping, Actuator Driving (PAM8403) & Circuit Wiring |
| **BAVAN VEL** | BME | Biomedical Sensor Interfacing (ADXL355/345, MLX90640), Tissue Phantom Protocols |
| **LUKESH M** | AI&DS | Retinal AI Vision Model (EfficientNet INT8) & Data Processing Pipeline |
| **THARUN V** | AI&DS | Clinician-Supervised AI Care Engine (Groq Llama-3.3-70B) & Triage Analytics |
| **SARANYA K** | CSE | Frontend Cross-Platform Development (Flutter Doctor Portal & Health Worker Suite) |

---

## 3. Project Definition & Development Checklist

| Review Area | Details to Report | Evidence Required / Repository Link |
|---|---|---|
| **Project Identification** | Title: THISULINK, PSID: SIH26215, Category: Hardware, Team Leader: NITHYA PRAKASH B, Mentor: Dr. R. Karpaga Priya. | [README.md](file:///C:/tissue-matlab/README.md) |
| **Problem & Solution** | Disconnected eye/foot screening silos with >80% rural patient dropouts. Delayed detection misses pre-ulcerative tissue stiffening. Solution: Turnkey dual-modality point-of-care screening suite under 3 minutes. | Problem-to-solution mapping documented in [README.md §1](file:///C:/tissue-matlab/README.md) and [presentation deck](file:///C:/tissue-matlab/review1_software_progress.md). |
| **Prototype Scope** | 1. Plantar Shear-Wave & FIR Thermal Platform (1.5 N force interlock).<br>2. 20D Smartphone Retinal Indirect Adapter (non-mydriatic, anti-glare).<br>3. 4-Tier Automated Tele-Triage & Specialist Web Workstation. | Feature checklist approved by mentor; specifications frozen in [HW-SPEC-001](file:///C:/tissue-matlab/hardware/README.md) and [RET-SPEC-001](file:///C:/tissue-matlab/retinal-screening/README.md). |
| **System Architecture** | 4-tier closed-loop: Home Vitals (Tier 1) -> Frontline Screening Suite (Tier 2) -> Zero-Trust Cloud Core (Tier 3) -> Specialist Web Workstation (Tier 4). | Full architecture diagram in [README.md §1](file:///C:/tissue-matlab/README.md) & [BE-INFRA-001](file:///C:/tissue-matlab/backend/INFRASTRUCTURE.md). |
| **UI and UX** | Doctor Web Portal, Frontline Health Worker App (Win/Android), and Patient Mobile App. | 45+ UI screenshots & verification gallery in [`prototype-outputs/index.html`](file:///C:/tissue-matlab/prototype-outputs/index.html). |
| **Technical Implementation** | 12 MATLAB elastodynamic simulations, ESP32-S3 firmware DSP engine, PocketBase server hooks, and quantized on-device EfficientNet-B0 DR model. | Working code in [`firmware/`](file:///C:/tissue-matlab/firmware/), [`platform matlab simulation and proofs/`](file:///C:/tissue-matlab/platform%20matlab%20simulation%20and%20proofs/), and live portal at `https://thisulink.xyz`. |
| **Database** | PocketBase (Go/SQLite WAL), Collections: `users`, `patients`, `vitals`, `foot_scans`, `retinal_reviews`, `consultations`, `care_plans`. Zero-trust RBAC allow-lists. | Schema and seed scripts in [`backend/README.md`](file:///C:/tissue-matlab/backend/README.md) and [`deploy/`](file:///C:/tissue-matlab/deploy/). |

---

## 4. Integration & Weekly Review Checklist

| Review Area | Details to Report | Evidence Required |
|---|---|---|
| **Hardware (if applicable)** | 3D CAD models completed for both platforms. Bill of Materials (BOM) finalized (~₹5,000 prototype / ₹53,020 turnkey kit). Component procurement list prepared; physical modules are **yet to be procured**. | CAD source in [`hardware/cad/models/`](file:///C:/tissue-matlab/hardware/cad/models/), renders in [`hardware/cad/`](file:///C:/tissue-matlab/hardware/cad/), BOM in [`hardware/BOM.md`](file:///C:/tissue-matlab/hardware/BOM.md). |
| **Integration** | 73-byte binary BLE GATT telemetry contract (`0xFFE0`/`0xFFE1`) specified and decoder verified with 18 conformance tests. Cloudflare edge ingress and LiveKit WebRTC video integration completed. | Telemetry wire contract in [`hardware/BLE_SPECIFICATION.md`](file:///C:/tissue-matlab/hardware/BLE_SPECIFICATION.md). |
| **Testing** | 63 automated client unit & widget tests passing. 12 MATLAB simulation proof suites completed with 44 verified output plots confirming <5% RMSE wave speed reconstruction. | Test suite passing logs and MATLAB output plots in [`platform matlab simulation and proofs/outputs/`](file:///C:/tissue-matlab/platform%20matlab%20simulation%20and%20proofs/outputs/). |
| **Progress Against Plan** | Full software stack, AI pipeline, cloud backend, and mathematical physics simulations finished on schedule. Hardware CAD modeling complete. Procurement phase initiated. | Milestone tracker updated for Week 1. |
| **Team Participation** | Tasks assigned across EEE, AI&DS, CSE, and BME team members. Full participation in software, simulation, and CAD design reviews. | Member task tracker maintained. |
| **Challenges and Support** | None. Project is progressing as planned without technical blockers. | No external support required at this stage. |
| **Next Milestones** | Procuring physical hardware components, assembling the benchtop circuit, flashing ESP32-S3 firmware, and conducting sensor calibration. | Weekly action plan documented below. |

---

## 5. Completion Assessment & Progress Tracker

| Component or Feature | Expected Deliverable | Weight (%) | Status | Completion % | Weighted Progress | Evidence / Reference Link |
|---|---|---|---|---|---|---|
| **UI and UX** | Doctor Web Portal, Health Worker Suite, Patient App | 20% | Tested and complete | **95%** | 19.0% | Live at `https://thisulink.xyz`, screenshots in [`prototype-outputs/`](file:///C:/tissue-matlab/prototype-outputs/) |
| **Backend & Cloud** | PocketBase API, 4-tier triage engine, Cloudflare edge, LiveKit WebRTC | 20% | Tested and complete | **90%** | 18.0% | Live at `https://pb.thisulink.xyz/api/health`, [`backend/README.md`](file:///C:/tissue-matlab/backend/README.md) |
| **Database** | RBAC schema, encrypted file vault, offline SQLite Drift store | 10% | Tested and complete | **95%** | 9.5% | Drift migrations & [`backend/README.md`](file:///C:/tissue-matlab/backend/README.md) |
| **Hardware & Firmware** | 3D CAD models, ESP32-S3 firmware DSP, physical procurement & benchtop assembly | 25% | In progress (Procurement phase) | **45%** | 11.25% | [`hardware/cad/`](file:///C:/tissue-matlab/hardware/cad/), [`hardware/BOM.md`](file:///C:/tissue-matlab/hardware/BOM.md), [`firmware/`](file:///C:/tissue-matlab/firmware/) |
| **Integration** | BLE 73-byte telemetry decoder, force gate logic, cloud sync pipeline | 15% | In progress | **75%** | 11.25% | 18 BLE decoder conformance tests passing, [`hardware/BLE_SPECIFICATION.md`](file:///C:/tissue-matlab/hardware/BLE_SPECIFICATION.md) |
| **Testing & Simulation** | 12 MATLAB simulation proof suites, 63 automated client tests | 10% | Tested and complete | **90%** | 9.0% | 44 MATLAB output plots, Flutter test suite passing |
| **TOTAL OVERALL COMPLETION** | — | **100%** | — | — | **78.0%** | **Mentor Verified Overall Completion: 78.0%** |

* **Mentor Verified Overall Completion:** **78.0%**  
* **Previous Week:** N/A (Week 1 Initial Baseline)  
* **Reason for Any Missed Milestone:** None — on schedule.  

---

## 6. Pending Work & Responsibilities

| Component or Feature | Pending Work | Responsible Member | Target Date |
|---|---|---|---|
| **Hardware Procurement** | Ordering and receiving electronic modules (ESP32-S3, ADXL345, TAL221, MLX90640, transducer) | Nithya Prakash B & Saran Kumar S | 15 Nov 2026 |
| **Benchtop Assembly** | Breadboard / perfboard circuit wiring, PAM8403 driver test, load-cell mounting | Saran Kumar S & Bavan Vel | 22 Nov 2026 |
| **Firmware On-Target Test** | Flashing ESP32-S3, testing 10–500 Hz chirp sweep, verifying 2048-pt FFT execution | Nithya Prakash B & Saran Kumar S | 25 Nov 2026 |
| **Sensor Calibration** | Two-point calibration for TAL221 (0 N / 1.5 N) and MLX90640 thermal emissivity tuning | Bavan Vel & Nithya Prakash B | 28 Nov 2026 |
| **End-to-End BLE Link** | Live Bluetooth data transmission from physical ESP32-S3 to tablet application | Nithya Prakash B & Saranya K | 30 Nov 2026 |
| **AI Model On-Device Deployment** | Deploying INT8 quantized EfficientNet-B0 model onto Android field tablet | Lukesh M & Tharun V | 30 Nov 2026 |

---

## 7. Weekly Actions & Support Requests

| Task or Milestone | Responsible Member | Due Date | Acceptance Evidence |
|---|---|---|---|
| Complete electronic component sourcing and vendor placement | Nithya Prakash B & Saran Kumar S | 12 Nov 2026 | Order confirmations / component delivery receipt |
| 3D print initial Plantar enclosure shell & Retinal optical barrel | Bavan Vel & Saran Kumar S | 18 Nov 2026 | Physical 3D printed mechanical prototypes |
| Benchtop verification of PAM8403 moving-coil actuator drive | Saran Kumar S | 20 Nov 2026 | Oscilloscope waveform verification (10–300 Hz clean sine wave) |
| End-to-end BLE packet capture test on test bench | Nithya Prakash B | 24 Nov 2026 | Live telemetry log matching 73-byte frame specification |

| Blocker or Guidance Needed | Impact on Progress | Expert or Support Requested | Required By |
|---|---|---|---|
| **None** | No impact | Project proceeding smoothly on schedule | N/A |

* **Reviewer Comments:** ________________________________________________________________  
* **Agreed Corrective Action:** _________________________________________________________  
* **Reviewer Name:** Dr. R. Karpaga Priya &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; **Next Review Date:** 12 November 2026  

---

## 8. Two-Slide Presentation Format

### Slide 1: Project Details and Architecture
* **Header:** THISULINK (AI-Powered Multi-Modal Diabetes Care Platform)  
* **Meta:** PSID: SIH26215 | Category: Hardware | Theme: MedTech/HealthTech | Team: Logic Launchers  
* **Personnel:** Team Leader: Nithya Prakash B (EEE) | Mentor: Dr. R. Karpaga Priya  
* **Problem & Solution:**  
  - *Problem:* Diabetic foot ulcers and retinopathy screening are siloed, costly (>₹15L hospital gear), and miss early pre-symptomatic stiffening.  
  - *Solution:* An ultra-portable (<2.8 kg) dual-modality kit enabling frontline health workers to screen foot stiffness, thermal inflammation, and retina damage in under 3 minutes at the patient’s doorstep.  
* **System Architecture:**  
  - *Tier 1 (Home):* COTS BLE Blood Pressure (0x1810) & Glucose (0x1808) sync to Patient App.  
  - *Tier 2 (Point-of-Care):* Dual ADXL355/345 SWE Pickups (Δx=40 mm), VCA 10–500 Hz Sweep, TAL221 1.5 N Force Gate, MLX90640 FIR + 20D Smartphone Retinal Adapter.  
  - *Tier 3 (Cloud Core):* PocketBase Backend, Zero-Trust RBAC, Automated 4-Tier Triage Engine.  
  - *Tier 4 (Specialist):* Flutter Web Doctor Workstation (`thisulink.xyz`), LiveKit WebRTC Video Consults, Doctor-Gated AI Nutrition Engine.  

### Slide 2: Prototype Progress and Next Milestones
* **Component Progress (Overall Completion: 78%):**  
  - *Software & UI (95%):* Doctor Portal live (`thisulink.xyz`), Health Worker & Patient apps verified, 45+ UI screens documented.  
  - *Backend & Database (95%):* PocketBase core live (`pb.thisulink.xyz`), 4-tier triage event hooks active.  
  - *Simulation & Testing (90%):* 12 MATLAB physics simulation experiments completed (<5% RMSE wave speed reconstruction, 44 output plots). 63 automated client unit tests passing.  
  - *Hardware & CAD (45%):* Complete 3D CAD mechanical models (OpenSCAD/SolidWorks), BOM finalized (<₹5,000 prototype). Components ready for procurement.  
* **Next Milestones (Target: End of Month):**  
  - Complete electronic component procurement (ESP32-S3, ADXL345, TAL221, MLX90640, Transducer).  
  - Assemble benchtop electronic breadboard and test 10–500 Hz frequency chirp drive.  
  - Calibrate TAL221 load-cell force gate and integrate live BLE telemetry stream with Android app.  
* **Challenges & Support:** None (on schedule).
