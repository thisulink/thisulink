# THISULINK Vitals Integration — Standard COTS BLE Architecture

> **Purpose**: Seamless, clinically validated blood pressure (BP) and blood glucose data capture  
> **Hardware Strategy**: Commercial Off-The-Shelf (COTS) standard medical devices via Bluetooth Low Energy (BLE)  
> **Connectivity**: Standard Bluetooth SIG Health Profiles (GATT) → THISULINK Flutter App → PocketBase (`thisulink.xyz`)  
> **Regulatory Reference**: ISO 81060-2 (Blood Pressure), ISO 15197 (In vitro glucose monitoring), ADA Standards of Care 2026

---

## 1. Architectural Strategy: Why COTS Over Custom Cuffless Sensors?

Early screening platform concepts often attempt to engineer custom optical photoplethysmography (PPG) cuffless blood-pressure sensors and non-invasive spectroscopic glucometers into a single handheld unit. However, clinical and regulatory reality presents insurmountable barriers to that approach:

1. **Severe Algorithmic Drift:** Optical cuffless BP estimation requires frequent individual calibration against a validated cuff (every 7–14 days) and degrades significantly under motion, vasoconstriction, and skin tone variations (Natarajan et al., *Nature Scientific Reports* 2023).
2. **Regulatory & Clinical Liability:** Non-invasive glucose and cuffless BP devices are not approved as primary diagnostic instruments by CDSCO or the US FDA (which issued restrictive draft guidance in January 2026 for cuffless BP devices).
3. **Clinical Trust:** Doctors and Primary Health Centre (PHC) Medical Officers will not prescribe medications based on experimental optical pulse estimations.

### The THISULINK Approach
THISULINK strictly separates **proven, gold-standard routine vitals monitoring** from **novel subclinical complication screening**:
* **Routine Daily Vitals (BP & Glucose):** Sourced directly from **standard, clinically validated digital oscillometric BP monitors** and **standard digital glucometers** equipped with Bluetooth Low Energy (BLE) or transparent BLE bridges.
* **THISULINK Novel Hardware Innovation:** Focused entirely where the true unmet diagnostic gap exists: **plantar shear-wave elastography (SWE)** for subclinical tissue stiffening and **smartphone non-mydriatic fundus imaging** for diabetic retinopathy (DR).

```
+-----------------------------------------------------------------------------------+
|                        THISULINK VITALS INTEGRATION ARCHITECTURE                  |
+-----------------------------------------------------------------------------------+
|                                                                                   |
|   +------------------------------------+    +---------------------------------+   |
|   | Standard Digital BP Monitor        |    | Standard Digital Glucometer     |   |
|   | (Oscillometric Upper-Arm Cuff)     |    | (Capillary Electrochemical)     |   |
|   | e.g. Omron / A&D / Beurer BLE      |    | e.g. Accu-Chek / OneTouch BLE   |   |
|   +-----------------+------------------+    +----------------+----------------+   |
|                     |                                        |                    |
|                     | Standard BLE GATT                      | Standard BLE GATT  |
|                     | Service 0x1810                         | Service 0x1808     |
|                     v                                        v                    |
|       +-------------------------------------------------------------+             |
|       |               THISULINK FLUTTER MOBILE APP                  |             |
|       |       (Runs on Patient Phone or Health Worker Tablet)       |             |
|       +-----------------------------+-------------------------------+             |
|                                     |                                             |
|                                     | HTTPS / TLS REST API                        |
|                                     v                                             |
|       +-------------------------------------------------------------+             |
|       |                   POCKETBASE BACKEND                        |             |
|       |                 (https://thisulink.xyz)                     |             |
|       |       - Longitudinal Patient Records (ABHA Linked)          |             |
|       |       - Real-time 4-Tier Clinical Triage Engine             |             |
|       +-------------------------------------------------------------+             |
+-----------------------------------------------------------------------------------+
```

---

## 2. Supported Bluetooth SIG Standard Profiles

THISULINK's mobile application (`thisulink_app/`) implements native support for standard Bluetooth Special Interest Group (SIG) GATT services:

