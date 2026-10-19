# THISULINK — Review 1 Software Progress Report
**Team Logic Launchers | Project Status Update**

---

## What We Set Out To Build
We wanted to give visiting village health workers a fast, portable kit to check diabetic patients for both foot ulcers and retinal damage in under three minutes, while streaming that data straight to a hospital doctor.

Here is what we have built, tested, and deployed on the software side so far.

---

## 1. Specialist Web Workstation (Doctor Portal)
* **Where it runs:** Live on the web at `https://thisulink.xyz` (built with Flutter Web).
* **Live Triage Queue:** The moment a field worker finishes a test, the patient appears in the doctor's queue sorted by risk:
  - 🔴 **Red:** Severe risk / emergency flare. Needs immediate attention.
  - 🟠 **Orange:** High risk. Tele-consult needed within 24 hours.
  - 🟡 **Yellow:** Moderate stiffening. Monitor on regular cycles.
  - 🟢 **Green:** Stable / healthy reading.
* **Retinal Image Review:** The doctor can open the patient's fundus photo, see the on-device AI grade, inspect the vessels, and either confirm or override the diagnosis.
* **Built-in Video Calls:** We integrated LiveKit WebRTC so the doctor can start a secure video call with the patient and field worker right inside the browser.
* **Prescription & PDF Export:** The doctor adds medicines, dosage, and notes. The portal stamps a signed digital PDF report ready for printing or download.
* **Diet Safety Check:** The doctor reviews AI-suggested meal plans before the patient can see them.

---

## 2. Frontline Health Worker App (Windows & Android)
* **Patient Registration:** Workers can enroll new patients on the spot, pull up their past test history, and hand out one-time passwords for mobile access.
* **Bluetooth Link to the Foot Probe:**
  - Talks wirelessly to our ESP32-S3 over BLE (GATT 0xFFE0 / 0xFFE1).
  - Enforces the 1.4 N to 1.6 N force window so readings are not ruined by uneven foot pressure.
  - Pulls vibration waveforms and 64 infrared sole temperatures in real time.
* **Sync with Commercial Vitals:** Automatically reads Bluetooth blood pressure cuffs and glucometers without manual typing.
* **Retinal Camera Capture:** Guides the worker to snap clear fundus photos through our 20D lens attachment.
* **Works Completely Offline:** In remote villages with zero network, the app writes everything to an encrypted local SQLite database and syncs automatically once back in cell range.

---

## 3. Patient Mobile App (Health Companion)
* **Simple Dashboard:** Patients log in with their phone number to see their latest checkup summary.
* **Trend Graphs:** Visual curves showing whether fasting sugar and blood pressure are staying in the safe zone over weeks.
* **Doctor-Approved Meals:** Shows customized breakfast, lunch, and dinner suggestions along with a list of foods to avoid.
* **Video Call Lobby:** Patients can wait in a virtual room and join scheduled video follow-ups with one tap.

---

## 4. Backend Core & Cloud Services
* **Live Server:** Running at `https://pb.thisulink.xyz` using PocketBase.
* **Data Security & Privacy:** Strict role-based rules prevent patients from seeing anyone else's medical records.
* **Automatic Risk Scoring:** Server-side hooks recalculate the patient's triage tier whenever a new reading lands.
* **Cloudflare Security:** The server sits behind Cloudflare tunnels with zero open public ports to prevent unauthorized access.

---

## 5. Machine Learning & Telemetry
* **On-Device Eye Model:** We quantized an EfficientNet model down to INT8 so it runs directly on a phone in under 2 seconds without requiring an internet connection.
* **Glare Check:** We added an image filter that spots corneal light reflections and tells the worker to adjust the angle before grading.
* **Diet Engine:** Runs through Groq Llama-3.3-70B to turn doctor notes into regional meal plans, applying safety rule checks before doctor review.

---

## Current Work Summary

| Subsystem | What We Completed | Current Status |
|---|---|---|
| **Doctor Portal** | Live triage dashboard, retinal review, LiveKit video calls, e-prescriptions | **100% Deployed & Live** |
| **Health Worker App** | BLE foot probe telemetry, preload interlock, vitals sync, offline SQLite | **100% Tested (63 tests passing)** |
| **Patient App** | Sugar/BP trends, diet plan viewer, video lobby | **UI & flows verified** |
| **Backend Core** | PocketBase API, role-based security, automated triage hooks | **100% Live & Operational** |
| **Edge AI** | Offline 5-class retinal grading model + glare detection | **Benchmarked on phone** |
| **Verification** | 45+ UI screenshots on GitHub + 12 MATLAB simulation tests | **Pushed to GitHub** |

---

## Verified Links
* **Doctor Portal:** https://thisulink.xyz
* **Backend API:** https://pb.thisulink.xyz/api/health
* **GitHub Repository:** https://github.com/thisulink/thisulink
* **UI Screenshot Gallery:** https://github.com/thisulink/thisulink/tree/main/prototype-outputs
