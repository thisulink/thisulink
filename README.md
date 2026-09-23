# THISULINK — Multimodal Diabetic Complication Screening Platform

<p align="center">
  <img src="https://img.shields.io/badge/SIH%202026-%20-orange?style=for-the-badge" alt="SIH 2026"/>
  <img src="https://img.shields.io/badge/Domain-MedTech%20%26%20BioTech-red?style=for-the-badge" alt="Domain"/>
</p>

<p align="center">
  <b>AI-driven daily vital monitoring. Three modalities. One triage colour.</b><br/>
  Designed for community health worker delivery in rural India.
</p>

---

## What is THISULINK?

THISULINK is a multimodal diabetic complication early-detection system built for **Smart India Hackathon 2026**. It addresses two of the most common — and most preventable — complications of diabetes:

| Complication | Leading cause of | THISULINK detection method |
|---|---|---|
| **Diabetic foot / peripheral neuropathy** | Lower-limb amputation | Plantar shear-wave elastography (SWE) via custom VCA probe |
| **Diabetic retinopathy** | Preventable blindness | AI fundus grading (EfficientNet-B0, APTOS 2019, AUC 0.976) |

Both are screened continuously by the patient at home with daily AI reminders, supported by community health workers (ASHA, VHN, ANM, CHO) who are alerted only when triage turns Orange or Red. The system tracks **blood pressure** and **blood glucose** in a single handheld device. All data flows to a **4-tier triage engine** (🟢 Green / 🟡 Yellow / 🟠 Orange / 🔴 Red) running on a self-hosted PocketBase server at `thisulink.xyz`.

> [!IMPORTANT]
> All outputs are **research and screening-assistance results**. 

---

## Platform at a glance

```
Patient (home — self-monitoring with AI daily reminders)
│
├─ Every day ──► AI reminder → BP + Glucose reading (THISULINK-VM device)
│                ├─ PPG waveform → SBP / DBP (cuffless, XGBoost on ESP32-S3)
│                └─ Electrochemical strip → Blood glucose (mg/dL)
│
├─ When available ──► THISULINK Foot Probe (VCA + dual ADXL355 + thermometer)
│                     ├─ 10–300 Hz sweep → c_s → E (kPa) → Tissue class A/B/C
│                     └─ Contact thermometry → ΔT °C → flag if ≥ 2.2°C
│
├─ Periodic ──► Smartphone fundus photo → EfficientNet-B0 → DR grade 0–4
│
└─ All channels → BLE → Flutter app → PocketBase (thisulink.xyz)
                                            │
                               Triage engine (PocketBase JS hook)
                                            │
                    🟢 Green / 🟡 Yellow → patient self-manages
                    🟠 Orange → ASHA / VHN / ANM alerted
                    🔴 Red   → Health Worker + PHC Medical Officer alerted
```

**Community health workers** (ASHA, VHN, ANM, CHO) are alerted **only when triage turns Orange or Red**. No fixed visit schedule — visit happens when the data says it's needed.

**AI reminder system** (no FCM): WorkManager + BGTaskScheduler check daily whether BP and glucose have been recorded. Unacknowledged reminders after 4 hours trigger a health worker relay alert.


---

## Repository map