### 2.1 Blood Pressure Service (`0x1810`)
* **Service UUID**: `0x1810` (Standard Blood Pressure Service)
* **Characteristic**: `0x2A35` (Blood Pressure Measurement — Indication)
* **Payload Structure**:
  * Flag Byte: Units (mmHg vs. kPa), timestamp present, pulse rate present
  * Systolic Blood Pressure (IEEE-11073 16-bit SFLOAT, mmHg)
  * Diastolic Blood Pressure (IEEE-11073 16-bit SFLOAT, mmHg)
  * Mean Arterial Pressure (MAP, mmHg)
  * Pulse Rate (BPM)
* **Compliance**: Ensures compatibility with any ISO 81060-2 compliant commercial digital monitor without proprietary drivers.

### 2.2 Glucose Service (`0x1808`)
* **Service UUID**: `0x1808` (Standard Glucose Service)
* **Characteristic**: `0x2A18` (Glucose Measurement — Notification)
* **Payload Structure**:
  * Sequence number
  * Timestamp (Year, Month, Day, Hours, Minutes, Seconds)
  * Glucose Concentration (IEEE-11073 16-bit SFLOAT in mg/dL or mmol/L)
  * Sample Type & Location (Capillary Whole Blood, Finger)
* **Compliance**: Conforms to ISO 15197 accuracy standards for point-of-care capillary monitoring.

### 2.3 Transparent UART BLE Bridge (Low-Cost Alternative)
For legacy or low-cost clinic meters lacking built-in Bluetooth, a simple external opto-isolated BLE bridge module (e.g. JDY-08 / nRF52810 dongle) interfaces with the meter's serial test port to broadcast standard ASCII records:
```
$THV1,BP,128,84,72,2026-09-24T08:30:00Z*CS\r\n
$THV1,GLU,142,MGDL,FASTING,2026-09-24T08:32:00Z*CS\r\n
```

---

## 3. Data Integration & Clinical Triage Flow

Once vitals are captured over BLE, they automatically populate the patient's record in SQLite and sync asynchronously to PocketBase:

```dart
// Dart BLE parsing snippet (Flutter App)
void onVitalsReceived(VitalsRecord record) {
  // Store locally offline
  await localDb.insertVital(record);
  
  // Evaluate immediate thresholds locally
  if (record.sbp > 180 || record.glucoseMgDl > 400) {
    escalateTriage(TriageLevel.RED, reason: 'Hypertensive or Hyperglycemic Crisis');
  } else if (record.sbp > 140 || record.glucoseMgDl > 300) {
    escalateTriage(TriageLevel.ORANGE, reason: 'Elevated Stage 2 Vitals');
  }

  // Push to PocketBase when online
  syncService.queueSync();
}
```

### Multimodal Triage Rules Incorporating Vitals
| Priority | Metric | Triage Color Trigger | Clinical Action |
|:---:|:---|:---:|:---|
| **Crisis** | SBP > 180 mmHg or Glucose > 400 mg/dL | 🔴 **RED** | Immediate referral to Medical Officer at PHC / CHC |
| **High Risk** | SBP > 140 mmHg or Glucose > 300 mg/dL | 🟠 **ORANGE** | Health Worker doorstep review & tele-consultation within 48h |
| **Warning** | SBP > 130 mmHg or Glucose > 180 mg/dL | 🟡 **YELLOW** | Medication reminder & lifestyle compliance monitoring |
| **Normal** | SBP $\le$ 120 mmHg and Fasting Glucose $\le$ 130 mg/dL | 🟢 **GREEN** | Routine monitoring |

---

## 4. Summary of Benefits

1. **Zero Clinical Calibration Uncertainty:** No custom machine-learning models predicting blood pressure from finger optical waves.
2. **Immediate Doctor Acceptance:** Readings come from standard oscillometric cuffs and glucose test strips that clinicians already trust.
3. **Reduced BOM Cost & Complexity:** Eliminates custom analog front-ends (AFE), strip connectors, and calibration circuitry from the THISULINK probe housing.
4. **Focused Innovation:** Preserves engineering focus on the breakthrough dual-modality modules: Plantar Shear-Wave Elastography and Non-Mydriatic Smartphone Retinal DR Screening.