| Folder | What it contains | Key file |
|---|---|---|
| [`platform matlab simulation and proofs/`](platform%20matlab%20simulation%20and%20proofs/) | 12 MATLAB simulation experiments proving SWE physics — Kelvin-Voigt model, dual-pickup phase delay, shear-wave dispersion, tremor suppression, 120-patient triage cohort | [`README.md`](platform%20matlab%20simulation%20and%20proofs/README.md) |
| [`Clinical_Datasets_and_Parameter_Conversion/`](Clinical_Datasets_and_Parameter_Conversion/) | Literature provenance for all physical constants (ρ, c_s, ΔT threshold) and 5-step mechanical-to-clinical conversion pipeline | [`README.md`](Clinical_Datasets_and_Parameter_Conversion/README.md) |
| [`retinal-screening/`](retinal-screening/) | EfficientNet-B0 retinal DR grading module — APTOS 2019 results, research protocol, evaluation contract, all figures | [`README.md`](retinal-screening/README.md) |
| [`vitals-monitor/`](vitals-monitor/) | Cuffless BP + blood glucose in one ESP32-S3 handheld — PPG/IMU/XGBoost pipeline, electrochemical strip AFE, BLE packet spec | [`README.md`](vitals-monitor/README.md) |
| [`hardware/`](hardware/) | THISULINK foot probe BOM and PCB spec — VCA actuator, dual ADXL355, HX711 load cell, contact thermometer, Velcro stabilisation | [`README.md`](hardware/README.md) |
| [`firmware/`](firmware/) | ESP32-S3 + ADXL345 Arduino firmware POC — ring buffer, IIR biquad DSP, radix-2 FFT, feature extraction | [`README.md`](firmware/thisulink-esp32s3-adxl345/arduino/thisulink_firmware/README.md) |
| [`software/`](software/) | Flutter app architecture — dual-role (ASHA worker + Mentor), BLE probe connect, AI vital reminder system, 5-tab shell | [`README.md`](software/README.md) |
| [`backend/`](backend/) | Self-hosted infra — Cloudflare Tunnel + Tailscale + PocketBase + Node.js/Express — full deployment guide | [`README.md`](backend/README.md) |

---

## Key results (measured, not claimed)

### Retinal DR grading — EfficientNet-B0 on APTOS 2019 (677 held-out test images)

| Metric | Result | 95% CI |
|---|---|---|
| Quadratic weighted kappa | **0.860** | 0.828 – 0.888 |
| 5-grade accuracy | **76.7%** | 73.6 – 79.6% |
| Referable DR: ROC-AUC | **0.976** | — |
| Referable DR: specificity | **96.3%** | 94.4 – 98.0% |
| Calibration error (ECE) | **0.046** | — |

### Plantar SWE — MATLAB simulation (12 experiments)

| Result | Value | Experiment |
|---|---|---|
| Shear-wave speed reconstruction error | < 5% RMSE | Exp 10 |
| Tissue class separation (A/B/C) | E: 43.5 / 96 / 204 kPa | Exp 02 |
| Tremor attenuation (Velcro + flexure, 0–5 Hz) | ≥ 97.5% | Exp 11 |
| 120-patient triage cohort (E + ΔT multimodal) | 4-tier classification | Exp 12 |

### Hardware (THISULINK foot probe)

| Parameter | Value |
|---|---|
| VCA drive force | 0.100 N, 10–300 Hz sweep |
| Load cell interlock | 1.40 – 1.60 N acceptance window |
| Dual ADXL355 separation | Δx = 40 mm (x₁=105 mm, x₂=145 mm) |
| Thermometry threshold | ΔT ≥ 2.2°C (Armstrong & Lavery, *Diabetes Care* 1997) |

---

## Technology stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter 3.19+, Riverpod 2, go_router 14, fl_chart |
| BLE | flutter_blue_plus — 73-byte probe packet |
| AI (retinal, on-device) | EfficientNet-B0 ONNX INT8 via onnxruntime-android |
| AI (vitals) | XGBoost int8 via m2cgen → bare-metal ESP32-S3 |
| AI (clinical assistant) | llama-3.3-70b-versatile via Groq (supervised routing) |
| Backend | PocketBase (auth, DB, files, realtime, JS hooks) |
| Infrastructure | Cloudflare Tunnel + Tailscale + Node.js/Express |
| Notifications | WorkManager + BGTaskScheduler — no FCM, no push cloud |
| Probe MCU | ESP32-S3 + dual ADXL355 + HX711 + VCA driver |
| MATLAB simulation | 12 experiments, Kelvin-Voigt ODE, shear-wave propagation |

---

## Community health worker roles

India's NPCDCS programme does not mandate fixed monthly visits for every diabetic patient. THISULINK is designed around this reality — health workers are alerted **when the data demands it**, not on a calendar.

| Role | Full name | Triggered when |
|---|---|---|
| **ASHA** | Accredited Social Health Activist | 🟠 Orange / 🔴 Red triage or 4-hr unacknowledged reminder |
| **VHN** | Village Health Nurse (Tamil Nadu) | 🟠 Orange / 🔴 Red — doorstep visit |
| **ANM** | Auxiliary Nurse Midwife | Sub-centre follow-up for flagged patients |
| **CHO** | Community Health Officer | Health & Wellness Centre review |
| **MO** | Medical Officer at PHC | 🔴 Red — emergency referral pathway |

---

## Triage logic (PocketBase JS hook)

| Colour | Condition |
|---|---|
| 🔴 Red | Tissue class C **or** (referable DR + grade ≥ 3) **or** glucose > 400 mg/dL **or** SBP > 180 |
| 🟠 Orange | (Class B + ΔT ≥ 2.2°C) **or** referable DR **or** glucose > 300 **or** SBP > 140 |
| 🟡 Yellow | Class B **or** ΔT ≥ 2.2°C **or** DR grade ≥ 2 **or** glucose > 180 **or** SBP > 130 |
| 🟢 Green | None of the above |

---

## Deployment

```bash
# Self-hosted on a Linux laptop, exposed via Cloudflare Tunnel
# No cloud VM, no open ports, no static IP required

# 1. PocketBase at thisulink.xyz (direct)
# 2. Express API at api.thisulink.xyz (ONNX retinal grading)
# 3. Tailscale for SSH and admin panel access

# Health check
curl https://api.thisulink.xyz/api/health
```

Full deployment guide → [`backend/README.md`](backend/README.md)

---

## Safety statement

This system is a **research and screening-assistance prototype**. It is not a certified medical device. All outputs (triage colours, DR grades, BP estimates, glucose readings) are research results that a qualified clinician must review before any clinical decision is made. The platform is not approved by CDSCO, FDA, or CE for diagnostic use.

---

## References

| Reference | Used for |
|---|---|
| Armstrong & Lavery, *Diabetes Care* 1997 | Thermometry threshold ΔT ≥ 2.2°C |
| Raman et al., *Indian J Ophthalmol* 2019 | Referable DR = ICDR grade ≥ 2 (Indian consensus) |
| APTOS 2019, Aravind Eye Hospital, Kaggle | Retinal training dataset (3,385 images) |
| PubMed PMID 40030275 | PPG-only cuffless BP — 25-study systematic review |
| FDA Draft Guidance, January 2026 | Cuffless BP clinical performance testing requirements |
| WHO South-East Asia DR Report | Rural screening motivation |

---

## Prior-Art Differentiation

### The Closest Prior Art: VIBRASENSE (Ayati Devices / BETiC, IIT Bombay)

The most technically relevant Indian prior art is **VIBRASENSE**, developed at the Biomedical Engineering and Technology Incubation Centre (BETiC), IIT Bombay, commercialised by **Ayati Devices Pvt. Ltd.** (SINE incubatee), and CDSCO-approved. It addresses the same clinical problem — portable diabetic foot neuropathy screening in India.

Understanding exactly how VIBRASENSE works is required to understand where THISULINK is technically different.

#### What VIBRASENSE Does

VIBRASENSE is a **quantitative sensory testing (QST) device** that measures **Vibration Perception Threshold (VPT)**:

1. A 12 mm probe tip is placed on a single anatomical site (great toe, metatarsal head).
2. The probe delivers a **single controlled sinusoidal vibration at a fixed frequency** (amplitude up to 6 µm displacement).
3. The clinician increases amplitude until the patient reports feeling the vibration. That amplitude is the VPT in arbitrary units (Volts or microns).
4. VPT is elevated when large-fibre sensory nerve axons are already lost — i.e., when **established peripheral neuropathy is present**.

VIBRASENSE+T extends this by adding warm and cold temperature perception thresholds (small-fibre testing). Both versions depend on **patient self-report** of "I can feel it now".

#### What THISULINK SWE Probe Does — and Why It Is Different

THISULINK's plantar probe measures **tissue mechanical properties directly**, without relying on patient sensation reporting:

1. A Voice Coil Actuator (VCA) drives a **broadband mechanical chirp (10–300 Hz, 200 ms)** — not a single frequency.
2. Two ADXL355 accelerometers at x₁ = 105 mm and x₂ = 145 mm from the actuator record the **travelling shear wave's phase delay** as it propagates through plantar tissue.
3. Shear-wave speed `c_s = 2πfΔx / Δφ(f)` is computed per frequency bin; Young's modulus is derived as `E = 3ρc_s²`.
4. The tissue is classified as A / B / C based on the computed modulus — **no patient input required at any step**.

| Technical property | VIBRASENSE (IITB/BETiC) | THISULINK SWE Probe |
|---|---|---|
| **Physical stimulus** | Single-frequency sinusoidal vibration (fixed freq.) | Broadband chirp 10–300 Hz (30 frequency bins) |
| **Measured quantity** | Vibration perception threshold — patient self-report | Shear-wave phase velocity — accelerometer signal processing |
| **What the output represents** | Nerve conduction function (large-fibre or small-fibre) | Tissue mechanical stiffness (Young's modulus E, shear-wave speed c_s) |
| **Requires patient cooperation?** | ✅ Yes — patient must report sensation onset | ❌ No — fully objective, no patient input |
| **Detects subclinical glycation stiffening (Class B)?** | ❌ No — VPT is normal until nerve fibres are lost | ✅ Yes — E rises from ~43.5 kPa (Class A) to ~96 kPa (Class B) before nerve loss (simulation-validated) |
| **Thermal asymmetry channel** | ❌ None in VIBRASENSE; VIBRASENSE+T adds thermal QST (perception threshold only) | ✅ MLX90621 16×4 FIR array, 64 pixels, ΔT ≥ 2.2 °C flag (Lavery et al. 2004) |
| **Propagation physics** | Forced vibration (standing-wave, single site) | Travelling shear wave (two-point phase-velocity measurement) |
| **BOM cost estimate** | Commercial device, priced for clinic/hospital use | ₹12,000–₹18,000 (field-deployable BOM) |
| **Regulatory status** | CDSCO-approved (Class B medical device) | Prototype — CDSCO submission not yet filed |

#### The Core Technical Claim

> VIBRASENSE answers: *"Have this patient's nerve fibres already been damaged?"*
>
> THISULINK answers: *"Has this patient's plantar tissue already become pathologically stiff — before their nerve fibres are lost?"*

These are **different questions at different stages of the disease trajectory**:

```
Healthy foot
    │
    ├─► Hyperglycaemia → non-enzymatic glycation → collagen cross-linking
    │         │
    │         ▼
    │   Plantar tissue stiffens:  E: 43.5 kPa → 96 kPa  [THISULINK detects here — Class B]
    │         │
    │         ▼
    │   Microvascular ischaemia → peripheral nerve axon loss
    │         │
    │         ▼
    │   Vibration perception threshold rises  [VIBRASENSE / biothesiometer detects here]
    │         │
    │         ▼
    │   Established peripheral neuropathy → ulcer risk
    │         │
    │         ▼
    └─► Ulceration → amputation
```

THISULINK's Class B detection targets the **mechanically stiff, neurologically intact** phase — the window where glycation-driven stiffening can be flagged before large-fibre nerve damage is measurable. This mechanistic claim is derived from the tissue viscoelastic model in MATLAB Experiments 01–02 and requires human-subject clinical comparison against simultaneous biothesiometer VPT for validation.

> [!IMPORTANT]
> The subclinical detection claim (Class B preceding nerve-fibre loss) is **simulation-validated only**. Clinical confirmation via a head-to-head comparison with VIBRASENSE VPT and histological tissue sampling has not been performed. This is the highest-priority validation gap.

---

### Full Device Comparison Table

| Device | Measuring method | Subclinical stiffness | Objective (no patient report) | Thermal channel | Digital/BLE output | India price |
|---|---|---|---|---|---|---|
| **Biothesiometer** | VPT, 128 Hz, single site | ❌ | ❌ | ❌ | ❌ | ₹10,500–40,000 |
| **VIBRASENSE** (Ayati/IITB) | VPT, digital QST, 12 mm probe, single freq. | ❌ | ❌ (patient reports) | ❌ (VIBRASENSE+T adds thermal QST) | ✅ App + digital report | Commercial (clinic-priced) |
| **Yostra NEURO TOUCH** | VPT + monofilament + pressure, automated | ❌ | Partially (auto sequence) | ❌ | ✅ | ₹60,000–₹1,20,000 |
| **10 g Monofilament** | Pressure threshold | ❌ | ❌ | ❌ | ❌ | < ₹500 |
| **THISULINK SWE Probe** | Broadband SWE, 10–300 Hz chirp, dual accelerometer | ✅ Class B (simulation) | ✅ Fully objective | ✅ 16×4 FIR array | ✅ BLE 5.0 | ₹12,000–18,000 |

### Retinal Screening

| Device / Service | Approach | Typical India access | Key limitation vs. THISULINK |
|---|---|---|---|
| **Remidio FOP (Fundus-on-Phone)** | Smartphone non-mydriatic fundus camera, grades by ophthalmologist telemedicine | ₹4,12,000 per unit | Hardware cost prohibitive for PHC; no AI on-device grading; no integration with foot/vitals data |
| **Aravind / Sankara telemedicine** | Fundus photo → ophthalmologist grading | City-based hub and spoke | Rural patient must travel to hub; no field-worker deployment |
| **THISULINK Retinal Module** | Smartphone + 20D adapter, EfficientNet-B0 AI grading (AUC 0.976 on APTOS 2019 test set), on-device ONNX INT8 offline | Smartphone + ₹500–₹1,200 lens adapter | AI-only (no ophthalmologist in loop at capture time); external validation pending |

**Key differentiator**: Remidio FOP costs ₹4,12,000. THISULINK's retinal module uses the health worker's existing smartphone plus a low-cost 20D adapter and runs AI inference on-device when offline — reducing hardware cost by ~99 %. The trade-off is that AI grading replaces (but does not yet match) a trained ophthalmologist's reading at the point of care; a telemedicine ophthalmologist review is still required for Orange/Red triage cases.

### Vitals Monitor

| Device | Approach | THISULINK equivalent |
|---|---|---|
| OMRON / A&D digital BP monitor | Oscillometric cuff | PPG-based cuffless BP (IEEE JBHI 2025, PMID 40030275) — research stage, not validated for regulatory submission |
| Glucometer (Accu-Chek, OneTouch) | Finger-prick electrochemical | PPG-based non-invasive glucose — research stage only |

> [!IMPORTANT]
> PPG-based cuffless BP and non-invasive glucose are **research-stage methods**. They are not approved as replacements for cuff BP or glucometer readings. THISULINK presents them as supplementary indicators, not primary diagnostic measurements.

---

## License

MIT — see [`LICENSE`](LICENSE)

---

<p align="center">
  Built for <b>Smart India Hackathon 2026</b> — Healthcare &amp; BioMedical Track<br/>
  <a href="https://thisulink.xyz">thisulink.xyz</a> · <a href="https://github.com/thisulink/thisulink">github.com/thisulink/thisulink</a>
</p>
